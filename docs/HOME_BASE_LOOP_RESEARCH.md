# Home Base ↔ Wasteland Gameplay Loop — Research & Design

Branch: `home-base-loop` (off `fable-5-gonna-fix-it-all`). Started 2026-07-08.

**Goal loop:** each player spawns in their own **home base** (a safe zone — a bunker now,
possibly a spaceship later) → triggers travel → an **intermission travel time** → arrives in
the **wasteland** → loots → returns home → **stores loot in the base** → spends loot to
**upgrade / expand / build** the base. Persist base progress across sessions.

**This document's scope:** research only — how to architect this on top of what already
exists, the key fork in the road, the data model, and the open design questions. No code
written yet.

---

## What already exists (and what it means for us)

| System | File | State / implication |
|--------|------|---------------------|
| **Persistence** | `Miscellaneous/DataSaveSystem.server.lua` | **One DataStore per stat**, keyed by UserId, storing a single number attribute. Persists only Caps + 5 ammo types (`Utility/PlayerStatsInfo.lua`). Has `BindToClose` (Tier 1 M15 partial). **No inventory/storage/build persistence, no session-locking, no serialization layer.** This is the biggest gap the loop must fill. |
| **Spawning** | `RandomSpawnPoints.server.lua`, `SpawnAndDeathSystem_Server/Main.server.lua` | **Single place.** Sets `RespawnLocation` (currently hard-forced to a `testMain` spawn). Safe zone = ZonePlus `workspace.Zones.ProtectedSpawnArea` applying a ForceField + anchoring via `SpawnAndDeathManager`. |
| **Teleport remote** | `SpawnAndDeathSystem_Server/Main.server.lua:30` | `MoveCharacterToSpawn` still `PivotTo`s to a **client-supplied CFrame** — this is unfixed exploit **C5**. The new transport system should own movement server-side and delete this. |
| **Tool identity** | `ItemSystem_Server/ToolCatalog.lua` | Tools are **catalog entries keyed by name** (`ToolObject`, `Tag`, `Type`, `Price`). This makes item serialization tractable: a stored item = `{tag = toolName, quantity = n, attributes = {…}}`, rehydrated by cloning the catalog model (the `ToolSpawner` already does exactly this server-side). |
| **Storage today** | runtime `LootStorage` folder, looting system | Loot is **runtime-only**; there is no persisted per-player storage. Bunker storage is net-new. |
| **Zones / ambience** | `workspace.Zones`, `AmbienceManager.client.lua` | ZonePlus-driven; the wasteland/base boundary can reuse this pattern for ambience + safe-zone rules. |
| **Teleport/multi-place** | — | **Nothing** in the repo uses `TeleportService`, reserved servers, or multiple places today. Adopting that model would be greenfield infra. |

**Takeaways:**
1. The **transport** and **base creation** are moderate; the **persistence rewrite** is the
   hard part and the critical path. The current per-stat-number DataStore design cannot hold
   storage contents + build state.
2. Item serialization is *feasible* because tools are name-keyed catalog clones.
3. We should fold the **C5 fix** into the transport system (server owns all base↔wasteland
   movement), and this is the concrete reason to finally do **M15's** full session-locking.

---

## The one big fork: where do bunkers live?

### Option A — Single place, instanced bunkers (recommended to start)
Clone a home-base template into a unique region (a grid cell offset) per player on join;
the wasteland is a shared area in the same place. "Travel" = a **server-side** move
(`PivotTo`) plus an intermission screen; the safe zone stays a ZonePlus zone.

- **Pros:** reuses everything that exists (spawn, zones, one server, one DataStore layer);
  one server authoritatively owns base + wasteland + inventory, so no cross-place data
  handoff; trivial to test in Studio; leaves the door open to co-op wasteland later.
- **Cons:** every active player's bunker is loaded in one place → memory/StreamingEnabled
  cost; builds must be constrained to the allocated region; the per-server player cap limits
  concurrent bunkers; a shared wasteland needs grief/PvP rules.

### Option B — Multi-place + reserved servers (TeleportService)
Base is its own place (or a per-player reserved-server instance); the wasteland is another.
Travel = a real cross-place teleport.

- **Pros:** true isolation and full server resources per base/wasteland; scales past one
  server's player cap; the teleport loading screen *is* the intermission; matches the
  "private base" fantasy cleanly.
- **Cons:** all greenfield — TeleportService, `ReserveServer` access codes, cross-place data
  handoff (carried inventory must ride teleport data **and** be persisted for crash safety),
  more failure modes, and much harder to iterate on in Studio. The repo has none of this.

### Recommendation
**Start with Option A**, but hide the boundary behind a **`TravelService` seam** so the rest
of the game only ever says *"take me to the wasteland / take me home"* and never knows whether
that's an in-map `PivotTo` or a `TeleportService` jump. If scale later forces Option B, only
`TravelService`'s internals change. This gives us the fast path now without painting us into a
corner.

### Decisions locked (2026-07-08)
- **Hosting = Option A (single place).** ✅ Multiplayer server: several players per server.
- **Bunkers = per-player, private, instanced regions.** Each player's base is its own region,
  allocated for their session and rebuilt from their profile on join.
- **Wasteland = one shared, persistent region.** All players on the server travel into the
  **same** wasteland — there is no per-player wasteland instance. `HomeBaseService` allocates
  base regions; the wasteland is a single fixed area.
- **Travel is independent per player.** Each player initiates their own trip (own intermission
  timer) and returns home on their own schedule; travel is asynchronous, the destination is the
  shared wasteland.
- **Combat is emergent.** The wasteland is **not** a safe zone — players who meet there choose
  to fight or team up. PvP and co-op are both allowed; don't hardcode friendly-fire-off or
  forced PvP. The base remains the safe zone (ForceField/zone rules).
- **Death = drop a lootable corpse (Tarkov-style).** ✅ Reuses the existing corpse/looting
  system. Because the wasteland is a single persistent region (not torn down per run), a dropped
  corpse simply stays in the wasteland to be recovered/looted on a later visit — **no
  per-player `pendingRecovery` persistence needed**, as long as the wasteland isn't reset out
  from under a corpse (see open question on wasteland reset).

### Kept flexible for the future
- **Visiting other players' bases.** Bases must be **addressable and visitable by non-owners**,
  so base access is a **permission check** (`TravelService` validates "may X enter Y's base?"),
  not a physical impossibility. Concretely: don't assume only the owner is ever present in a
  base region; the safe-zone/spawn/storage rules must be written in terms of "is this player
  allowed here / does this player own this storage," not "this region belongs to exactly one
  player." This costs almost nothing now and avoids a retrofit later.

---

## Two flexibility axes (design for both from day one)

1. **Base type** (bunker → spaceship → …): the system must not hardcode "bunker." Model a
   home base as a **`HomeBaseTemplate`** (a ServerStorage model) + a **config** describing its
   contract: spawn/entry CFrame offset, the storage anchor, upgrade/build node anchors, the
   safe-zone volume. Code references a base through this interface, so swapping the bunker
   model for a spaceship model is content + config, not a rewrite.
2. **Transport** (in-map ↔ cross-place): the `TravelService` seam above.

---

## Proposed architecture (Option A)

- **`HomeBaseService` (server)** — on `PlayerAdded`: load the player's profile, allocate a
  region, clone the configured `HomeBaseTemplate` into it, rehydrate stored items + build
  state from the profile, and set the player's spawn to the base entry point. On
  `PlayerRemoving`: snapshot → save → free the region.
- **`TravelService` (server)** — owns all base↔wasteland movement. A validated request
  (player is in their base, not already traveling) starts an intermission (freeze + UI), then
  server-moves the character to the wasteland arrival point; the return trip is symmetric.
  **Deletes C5.** Client only ever *requests* travel and shows the intermission UI.
- **`ProfileStore`/profile DataStore (server)** — replace the per-stat DataStores with **one
  session-locked profile per player** (`UpdateAsync` + lock, or the community `ProfileStore`
  module). Profile shape:
  ```
  {
    stats   = { Caps = n, LightBullets = n, ... },   -- migrate current attributes in
    storage = { {tag="Raider Axe", quantity=1, attributes={}}, ... },
    base    = { type="Bunker", upgrades={...}, builds={...} },
  }
  ```
- **Item (de)serialization** — pure module: `serialize(tool) -> {tag, quantity, attributes}`
  using the catalog name + a **per-type attribute whitelist** (e.g. Stackable → `Quantity`,
  Gun → ammo attributes); `deserialize(entry) -> Tool` via the existing catalog-clone path.
  Unit-testable with TestEZ like the other pure modules.
- **Base storage remotes** — deposit/withdraw between the player's inventory and base storage,
  routed through the existing `Receivers/Validation` ownership layer (same discipline as the
  Stackable/Looting receivers). Storage is server state; the UI is a view.
- **Player loop state** — `InBunker → TravelingOut → InWasteland → TravelingHome → InBunker`,
  server-owned, gating what actions are legal in each state.

---

## Open design questions (still to answer)

*(Resolved: single-place multiplayer; per-player private instanced bunkers; one shared
persistent wasteland; independent per-player travel; emergent PvP/co-op; lootable corpse on
death; base access designed as a permission check for future cross-base visiting — see
"Decisions locked" above.)*

1. **Wasteland reset policy** — does the shared wasteland persist unchanged for the whole
   server life, or does loot regenerate / the area reset periodically? Drives loot respawn and
   how long a dropped corpse survives.
2. **Loot contention** — in the shared wasteland, is a loot item first-come (one player grabs
   it, it's gone for others), or instanced per player? First-come is simpler and matches the
   PvP tension; confirm.
3. **Logout mid-run** — if a player quits while in the wasteland, do they just leave (carried
   loot goes with them / is saved), or drop a corpse like death? (Crash-safety + anti-loss.)
4. **PvP consequences** — is friendly fire simply on in the wasteland with no penalty, or are
   there consequences (karma, safe-logout rules)? Affects nothing structural now but shapes the
   combat receivers later.
5. **Concurrency** — expected players per server? Under Option A this caps concurrent loaded
   base regions and sets the allocation budget.
6. **Base uniqueness** — one persistent base per player globally, rebuilt from the profile on
   join (assumed). Confirm.
7. **Travel cost/gating** — is travel free, timed, resource-gated (fuel/caps)? Affects the
   `TravelService` request validation.

---

## Suggested build order (once questions are answered)

1. **Profile persistence rewrite** (the critical path; also closes M15) — one session-locked
   profile; migrate the existing Caps/ammo attributes into it behind the same attribute API so
   nothing downstream breaks.
2. **Item (de)serialization module** + TestEZ spec (pin round-trip: serialize→deserialize
   yields an equivalent tool).
3. **`HomeBaseService`** — template config, region allocation, per-join clone + rehydrate.
4. **`TravelService`** — server-authoritative transport + intermission; **delete C5**.
5. **Base storage** deposit/withdraw through the validation layer + storage UI view.
6. **Upgrades/build** on top of the persisted `base` table (last — largest design surface).

Each step gets a PLAYTEST_VERIFICATION entry per the project's verification policy.
