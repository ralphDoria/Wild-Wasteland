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
  **Deferred:** C13 wearables (design-gated — needs the accessory↔tool relationship pinned) and the
  full C14 sound whitelist/rate-limit (Q8).
- 🔵 Also fixed this session (outside the Tier 2 batches): the looting infinite-yield
  (`GetChangeReplicatorRemote` M17 + `ToolSpawner` H4) — see `cc66952`.

**Important working-session detail:** connect Rojo with **`test.project.json`** (not
`default.project.json`) during Tier 2 dev, so DevPackages + tests sync and specs can run in-session.
Do a final per-batch verification pass on `default.project.json` to confirm what actually ships.

**Next steps:**
1. Manual gate still open for Batch 0: gun regression smoke test (see PLAYTEST_VERIFICATION.md →
   Tier 2 → Batch 0) — equip Beretta, empty a mag into a dummy, reload; confirm unchanged.
2. ✅ Batch 1 playtest gate closed (2026-06-20). A regression was found+fixed during it: the
   `operationId` type guard rejected the numeric counter and broke the split menu (fix in `6de7cdf`).
3. ✅ Batch 2 melee (C6) done + verified 2026-06-20.
4. ✅ Batch 3 C10/C11 done + verified 2026-06-20. **In progress:** C13 wearables (`ToggleWear`) —
   design question being pinned: how to verify `originalAccessory`/`thisAccessory` belong to the
   sender's wearable tool (likely an ancestry check against the tool's `ToolModel`). Then:
   own-character + own-tool + accessory-belongs-to-tool, and turn the `error()`s into graceful returns.
5. Remaining Tier 2: consumables (C3/C4), vitals/respawn (C9/C16), C14 sound whitelist (Q8).
   Per-system design questions in BUGFIX_STRATEGY.md → Tier 2 gate each one.
5. Still pending before the looting batch: deep-review `CorpseLootable.lua` / `StandardLootable.lua`.
