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
