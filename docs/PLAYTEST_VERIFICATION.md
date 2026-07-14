# Playtest Verification Guide

How to verify that bug fixes actually work in-engine. This is the **manual safety net** that
complements (and, until the test suite exists, substitutes for) automated tests.

**Scope of this revision:** verifies the Tier 1 mechanical pass shipped in commits
`fbfc7dd` (BUGS.md Tier 1 batch) and `0d3da3b` (self-healing melee hitbox). Future tiers append
their own sections following the same format.

> **Policy:** see [BUGFIX_STRATEGY.md → Verification policy](BUGFIX_STRATEGY.md#verification-policy).
> No bugfix batch is considered "done" until the relevant checks below pass in a Studio playtest
> (and, for replication items, a 2-player Studio test server).

---

## How to run a playtest

1. **Sync the repo into the place.** Make sure Rojo is serving (`rojo serve`) and connected in
   Studio, so the working-tree code is what runs. Confirm there are no Rojo sync errors.
2. **Single-client run:** Studio → **Test → Play** (F5). Covers everything except true replication.
3. **Two-client run (required for ★ replication items):** Studio → **Test → Clients and Servers →
   2 players → Start**. Needed to see what *other* players see (melee hit/swing FX, dropped tools).
4. **Watch the Output window** the entire session. A passing run is one where the listed behavior
   works **and** the Output stays free of the error signatures called out below.
5. Optionally drive checks via the Roblox Studio MCP: `start_playtest` / `get_playtest_output`,
   `execute_luau` for setup, `capture_screenshot` for UI state. Note the MCP drives a **single**
   client — it cannot verify the ★ replication items.

**Severity of a failed check:** any ❌ under a 🔴/🟠 item blocks the batch; ❌ under 🟡/🔵 is logged
and triaged but need not block.

---

## Global pass condition — clean Output

Several Tier 1 fixes were debug-noise and crash removals. Across an entire normal play session
(spawn, equip each item, shoot, melee, pick up loot, open inventory, hover/drag slots, die, respawn):

- ✅ **No** `attempt to index nil` / `attempt to call missing method` errors.
- ✅ **No** `attempt to call a nil value` from `FireClient`.
- ✅ Output is **not** spammed with `print`/`warn` debug lines. Specifically these should be **gone**
  (L2/L7/INV-L1/INV-L4): `Created new hitbox manager`, `print(self.HitboxManager)`,
  `print(ammoReserve)`, `print(player)` from looting, the ActionHandlers per-action prints,
  `making this thang invisible`, and the StackableReceiver `warn(stackableName, …)`.

If Output is noisy or throwing on a clean run, stop and triage before checking individual systems.

---

## Per-system checks

Each check lists the **bug ID**, **how to reproduce**, **✅ pass**, and **❌ fail signature**.

### 1. Melee — replication ★ and self-healing hitbox

**H1 — melee FX replicate (★ 2-client).** Player A equips the Raider Axe and swings near Player B.
- ✅ Player B sees A's swing trail and the hit particles/impact at the hit position.
- ❌ Output on the server throws `Unable to cast value to Object` / `FireClient: Player expected`
  on every swing, and B sees nothing. (This was the pre-fix behavior — calling `FireClient` without
  the player.)

**Self-healing hitbox (`0d3da3b`) — the crate round-trip.** This is the key regression test.
1. Equip the Raider Axe, confirm a normal swing damages an NPC/dummy.
2. Store the axe into a loot crate (or get it looted into `ReplicatedStorage.LootItemsHolding`),
   then take it back out into your inventory and re-equip.
3. Swing again.
- ✅ The swing still registers hits after the round-trip.
- ❌ `attempt to call missing method 'HitStop' (or 'HitStart') of table` on the first post-reparent
  swing. (The client-only `_RaycastHitboxV4Managed` tag was stripped on the server reparent, tearing
  the hitbox down.)

### 2. Inventory slots

**INV-H3 — pickup reliably appears (the big one).** Walk over several ground pickups
(caps, ammo, tools) repeatedly across multiple lives/sessions.
- ✅ Picked-up items **always** appear in an inventory/hotbar slot.
- ❌ Intermittently an item is consumed from the world but no slot fills (load-order dependent — the
  pre-fix `return`-instead-of-`continue` aborted the slot search when a looting slot-group was
  visited first). Because it's nondeterministic, **repeat ~10 pickups** before declaring pass.

**INV-H2 — emptying a slot never errors.** Equip then unequip/drop items; split and merge stacks so
slots empty.
- ✅ No errors when a slot empties.
- ❌ `attempt to index nil with 'Name'` from `Slot.EmptySlot` (the `self.tool` nil case).

**INV-H5 — corpse-routed tools drag correctly.** Loot a tool off a corpse into your inventory, then
drag that tool between inventory/equipment slots.
- ✅ Drag resolves to the correct slot group.
- ❌ Drag misbehaves / a corpse Model is treated as the target frame (pre-fix it grabbed the first
  `ObjectValue`, which could be `CorpseCharacterValue`). Fix looks up `AssociatedItemGroup` by name.

**INV-H6 — hover with no Description.** Hover over a filled slot whose tool lacks a `Description`
attribute.
- ✅ Hover info shows (blank description is fine), no error.
- ❌ `invalid argument … Text expected, got nil`.

**INV-M2 — equipment swap.** Drag an inventory item onto an occupied equipment/wearable slot to swap.
- ✅ Swap completes, both slots show the correct items.
- ❌ Wrong branch taken / stale slot. (Was an always-true `elseif` collapsed to `else`.)

### 3. Guns

**M1 — aiming survives gun swaps (the important one).** Equip a gun, right-click to aim (ADS),
unequip it, equip another gun (or the same one again), right-click to aim.
- ✅ Right-click aiming works on the second gun.
- ❌ Second gun won't aim — the "Aiming" action was leaked/never unbound because inspect clobbered
  `actionNames.aiming`. Fixed to use `actionNames.inspect`.

**H10 — shell ejection nil guard.** Fire a gun.
- ✅ Shells eject (or simply nothing happens if the casing asset is missing) without error.
- ❌ `attempt to index nil with 'Clone'` in `_shellEjection`.

**H8 — inspect toggle no error.** Equip a gun, trigger the inspect animation/bind, unequip.
- ✅ No error from `forceToggle("Inspect", …)` when the bind may not exist.
- ❌ `attempt to index nil with 'enabled'` in ActionManager.

### 4. Stamina & breathing

**M10 — stamina never goes negative.** Sprint to near-zero stamina, then melee-swing (a costed
action) so the cost exceeds remaining stamina.
- ✅ Stamina bar bottoms out at 0; regen timing looks normal.
- ❌ Bar visibly overshoots empty / regen takes abnormally long (was `currentStamina = -5`).

**M8 — breathing thresholds.** Drain stamina and listen.
- ✅ Heavy-breathing audio escalates at the right stamina levels (now divides by `MAX_STAMINA`).
- ❌ Thresholds feel wrong if `MaxHealth ≠ 100` (only observable if MaxHealth was changed).

**M9 — female breathing.** Select the female breathing voice and drain stamina.
- ✅ The GUI breathing sync ends on the correct marker (reads FemaleBreathing's own `TimeLength`).
- ❌ Breathing sync runs past the end / desyncs for female characters.

**M7 — staminaChanged old/new.** (Mostly an internal/listener check.) If any UI listens to
`staminaChanged`, confirm it reacts to deltas.
- ✅ Listeners receive distinct `(old, new)` values.
- ❌ Listeners that compare old≠new never fire (pre-fix fired `(new, new)`).

### 5. NPCs

**H7 — NPC target death/leave doesn't spam errors.** Aggro an NPC, then die / respawn / have the
targeted player leave while the NPC is mid-chase or mid-attack.
- ✅ The NPC FSM keeps running (re-acquires or idles), Output stays clean.
- ❌ Per-frame `attempt to index nil with 'Humanoid'` / `'PrimaryPart'` from Attack/Chasing/SawPlayer.

### 6. Pickups & doors

**M14 — cap/ammo prompt guard.** Walk into a caps/ammo pickup; let it trigger.
- ✅ The pickup's **own** prompt disables (no double award), and **other** identical pickups still
  work afterward (the shared ReplicatedStorage template was not disabled).
- ❌ First pickup permanently breaks all subsequent identical pickups (pre-fix disabled the template).

**M16 — vault door close sound.** Open then close the vault door.
- ✅ Opening plays the open sound; closing plays the **close** sound.
- ❌ Closing plays the open sound again.

### 7. Looting

**H5 / H6 / H3 — loot asserts & nil guards.** Open corpse loot and standard crates; trigger a
tool-destroyed/loot-data lookup on an unregistered/edge instance.
- ✅ No asserts fire on normal looting; edge lookups fail gracefully.
- ❌ `attempt to index nil with 'FilledSlotsData'` or a misfiring assert.

**M18 — every-item crate, no duplicate Light Bullets.** Open the dev "all items" crate.
- ✅ Exactly one Light Bullets stack-set (6), not a stray 7th.
- ❌ An extra Light Bullets entry appears.

### 8. Data persistence

**M15 — BindToClose saves on shutdown.** Change a saved stat (collect caps), then **Stop** the
playtest (or trigger a server shutdown) and re-enter.
- ✅ The stat persists across the shutdown (BindToClose flushed the save), and a load/save failure
  now surfaces a warning instead of failing silently.
- ❌ Progress lost on shutdown / silent save failures.

### 9. Security — removed remote

**C1 — `SpawnTool` client remote removed.** In the running game, confirm there is no client-facing
`rev_SpawnTool` RemoteEvent that clients can fire.
- ✅ The client-facing spawn remote is gone; the server-side `ServerSpawnTool` bindable still works
  for legitimate spawns (items still spawn through normal flow).
- ❌ A client can still fire a remote to clone arbitrary catalog tools.

> Verify quickly via MCP `execute_luau`:
> `print(game.ReplicatedStorage:FindFirstChild("rev_SpawnTool", true))` → expect `nil`.

---

## Tier 2 — server-authority boundary

Appended as Tier 2 batches land. Unit-testable pieces also have TestEZ specs (run via
`test.project.json` → Play, or the MCP); the checks here cover what specs can't.

### Batch 0 — shared validation layer + gun migration

Added `Receivers/Validation` (shared type validators + `Ownership`) and **migrated the gun's
`TypeValidation` into it**, re-pointing `GunReceiver` and `validateShootArguments`. No gameplay
behavior changed — this is a relocation, so the check is a regression test of the gun path.

- **Unit (automated):** `TypeValidation.spec` — 18 cases incl. `isBoundedNumber` rejecting
  `math.huge` and `isInteger` rejecting fractional/negative. ✅ 19/19 green in-engine
  (incl. sanity). Re-run any time via the MCP or by serving `test.project.json` and pressing Play.
- **Gun regression (playtest):** equip the Beretta, fire a full magazine at a dummy, and reload.
  - ✅ Shots register and damage the dummy; ammo decrements; reload pulls from reserve — exactly as
    before the migration.
  - ❌ `attempt to index nil` / require error mentioning `TypeValidation` or `Validation` on the
    first shot or at server start (would mean a re-point path is wrong).

### Batch 1 — Stackable remotes routed through the boundary (C7, type/ownership hardening) ✅ VERIFIED 2026-06-20

Routed `RequestMergeStackables` / `RequestQuantityTransfer` / `RequestDuplicateStackable` /
`DestroyUnusedStackable` through `Validation`, and extracted the merge/transfer arithmetic into the
pure `StackableMath` module. Ownership is enforced on transfer + duplicate (caller-owned only);
**merge is intentionally left un-gated** because it legitimately operates on loot-container stacks
(deferred to the looting authorization layer, design Q5).

- **Unit (automated):** `StackableMath.spec` — merge cap/deplete cases; `canTransfer` accepts
  in-range + `transfer 0`, **rejects negative transfer (the C7 dupe)**, rejects `>= pool`,
  fractional, NaN, and non-number. Run via `test.project.json` → Play (or the MCP).

- **C7 — no duplication via transfer (playtest).** Open the split menu on a stack (e.g. Light
  Bullets), split a valid amount, confirm and cancel a few splits.
  - ✅ Splitting moves quantity without ever increasing the grand total; the source keeps the
    remainder; cancelling restores the original stack (the `transfer 0` cleanup still works).
  - ❌ Total ammo/caps increases after a split/cancel cycle, or the split menu errors / fails to
    restore on cancel (would mean the `transfer 0` path was wrongly rejected).

- **Merge still works, incl. loot (playtest).** Drag-merge two same-type stacks in the inventory;
  then merge a stack into/out of a corpse/crate loot slot (`L_INVENTORY` paths).
  - ✅ Both merges combine correctly and cap at MAX_QUANTITY; the depleted source is destroyed.
  - ❌ A legitimate loot-stack merge is rejected (would mean ownership was wrongly applied to merge).

- **Edge inputs don't error the server (playtest/Output).** During normal stacking play, Output
  stays clean — no `attempt to index nil` / assert errors from StackableReceiver, and none of the
  old `starting merge` / `Destroyed unused stackable` debug prints appear.

### Batch 2 — Melee hit routed through the boundary (C6, server-authoritative damage) ✅ VERIFIED 2026-06-20

`MeleeReceiver.Hit` no longer trusts the client. Damage now comes from `Data/CombatStats` keyed by
the sender's *equipped* tool; the client's `damage` argument is ignored. Added: alive-sender check,
equipped-known-melee check, Humanoid type/health validation, distance vs `maxRange`, and a
per-(player, target) swing-rate limit (`swingCooldown`). H1 replication was already fixed.

- **Unit (automated):** `CombatStats.spec` — every weapon entry has positive/finite
  damage, cooldown, range. Run via `test.project.json` → Play (or the MCP).

- **C6 — damage is server-fixed (playtest).** Equip a melee, hit a dummy/NPC.
  - ✅ Target takes the config damage (50) per hit and dies in the expected number of swings.
  - ❌ Target takes a different amount, or a remote-spammer can still vary damage (would mean the
    client value is still being applied).

- **No-weapon / wrong-weapon can't damage (playtest or remote test).** With nothing equipped (or a
  non-melee tool), firing the Hit remote does nothing.
  - ✅ No damage is applied; Output stays clean (graceful reject, no error).
  - ❌ Damage lands, or the handler throws on a non-Humanoid target.

- **Cleave still works; single-target spam is capped (playtest).** Swing through 2+ NPCs standing
  together; separately, try to land hits on ONE target faster than the swing cycle.
  - ✅ A single swing damages each distinct NPC once; the same target can't be hit faster than
    `swingCooldown`.
  - ❌ A swing only hits one of several adjacent NPCs (rate limit wrongly keyed per-player), or a
    single target takes rapid stacked hits.

- **★ Replication (2-client).** Player A's hit FX (blood/impact) still appear for Player B — the H1
  fix plus the new validation path didn't regress replication.

### Batch 3 — Shared ownership remotes (C10/C11, + H11/C14 hardening) ✅ VERIFIED 2026-06-20

`DropTool` and `ToggleToolCanCollide` now route through `Validation`. `DropTool` requires the tool be
a `Tool` the **sender owns**; `ToggleToolCanCollide` requires the model belong to a real `Tool` that
is sender-owned **or** already dropped in `workspace` (so the drop re-enable still works).
`RequestPickUpTool` and `PlaySound` got type guards. **Not** in this batch: C13 wearables (design-
gated) and the full C14 sound whitelist/rate-limit (Q8).

- **C11 — drop only your own tool (2-client).** Player A equips a tool; Player B fires `DropTool`
  with A's tool (or just play normally and drop your own).
  - ✅ You can drop your own equipped/backpack tool exactly as before (equipped drops in place,
    backpack drops in front of you). B cannot force-drop A's tool.
  - ❌ A's tool pops to the ground when B acts / your own drop stops working.

- **C10 — collision toggle scoped to tools (playtest).** Equip, unequip, and drop tools; move around
  the map.
  - ✅ Equip disables tool collision, drop re-enables it (dropped tools rest on the floor, don't fall
    through) — unchanged from before. Output clean.
  - ❌ A dropped tool falls through the floor (the workspace re-enable was wrongly rejected), or
    Output errors on equip/drop.

- **Pickup unaffected (playtest).** Walk over and pick up dropped tools.
  - ✅ Pickup still works within range; no error on odd input.

### Batch 4 — Wearable remote (C13, ToggleWear ownership/accessory validation) ✅ VERIFIED 2026-06-20

`ToggleWear` now validates every argument: `character` must be the sender's own, `tool` must be a
sender-owned `Tool`, `thisAccessory` must be a descendant of that tool, `originalAccessory` must be a
descendant of the tool's `ToolCatalog` folder, and `wearableCategory` must be a real category. The
`error()` calls became graceful returns. `MakeAccessoryVisibleOnDeath` only reveals an accessory the
sender owns. (`ownsTool` already covers `WornItems` — it's under the Backpack.)

- **Wear / unwear works (playtest).** Equip the NV Goggles (or any wearable), toggle worn on, then off.
  - ✅ Wearing parents the accessory to your character and hides the held one; unwearing reverses it;
    the tool moves into/out of `Backpack/WornItems`. Output clean (no `error()` spam).
  - ❌ Wearing throws, or the worn accessory doesn't appear / doesn't clear.

- **Can't wear onto / using another player's stuff (2-client or remote test).** Fire `ToggleWear`
  with another player's character or tool, or with a foreign accessory.
  - ✅ Nothing happens — rejected before any clone/reparent.
  - ❌ An accessory is cloned onto someone, or another player's tool is reparented.

- **Death reveal still works (playtest).** Die while wearing a wearable.
  - ✅ The worn accessory becomes visible on the corpse as before; no error.

### Batch 5 — Consumable remotes (C3/C4, server-authoritative heal + gated dispose) ✅ VERIFIED 2026-07-13

> Verified via the Tier 3 Batch V3 heal-regression run (same flow: heal lands, item
> consumed, cooldown caps spam). The can't-heal-others/negative checks are satisfied by
> inspection — the handler no longer reads those arguments.

`Heal` now ignores both client arguments: the server heals the **sender's own humanoid only**, by the
amount in `Data/ConsumableStats` for the sender's *equipped* consumable, with a per-player
`useCooldown`, and **consumes the item server-side** (`Debris` on the equipped tool) — so a client
can't heal without losing the item. `Dispose` is only honored for the exact tool the server just
consumed for that player (it merely triggers the all-clients cleanup echo). The client
`HealingInjection` no longer sends a humanoid or amount.

- **Unit (automated):** `ConsumableStats.spec` — positive/finite heal amount and cooldown, Healing
  Injection entry present. Run via `test.project.json` → Play (or the MCP).

- **C3 — legit heal works, amount is server-fixed (playtest).** Take damage (e.g. from an NPC),
  equip a Healing Injection, activate it, let the animation finish.
  - ✅ Health rises by exactly 25 (clamped at MaxHealth); the injection is dropped and disappears
    ~10s later; the pickup prompt/slot cleanup runs as before. Output clean.
  - ❌ No heal (would mean the validated path wrongly rejects the real flow), a different amount,
    or the tool lingers/never cleans up (dispose echo not firing).

- **C3 — can't heal others / can't damage via negative amounts (remote test).** From a client, fire
  `Heal` with another humanoid and/or a negative number (or just verify by code inspection — the
  arguments are no longer read).
  - ✅ Only the sender's own humanoid can ever be healed, by the config amount; no target damage.
  - ❌ Any humanoid other than the sender's changes health.

- **C3 — no free healing without the item (playtest/remote test).** With no consumable equipped
  (or a non-consumable tool equipped), fire the Heal remote; also spam it while one is equipped.
  - ✅ Nothing happens without an equipped known consumable; spam heals at most once per
    `useCooldown` and consumes the item on the first validated use.
  - ❌ Health rises with no item, or repeated heals from one item.

- **C4 — dispose can't delete arbitrary tools (2-client or remote test).** Fire `Dispose` with
  another player's tool, a map instance, or a tool you own but haven't consumed.
  - ✅ Nothing is destroyed — only the tool the server consumed on your own validated heal is
    accepted (and it was already scheduled for destruction by the heal itself).
  - ❌ Any client-chosen instance gets destroyed or triggers the cleanup echo.

---

## Tier 3 — Vitals rewrite (merged to `main`; playtest-verified 2026-07-13, except the V3 food/drink restore leg — no such item exists yet)

Server-authoritative vitals per [VITALS_REWRITE_PLAN.md](VITALS_REWRITE_PLAN.md). Run with
Rojo serving **`test.project.json`** so the specs are in-place.

### Batch V0 — shared config + pure sim (no behavior change)

`Data/VitalsConfig` + `Sim/VitalsSim` + specs only; nothing requires them at runtime yet.

- **Unit (automated):** `VitalsSim.spec` (decay clamp, threshold sections incl. boundaries/
  clamping, stamina drain/cooldown/regen/cost clamps) and `VitalsConfig.spec` (shape:
  positive finite numbers, strictly ascending 0→1 thresholds, affordable costs). Run via
  `test.project.json` → Play (or the MCP). Suite must stay green alongside the existing specs.

### Batch V1 — server-authoritative hunger/thirst + gated respawn (C9/M11/M12/M13/C16) ✅ VERIFIED 2026-07-13

`VitalsService` simulates decay/starvation on ONE Heartbeat tick and replicates via player
attributes; client `HungerThirstManager` is now a pure view; `hungerThirstDamage` has no
server listener; `RespawnPlayerCharacter` requires the sender to be dead + rate limit.

- **Decay + GUI (playtest).** Play and watch the hunger/thirst bars for a couple of minutes
  (or speed it up: temporarily raise `decayPerSecond` in `Data/VitalsConfig`).
  - ✅ Both bars tick down (thirst faster than hunger), the % labels count down, threshold
    crossings play the stomach-rumble/gulp sound for the RIGHT stat only, and the bar tints
    toward the stat color below 50%. Server attribute check: select your Player in the
    Explorer → Attributes shows `Hunger`/`Thirst` falling.
  - ❌ Bars never move (attributes not replicating — check the server Output for a
    VitalsService require error), or a thirst threshold plays the hunger sound (the old
    M11 cross-fire).

- **C9 — starvation is server-owned (playtest).** Set both decay rates high (e.g. 5/s) in
  VitalsConfig, let both stats hit zero.
  - ✅ Health starts dropping ~2 HP/s (1 per starving stat) ONLY once a stat is at zero,
    and the death flow triggers normally at 0 HP. A client firing the old
    `hungerThirstDamage` remote (command bar on the client:
    `game.ReplicatedStorage.VitalsSystem_Storage.hungerThirstDamage:FireServer(true, workspace.SomeDummy.Humanoid, 100)`)
    does nothing to anyone.
  - ❌ No starvation damage ever lands, damage lands while stats are above zero, or the
    old remote still damages a humanoid.

- **M12 — respawn refills (playtest).** Die (starve or jump off something), respawn.
  - ✅ Hunger/thirst are back at 100% on the new character; bars white; no leftover rumble.
  - ❌ The new life starts with the dead life's values, or the GUI shows stale tint/values.

- **C16 — respawn only when dead (remote test).** While ALIVE, fire
  `game.ReplicatedStorage.VitalsSystem_Storage.RespawnPlayerCharacter:FireServer()` from the
  client command bar; then die and use the death screen's respawn button normally.
  - ✅ Nothing happens while alive; the death-screen respawn still works when dead (spam
    is capped at 1/s).
  - ❌ An alive character respawns (combat escape), or the legitimate death-screen respawn
    is rejected.

- **Output clean (playtest).** Whole session: no errors from `VitalsService`/
  `VitalsSystemReceivers`/`HungerThirstManager`, and no "adding to tbl" warns.

### Batch V2 — stamina authority + movement intent (C2, M7–M10 structural) ✅ VERIFIED 2026-07-13 (incl. addendum)

Server stamina joins `VitalsService` (replicated as the `Stamina` attribute); WalkSpeed is
now set ONLY by the server from `Data/Config.speed`, driven by the new runtime-created
`MovementIntent` remote (mode name only — never a number or humanoid). Sprint is gated on
server stamina; sprint drain requires the server to observe horizontal movement; jump cost
charges on `Humanoid.StateChanged → Jumping`; melee swing cost charges on the validated
`Swing` remote. Client `StaminaManager` is prediction (same `VitalsSim` math) + view,
snapping to the attribute when divergence exceeds `reconcileSnapTolerance`. The old
`ChangeHumanoidWalkSpeed` handler is deleted (Studio remote inert); the empty
`SprintReceiver.lua` stub (L5) was removed.

- **Unit (automated):** `VitalsSim.spec` gains `effectiveMovementMode` (sprint requires
  stamina; other modes pass through) and `reconcile` (keep within tolerance, snap past it)
  blocks; `VitalsConfig.spec` covers the new `movingSpeedThreshold`/`reconcileSnapTolerance`
  knobs. Run via `test.project.json` → Play (or the MCP).

- **Sprint feel unchanged (playtest — the big one).** Hold Shift and run; stop moving while
  still holding Shift; release; sprint again.
  - ✅ Moving while sprinting is visibly faster and drains the bar ~5/s; standing still
    while "sprinting" does NOT drain; after stopping, regen kicks in after ~0.5 s at ~10/s;
    the bar is smooth (no 1 Hz stutter or visible snapping while sprinting normally).
  - ❌ No speed change on sprint (remote/intent wiring broken — check server Output for a
    `MovementIntent`/`VitalsService` error), drain while standing, or the bar visibly
    snaps/rubber-bands every second (reconcile tolerance too tight / server-client drift).

- **Sprint exhaustion (playtest).** Sprint until stamina hits zero.
  - ✅ At 0 the character drops to walking speed even if Shift is still held (server
    downgrade + client kick-out agree); once stamina regenerates you can sprint again.
  - ❌ Sprint speed persists at 0 stamina, or sprint never re-enables after regen.

- **Crouch (playtest).** Press C to crouch, move, release.
  - ✅ Crouch slows to the config speed with anims and camera offset as before;
    releasing restores default speed.
  - ❌ Speed doesn't change (intent path broken) or stays slow after release.

- **Jump + melee swing costs (playtest).** Jump repeatedly; equip the Raider Axe and swing.
  - ✅ Each jump and each swing knocks ~10 off the bar; the server agrees (select your
    Player in Explorer → the `Stamina` attribute tracks the bar within ~15); jump/swing
    gate off below their thresholds as before.
  - ❌ Bar drops but the attribute never moves (server charge not landing — StateChanged
    hook or Swing receiver), or double-charging (bar drops ~20 per action).

- **C2 — speedhack is dead (remote test).** From the client command bar:
  `game.ReplicatedStorage.MovementAndStaminaSystem_Storage.Remotes.ChangeHumanoidWalkSpeed:FireServer(game.Players.LocalPlayer.Character.Humanoid, 100)`
  and also try it against another player's/NPC's humanoid. Then try
  `...Remotes.MovementIntent:FireServer("Sprint")` with an empty stamina pool, and
  `MovementIntent:FireServer(999)` / `("Turbo")`.
  - ✅ The old remote does nothing (no listener). MovementIntent only ever yields the
    three config speeds on YOUR OWN humanoid: garbage modes are ignored, Sprint with an
    empty pool walks, and no other humanoid can be touched at all.
  - ❌ Any WalkSpeed change lands on another humanoid, or a non-config speed appears.

- **Respawn resets movement (playtest).** Die while sprinting/crouching.
  - ✅ The new character walks at default speed and spawns with a full stamina bar.
  - ❌ The new character spawns crouch-slow or sprint-fast (stale movement mode).

- **Output clean (playtest).** No errors from `VitalsService`, `Main` (movement receiver),
  `StaminaManager`, or `MeleeReceiver` across sprint/crouch/jump/swing/death.

**Addendum (2026-07-08) — breathing GUI pulse fixes** (user-reported blue-snap bug + a
leak found alongside it; both in `_toggleGuiBreathingSync`):

- **Pulse is smooth on a cold start (playtest).** In a fresh session (ideally first run
  after a Studio restart, so audio isn't cached), drain stamina below 50% and watch the
  stamina bar's breathing pulse for several breath cycles.
  - ✅ The bar color oscillates white → blue → white smoothly, in sync with the breathing
    audio, from the very first cycle (or begins pulsing the moment the sound asset loads).
  - ❌ The color ramps to blue, freezes, then snaps to white once per breath (the old
    behavior: the sound's `TimeLength` was captured as 0 at require time, so the
    blue→white half of the pulse never rendered).

- **Breathing sync survives death (playtest).** Drain stamina below 50% (breathing sync
  active), die, respawn, drain below 50% again.
  - ✅ The pulse works on the new life; no errors on death or respawn.
  - ❌ `BindToRenderStep: 'GuiBreathingSync' is already bound` (or similar) in Output on
    the second life, and/or the pulse never returns (the binding leaked across death).

### Batch V3 — consumable restore path (M12's missing food/drink feature) 🟡 heal leg VERIFIED 2026-07-13; restore leg deferred

`ConsumableStats` entries now declare `restores = { Health/Hunger/Thirst/Stamina = n }`
instead of `healAmount`. On a validated use, `ConsumableReceiver` applies `restores.Health`
to the sender's humanoid (clamped to MaxHealth, exactly as before) and passes the table to
`VitalsService.restore`, which clamps Hunger/Thirst/Stamina to their config max and ignores
unknown keys. Gameplay is otherwise unchanged: the Healing Injection still restores only
25 Health — no food/drink item exists yet, so the hunger/thirst leg is verified with a
temporary config tweak.

- **Unit (automated):** `ConsumableStats.spec` rewritten for the shape: every entry
  restores ≥ 1 stat from the known set (typo'd keys fail the spec instead of silently
  restoring nothing), positive finite amounts, finite cooldown, Healing Injection restores
  Health. Run via `test.project.json` → Play (or the MCP).

- **Heal regression (playtest).** Take damage, use a Healing Injection (the full Batch 5
  flow).
  - ✅ Health rises by exactly 25 (clamped at MaxHealth); item consumed; cooldown caps
    spam — identical to the Batch 5 checks.
  - ❌ No heal or a different amount (the `restores.Health` re-shape broke the path).

- **M12 — food/drink restores land (playtest, config tweak). ⚠ STILL OPEN 2026-07-13** —
  deferred until a real food/drink item exists (run it then, or with the tweak below).
  Temporarily add
  `Hunger = 25, Thirst = 25, Stamina = 25` to the Healing Injection's `restores` in
  `Data/ConsumableStats`, let hunger/thirst tick down a bit and drain some stamina, then
  use an injection.
  - ✅ The hunger and thirst bars jump up by 25 points each (server attributes on the
    Player rise too), stamina refills by 25, all clamp at max, and **no** rumble/gulp
    sound plays on the upward crossing (the V1 view is downward-only). Revert the tweak.
  - ❌ Bars don't move (restore not reaching VitalsService), a stat overshoots its max,
    or the threshold sound fires on a refill.

- **Output clean (playtest).** No errors from `ConsumableReceiver`/`VitalsService` during
  repeated consumable use.

---

## Quick checklist (copy into the PR/commit notes)

- [ ] Output clean across a full session (no nil-index/missing-method/FireClient errors, no debug spam)
- [ ] ★ Melee hit + swing FX visible to a second player (2-client)
- [ ] Melee still hits after crate store→retrieve round-trip (no HitStop/HitStart error)
- [ ] 10× pickups all land in inventory (INV-H3)
- [ ] Emptying / splitting / merging slots: no errors
- [ ] Corpse-looted tool drags to the right slot group
- [ ] Hover over a description-less item: no error
- [ ] Equipment swap puts both items in the right slots
- [ ] Aiming works on a second gun after a swap (M1)
- [ ] Firing ejects shells with no error
- [ ] Stamina bar floors at 0; breathing audio escalates correctly (incl. female voice)
- [ ] Killing/respawning while an NPC targets you: no per-frame errors
- [ ] Cap/ammo pickup doesn't break other pickups; vault door close sound plays
- [ ] Loot crates open without asserts; "all items" crate has no duplicate Light Bullets
- [ ] Saved stat persists across a playtest Stop (BindToClose)
- [ ] `rev_SpawnTool` client remote is absent

---

## Item serialization (salvaged from the scrapped home-base loop)

The home-base↔wasteland loop scaffold was scrapped 2026-07-13 (history on branch
`home-base-loop` before the removal commit). The pure `ItemSerializer` survived it and now
lives at `ItemSystem_ScriptStorage/ItemSerializer.lua` (whitelist config in
`Data/ItemPersistence.lua`) as the foundation for future inventory persistence.

- **Unit (automated):** `ItemSerializer.spec` — serialize captures name + whitelisted
  attributes only, quantity defaults to 1, per-type whitelists (gun ammo), malformed
  persisted entries rejected (no crash), round-trip rehydrates an equivalent tool. Run via
  `test.project.json` → Play (or the MCP).
