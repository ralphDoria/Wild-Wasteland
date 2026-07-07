Read @docs/CODEBASE.md for context on the codebase.

We are currently focusing on fixing detected bugs. Read @docs/BUGS.md and @docs/BUGFIX_STRATEGY.md
For how to verify fixes in-engine, read @docs/PLAYTEST_VERIFICATION.md

## Vitals rewrite (Tier 3, started 2026-07-06 on branch `vitals-rewrite`)

The sanctioned server-authoritative vitals rewrite is underway on `vitals-rewrite`
(cut from `fable-5-gonna-fix-it-all` @ `adc0eb1`). Full plan: docs/VITALS_REWRITE_PLAN.md.
Architecture: shared `Data/VitalsConfig` + pure `Sim/VitalsSim`; server `VitalsSystem_Server/
VitalsService` (one Heartbeat tick, player-attribute replication, `restore()` mutation API);
client managers become views.

- ✅ **Batch V0** — config + pure sim + `VitalsSim.spec`/`VitalsConfig.spec` (commit `0b0beba`).
  ⚠ Specs not yet run in-engine.
- 🟡 **Batch V1** — server hunger/thirst + starvation damage (C9/M12/M13), client
  `HungerThirstManager` rewritten as attribute-driven view (M11), `hungerThirstDamage`
  listener deleted, `RespawnPlayerCharacter` gated dead-only + rate limit (C16). Code
  complete; **playtest gate OPEN** (PLAYTEST_VERIFICATION.md → Tier 3 Batch V1).
- 🟡 **Batch V2** — stamina authority + movement intent (C2, M7–M10). Server: stamina in
  `VitalsService` (`Stamina` attribute; sprint gated on server pool; drain only while the
  server observes movement; jump cost on `StateChanged→Jumping`; swing cost in
  `MeleeReceiver.Swing`). New `MovementIntent` remote (mode name only, created at runtime
  by `MovementAndStaminaSystem_Server/Main.server.lua`) replaces the deleted
  `ChangeHumanoidWalkSpeed` handler (Studio remote now inert). Client: `StaminaManager` =
  VitalsSim prediction + attribute reconciliation; Sprint/Crouch fire intents; Melee cost
  reads VitalsConfig. `SprintReceiver.lua` stub (L5) deleted. Specs extended. Code
  complete; **playtest gate OPEN** (PLAYTEST_VERIFICATION.md → Tier 3 Batch V2).
- 🟡 **Batch V3** — restore path (M12's missing food/drink feature). `ConsumableStats`
  entries reshaped: `healAmount` → `restores = {Health/Hunger/Thirst/Stamina = n}`;
  `ConsumableReceiver.heal` applies Health to the humanoid and routes the rest through
  `VitalsService.restore`. Healing Injection unchanged in behavior (Health 25 only — no
  food/drink item exists yet; the hunger/thirst leg is playtested via a temporary config
  tweak). `ConsumableStats.spec` rewritten (restore-key whitelist catches typos). Code
  complete; **playtest gate OPEN** (PLAYTEST_VERIFICATION.md → Tier 3 Batch V3).

Note: `npc-system-v2` had uncommitted Phase 3.4 WIP when this branch was cut — it is in
`git stash` ("npc-system-v2 WIP: Phase 3.4 target re-evaluation"); pop it when back on
that branch.

## Where we left off (updated 2026-07-05)

**Plan of record:** targeted rewrites inside a refactor — NOT a ground-up rewrite. See the
"Approach" section in BUGFIX_STRATEGY.md. Two sanctioned rewrites: the server-authority boundary
(Tier 2) and the vitals subsystem (Tier 3). Everything else is refactored for its specific bugs only.

**Progress:**
- ✅ Tier 1 mechanical pass — commits `fbfc7dd`, `0d3da3b` (not yet playtest-verified per the policy).
- ✅ Testing framework: **TestEZ** installed as a Wally dev-dependency (`DevPackages/`, gitignored).
  Wired via `tests/specs/*.spec.lua`, `tests/TestRunner.server.lua`, and `test.project.json`
  (a separate Rojo project overlaying tests onto the source — production `default.project.json`
  is untouched). Run by serving `test.project.json` and pressing Play, or via the Studio MCP.
- ✅ Tier 2 Batch 0 — shared server-authority validation layer:
  `src/ServerScriptService/ItemSystem_Server/Revamp/Receivers/Validation/`
  (`TypeValidation/` incl. new `isBoundedNumber`/`isInteger`, `Ownership.lua`, `init.lua` aggregator).
  The gun's old `TypeValidation/` was **migrated** into it and `GunReceiver`/`validateShootArguments`
  re-pointed. `TypeValidation.spec` = 19/19 green in-engine.
- ✅ Tier 2 Batch 1 — **Stackable remotes routed through the boundary** (C7). New pure
  `Receivers/Components/StackableMath.lua` (merge/transfer arithmetic) + `StackableMath.spec`
  (negative-transfer dupe is now a failing-input test). `StackableReceiver` re-pointed:
  type-validates all operands; ownership-gates `RequestQuantityTransfer` + `RequestDuplicateStackable`
  (caller-owned only) and `DestroyUnusedStackable`; `RequestMergeStackables` left **un-gated** on
  purpose (it legitimately merges loot-container stacks — that gate is design Q5, the looting batch).
  Decisions this session: do Stackable before melee; melee damage (future) reads from a server-side
  per-weapon attribute. ✅ Playtest-verified 2026-06-20 (split menu opens, no dup on
  split/cancel, loot-stack merges intact). Committed: `6de7cdf` (+ harness `c9bee4c`, Batch 0
  `53bffc1`, looting M17/H4 `cc66952`, docs `9ce3c77`).
- ✅ Tier 2 Batch 2 — **Melee Hit routed through the boundary** (C6). Damage is now
  server-authoritative: chose a **config module** (`ItemSystem_ScriptStorage/Data/CombatStats.lua`,
  keyed by tool name) over per-instance Studio attributes, to keep balance version-controlled and
  testable (the gun path still uses instance attributes — could migrate later). `MeleeReceiver.Hit`
  picks the equipped weapon server-side, ignores the client damage, validates Humanoid/range/
  ownership, and rate-limits per-(player, target) so cleave still works. `CombatStats.spec` shape
  test. Client `Melee` reads the same config. ✅ Playtest-verified 2026-06-20.
- ✅ Tier 2 Batch 3 — **Shared ownership remotes** (C10/C11). `DropTool` now requires the tool be a
  `Tool` the sender owns; `ToggleToolCanCollide` requires the model belong to a real `Tool` that's
  sender-owned or already dropped in `workspace` (blocks map-geometry noclip + tool disarm). Plus
  `isInstance` guards on `RequestPickUpTool`/`PlaySound`. ✅ Playtest-verified 2026-06-20.
  Committed `945edc2`. (Full C14 sound whitelist/rate-limit still deferred — design Q8.)
- ✅ Tier 2 Batch 4 — **Wearable remote** (C13). `WearableReceiver.ToggleWear` validates every arg:
  `character` must be the sender's; `tool` sender-owned; `thisAccessory` descendant of the tool;
  `originalAccessory` descendant of the tool's `ToolCatalog` folder; category validated; `error()`s →
  graceful returns. `MakeAccessoryVisibleOnDeath` reveals only the sender's own accessory.
  Ownership.lua TODO corrected (WornItems is under Backpack). ✅ Playtest-verified 2026-06-20.
- 🔵 Also fixed this session (outside the Tier 2 batches): the looting infinite-yield
  (`GetChangeReplicatorRemote` M17 + `ToolSpawner` H4) — see `cc66952`.
- 🟡 Tier 2 Batch 5 — **Consumable remotes** (C3/C4), committed 2026-07-03. `Heal` ignores both
  client args: heals the sender's own humanoid only, by `Data/ConsumableStats` amount for the
  *equipped* consumable, per-player `useCooldown`, server consumes the item; `Dispose` honored
  only for the tool the server just consumed (it's just the all-clients cleanup echo trigger).
  `ConsumableStats.spec` green (2026-07-05, in the 69/69 suite run). **⚠ Playtest gate OPEN** —
  the batch is NOT verified yet: run the Batch 5 checks in PLAYTEST_VERIFICATION.md (heal
  works + item consumed + cooldown caps spam). The can't-heal-others/negative checks are
  satisfied by inspection (the handler no longer reads those args). **The bugfix workstream is
  paused here** (2026-07-05) while NPC System v2 is built on branch `npc-system-v2`.

**Important working-session detail:** connect Rojo with **`test.project.json`** (not
`default.project.json`) during Tier 2 dev, so DevPackages + tests sync and specs can run in-session.
Do a final per-batch verification pass on `default.project.json` to confirm what actually ships.

**Session end 2026-06-20:** Tier 2 Batches 0–4 are all committed and playtest-verified, plus the
looting infinite-yield fix. Branch `fable-5-gonna-fix-it-all`; **nothing pushed to origin yet.**
Working tree clean at session end. Commits this session (oldest→newest): `c9bee4c` (harness +
sourcemap untrack), `53bffc1` (Batch 0), `6de7cdf` (Batch 1), `cc66952` (looting M17/H4), `9ce3c77`
(docs move), `62a495f` (Batch 1 verified), `7c94b0f` (Batch 2 melee), `945edc2` (Batch 3 C10/C11),
+ this Batch 4 commit.

**Next steps (pick up here):**
1. **Verify Batch 5 in-engine** (see the ⚠ open gate above) — then the still-open Tier 2
   remotes (each has a design question in BUGFIX_STRATEGY.md → Tier 2):
   - Vitals/respawn **C9/C16** — but C9 (hunger/thirst authority) overlaps the Tier 3 vitals rewrite;
     decide whether to do an interim cap or fold into Tier 3.
   - **C14** sound whitelist/rate-limit (Q8) — `PlaySound` only has a type guard so far.
   - Looting **C8/C12** — gated on first deep-reviewing `CorpseLootable.lua` / `StandardLootable.lua`
     (still unreviewed). Also the looting `ToggleWornWearableAccessory` remote (corpse-side twin of
     C13, in `LootingSystemExecutor`) needs the same treatment.
2. **Open manual gate:** Batch 0 gun regression smoke test was never run (equip Beretta, empty a mag
   into a dummy, reload; confirm unchanged) — low risk since it was a pure relocation, but unticked.
3. The looting redesign (registration/readiness, and whether loot-change replication should be on a
   reliable rather than Unreliable remote) is noted as a **Tier 3** item — see the diagnosis in this
   session's discussion of `GetChangeReplicatorRemote`.
