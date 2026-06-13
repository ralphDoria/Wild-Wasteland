# Bugfix Strategy

Companion to [BUGS.md](BUGS.md) (68 findings, audited 2026-06-11). This documents the agreed plan of
attack, why the bugs are **not** being fixed in one pass, and the order of operations.

**Key decision:** a unit testing framework will be implemented *before* attempting the complex fixes
(Tier 3, and ideally before Tier 2). Rationale below.

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

### Tier 2 — Server validation hardening (most of C3-C16, ~1-2 days once questions are answered)

Formulaic in shape — copy the existing `ServerChecks`/`TypeValidation` pattern from the gun path — but each
remote needs a design decision first:

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

1. **Server-authoritative vitals** (C9, M11, M12, M13) — includes *designing and building* the
   food/drink restore path, which doesn't exist. Biggest single chunk.
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

Options (repo already uses Wally, so any of these install cleanly):
- **Jest-Lua** (`jsdotlua/jest-lua` fork on Wally) — actively maintained, familiar Jest API, best choice
  if starting fresh.
- **TestEZ** (`roblox/testez`) — older Roblox standard, simpler, widely documented.
Runner: `run-in-roblox` (aftman-installable) for CI-style runs, or a Studio test-runner script invoked via
the MCP (`execute_luau` / `start_playtest` + `get_playtest_output`) for in-session verification.

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
2. ⬜ Tier 1 mechanical pass (can happen anytime, including now)
3. ⬜ Unit testing framework + suites for the testable modules above
4. ⬜ Answer the 9 Tier 2 design questions
5. ⬜ Deep-review the security-relevant unread files (TypeValidation, castRays, CorpseLootable/StandardLootable)
6. ⬜ Tier 2 server hardening, batched by system, tests green between batches
7. ⬜ Tier 3 one system at a time, in the order listed, human playtest after each
