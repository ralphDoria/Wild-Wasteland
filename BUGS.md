# Known Bugs & Vulnerabilities

Audit of `src/` performed 2026-06-11 (working tree at commit `4a605e9` + 1 uncommitted change).
Documentation only — no code has been changed. Line numbers refer to the current working tree.

**Scope:** ~5,700 of ~16,400 source lines (45 of 230 files) were read line-by-line, covering the main server
remote handlers and the core item/vitals/input/inventory client systems. See **Review coverage** at the end
of this document for the exact per-file breakdown of what was deeply analyzed, what was only sampled via
searches, and what has not been reviewed at all.

Severity legend:
- 🔴 **Critical** — remotely exploitable by any client (server trusts client input)
- 🟠 **High** — definite runtime error in normal or near-normal play
- 🟡 **Medium** — logic bug producing wrong behavior
- 🔵 **Low** — leaks, dead code, debug noise, fragile patterns

---

## Location index

Quick reference; full paths and details are in each entry below. Server files are under
`src/ServerScriptService/`, client/shared files under `src/ReplicatedStorage/` (INV- entries under
`src/ReplicatedStorage/InventorySystem_ScriptStorage/`).

| ID | File | Lines |
|----|------|-------|
| C1 | ItemSystem_Server/Revamp/ToolSpawner.server.lua | 20 |
| C2 | MovementAndStaminaSystem_Server/Main.server.lua | 7-9 |
| C3 | .../Receivers/Components/ConsumableReceiver.lua | 14-16 |
| C4 | .../Receivers/Components/ConsumableReceiver.lua | 10-13 |
| C5 | SpawnAndDeathSystem_Server/Main.server.lua | 31-35 |
| C6 | .../Receivers/Components/MeleeReceiver.lua | 13, 35 |
| C7 | .../Receivers/Components/StackableReceiver.lua | 65-96 (esp. 70-79) |
| C8 | LootingSystem_Server/Services/LootDataService.lua | 169-180 |
| C9 | VitalsSystem_Server/VitalsSystemReceivers.server.lua | 27-37 |
| C10 | .../Receivers/Components/SharedReceiver.lua | 18-28 |
| C11 | .../Receivers/Components/SharedReceiver.lua | 29-47 |
| C12 | LootingSystem_Server/Services/LootDataService.lua | 107-111 |
| C13 | .../Receivers/Components/WearableReceiver.lua | 15-56, 71-77 |
| C14 | .../Receivers/Components/SharedReceiver.lua | 15-17 |
| C15 | .../Receivers/Components/Gun/GunReceiver.lua + ServerChecks/validateShot.lua | 54, 169, 195-198; 44 |
| C16 | VitalsSystem_Server/VitalsSystemReceivers.server.lua | 39-41 |
| H1 | .../Receivers/Components/MeleeReceiver.lua | 32, 50 |
| H2 | .../Receivers/Components/StackableReceiver.lua | 114-115, 147-148 |
| H3 | .../Receivers/Components/StackableReceiver.lua | 21-23 |
| H4 | ItemSystem_Server/Revamp/ToolSpawner.server.lua | 9, 14 |
| H5 | LootingSystem_Server/Services/LootDataService.lua | 147 |
| H6 | LootingSystem_Server/Services/LootDataService.lua | 196, 216 |
| H7 | NPCtest/States/Attack.lua; Chasing.lua; Transitions/SawPlayer.lua | 18; 19; 19 |
| H8 | ActionManagerSystem/ActionManager.lua | 260-271 |
| H9 | Miscellaneous/ShopGuiManager.server.lua | 44-48 |
| H10 | ItemSystem_ScriptStorage/Classes/Subclasses/Gun.lua | 29, 158 |
| H11 | .../Receivers/Components/SharedReceiver.lua | 36, 38, 41, 56 |
| H12 | .../Receivers/Components/OnHitFloor.lua | 22-26 |
| M1 | ItemSystem_ScriptStorage/Classes/Subclasses/Gun.lua | 541 |
| M2 | ItemSystem_ScriptStorage/Classes/Subclasses/Gun.lua | 401-404, 465-470 |
| M3 | ItemSystem_ScriptStorage/Classes/Subclasses/Gun.lua | 247-249 |
| M4 | ItemSystem_ScriptStorage/Classes/Subclasses/Gun.lua | 302-308 |
| M5 | ItemSystem_ScriptStorage/Classes/Subclasses/Melee.lua | 170-173 |
| M6 | ItemSystem_ScriptStorage/Classes/Superclasses/Item.lua | 121, 233-265 |
| M7 | VitalsSystem_ScriptStorage/Stamina/StaminaManager.lua | 284-289 |
| M8 | VitalsSystem_ScriptStorage/Stamina/StaminaManager.lua | 178 |
| M9 | VitalsSystem_ScriptStorage/Stamina/StaminaManager.lua | 57 |
| M10 | VitalsSystem_ScriptStorage/Stamina/StaminaManager.lua | 295-301 |
| M11 | VitalsSystem_ScriptStorage/HungerThirst/HungerThirstManager.lua | 54, 85-89 |
| M12 | VitalsSystem_ScriptStorage/HungerThirst/HungerThirstManager.lua | 74, 108-122 |
| M13 | VitalsSystem_Server/VitalsSystemReceivers.server.lua | 10-24 |
| M14 | Miscellaneous/CapsAndAmmoPickUp.server.lua | 43 (also 35, 47, 55, 60) |
| M15 | Miscellaneous/DataSaveSystem.server.lua | 14-25, 27-39 (no BindToClose anywhere) |
| M16 | Miscellaneous/DoorManager.server.lua | 67, 76 (also 11, 18-24) |
| M17 | LootingSystem_Server/Services/LootDataService.lua | 184-190 |
| M18 | LootingSystem_Server/Services/LootDataService.lua | 66-81 |
| M19 | InventorySystem_ScriptStorage/Components/ToolStateMachine/Main_ToolStateMachine.lua | 89/96, 167-170, 327-333, 174-179 |
| M20 | InventorySystem_ScriptStorage/Components/ToolStateMachine/Main_ToolStateMachine.lua | 267-273 |
| L1 | CorpseKeeper.server.lua | 10-15 |
| L2 | ItemSystem_ScriptStorage/.../HitboxManager.lua (+4 files, see entry) | 22-23 |
| L3 | ItemSystem_ScriptStorage/Classes/Superclasses/Item.lua; StaminaManager.lua | 104-106; 193-195 |
| L4 | ActionManagerSystem/ActionManager.lua | 251-252, 328-334 |
| L5 | MovementAndStaminaSystem_Server/Components/SprintReceiver.lua | whole file |
| L6 | ItemSystem_ScriptStorage/Classes/Subclasses/Melee.lua; Item.lua | 49, 179; 176 |
| L7 | multiple (see entry) | — |
| INV-H1 | Components/Slot/Slot.lua | 266-270 (hook only connected at 89) |
| INV-H2 | Components/Slot/Slot.lua | 255 |
| INV-H3 | Components/Slot/EmptySlotFinder.lua; StackableSlotFinder.lua | 34; 47 |
| INV-H4 | .../ActionHandlers/Components/P_INVENTORY__X__P_EQUIPMENT.lua | 104-109 |
| INV-H5 | Components/Slot/Drag/handleDragDrop.lua | 46 |
| INV-H6 | Components/Slot/Hover.lua | 58 |
| INV-M1 | .../ActionHandlers/ActionHandlers.lua | 69-71, 83-85, 90-92, 115-117 |
| INV-M2 | .../ActionHandlers/Components/P_INVENTORY__X__P_EQUIPMENT.lua | 101 |
| INV-M3 | Components/Slot/Drag/DragFunctionality.lua | 43-75 |
| INV-M4 | Components/Slot/Drag/DragFunctionality.lua | 43 (guard commented out at 35) |
| INV-M5 | Components/Slot/Drag/DragFunctionality.lua | 68 |
| INV-M6 | Components/Slot/Slot.lua | 150, 154, 175, 233 |
| INV-M7 | Components/Slot/Hover.lua | 51, 98-107, 130-132 |
| INV-M8 | InventoryManager.lua | 120-135 |
| INV-L1 | Components/Slot/Hover.lua | 16-17 |
| INV-L2 | Components/Slot/Hover.lua | 4-7 |
| INV-L3 | Components/Slot/Drag/handleDragDrop.lua | 23-39 |
| INV-L4 | multiple (see entry) | — |
| INV-L5 | Components/Slot/Slot.lua; Components/SplittingMenuManager.lua | 128; 239 |

---

## 🔴 Critical — server trusts the client

The game's biggest systemic problem: most RemoteEvents apply client-supplied values with little or no
validation. The Gun shoot path (`ServerChecks/`, `TypeValidation/`) is the only well-validated remote;
everything below is exploitable by any client with a remote spammer.

### C1. Free item spawning
`src/ServerScriptService/ItemSystem_Server/Revamp/ToolSpawner.server.lua:20`
`rev_SpawnTool.OnServerEvent` clones any tool from the ToolCatalog into any client-chosen parent with zero
validation. Any client can give themselves (or place anywhere) every weapon/item in the game.

### C2. Arbitrary WalkSpeed on any humanoid
`src/ServerScriptService/MovementAndStaminaSystem_Server/Main.server.lua:7`
`ChangeHumanoidWalkSpeed` sets `humanoid.WalkSpeed = walkSpeed` for a **client-supplied humanoid and
number**. Enables speedhacks (self), freezing other players (WalkSpeed 0), and modifying NPCs.

### C3. Damage/heal any humanoid via the Heal remote
`src/ServerScriptService/ItemSystem_Server/Revamp/Receivers/Components/ConsumableReceiver.lua:14`
`humanoid:TakeDamage(-num)` with client-supplied humanoid and number. Sending a **negative** `num` damages
(kills) any humanoid; positive `num` is unlimited free healing. No check that a consumable was owned or used.

### C4. Delete any tool via the Dispose remote
`src/ServerScriptService/ItemSystem_Server/Revamp/Receivers/Components/ConsumableReceiver.lua:10`
`Debris:AddItem(tool, 10)` on a client-supplied instance. Any client can schedule destruction of any tool
in the game (including other players' weapons).

### C5. Client-authoritative teleport
`src/ServerScriptService/SpawnAndDeathSystem_Server/Main.server.lua:31`
`MoveCharacterToSpawn.OnServerInvoke` does `character:PivotTo(spawnPointCFrame)` with a client-supplied
CFrame. This is a free teleport-anywhere exploit.

### C6. Melee damage is client-supplied
`src/ServerScriptService/ItemSystem_Server/Revamp/Receivers/Components/MeleeReceiver.lua:13,35`
The Hit remote applies `humanoid:TakeDamage(damage)` where `damage` comes from the client. The only check
is a 10-stud distance between characters — no check that a melee weapon is equipped, no damage cap, no rate
limit, no type validation (a non-Humanoid instance errors the handler). Standing near someone is enough to
kill them with `damage = math.huge`.

### C7. Stackable quantity transfer allows item duplication
`src/ServerScriptService/ItemSystem_Server/Revamp/Receivers/Components/StackableReceiver.lua:70-79`
`RequestQuantityTransfer` never validates that `quantityToTransfer` is positive (or an integer), and never
checks the tools belong to the caller. A **negative** transfer increases the source above its original
quantity (`originalSourceQuantity - (-n)`) while setting the destination negative → ammo/caps duplication.
`RequestMergeStackables` (line 65) and `RequestDuplicateStackable` (line 81) similarly lack ownership checks.

### C8. Client can overwrite any lootable's contents
`src/ServerScriptService/LootingSystem_Server/Services/LootDataService.lua:169-180`
`OverrideItemData.OnServerInvoke` assigns `lootableObject.FilledSlotsData = filledSlotsData` directly from
the client with no validation at all (and nil-derefs if the instance isn't a registered lootable).

### C9. Client-authoritative hunger/thirst damage
`src/ServerScriptService/VitalsSystem_Server/VitalsSystemReceivers.server.lua:27`
The client tells the server when to start/stop starvation damage, **which humanoid** to damage, and **how
much**. Exploits: damage arbitrary humanoids repeatedly, or simply never send the event and be immune to
starvation. The entire hunger/thirst simulation runs client-side (`HungerThirstManager.lua`).

### C10. CanCollide toggle on arbitrary models
`src/ServerScriptService/ItemSystem_Server/Revamp/Receivers/Components/SharedReceiver.lua:18`
`ToggleToolCanCollide` accepts any Model/MeshPart and sets `CanCollide` on every BasePart descendant.
Passing a map/building model turns off its collision for everyone — a server-side noclip/grief vector.

### C11. Force-drop other players' equipped tools
`src/ServerScriptService/ItemSystem_Server/Revamp/Receivers/Components/SharedReceiver.lua:29`
`DropTool` never checks the tool belongs to the sender. Another player's equipped tool (replicated via their
character) can be passed; it takes the `else` branch and is re-parented to `workspace` — stealing/disarming.

### C12. Client-authoritative corpse loot creation
`src/ServerScriptService/LootingSystem_Server/Services/LootDataService.lua:107-111`
`SendClientCorpseFilledSlotsData` creates a server `CorpseLootable` from client-supplied data and an
arbitrary client-supplied BasePart. Fake/duplicate corpses with arbitrary contents can be registered. (Also
fragile legitimately: if the dying client crashes, no corpse is ever created.)

### C13. Wearable remote trusts every argument
`src/ServerScriptService/ItemSystem_Server/Revamp/Receivers/Components/WearableReceiver.lua:15`
`ToggleWear` clones a client-chosen Accessory onto a client-chosen character, sets transparency on a
client-chosen accessory, and re-parents a client-chosen tool. No ownership or type validation anywhere.
`MakeAccessoryVisibleOnDeath` (line 71) likewise un-hides any accessory passed in.

### C14. Server plays arbitrary sounds on request
`src/ServerScriptService/ItemSystem_Server/Revamp/Receivers/Components/SharedReceiver.lua:15`
`PlaySound` forwards any client-supplied Sound/parent/delay to `PlaySoundUtil` — global sound spam vector.

### C15. Gun remotes: missing item-type & rate-of-fire validation
`src/ServerScriptService/ItemSystem_Server/Revamp/Receivers/Components/Gun/GunReceiver.lua:54,169`
- Neither `validateShot` nor `validateReload` verifies the Tool is actually a gun. Passing an equipped
  non-gun tool makes `ammo <= 0` compare nil (`validateShot.lua:44`) or `math.rad(nil)` error.
- There is no shot-interval check against `RATE_OF_FIRE`: each request only needs a timestamp within 1s of
  now, so a client can fire far faster than the weapon allows (limited only by ammo).
- `replicateItemSound` handler (line 195-198) uses bare `assert(character)` / `assert(gun.Parent ==
  character)` on client data — exploiters can spam server error logs, and `gun` being nil errors before the
  assert. `soundName` is also unvalidated.

### C16. Free instant respawn
`src/ServerScriptService/VitalsSystem_Server/VitalsSystemReceivers.server.lua:39`
`RespawnPlayerCharacter` calls `player:LoadCharacter()` whenever asked — clients can respawn at will to
escape combat or reset state.

---

## 🟠 High — definite runtime errors

### H1. MeleeReceiver replication calls FireClient without the player
`src/ServerScriptService/ItemSystem_Server/Revamp/Receivers/Components/MeleeReceiver.lua:32,50`
```lua
remotes.ReplicateHit:FireClient(particles, position, normal)   -- line 32
remotes.ReplicateSwing:FireClient(trail, toggle)               -- line 50
```
`FireClient`'s first argument must be a Player; the loop variable `v` is never passed. **Both calls throw
every time they execute**, so melee hits and swing trails are never replicated to other players.

### H2. Stackable bindables nil-deref when no tool is equipped
`src/ServerScriptService/ItemSystem_Server/Revamp/Receivers/Components/StackableReceiver.lua:114-115,147-148`
`getAmmoReserve` and `subtractQuantityFromSum` do
`local equippedTool = character:FindFirstChildOfClass("Tool")` then immediately
`equippedTool:GetAttribute("Quantity")` with no nil check — errors whenever the character has no tool out.

### H3. MergeQuantities asserts in the wrong order
`src/ServerScriptService/ItemSystem_Server/Revamp/Receivers/Components/StackableReceiver.lua:21-23`
`assert(source.Name == destination.Name, ...)` runs before `assert(source and destination, ...)`, so a nil
`source` errors on the `.Name` index and the nil-guard assert is unreachable.

### H4. ToolSpawner indexes the catalog folder with an arbitrary string
`src/ServerScriptService/ItemSystem_Server/Revamp/ToolSpawner.server.lua:9`
`ToolCatalog[toolName]` on an Instance **throws** for names that aren't children (it does not return nil),
so the `if folder == nil` guard is unreachable and any bad/exploit-crafted name errors the handler. Should
be `FindFirstChild`. Also `tool:Clone()` (line 14) nil-derefs if the folder has no Tool child.

### H5. GetLootData nil-derefs on unregistered instances
`src/ServerScriptService/LootingSystem_Server/Services/LootDataService.lua:147`
If the passed instance is neither a standard nor corpse lootable, the else-branch calls
`getCorpseLootable(lootableInstance).FilledSlotsData` on nil. (`TrySlotInteraction` checks this case
properly; `GetLootData` doesn't.)

### H6. Loot ToolDestroyed assert checks the wrong variable
`src/ServerScriptService/LootingSystem_Server/Services/LootDataService.lua:196`
`assert(corpseLootable or standardLootableObjects, ...)` — `standardLootableObjects` is the module-level
**table of all lootables**, which is always truthy, so the assert can never fire; the code then nil-derefs
`standardLootable.FilledSlotsData` (line 216) when neither lookup matched. Should assert `standardLootable`.

### H7. NPC states index `player.Character` with no nil checks
`src/ReplicatedStorage/NPCtest/States/Attack.lua:18` — `player.Character.Humanoid`
`src/ReplicatedStorage/NPCtest/States/Chasing.lua:19` — `player.Character.PrimaryPart.Position`
Both run every Heartbeat. The moment a targeted player dies/respawns/leaves, `Character` is nil (or
PrimaryPart is nil) and the FSM errors every frame. `SawPlayer.lua:19` also indexes `character.PrimaryPart`
right after only checking `character` — PrimaryPart can still be nil while the character is loading.

### H8. ActionManager toggleEnabled/forceToggle have no nil guard
`src/ReplicatedStorage/ActionManagerSystem/ActionManager.lua:260-271`
Both do `ActionManager._bindings[actionName]` then immediately index `.enabled` — calling them for an
unbound action errors. `Gun.toggleAiming` calls `forceToggle("Inspect", false)` (Gun.lua:421) whenever an
inspect track exists, and the bind may legitimately not exist (see M1), so this fires in practice.

### H9. Shop GetToolModel: unvalidated name + clone leak
`src/ServerScriptService/Miscellaneous/ShopGuiManager.server.lua:44-48`
`ToolCatalog[toolName].ToolObject:Clone()` errors on any name not in the catalog (client-supplied string),
and every successful invoke parents a fresh clone into ReplicatedStorage that is **never destroyed** —
unbounded instance growth replicated to all clients.

### H10. Gun.lua assumes PistolCasingUsed exists at module load
`src/ReplicatedStorage/ItemSystem_ScriptStorage/Classes/Subclasses/Gun.lua:29,158`
`pistolShell` is fetched once with `FindFirstChild(..., true)` (no wait). If it hasn't replicated yet (or is
renamed), `pistolShell:Clone()` in `_shellEjection` nil-derefs on every shot.

### H11. RequestPickUpTool indexes PrimaryPart unchecked
`src/ServerScriptService/ItemSystem_Server/Revamp/Receivers/Components/SharedReceiver.lua:56`
`character.PrimaryPart.Position` — PrimaryPart can be nil (dying/loading character). DropTool similarly
indexes `character.HumanoidRootPart` directly (line 36) and uses `error()` on bad input (lines 38,41),
letting clients generate server errors.

### H12. OnHitFloor touch handler can nil-deref
`src/ServerScriptService/ItemSystem_Server/Revamp/Receivers/Components/OnHitFloor.lua:22-26`
`BodyAttach` is not nil-checked before `.Touched`, and inside the handler `partThatTouched.Parent` can be
nil if the touching part was destroyed the same frame. Each `DropTool` call also stacks an additional
Touched connection that only disconnects after a qualifying touch.

---

## 🟡 Medium — logic bugs

### M1. Gun inspect bind overwrites the aiming action name → leaked "Aiming" bind
`src/ReplicatedStorage/ItemSystem_ScriptStorage/Classes/Subclasses/Gun.lua:541`
`Gun.toggleInspectBind` sets `self.actionNames.aiming = "Inspect"` (copy-paste; should be a separate
`inspect` key). After equip, the gun's record of its aiming action is "Inspect", so on unequip
`toggleAimingBind(self, false)` unbinds "Inspect" instead of "Aiming" and **the "Aiming" action is never
unbound**. Cascade: the next gun's `bindAction("Aiming")` hits the already-bound guard
(ActionManager.lua:59) and silently no-ops, leaving right-click aiming wired to the previous (dropped/
destroyed) gun object's closures.

### M2. Module-level aiming state is shared across all gun instances
`src/ReplicatedStorage/ItemSystem_ScriptStorage/Classes/Subclasses/Gun.lua:401-404`
`transitioningToAiming`, `detransitioningFromAiming`, `targetAimingCFrame`, and
`aimTransitionTimeAccumulated` are module-level, not per-instance. `aimTransitionTimeAccumulated` is never
reset on equip/unbind, so unequipping mid-aim leaves a partially "charged" transition that applies to the
next weapon. `isAiming` is also only reset when the de-transition lerp completes with a vmHead present
(line 465-470), so it can be left stuck `true`.

### M3. Semi-auto fire's delayed Idle can stomp the Reloading state
`src/ReplicatedStorage/ItemSystem_ScriptStorage/Classes/Subclasses/Gun.lua:247-249`
`task.delay(60/rateOfFire, ChangeState "Idle")` fires unconditionally. If the player starts a reload (state
"Reloading") within that window — which `Gun.reload` allows from the "Shooting" state — the delayed callback
overwrites the state to "Idle" mid-reload, letting the player shoot while the reload animation plays.

### M4. Reload completes via `Stopped`, even when interrupted
`src/ReplicatedStorage/ItemSystem_ScriptStorage/Classes/Subclasses/Gun.lua:302-308`
The reload's effects (FireServer, `self.ammo += ammoToLoad`, state→Idle) run on `vmReloadTrack.Stopped`,
which also fires when the animation is **stopped early** (unequip/drop stops all tool animations). An
interrupted reload still completes — client and server ammo both update as if it finished.

### M5. Melee.swing resumes after interruption and forces "Idle"
`src/ReplicatedStorage/ItemSystem_ScriptStorage/Classes/Subclasses/Melee.lua:170-173`
After `swingTrack.Stopped:Wait()`, the code unconditionally plays the idle tracks and sets state to "Idle".
If the tool was unequipped/dropped mid-swing (which stops the track), this re-plays idle animations on an
unequipped tool and overwrites the "Unequipped"/"Dropped" state with "Idle", desyncing the slot state machine.

### M6. Item drop leaks the humanoid-Died connection
`src/ReplicatedStorage/ItemSystem_ScriptStorage/Classes/Superclasses/Item.lua:121,233`
`Item.equip` stores `dropEquippedToolOnDeath = humanoid.Died:Once(...)`; `Item.unequip` disconnects it but
`Item.drop` never does. Dropping an equipped item leaves the connection alive — when the player later dies
it fires `ToggleToolCanCollide`/`Item.drop` for a tool they no longer own.

### M7. StaminaManager staminaChanged fires (new, new) instead of (old, new)
`src/ReplicatedStorage/VitalsSystem_ScriptStorage/Stamina/StaminaManager.lua:284-289`
`self.currentStamina = value` is assigned **before** `staminaChangedEvent:Fire(self.currentStamina, value)`,
so listeners always receive `oldStamina == newStamina`.

### M8. Breathing proportion divides by MaxHealth, not MAX_STAMINA
`src/ReplicatedStorage/VitalsSystem_ScriptStorage/Stamina/StaminaManager.lua:178`
`newStamina / References.humanoid.MaxHealth` — copy-paste from the health manager. Only correct while
MaxHealth happens to equal 100; any MaxHealth change silently breaks breathing audio thresholds.

### M9. Female breathing config reads the Male sound's TimeLength
`src/ReplicatedStorage/VitalsSystem_ScriptStorage/Stamina/StaminaManager.lua:57`
The Female `timePositionMarkers` end marker is `FindFirstChild("MaleBreathing", true).TimeLength` —
should be FemaleBreathing. The GUI breathing sync runs past the wrong end-marker for female characters.

### M10. changeStaminaBarBy never clamps
`src/ReplicatedStorage/VitalsSystem_ScriptStorage/Stamina/StaminaManager.lua:295-301`
A melee swing with cost 10 at 5 stamina sets `currentStamina = -5` (negative GUI proportion, longer regen).
Clamping only happens in the RenderStepped drain/fill paths.

### M11. Hunger and Thirst share one module-level threshold event
`src/ReplicatedStorage/VitalsSystem_ScriptStorage/HungerThirst/HungerThirstManager.lua:54,85-89`
`thresholdChangedEvent` is module-level and fired by both stat instances with only the new section number.
Each instance's listener can't tell whose threshold changed, so crossing a thirst threshold also plays the
hunger (stomach rumble) sound and vice versa.

### M12. hungerThirstObject.currentValue is dead; no restore path exists
`src/ReplicatedStorage/VitalsSystem_ScriptStorage/HungerThirst/HungerThirstManager.lua:74,108-122`
The decay loop closes over the **local** `currentValue`; `self.currentValue` is never read or written again,
and a repo-wide search shows nothing else updates it. There is currently no way for eating/drinking to
restore hunger or thirst — the stats only ever decay to 0 and starve the player.

### M13. Vitals damage-thread table leaks/orphans threads
`src/ServerScriptService/VitalsSystem_Server/VitalsSystemReceivers.server.lua:10-24`
The `__newindex` metamethod never rawsets, so every assignment re-fires. Assigning a new entry for a key
that already has a running thread **overwrites the handle without cancelling it** — the old damage loop
becomes unstoppable (hunger + thirst both keyed by `player.Name` collide exactly this way; client sends
both). Threads also run forever if the humanoid is destroyed while Health > 0 (player leaves). The
`timeInterval` parameter is accepted but ignored (`task.wait(1)` hardcoded).

### M14. Pickup prompt disables the template instead of the clone
`src/ServerScriptService/Miscellaneous/CapsAndAmmoPickUp.server.lua:43`
`currencyProxProm.Enabled = false` inside `Triggered` disables the **ReplicatedStorage template**, not
`clonedProxProm`. The intended double-trigger guard never guards, and the master template is left disabled
after the first pickup. Also: `taggedInstance:GetAttribute("Amount") .. ...` (line 35) errors if the
attribute is missing, and `player:GetAttribute(stat) + value` (lines 47,55,60) errors if stats haven't
loaded yet (no `StatsLoaded` wait — races DataSaveSystem).

### M15. DataSaveSystem: no BindToClose, silent failures
`src/ServerScriptService/Miscellaneous/DataSaveSystem.server.lua`
- No `game:BindToClose` handler: on server shutdown/update, `PlayerRemoving` saves are not guaranteed to
  complete → **data loss for everyone online**.
- Load failure (line 16-23) is swallowed: the attribute is simply never set (downstream `GetAttribute(...) +
  n` then errors), yet `StatsLoaded` is still set to true.
- Save failure (line 29-31) is swallowed with the error branch commented out; no retry on either path.

### M16. Vault door plays the open sound when closing
`src/ServerScriptService/Miscellaneous/DoorManager.server.lua:67,76`
Both branches play `vaultDoorOpenSound`; `vaultDoorCloseSound` (line 11) is loaded but never used. Regular
doors also assume `Door Open`/`Door Close` sounds and a ProximityPrompt exist on every tagged model
(lines 18-24 — nil-deref otherwise).

### M17. GetChangeReplicatorRemote busy-waits forever
`src/ServerScriptService/LootingSystem_Server/Services/LootDataService.lua:184-190`
`while ... task.wait()` with a `print` every iteration, no timeout. A request for an instance that never
registers (exploiter, or a destroyed lootable) leaks a busy server thread printing every frame, forever —
a trivially triggered DoS/log-spam vector.

### M18. "Light Bullets" gets an extra spawn in the every-item crate
`src/ServerScriptService/LootingSystem_Server/Services/LootDataService.lua:66-81`
The special case spawns 6 Light Bullets stacks, then falls through to the generic spawn and adds a 7th.
A `continue` (or loop restructure) appears intended.

### M19. Tool state machine: unreachable reject + partial cancellation
`src/ReplicatedStorage/InventorySystem_ScriptStorage/Components/ToolStateMachine/Main_ToolStateMachine.lua`
- `GetToolToThisState` indexes `statePath[#statePath]` (line 89) before the `if statePath` guard (line 96),
  so the `reject("No state path found")` branch (line 167-170) is unreachable — a nil path errors instead.
- `cancelWhenToolDeviatesFromStatePath` is attached for the unequip/unworn legs and for the *unchained*
  target leg (line 333), but **not** when the target leg is chained after a prior promise (line 327-330) —
  deviation during the final leg of a chained operation never cancels the operation.
- `GetCurrentWornItemOfCategory` (lines 174-179) nil-derefs if the WornItems folder or category folder is
  missing (e.g. before WearableReceiver's CharacterAdded setup has run).

### M20. Loot crate "isEmptyTable" treats nil as viable
`src/ReplicatedStorage/.../Main_ToolStateMachine.lua:267-273` — minor: a nil path returns `false`
("not empty"), which is why the unreachable-reject path in M19 matters; a nil path slips through validation.

---

## 🔵 Low — leaks, dead code, debug noise

### L1. Corpses accumulate forever
`src/ServerScriptService/CorpseKeeper.server.lua:10-15`
Every `CharacterRemoving` re-parents the old character back into workspace; the `Debris:AddItem(character,
5)` cleanup is commented out and nothing else removes corpses. Long servers accumulate one corpse rig per
death (each with cloned tools via the looting system) — unbounded memory/replication growth.

### L2. Uncommitted debug output in HitboxManager
`src/ReplicatedStorage/ItemSystem_ScriptStorage/Classes/Components/Shared/HitboxManager.lua:22-23`
The only uncommitted change in the working tree adds `warn("Created new hitbox manager")` +
`warn(self.RaycastHitbox)`. Related debug noise shipped in committed code: `print(self.HitboxManager)` /
`print(self)` in `Melee.lua:120-121`, `print(ammoReserve)` in `Gun.lua:271`, `print(player)` in
`LootDataService.lua:159`, `warn(stackableName, quantityToSubtract)` in `StackableReceiver.lua:125`, and
many `print`s in `Item.lua` (`drop`, `immediateUnequip`, `initialize`).

### L3. Item.TrackAnimTrack can yield forever
`src/ReplicatedStorage/ItemSystem_ScriptStorage/Classes/Superclasses/Item.lua:104-106`
`while animTrack.Length == 0 do task.wait() end` has no timeout. If an animation asset fails to load, this
spins forever — and because it's called at the top of `Item.initialize`, **none of the item's bindable-event
connections are made**, leaving the item permanently unresponsive. Same unbounded-poll pattern in
`StaminaManager.waitForStaminaObject` (StaminaManager.lua:193-195).

### L4. unbindAction clears fields that don't exist
`src/ReplicatedStorage/ActionManagerSystem/ActionManager.lua:251-252`
`binding.fadeInTweens = nil` / `binding.fadeOutTweens = nil` — those are closure upvalues, not binding
fields; the assignments are dead code. Also `_updateInputDisplay` (line 328-334) leaves `buttonDisplay` nil
for the `Unknown` input category and then sets `.Parent` on it.

### L5. SprintReceiver.lua is an empty stub
`src/ServerScriptService/MovementAndStaminaSystem_Server/Components/SprintReceiver.lua`
File contains only a comment block — dead file (sprinting speed is enforced nowhere server-side; see C2).

### L6. Melee assumes a Trail exists
`src/ReplicatedStorage/ItemSystem_ScriptStorage/Classes/Subclasses/Melee.lua:49,179`
`tool:FindFirstChildWhichIsA("Trail", true)` is cast non-nil; `Melee.toggleSwingTrail` then sets
`self.trail.Enabled` — any melee tool without a Trail errors at construction time. Similarly `Item.unequip`
(Item.lua:176) assumes a viewmodel `unequip` track exists whenever the world-model one does.

### L7. Typos & misc
- `Gun.lua:282` — warn message "Can't reloading while aiming."
- `CapsAndAmmoPickUp.server.lua:16` — `FindFirstChild("PlayerSoundUtil")` (elsewhere it's `PlaySoundUtil`);
  the variable is unused.
- `LootDataService.lua:196` — assert message "Could not find lootalbe".
- `StaminaManager.lua:103` — assert message "cannot intiialize".
- `SpawnAndDeathSystem_Server/Main.server.lua:6,15` — `SpawnAndDeathManager` required twice into two
  differently-cased locals (`SpawnAndDeathManager` / `SpawnAndDeathmanager`).
- `selene.toml` exists but selene is not in `aftman.toml`, so the configured linter isn't installed by the
  toolchain.

---

## Inventory client UI (follow-up review)

All paths below are under `src/ReplicatedStorage/InventorySystem_ScriptStorage/`.

### 🟠 High

**INV-H1. EmptySlot kills the slot's own destroy hook**
`Components/Slot/Slot.lua:266-270`
`Slot.EmptySlot` disconnects every connection except `hoverBegin`/`hoverEnd` — **including `onDestroying`**,
which is only ever connected in `Slot.new` (line 89) and is what routes `Frame.Destroying` to `Slot.destroy`.
Any slot that has been emptied once no longer cleans itself up when its GUI instance is destroyed:
`instanceToObjectMap` keeps a dead entry and `Slot.destroy`'s bookkeeping never runs.

**INV-H2. EmptySlot errors on an already-empty slot**
`Components/Slot/Slot.lua:255`
`Slot.toolToObjectMap[self.tool:: Tool] = nil` — if `self.tool` is already nil, this is a nil table index
and **throws**. The function nil-checks `self` (line 249) but never `self.tool`.

**INV-H3. Slot finders `return` instead of `continue` on loot slot-groups**
`Components/Slot/EmptySlotFinder.lua:34`, `Components/Slot/StackableSlotFinder.lua:47`
Inside the slot-group loop, encountering a group under the LootingScrollingFrame does
`if ... then return end` — aborting the **whole search with nil** instead of skipping that group.
`SlotGroupRegistry.instanceToObjectMap` is a hash map, so iteration order is nondeterministic: whenever a
looting group happens to be visited first, `EmptySlotFinder.any()` reports the inventory full (pickup
autofill silently fails — `InventoryManager.lua:56-59` just doesn't fill a slot) and
`StackableSlotFinder.inventory()` fails to find stacks. `StackableSlotFinder.getSum` (line 81) does this
correctly with `continue`, which is what the other two clearly intended. Intermittent, load-order-dependent —
the classic "sometimes items don't show up in my inventory" bug.

**INV-H4. Equipment swap wipes the registry entry of the swapped-in tool**
`Components/Slot/Drag/ActionHandlers/Components/P_INVENTORY__X__P_EQUIPMENT.lua:104-109`
The swap branch runs: `emptySlot(wearableSlot)` → `fillSlot(wearableSlot, inventoryOrHotbarSlot.tool)` →
`emptySlot(inventoryOrHotbarSlot)` → `fillSlot(...)`. The third call's `EmptySlot` does
`toolToObjectMap[self.tool] = nil` for a tool that was **just re-mapped to `wearableSlot`** by the second
call — deleting the live registry entry for the now-worn tool. Later lookups
(`SlotRegistry.toolToObjectMap[tool]`, e.g. when the tool is dropped/removed) return nil and the slot UI is
left stale. The non-swap branch (lines 97-100) empties before filling — the correct order.

**INV-H5. getSlotData can grab the wrong ObjectValue**
`Components/Slot/Drag/handleDragDrop.lua:46`
For equipment slots it uses `slotObject.tool:FindFirstChildOfClass("ObjectValue")` and treats its `Value` as
the associated slot-group Frame. But `LootDataService.moveToolsToLootItemsHolding` adds a second ObjectValue
(`CorpseCharacterValue`, pointing at a corpse Model) to tools that went through a corpse — whichever child
comes first wins, so `slotGroupInstance` can silently become a corpse Model cast as a Frame. Should look up
`AssociatedItemGroup` by name.

**INV-H6. Hover info display assumes a Description attribute**
`Components/Slot/Hover.lua:58`
`textbox.Text = tool:GetAttribute("Description")` — assigning nil to `.Text` throws for any tool without the
attribute, from a bare hover over a filled slot.

### 🟡 Medium

**INV-M1. Four drag-drop combinations are silent no-op stubs**
`Components/Slot/Drag/ActionHandlers/ActionHandlers.lua:69-71,83-85,90-92,115-117`
L_INVENTORY→L_EQUIPMENT, L_EQUIPMENT→L_INVENTORY, L_EQUIPMENT→P_INVENTORY, and P_INVENTORY→L_EQUIPMENT only
`print` and return. The drag completes visually (item snaps back) with no feedback — unimplemented features
shipping as silent no-ops.

**INV-M2. Always-true elseif in the equipment swap resolve**
`.../P_INVENTORY__X__P_EQUIPMENT.lua:101`
`elseif not (wearableSlot._isEmpty and inventoryOrHotbarSlot._isEmpty)` — reached only when
`wearableSlot._isEmpty` is false, so the conjunction is false and the condition is always true. Harmless
today (it acts as a plain `else`) but the guard it was meant to express doesn't exist.

**INV-M3. In-progress drag survives its slot being emptied/destroyed**
`Components/Slot/Drag/DragFunctionality.lua:43-75`
`Slot.EmptySlot`/`Slot.destroy` disconnect the `MouseButton1Down` connection, but nothing cancels a drag
already in flight: the `"Drag"` render-step keeps lerping the ghost toward the cursor and reading the dead
slot's `ActionIndicator` attributes. If the dragged tool is removed mid-drag (despawn, another system moves
it), the ghost is orphaned and `Drag.stop` for it never runs (`Drag.currentSlot` stays set, which also
breaks the next drag's early-return logic).

**INV-M4. Hardcoded BindToRenderStep name collides on a second concurrent drag**
`Components/Slot/Drag/DragFunctionality.lua:43`
`BindToRenderStep("Drag", ...)` while a drag is already bound **throws**. Mouse can't trigger it, but touch
can: the `slot._itself.Interactable = false` guard is commented out (line 35), so a second finger starting a
drag on another slot errors and leaves the first drag's state inconsistent.

**INV-M5. Drag.stop force-shows the FilledSlotCounter on every wearable slot**
`Components/Slot/Drag/DragFunctionality.lua:68`
`slot.FilledSlotCounter.Visible = slot.WearableCategory ~= nil` — but `Slot.FillSlot` only makes that
counter meaningful for StorageWearables with an associated slot group (Slot.lua:196-231). Dragging any
non-storage wearable (e.g. NV Goggles) leaves a stale/empty counter label visible.

**INV-M6. Re-filling a slot overwrites connection handles without disconnecting**
`Components/Slot/Slot.lua:150,154,175,233`
`FillSlot` assigns `self.connections.updateQuantityLabel/openSplittingMenu/EquipFromClick/DragFunctionality`
unconditionally. If a fill happens without an intervening `EmptySlot` (the handlers call fill/empty in
varying orders — see INV-H4's ordering subtleties), the previous live connections are orphaned: duplicate
listeners (double equip toggles per click) that nothing can disconnect anymore.

**INV-M7. Hover state machine leaks info displays and table entries**
`Components/Slot/Hover.lua:51,98-107,130-132`
`itemInfoDisplays[slot] = createItemInfoDisplay(slot)` entries are never removed (`removeEffect` destroys
the frames but leaves the table keyed by slot objects forever — including destroyed ones), and
`destroyItemInfoDisplay` is dead code. Each hover also spawns a polling task; rapid hovering across slots
churns tasks and re-destroys already-destroyed frames.

**INV-M8. ResizeGui only ever shrinks**
`InventoryManager.lua:120-135`
Slot cells are resized only inside `if fifthSection < 50`; when the window grows back there is no branch to
restore the default cell size, so slots stay small after one shrink. (`cachedScreenSize.height` is also
dead — only `width` is ever read/written.)

### 🔵 Low

**INV-L1. Accidental globals in Hover.lua**
`Components/Slot/Hover.lua:16-17`
`SlotHoveredChangedBindable` and `SlotHoveredChanged` are missing `local` — they leak into the global
environment, and `SlotHoveredChanged` isn't exposed on the `Hover` table where consumers would look for it.

**INV-L2. Module-load busy-wait for the template UIStroke**
`Components/Slot/Hover.lua:4-7`
A `while ... task.wait()` poll with no timeout, at require time, for a UIStroke inside TemplateSlot — same
unbounded-poll pattern as L3; a missing stroke wedges every module that requires Hover.

**INV-L3. Slot-section detection by ancestor name string**
`Components/Slot/Drag/handleDragDrop.lua:23-39`
`getSlotType` classifies slots via `FindFirstAncestor(<Name>)`. Any unrelated ancestor sharing a cached name
("Hotbar", "Inventory", etc., which also exist in other ScreenGuis like `InventoryAndHotbar`) misclassifies
the slot and routes the drop to the wrong handler.

**INV-L4. Debug print spam throughout the drag/split path**
Every ActionHandlers entry prints its action (`ActionHandlers.lua` lines 33-133); `Slot.FillSlot`'s
storage-wearable path prints connection diagnostics (Slot.lua:200-222); `SplittingMenuManager` prints
("making this thang invisible", line 249); `DragFunctionality` prints on cancel (line 110).

**INV-L5. Infinite-repeat spinner tweens are never cancelled**
`Components/Slot/Slot.lua:128`, `Components/SplittingMenuManager.lua:239`
The suspend/loading spinners tween with `repeatCount = math.huge` and are "stopped" by playing a new 0-second
tween over the same property, relying on conflicting-tween override instead of `Cancel()` — the infinite
tween object stays alive on the instance.

---

## Recommended priorities

1. **Gate every remote** (C1-C16): the Gun shoot path's `ServerChecks`/`TypeValidation` pattern already in
   the repo is the right template — apply it to melee, consumables, stackables, vitals, movement, wearables,
   looting, and the tool spawner. Delete `rev_SpawnTool` and `ChangeHumanoidWalkSpeed` outright unless a
   validated use case exists.
2. **Fix H1** (one-line: pass `v` to FireClient) — melee replication is currently 100% broken.
3. **Move hunger/thirst and stamina authority to the server** (C9/M12/M13) — the current design is both
   exploitable and incomplete (no food/drink restore path).
4. **Add `game:BindToClose`** to DataSaveSystem (M15) before any wider playtest.
5. The Gun/Item state-machine races (M1-M6) are the largest source of "weird weapon behavior" bug reports
   to expect from alpha testers.
6. **INV-H3** (one-line `return` → `continue` in two slot finders) likely explains intermittent
   "picked-up items don't appear in my inventory" reports; INV-H1/H4 are the slot-registry leaks behind
   stale inventory UI after equip/swap operations.

---

## Review coverage

How this audit was performed, so future passes know where to look. Three tiers:
**deep** = read line-by-line; **sampled** = touched only by repo-wide searches (`currentValue`,
TODO/FIXME markers, remote-trust patterns) or skimmed for context; **unreviewed** = never opened.
Absence of findings in sampled/unreviewed code means nothing.

### Deeply analyzed (45 files, ~5,700 lines)

**ServerScriptService:**
- `ItemSystem_Server/Revamp/` — ToolSpawner.server.lua; Receivers/Components: ConsumableReceiver,
  MeleeReceiver, OnHitFloor, SharedReceiver, StackableReceiver, WearableReceiver;
  Gun/GunReceiver.lua; Gun/ServerChecks: validateShot, validateReload, validateTag, validateShootArguments
- `LootingSystem_Server/Services/LootDataService.lua`
- `Miscellaneous/` — DataSaveSystem, ShopGuiManager, CapsAndAmmoPickUp, DoorManager
- `MovementAndStaminaSystem_Server/` — Main.server.lua, Components/SprintReceiver.lua
- `NPC_Manager/StateMachineManager.server.lua`
- `SpawnAndDeathSystem_Server/Main.server.lua`
- `VitalsSystem_Server/VitalsSystemReceivers.server.lua`
- `CorpseKeeper.server.lua`

**ReplicatedStorage (client/shared):**
- `ItemSystem_ScriptStorage/Classes/` — Superclasses/Item.lua, Subclasses/Gun.lua, Subclasses/Melee.lua,
  Components/Shared/HitboxManager.lua
- `ActionManagerSystem/ActionManager.lua`
- `VitalsSystem_ScriptStorage/` — Stamina/StaminaManager.lua, HungerThirst/HungerThirstManager.lua
- `NPCtest/` — States/Attack.lua, States/Chasing.lua, Transitions/SawPlayer.lua
- `InventorySystem_ScriptStorage/` — InventoryManager.lua, Components/ToolStateMachine/Main_ToolStateMachine.lua,
  Components/SplittingMenuManager.lua, Components/Slot/Slot.lua, Components/Slot/Hover.lua,
  Components/Slot/EmptySlotFinder.lua, Components/Slot/StackableSlotFinder.lua,
  Components/Slot/Drag/DragFunctionality.lua, Components/Slot/Drag/handleDragDrop.lua,
  Components/Slot/Drag/ActionHandlers/ActionHandlers.lua,
  Components/Slot/Drag/ActionHandlers/Components/P_EQUIPMENT__X__L_INVENTORY.lua,
  Components/Slot/Drag/ActionHandlers/Components/P_INVENTORY__X__P_EQUIPMENT.lua

### Sampled only

- `LootingSystem_Server/Components/SharedFunctions.lua` (two lines via a search hit)
- Repo-wide grep results: TODO/FIXME locations, `currentValue` usages, server file listing
- `default.project.json`, `selene.toml`, `aftman.toml`, git history/diff

### Unreviewed — future bug-hunt targets, highest value first

**Security-relevant (the gun validation chain depends on these — verify before trusting C15's "well-validated" assessment):**
- `ItemSystem_Server/.../Gun/TypeValidation/` — validateCFrame, validateInstance, validateNumber,
  validateSimpleTable, validateVector3 (all 5 unread)
- `ItemSystem_ScriptStorage/Classes/Components/Gun/Utility/` — castRays, getRayDirections,
  canPlayerDamageHumanoid, drawRayResults, CameraRecoiler, Effects/impactEffect
- `LootingSystem_Server/Components/` — CorpseLootable.lua (10KB, processes loot data-change requests —
  the authorization layer for looting), StandardLootable.lua, LootToolsDestructionTracker.lua
- `ItemSystem_Server/Revamp/Receivers/InitItemServerReceivers.server.lua`,
  `.../Gun/AccessoryFiltering.server.lua`, `ItemSystem_Server/ToolCatalog.lua`

**Remaining server files (small but unread):**
- `OnPlayerAndCharacterAdded.server.lua`, `RandomSpawnPoints.server.lua`
- `CharacterReceivers/` — PlayFootstepSoundReceiver, TiltAtReceiver (both take client remotes)
- `PrepareCharacter/` — CharacterBundleRemover, CreateBodyAttachJoint, getShirtTemplateId
- `NPC_Manager/` — humanoidFinder, mutantRoach, npc_script_executor
- `Miscellaneous/CapsAndAmmoSpawner.server.lua`, `LootingSystem_Server/LootingSystemExecutor.server.lua`

**Large unread client files (likely bug-dense, by size):**
- `InventorySystem_ScriptStorage` remainder — ActionHandlers/Components: P_EQUIPMENT__X__L_EQUIPMENT (11.9KB),
  P_INVENTORY__X__L_INVENTORY, L_INVENTORY__SWAP, SPLIT_SLOT__X__L_INVENTORY, SPLIT_SLOT__X__P_INVENTORY,
  P_INVENTORY__SWAP, the four __DROP handlers, Utility.lua, References_ActionHandlers;
  LootingSection/ (LootGuiManager 9.8KB, initClientLootable, initStorageWearableLootable, Lootable,
  LootActions, LootPromptManager, Main_LootingSection); References_Inventory_Client (8.7KB); SlotGroup,
  SlotRegistry/SlotGroupRegistry, Select, InventoryToggle, ItemMovementTracker, GetStatePath;
  CharacterSection/ (ViewportCharacter, ViewportController, etc.); HotbarSection/
- `ItemSystem_ScriptStorage` remainder — Data/ToolInfo.lua (10.6KB), References_ItemSystem.lua,
  Components/Shared/ (ToolPromptManager 9.8KB, ViewmodelManager 9.4KB, ToolAnimationManager, ItemHUD,
  CrosshairManager, TouchInputController), Subclasses/Wearable.lua (9.3KB), Subclasses/Stackable.lua,
  Items/ (NVGoggles 6.6KB, HealingInjection, StorageWearable), ItemInstantiator
- `Components/ViewModelController.lua` (11.5KB), `SuperClasses/ItemTemplate.lua` (8.7KB)
- `VitalsSystem_ScriptStorage` remainder — Health/HealthManager.lua (8.5KB), StatGuiManager, SoundUtility,
  SpawnAndDeathManager, VFX/SFX modules
- `Utility/` — UiSliderManager (6.9KB, drives the splitting menu), CircularProgressBarManager (6.4KB),
  PlaySoundUtil, handleTaggedInstances, DiegeticErrorMessagingManager, CameraCutsceneManager, etc.
- `ActionManagerSystem/Components/` — InputCategorizer, InputMetadata, TouchDisplayManager
- `NPCtest/` remainder — States/Idle, States/Dead; Transitions/AttackRange, OffAttackRange, PlayerTooFar, Died

**Whole sections never opened:**
- `StarterPlayerScripts/` — PlayerFlow (Main_PlayerFlow, MainMenuManager 8.5KB), LocalShopGuiManager (8.3KB),
  ItemSystem_Client receivers, vitals/inventory/ambience/GUI executors
- `StarterCharacterScripts/` — DialogSystem (ProcessDialogInfo 7.6KB), CharacterStuff (DirectionalMovement,
  CameraSway, ViewmodelAttacher, TiltCharacterLimbs), MovementActions (6.7KB), InitDeathScreen (6.3KB),
  ItemSystem_CharacterScripts
- `ReplicatedFirst/LoadingScreenScripts/` (LoadingScreenManager 5.4KB)
- Scripts that exist only in the Studio place (AlphaTesterBadgeAwarder, VIEWPORT FRAME, MobileShiftLock setup,
  workspace part scripts like hotMetal, NPC rig RagdollR6NPC scripts) — not in this repo at all
- Third-party: `Packages/`, `Submodules/` (Promise, GoodSignal, RaycastHitbox), `dweq` patch file
