Read @docs/CODEBASE.md for context on the codebase.

We are currently focusing on fixing detected bugs. Read @docs/BUGS.md and @docs/BUGFIX_STRATEGY.md
For how to verify fixes in-engine, read @docs/PLAYTEST_VERIFICATION.md

## Vitals rewrite (Tier 3) — ✅ DONE, merged to `main`, playtest-verified 2026-07-13

The sanctioned server-authoritative vitals rewrite is complete (built on the now-deleted
`vitals-rewrite` branch, merged via `ebcfcf1`). Full plan: docs/VITALS_REWRITE_PLAN.md.
Architecture: shared `Data/VitalsConfig` + pure `Sim/VitalsSim`; server `VitalsSystem_Server/
VitalsService` (one Heartbeat tick, player-attribute replication, `restore()` mutation API);
client managers are views (`StaminaManager` = VitalsSim prediction + attribute reconciliation;
movement speed set server-side via the `MovementIntent` remote — mode name only).

- ✅ **Batch V0** — config + pure sim + `VitalsSim.spec`/`VitalsConfig.spec` (`0b0beba`).
  Specs green in-engine (part of the 73/73 suite).
- ✅ **Batch V1** — server hunger/thirst + starvation (C9/M11/M12/M13); `hungerThirstDamage`
  listener deleted; `RespawnPlayerCharacter` gated dead-only + rate limit (C16).
  Playtest-verified 2026-07-13.
- ✅ **Batch V2** — stamina authority + movement intent (C2, M7–M10); `ChangeHumanoidWalkSpeed`
  handler deleted; incl. the 2026-07-08 breathing-pulse addendum (lazy TimeLength +
  `GuiBreathingSync` unbind on death). Playtest-verified 2026-07-13.
- 🟡 **Batch V3** — restore path: `ConsumableStats` reshaped to
  `restores = {Health/Hunger/Thirst/Stamina = n}`, routed through `VitalsService.restore`.
  **Heal leg playtest-verified 2026-07-13**; the food/drink restore leg (M12) is the ONE
  remaining open vitals check — no food/drink item exists yet. Run it when one is added
  (PLAYTEST_VERIFICATION.md → Batch V3 M12 has a config-tweak recipe to test sooner).

Note: `npc-system-v2` had uncommitted Phase 3.4 WIP when this branch was cut — it is in
`git stash` ("npc-system-v2 WIP: Phase 3.4 target re-evaluation"); pop it when back on
that branch.

## XP & Level system (scaffolded 2026-07-13) — CURRENT WORKSTREAM

Server-authoritative persistent progression; design + rationale in docs/XP_SYSTEM_RESEARCH.md.
Bugfix tiers are ON HOLD while this is built.

- Shared: `XPSystem_ScriptStorage/Data/XPConfig.lua` (curve + `awards` table) and pure
  `Sim/XPCurve.lua` (level DERIVED from cumulative XP — XP is the only stored stat).
- Server: `XPSystem_Server/XPService.lua` — `award(player, awardName)` is the single grant
  surface (NO remotes exist); `notifyDamageDealt(attacker, humanoid)` does killing-blow
  attribution, called after `TakeDamage` in `MeleeReceiver.Hit` and `GunReceiver`;
  `levelUp` GoodSignal for future server listeners.
- Persistence: `PlayerStatsInfo.ATTRIBUTE_XP` + new `getPersisted()` (DataSaveSystem
  re-pointed to it; `getAll()` still means "world pickup stats" for CapsAndAmmoPickUp).
- **Expandability contract:** new XP-granting action = one `XPConfig.awards` key + one
  server-side `XPService.award` call. Nothing else.
- ✅ Specs green in-engine 2026-07-13 (86/86 incl. `XPCurve.spec`/`XPConfig.spec`); require
  chain verified. **Playtest gate OPEN** (PLAYTEST_VERIFICATION.md → "XP & Level system"):
  kill XP via both weapons, 2-client player-kill classification, persistence across Stop.
- ✅ **XP bar UI wired + playtest-verified 2026-07-14** (PLAYTEST_VERIFICATION.md → "XP bar
  UI"): bar lives in the place at `VitalsGui.Container.XPBar` (grouped with the vitals icons
  under a shared UIListLayout `Container` so `VitalsManager`'s touch/desktop repositioning
  moves both — the vitals managers' GUI lookups were repointed through `Container`);
  `XPSystem_ScriptStorage/XPGuiManager.lua` is a pure view of the `XP` attribute via
  `XPCurve.progress`, re-attaching per life (VitalsGui is ResetOnSpawn). Its client-side
  `levelUp` GoodSignal is the hook for the upcoming user-built level-up animation.
- ✅ **Indicator banners + XP feed wired + playtest-verified 2026-07-14**
  (PLAYTEST_VERIFICATION.md → "Indicator banners"): general-purpose
  `Utility/IndicatorBannerManager.lua` (`show(actionText, gainText?)`, code-driven
  slide-in/stack/fade/slide-out, ExperienceGained chime) drives the place-built
  `IndicatorBannerGui`; `XPService.award` now fires the outbound-only `XPAwarded` remote
  (no server listener — not a grant surface) and `XPBannerFeed` renders it
  ("Killed {name} — +50 XP"). ⚠ `BannerList` must stay a plain clipping Frame, NOT a
  CanvasGroup (composite clipping dies at low graphics quality).
- ✅ **Level-up presentation wired + playtest-verified 2026-07-14**
  (PLAYTEST_VERIFICATION.md → "Level-up presentation"): `Utility/
  TerminalTypewriterManager.lua` (`play(message)`, terminal-style typing into the
  place-built `IndicatorBannerGui.TerminalTypewriter`: solid cursor while typing,
  blinks when idle, keystroke sound per letter, hold-then-fade) connected to
  `XPGuiManager.levelUp` in `XPGuiExecutor` ("LEVEL {n}" + Jungle Jazz Room Sting).
  `XPGuiManager` no longer fires levelUp off the initial persisted-XP load (the
  session-start false level-up).
- Deferred (see research doc): assists/damage-share, per-source rate limits,
  ProfileStore consolidation.

## Build system v1 (scaffolded 2026-07-16, branch `build-system`) — CURRENT WORKSTREAM

Fortnite-style grid building: Wall/Floor/Stairs, all clones of the place-built
**RustyMetalSheet union** (`ReplicatedStorage.BuildSystem_Storage.RustyMetalSheet`,
8×0.205×8 — Y-thin; a placeholder Part is generated if it's ever missing). Design
decisions: 5 s Fortnite-style ramp-up (spawns instantly translucent at 10% health,
ramps to max), orientation auto-faces camera yaw (90° snap), stairs stretched to
cellSize·√2 to span the cell diagonal, **3×3×3 build region** centered on the
HumanoidRootPart's cell (client clamps the preview into it, server enforces), **no
floating pieces** (must touch map geometry/terrain/another structure — shared
`isSlotSupported` probe; characters never count as support), health is server-side
with `BuildService.damageStructure` as the ONLY mutator (no weapon integration yet —
one call per damage site when it comes).

- Shared: `BuildSystem_ScriptStorage/Data/BuildConfig.lua` (**`panelSize` is THE knob**
  — the grid derives from it, and BuildMath DETECTS the panel's thin axis from it, so
  re-orienting/resizing the piece is config-only) + pure `Sim/BuildMath.lua` (slot
  model: walls live on cell-boundary planes so both sides of a face are ONE slot;
  stairs occupancy ignores orient; `clampSlotToRegion`/`isSlotInRegion` for the build
  region). `Components/getPanelTemplate.lua` resolves the template;
  `Components/isSlotSupported.lua` is the grounding probe (GetPartBoundsInBox +
  terrain-voxel read; humanoid-model parts filtered out).
- Server: `BuildSystem_Server/BuildService.lua` — the `PlaceStructure` remote (runtime
  `BuildSystem_Storage` folder) carries five flat scalars (kind, x, y, z, orient);
  geometry is re-derived server-side via `BuildMath.validateSlot`/`slotToCFrame`
  (validated: alive sender, rate limit, in-region vs the sender's HRP cell, occupancy,
  supported). ONE Heartbeat accumulator ramps construction; ONE ChildRemoved listener
  on `workspace.PlacedStructures` frees occupancy; structures are tagged
  `BuildStructure`, state in attributes.
- Client: `BuildModeManager.lua` — TEMPORARY entry via the place-built
  `Inventory.Hotbar.TempBuildButton` (UICorner scale 1 on `innerFrame` = active);
  V/B/N ActionManager toggles (mutually exclusive via forceToggle), MouseButton1/tap
  "Place Structure" bind, ONE reused CanQuery=false ghost on a RenderStepped loop that
  runs only while a structure is selected. **Selection prefers the builder's OWN cell**
  (`BuildMath.primarySlot`: walls take the yaw-facing cell face, floors the feet plane
  or — pitched up past 15° — the ceiling, stairs the cell ascending away) and expands
  to the aim-raycast search over the 3×3×3 region only when that slot is occupied.
  Preview look is a **Highlight** (default settings; FillColor = previewColor, flips to
  previewInvalidColor when the slot is occupied or unsupported — occupancy from SlotKey
  attributes on PlacedStructures children); invalid clicks aren't sent. Inert-with-warn
  if the button GUI is missing.
- ⚠ In-engine spec runs via `execute_luau` must fresh-load modules: the MCP plugin VM
  CACHES `require` results across calls, so a plain TestBootstrap re-run reports stale
  results (the 2026-07-16 session hit this — use the loadstring fresh-require runner,
  or a real Play session).
- Icon IDs for the touch buttons still to come (empty strings for now).
- First playtest round (2026-07-16, pre-region/template): button + binds + ghost +
  placement verified by the user. Gate for the region/grounding/red-ghost/template
  round still OPEN (PLAYTEST_VERIFICATION.md → "Build system v1"); specs green
  in-engine 126/126 (2026-07-16).

## Where we left off (updated 2026-07-13)

**Session 2026-07-13:** the home-base↔wasteland loop scaffold (branch `home-base-loop`) was
**scrapped** — removed in `3bedb0e`, history preserved before that commit. Salvaged from it:
the pure `ItemSerializer` now lives at `ItemSystem_ScriptStorage/ItemSerializer.lua` (attribute
whitelist in `Data/ItemPersistence.lua`, spec green) as the foundation for future inventory
persistence. Place stubs (BunkerTemplates, WastelandArrival) deleted via MCP. Branches
consolidated: **everything is on `main`** (26+ commits ahead of origin, still nothing pushed);
`home-base-loop`, `vitals-rewrite`, and `fable-5-gonna-fix-it-all` are deleted locally
(`origin/fable-5-gonna-fix-it-all` is stale on the remote). Consequence of the scrap:
**C5 (client-CFrame teleport) is back on the Tier 2 open list** — TravelService would have
replaced it. Vitals rewrite + Tier 2 Batch 5 playtest gates closed this session (see above).

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
- ✅ Tier 2 Batch 5 — **Consumable remotes** (C3/C4), committed 2026-07-03. `Heal` ignores both
  client args: heals the sender's own humanoid only, by `Data/ConsumableStats` amount for the
  *equipped* consumable, per-player `useCooldown`, server consumes the item; `Dispose` honored
  only for the tool the server just consumed (it's just the all-clients cleanup echo trigger).
  ✅ Playtest-verified 2026-07-13 via the Tier 3 Batch V3 heal-regression run (same flow); the
  can't-heal-others/negative checks are satisfied by inspection (the handler no longer reads
  those args). (NPC System v2 remains parked on branch `npc-system-v2` with its WIP stash.)

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
   - **C5** teleport-to-spawn (Q4) — back open after the home-base scrap; server should pick the
     spawn CFrame itself instead of trusting the client.
   - **C14** sound whitelist/rate-limit (Q8) — `PlaySound` only has a type guard so far.
   - Looting **C8/C12** — gated on first deep-reviewing `CorpseLootable.lua` / `StandardLootable.lua`
     (still unreviewed). Also the looting `ToggleWornWearableAccessory` remote (corpse-side twin of
     C13, in `LootingSystemExecutor`) needs the same treatment.
2. **Open manual gates:** Batch 0 gun regression smoke test was never run (equip Beretta, empty a mag
   into a dummy, reload; confirm unchanged) — low risk since it was a pure relocation, but unticked.
   And the V3 food/drink restore leg (see the vitals section above).
3. The looting redesign (registration/readiness, and whether loot-change replication should be on a
   reliable rather than Unreliable remote) is noted as a **Tier 3** item — see the diagnosis in the
   2026-06-20 session's discussion of `GetChangeReplicatorRemote`.
