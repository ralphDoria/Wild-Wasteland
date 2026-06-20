# Bugfix Strategy

Companion to [BUGS.md](BUGS.md) (68 findings, audited 2026-06-11). This documents the agreed plan of
attack, why the bugs are **not** being fixed in one pass, and the order of operations.

**Key decisions:**
- A unit testing framework is implemented *before* the complex fixes (Tier 3, and ideally before Tier 2).
- The approach is **targeted rewrites inside a refactor**, *not* a ground-up rewrite — see below.

---

## Approach: targeted rewrites inside a refactor

We explicitly evaluated a near-full rewrite versus refactoring the systems we have. **Decision: refactor,
with two surgical rewrites.** A ground-up rewrite would be slower *and* riskier here, for reasons specific
to this project — not a generic distaste for rewrites.

**Why a full rewrite loses:**

1. **The code is not the product — the place file is.** `default.project.json` is a *partial sync* into an
   existing Studio place (see CODEBASE.md → "Live Studio Place"). The map, all 19 ScreenGuis, every tool
   model, the animations, and the rigs live in the place, not the repo. The ~16k lines we'd rewrite are
   welded to that place by hundreds of hard dependencies — instance names, attributes, hierarchy paths,
   tag names, GUI templates. A script rewrite still has to honor that entire undocumented contract, so it
   gets the same minefield with none of the working code that already navigates it. This coupling is what
   kills Roblox rewrites.
2. **The bugs don't indicate rot.** The criticals are one systemic problem — "server trusts client" — which
   is a *missing layer*, not architectural decay. The audit rates most of them as "copy the existing gun
   `ServerChecks` pattern." Tier 1 already cleared ~25 bugs with tiny diffs. That is a fixable codebase.
3. **A rewrite is riskiest exactly where we're weakest:** no tests yet (we'd rewrite blind) and two-thirds
   of the codebase is still unreviewed (we'd rewrite systems we haven't characterized). It also discards
   hard-won Roblox-specific knowledge already baked into the code (e.g. the self-healing hitbox fix for
   client-tag-stripping-on-reparent, commit `0d3da3b`).

**What we keep (refactor only their specific bugs):** the item OOP hierarchy, inventory drag/drop, the
viewmodel system, the NPC FSM, and the looting system all work — touch them only for their documented bugs.

**The two surgical rewrites** (where rewrite genuinely beats retrofit):

- **The server-authority boundary (Tier 2).** Don't harden 14 remotes ad hoc — build the missing layer
  *once*: a single server-side validation/ownership gate that every remote routes through, modeled on the
  gun path's `ServerChecks`/`TypeValidation`. This is the strong version of the rewrite instinct — rewrite
  the *seam*, not the systems.
- **The vitals (hunger/thirst/stamina) subsystem (Tier 3).** It is client-authoritative *and* incomplete —
  there is no food/drink restore path at all (M12). Since we're building new functionality there regardless,
  writing it server-authoritative from scratch is cleaner than retrofitting the current decay-only loop.

**What would change this decision:** switching engine/framework, rebuilding the place itself, or finding the
core data model is fundamentally wrong. None hold today — the remaining bugs are validation gaps and
lifecycle races, which are surgically fixable.

---

## Verification policy

**No bugfix batch is "done" until it is verified in-engine.** Every batch (a tier, or a system-sized
slice of a tier) must be checked against [PLAYTEST_VERIFICATION.md](PLAYTEST_VERIFICATION.md) before
it is considered complete and before moving to the next batch.

Rules:

1. **Each fix ships with a check.** When a batch is written, add a corresponding entry to
   PLAYTEST_VERIFICATION.md (bug ID → reproduce → ✅ pass → ❌ fail signature) in the same change.
   A fix with no verification step is not finished.
2. **Run order:** single-client Studio playtest (or MCP `start_playtest` / `get_playtest_output`)
   for logic and Output-cleanliness; a **2-player Studio test server** for any item marked ★
   (replication — e.g. H1), since the MCP drives only one client.
3. **Gating severity:** a failed check on a 🔴/🟠 item blocks the batch; a failed 🟡/🔵 check is
   logged and triaged but need not block.
4. **Once the test suite exists** (see below), unit-testable bugs must also have a green test; the
   playtest guide remains the authority for replication, animation-timing, drag-input, and
   multi-client behavior that unit tests can't cover.

---

## Why not one-shot all 68

1. **Verification is the bottleneck, not code.** The repo has no test framework; today the only check is
   manual playtesting. A 68-fix mega-commit would be unve   rifiable.
2. **The criticals are design changes, not patches.** Most of C1-C16 require gameplay decisions (see the
   design questions below) before the validation code can even be written. C9/M12 requires building a
   feature that doesn't exist yet (hunger/thirst restore).
3. **Fixes interact with unreviewed code.** Two-thirds of the codebase hasn't been deep-reviewed
   (see "Review coverage" in BUGS.md); some of it may depend on current buggy behavior. Known example:
   the C7 fix (quantity-transfer validation) must preserve `SplittingMenuManager`'s legitimate
   `transfer 0` cleanup call (`SplittingMenuManager.lua:119`).
4. **Some fixes need human feel-testing** — recoil, equip timing, aiming transitions (M2-M4) can be
   "correct" and still feel wrong.

---

## The three tiers

### Tier 1 — Mechanical fixes (~25 bugs, one session, low risk)

Unambiguous one-to-five-line fixes with small blast radius. Safe to do **before** the testing framework
exists; verified with a Studio smoke test (MCP playtest).

| Fix | Bugs |
|-----|------|
| Pass the player to `FireClient` | H1 |
| `return` → `continue` in slot finders | INV-H3 |
| `actionNames.aiming` → `actionNames.inspect` | M1 |
| Fire signal before assigning (old/new values) | M7 |
| Divide by `MAX_STAMINA`, not `MaxHealth` | M8 |
| Female sound's own `TimeLength` | M9 |
| Clamp in `changeStaminaBarBy` | M10 |
| Assert order / wrong-variable asserts | H3, H6 |
| Nil guards | H2, H5, H7, H10, H11, H12, INV-H2, INV-H5, INV-H6, H8 |
| Vault door close sound | M16 |
| Light Bullets `continue` | M18 |
| Always-true elseif | INV-M2 |
| Disable template prompt → clone | M14 (first part) |
| `game:BindToClose` for DataStores | M15 (partial — full retry/session-locking is Tier 3) |
| Delete debug prints/warns, `local` the Hover globals, typos | L2, L7, INV-L1, INV-L4 |
| Delete the two indefensible remotes outright | C1 (`SpawnTool` OnServerEvent), C2 (`ChangeHumanoidWalkSpeed`) |

C1/C2 are included here because deletion *is* the fix — `SpawnTool`'s only legit callers are commented-out
dev-spawn lines, and no shipped client code calls `ChangeHumanoidWalkSpeed` legitimately enough to justify
its existence (verify with a grep for the remote names before deleting).

### Tier 2 — Build the server-authority boundary (most of C3-C16, ~1-2 days once questions are answered)

**Frame this as building one layer, not patching N remotes** (see "Approach" above). First stand up a shared
server-side validation/ownership module — reusing the gun path's `TypeValidation` and adding an ownership
helper (e.g. `isOwnedBySender(player, instance)` = ancestry check against the sender's character/Backpack/
WornItems) — then route each remote's handler through it. Same end state as per-remote hardening, but the
rules live in one place and are unit-testable once instead of re-derived per file.

The per-remote work is formulaic once the layer exists, but each remote still needs a design decision first:

**Design questions to answer before starting Tier 2:**
1. **Melee damage model** — move damage to per-weapon server-side attributes (like guns)? What validation:
   equipped-melee check + swing-rate limit + distance? (C6)
2. **Heal remote** — should healing amounts come from the consumable's server-side attributes, with the
   server consuming the item? (C3, C4)
3. **Respawn remote** — does free client-triggered respawn have a legit use, or delete and make the server
   own the death→respawn flow? (C16)
4. **Teleport-to-spawn** — server picks the spawn point itself instead of trusting a CFrame? (C5)
5. **Stackable ownership** — define "owns": tool in player's Backpack/character/WornItems only? How do loot
   container stacks get merged — via the lootable authorization layer instead? (C7)
6. **Corpse creation** — move corpse-data assembly server-side at death time (server snapshots the dying
   player's inventory) instead of trusting the client? (C12)
7. **Hunger/thirst authority** — full server-side simulation (Tier 3), or interim server-side caps/rate
   limits on the existing remote? (C9)
8. **Sound replication** — whitelist sounds by name against the tool's own `soundObjects`? Rate limit? (C14, C15's soundName)
9. **CanCollide / DropTool / wearables** — require the instance to be a tool the *sender owns* (ancestry
   check against their character/backpack)? (C10, C11, C13)

Also in this tier: GunReceiver item-type + fire-rate validation (C15), LootDataService's
`OverrideItemData` removal or validation (C8) and the busy-wait timeout (M17).

**Prerequisite reading:** before trusting the gun chain as the template, deep-review the 5 unread
`TypeValidation` modules and `castRays`/`canPlayerDamageHumanoid` (flagged in BUGS.md Review coverage).

### Tier 3 — Architectural fixes (week-plus, iterative, tests required first)

In dependency order:

1. **Server-authoritative vitals — subsystem rewrite** (C9, M11, M12, M13). This is one of the two
   sanctioned rewrites (see "Approach"): the current hunger/thirst loop is client-authoritative and
   decay-only, so rather than retrofit it, rebuild it server-side from scratch, *including designing and
   building the food/drink restore path that doesn't exist yet*. Biggest single chunk.
2. **Gun state machine** (M2, M3, M4) — per-instance aiming state, fire-state vs reload races,
   interruption-safe reload completion. Needs feel-testing by a human.
3. **Item/Melee lifecycle** (M5, M6, L3) — interruption-safe swing, Died-connection cleanup,
   bounded animation waits.
4. **Tool state machine & slot registry** (M19, M20, INV-H1, INV-H4, INV-M3, INV-M6) — promise-chain
   cancellation, registry ordering. Do this *after* reviewing the six unread drag handlers, since they
   are the main consumers.
5. **Looting authorization layer** (C8, C12, H5, H6, M17) — requires first deep-reviewing
   `CorpseLootable.lua` / `StandardLootable.lua` (unreviewed).
6. **Corpse lifecycle & DataStore hardening** (L1, M15 full) — corpse cleanup policy, save retry,
   optional session locking.

---

## Testing framework (do this before Tier 2/3)

**Plan:** implement unit testing first, then hand the complex bugs to Claude with tests as the safety net.

**Chosen: TestEZ** (`roblox/testez@0.4.1`), installed as a Wally **dev-dependency** (`wally.toml`
`[dev-dependencies]`). It regenerates into `DevPackages/` on `wally install` and is gitignored like
`Packages/`.

How it's wired:
- `tests/specs/*.spec.lua` — TestEZ spec modules (discovered by the runner).
- `tests/TestRunner.server.lua` — `TestBootstrap:run` entry point with a `TextReporter`.
- `test.project.json` — a **separate** Rojo project that overlays `DevPackages`,
  `ReplicatedStorage.Tests` (← `tests/specs`), and `ServerScriptService.TestRunner` onto the normal
  source tree. The production `default.project.json` is untouched, so tests never ship to the live place.

Run it: `rojo serve test.project.json` → connect in Studio → **Play** (runner prints PASS/FAIL to
Output and errors on failure). Or `rojo build test.project.json -o test.rbxl` for a throwaway test place.
In-session checks can also drive it via the MCP (`start_playtest` / `get_playtest_output`).

(Jest-Lua was the alternative; TestEZ was chosen for simplicity and documentation.)

**What's actually unit-testable here (write these first — they directly cover documented bugs):**
- `GetStatePath` — state-path generation (guards M19/M20)
- `EmptySlotFinder` / `StackableSlotFinder` — slot search across mock registries (guards INV-H3; the
  nondeterministic-iteration bug is exactly the kind unit tests catch)
- `StackableReceiver` math — merge/transfer/subtract logic extracted into pure functions (guards C7, H2, H3;
  duplication via negative transfer becomes a one-line test case)
- The `ServerChecks`/`TypeValidation` validators — pure functions already, trivially testable (guards C15
  and validates the Tier 2 template)
- `findThresholdSection` and stamina math (guards M8, M10)
- `CalculateExpectedPathTime`, `getSlotType`/`getSlotData` with mock hierarchies (guards INV-H5, INV-L3)

**What unit tests won't cover** (don't over-invest trying): replication (H1), animation-event timing
(M4, M5), drag input flows (INV-M3, INV-M4), multi-client behavior. These stay on playtest verification —
note the MCP drives a single Studio client, so true multi-client replication tests (e.g. verifying the H1
fix) need Studio's multi-client test server run by a human.

**Refactor note:** several testability targets require extracting logic from scripts into ModuleScript pure
functions (StackableReceiver math especially). Do that extraction as part of the framework setup, *before*
fixing the logic, so the tests pin current-minus-bug behavior.

---

## Estimates

| Phase | Effort |
|-------|--------|
| Tier 1 | One session (~1-2 hours including Studio smoke test) |
| Testing framework + first test suites | 1-2 sessions |
| Tier 2 (after design questions answered) | ~1-2 days of focused sessions |
| Tier 3 | Week-plus of iterative sessions, one system at a time, playtests between |
| Solo human equivalent, total | ~4-6 weeks |

## Sequence

1. ✅ Audit complete (BUGS.md)
2. ✅ Tier 1 mechanical pass (commits `fbfc7dd`, `0d3da3b`) — verify via
   [PLAYTEST_VERIFICATION.md](PLAYTEST_VERIFICATION.md)
3. ⬜ Unit testing framework + suites for the testable modules above
4. ⬜ Answer the 9 Tier 2 design questions
5. 🟡 Deep-review the security-relevant unread files — TypeValidation + castRays/canPlayerDamageHumanoid
   ✅ done; CorpseLootable/StandardLootable still pending (needed before the looting batch)
6. 🟡 Tier 2: shared server-authority boundary built (`Receivers/Validation`: type validators +
   `Ownership`, gun's TypeValidation migrated in, `TypeValidation.spec` green). Routing each remote
   through it, batched by system, tests green between batches:
   - ✅ Batch 1 — Stackable (C7): `StackableMath` extracted + spec'd, receiver type/ownership-gated
     (merge left un-gated pending the loot authz layer, Q5). Playtest gate still open.
   - ⬜ Next: melee (C6, damage from a server-side per-weapon attribute), then C10/C11/C13.
7. ⬜ Tier 3 one system at a time, in the order listed, human playtest after each. Vitals (item 1) is a
   deliberate server-authoritative **rewrite**, not a refactor.
