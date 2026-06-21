Read @docs/CODEBASE.md for context on the codebase.

We are currently focusing on fixing detected bugs. Read @docs/BUGS.md and @docs/BUGFIX_STRATEGY.md
For how to verify fixes in-engine, read @docs/PLAYTEST_VERIFICATION.md

## Where we left off (updated 2026-06-20)

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
1. **Still-open Tier 2 remotes** (each has a design question in BUGFIX_STRATEGY.md → Tier 2):
   - Consumables **C3/C4** (`ConsumableReceiver` — heal/dispose; the heal remote can damage any
     humanoid with a negative number). Probably the cleanest next batch.
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
