# Project-RF-Demo Codebase Overview

A Roblox survival RPG game built with **Rojo** (code sync), **Wally** (package manager), and **Luau** (typed Lua). Post-apocalyptic setting with items like Bloxy Cola Caps, Raider Axe, and NV Goggles.

**Live place:** "[Alpha Release] Wild Wasteland" — placeId `16414030584`, gameId (universe) `5657311237`. This repo holds the *code* only; the map, UI, tool models, and animation assets live in the Studio place itself (see [Live Studio Place](#live-studio-place-whats-not-in-this-repo)).

---

## Technical Stack

| Layer | Technology |
|-------|-----------|
| Engine | Roblox Luau |
| Build Tool | Rojo 7.4.1 |
| Package Manager | Wally 0.3.2 |
| Async/Promise | evaera/promise 4.0.0 |
| State Machines | RobloxStateMachine 1.1.7 |
| UI Framework | React 17.2.1 (via react-roblox) |
| Signals/Events | GoodSignal 0.2.1 |
| Resource Cleanup | Trove 1.5.0 |
| Melee Combat | RaycastHitbox 1.0.2 |
| Zones/Regions | ZonePlus 3.2.1 |
| Linting | Selene (Roblox std) |

**29 total packages** (including transitive). **3 git submodules**: Promise, GoodSignal, RaycastHitbox.

---

## Source Structure

```
src/
├── ReplicatedFirst/              # Early-loading client code
│   └── LoadingScreenScripts/     # Title screen & loading UI
│
├── ReplicatedStorage/            # Shared (client + server) code
│   ├── ActionManagerSystem/      # Input/action binding framework
│   ├── ItemSystem_ScriptStorage/ # Complete item/gear system
│   ├── InventorySystem_ScriptStorage/ # Inventory UI & management
│   ├── VitalsSystem_ScriptStorage/    # Health, stamina, hunger/thirst
│   ├── BuffsDebuffsSystem_ScriptStorage/ # Status effects (WIP)
│   ├── NPCtest/                  # NPC AI state machines
│   ├── SpawnAndDeathSystem_ScriptStorage/ # Respawn logic
│   ├── Components/               # Shared component classes
│   ├── SuperClasses/             # Base class definitions
│   ├── Submodules/               # Git submodules
│   └── Utility/                  # Helper functions & managers
│
├── ServerScriptService/          # Server-only code
│   ├── ItemSystem_Server/        # Server item handling & validation
│   ├── LootingSystem_Server/     # Corpse looting mechanics
│   ├── VitalsSystem_Server/      # Damage/respawn remotes
│   ├── MovementAndStaminaSystem_Server/ # Walk speed sync
│   ├── NPC_Manager/              # NPC spawning & FSM
│   ├── PrepareCharacter/         # Character initialization
│   ├── SpawnAndDeathSystem_Server/ # Spawn protection zones
│   ├── CharacterReceivers/       # Animation event receivers
│   └── Miscellaneous/            # Shops, pickups, doors, data saving
│
├── StarterPlayerScripts/         # Per-player initialization
│   ├── ItemSystem_Client/        # Gun/melee input receivers
│   ├── PlayerFlow/               # Main client flow & UI orchestration
│   └── [Individual managers]     # Vitals, Inventory, Ambience, GUIs
│
└── StarterCharacterScripts/      # Per-character code
    ├── CharacterStuff/           # Movement, camera, viewmodels
    ├── DialogSystem/             # NPC conversation system
    ├── ItemSystem_CharacterScripts/ # Equip/unequip handlers
    └── MovementActions/          # Movement abilities
```

Rojo maps each top-level `src/` folder into a `RojoManaged_*` Folder under the corresponding service (verified live via MCP):

| `src/` folder | In-game location |
|---------------|------------------|
| `ReplicatedStorage` | `ReplicatedStorage.RojoManaged_RS` |
| `ReplicatedFirst` | `ReplicatedFirst.RojoManaged_RF` |
| `ServerScriptService` | `ServerScriptService.RojoManaged_SSS` |
| `StarterPlayerScripts` | `StarterPlayer.StarterPlayerScripts.RojoManaged_SPS` |
| `StarterCharacterScripts` | `StarterPlayer.StarterCharacterScripts.RojoManaged_SCS` |

Wally packages go to `ReplicatedStorage.Packages`.

---

## Core Game Systems

### Item System (Most Complex)

**Location:** `ReplicatedStorage/ItemSystem_ScriptStorage/`

Class hierarchy with OOP inheritance:

```
Item (Superclass)
├── Gun         - Raycast shooting, ammo, recoil, shell casings, impact FX
├── Melee       - RaycastHitbox-based hit detection
├── Consumable  - HealingInjection (state machine: equip -> idle -> activate)
├── Stackable   - Merge/split support
└── Wearable    - NV Goggles (toggleable), StorageWearable (backpack)
```

**Key components:** ViewmodelManager (first-person arms), ToolAnimationManager, ToolPromptManager (pickup prompts), ItemHUD, CrosshairManager, HitboxManager, TouchInputController.

**References_ItemSystem.lua** acts as a dependency injection container, providing centralized access to tool catalog, animation data, player context, networking, and lifecycle management.

**Gun system features:** Ammo attributes, first-person aiming, raycast hit detection, camera recoil, shell ejection, impact decals, cross-client sound replication, client-server hit validation. Post-rewrite (merged `Gun-Class-Rewrite` branch): Shooting/Reloading are represented as item *states* rather than boolean properties, the class is strictly typed, reload consumes a stackable ammo item type, and a toggleable inspect animation exists.

### Inventory System

**Location:** `ReplicatedStorage/InventorySystem_ScriptStorage/`

Slot-based inventory with:
- **CharacterSection** (left panel - equipped items)
- **HotbarSection** (bottom - quick slots)
- **InventorySection** (main grid)
- **LootingSection** (corpse interaction)
- **SplittingMenuManager** (stack splitting UI)
- **SlotRegistry** (slot-based management)

Features: drag-and-drop, hotbar quick equip, auto-fill on pickup, responsive sizing, stack split/merge.

**Entry:** `InventoryAndItemSystemsExecutor.client.lua` initializes on character load.

### Vitals System (Health, Stamina, Hunger/Thirst)

**Location:** `ReplicatedStorage/VitalsSystem_ScriptStorage/`

Three managers:
1. **HealthManager** - Heartbeat SFX intensifying at low health, color desaturation, reverb/ear ringing at critical health, audio ducking
2. **StaminaManager** - Breathing SFX varying by stamina level, gender-selectable breathing sounds, regeneration after exertion, linked to ActionManager
3. **HungerThirstManager** - Passive damage below thresholds, server-side damage application, respawn on starvation

Shared: StatGuiManager (UI bars), SoundUtility (sound tweening), VFX/SFX modules.

### Action Manager (Input System)

**Location:** `ReplicatedStorage/ActionManagerSystem/`

Centralized input binding for Keyboard, Gamepad, and Touch. Features: cooldown timers with visual progress bars, context-aware input categorization, dynamic GUI display, mobile touch button generation, conditional activation. Used by weapon firing, sprinting, aiming, and item usage.

### NPC System

**Location:** `ReplicatedStorage/NPCtest/`

RobloxStateMachine-based AI with states: **Idle** (patrol), **Chasing** (pursue player), **Attack** (melee in range), **Dead**. Transitions: SawPlayer, AttackRange, OffAttackRange, PlayerTooFar, Died. Server-side StateMachineManager uses CollectionService tags ("NPC_FSM_Test").

### Spawn & Death System

Protected spawn zones via ZonePlus. Corpse preservation (CorpseKeeper). Random spawn point selection. Respawn remote functions.

### Dialog System

**Location:** `StarterCharacterScripts/DialogSystem/`

NPC proximity triggers (ProximityPrompts), dynamic dialog trees, distance check cancellation, character-specific dialog info.

### Movement & Camera

**Location:** `StarterCharacterScripts/CharacterStuff/`

- **DirectionalMovement** - Dynamic limb rotation based on movement direction
- **CameraSway** - First-person camera bob
- **TiltCharacterLimbs** - Character tilt on slopes
- **ViewmodelAttacher** - First-person gun model attachment

### Looting System

**Location:** `ServerScriptService/LootingSystem_Server/`

LootDataService manages lootable data. Toggle worn accessories on corpses. Remote event for wearable toggling. Loot crates (standard non-wearable lootables) are generated with random preset data; a dev preset containing all items also exists. Server-side `LootStorage` folder holds loot at runtime.

---

## Client Flow

1. **ReplicatedFirst** -> `ExecuteLoadingScreen.client.lua` shows preload UI
2. **StarterPlayerScripts** -> `Main_PlayerFlow.client.lua` orchestrates:
   - Loading screen transition
   - Title screen / main menu (MainMenuManager)
   - Nuke scene animation / cutscene
   - Transition to gameplay (first-person camera, touch controls)
3. Parallel initialization of: Inventory, Vitals, CentralGuiManager, LootPrompts, ShopGUI, Ambience, ItemSystem_Client receivers

---

## Server Systems

- **PrepareCharacter/** - CharacterBundleRemover, CreateBodyAttachJoint, getShirtTemplateId
- **MovementAndStaminaSystem_Server** - Syncs humanoid walk speed from client
- **VitalsSystem_Server** - Applies hunger/thirst damage, handles respawn, damage thread management
- **ItemSystem_Server** - `ToolCatalog` (item definitions) plus a `Revamp/` architecture: `ToolSpawner` and `Receivers/` with per-class receiver components (Gun, Melee, Consumable, Stackable, Wearable, Shared, OnHitFloor). The Gun receiver carries dedicated `ServerChecks/` (validateShot, validateReload, validateShootArguments, validateTag) and `TypeValidation/` modules (CFrame, Instance, Number, Vector3, simple tables) for anti-exploit validation of client remotes
- **NPC_Manager** - AI setup via StateMachineManager
- **Miscellaneous/** - DoorManager, ShopGuiManager, DataSaveSystem, CapsAndAmmoSpawner

---

## Live Studio Place (what's NOT in this repo)

Surveyed via the Roblox Studio MCP. Only the `RojoManaged_*` folders and `Packages` come from this repo — a large amount of game content exists solely in the place file:

### Workspace (~105 top-level children)
- **DemoArea/** — the playable demo map: `spawnPoints`, `spawnBox`, `Doors` (9), `NPCs`, `ArmsDealer`, `highwayBridge`, `vaultBuild`, `trees`, terrain props (ammo cans, bottle caps, sheet metal, etc.)
- **DeveloperArea/** — dev sandbox: animation rigs per item (`animRig_beretta`, `animRig_raiderAxe`, `animRig_healingInjection`, NV Goggles rig, accessory test rigs), shooting targets, material tests, a Prototype Pistol tool
- ~52 loose Models (Ghoul/Dummy NPC ragdoll rigs, etc.), ~25 loose KeyframeSequences (animation editor leftovers), Terrain, a `Shop` part with ProximityPrompt/BillboardGui

### StarterGui (19 ScreenGuis — all UI is built in Studio, not in code)
`MainMenu`, `AlphaNotice`, `Inventory` + `InventoryAndHotbar` (with slot Templates and SplittingMenu), `VitalsGui`, `ItemHUD`, `CrosshairGui`, `ActionGui2`, `ShopUI`, `DialogGui`, `LootingGui`, `DeathScreen`, `EffectsOverlay` (Heal/Blood), `Eyelids`, `GlitchEffect`, `DiegeticErrorMessaging`, `TransitionBlackScreen`, `MobileShiftLock`, `3Dto2D`. Repo scripts find and drive these GUIs at runtime.

### ServerStorage
- **ToolModels/** — the physical Tool assets the `ToolCatalog` spawns: `Raider Axe`, `Beretta`, `Healing Injection`, `Night Vision Goggles`, plus a shared `ToolProximityPrompt` template. Each tool carries `ToolModel`, `BodyAttach`, `SFX_part`, `DropDetector`, `Anims`; guns add `Muzzle`, `aimPart`, `shellSpawnPart`
- **TagList/** — CollectionService tag configs: `doorModel`, `Slider`, `Melee`
- **LootStorage/** — runtime loot container; **RBX_ANIMSAVES** — 21 animation save rigs

### ReplicatedStorage (Studio-only siblings of RojoManaged_RS)
`Viewmodel` (first-person arms model), `Footprints/` (Snow/Sand/Dirt/Grass footprint models), `WearablesViewportCharacter` & `originC0Holder` (inventory viewport rigs), a standalone `RaycastHitboxV4` ModuleScript copy, `SpawnAndDeathManager_Storage` (RemoteFunctions), `ProgressBar` frame, `FadeInTitleScreen` BindableEvent, `getShirtTemplateId` RemoteFunction, and ~12 more asset folders.

### Loose scripts in the place (not Rojo-managed)
`ServerScriptService.AlphaTesterBadgeAwarder`, `ReplicatedStorage.VIEWPORT FRAME` LocalScript. Changes to these never reach version control.

**Implication:** Rojo cannot rebuild this game from the repo alone — `default.project.json` is a partial-sync mapping into an existing place, not a full place definition. The place file is the source of truth for the map, UI, and assets.

---

## Code Patterns

| Pattern | Usage |
|---------|-------|
| **Singleton** | References.lua, References_ItemSystem.lua (centralized state) |
| **Object Factory** | ItemInstantiator, ToolInfo catalog |
| **Observer/Listener** | Event-driven UI updates, animation callbacks |
| **State Machine** | NPC AI (RobloxStateMachine), Tool states |
| **Component Composition** | ViewmodelManager, ToolAnimationManager |
| **Lifecycle Management** | Trove-based cleanup, .Destroy() methods |
| **Async** | Promise chains, task.spawn/defer |

**Module pattern:** `module = {} function module.new() ... return module end` with `export type` and `--!strict`.

**Networking:** RemoteEvent for unreliable firing (SFX, input), RemoteFunction for request/response (spawn, properties), BindableEvent for internal client communication.

**State management:** Item states ("Unequipped", "Equipped", "Shooting", "Reloading"), NPC states via FSM, tool attributes for persistent data.

---

## Metrics

- 230 Lua/Luau files across ~95 directories
- ~16,400 lines of source code (excluding packages)
- 29 package dependencies (11 direct)
- 3 git submodules
- Last commit: 2025-10-12 (`4a605e9` — title screen right panel)

---

## Incomplete/WIP Systems

- **Buffs/Debuffs** - Folder exists but appears incomplete
- **CI/CD** - No GitHub Actions workflows configured
- **Tests** - No test framework in use
- **NPC AI** - Basic 4-state FSM, no pathfinding service usage yet
- **Dialog Trees** - Basic support, no visible branching logic

(The day/night cycle was reactivated in commit `1b2cf14` and is no longer WIP.)

---

## Notes

- `dweq` file at repo root is a git diff patch with uncommitted experimental changes to Vitals/Stamina systems (breathing thresholds, jump cooldown, heartbeat markers)
- `.github/` only contains an issue template for bug reports
- Working tree has one uncommitted change: a 2-line addition to `src/ReplicatedStorage/ItemSystem_ScriptStorage/Classes/Components/Shared/HitboxManager.lua`
