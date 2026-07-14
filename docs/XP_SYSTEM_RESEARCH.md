# Level & XP System — Research + Design

Written 2026-07-13, before scaffolding. Goal: a **persistent, server-authoritative level/XP
stat** saved across sessions; XP granted on NPC kills and player kills **now**, with an
expandable award surface so ANY future action (quests, crafting, discovery, survival time…)
can grant XP by adding one config entry + one server-side call.

---

## 1. How games do this in general

**One authority, one entry point.** Mature progression systems funnel every XP grant through
a single service call (`award(player, source)`), never scattering `xp += n` across gameplay
code. This gives one place for logging/anti-cheat/multipliers, and makes "add a new XP
source" a data change, not a code change. (This is the same "single mutation surface"
argument as our `VitalsService.restore`.)

**Store total XP; derive level.** Persisting both `xp` and `level` invites drift (double
level-ups, missed ones after curve retunes). The durable stat is **cumulative XP**; level is
a pure function of it. Retuning the curve then retroactively re-levels everyone consistently
on next load.

**Curves.** The three classic families:
- *Linear* (`xpToNext = base + k·level`) — flat grind feel, fine for shallow caps.
- *Polynomial* (`total = base·level^e`, e≈1.5–3; D&D/RuneScape-adjacent) — steady stretch.
- *Exponential per-level* (`xpToNext = base·g^(level−1)`, g≈1.05–1.2) — early levels fast
  (hook), later levels slow (retention). Most survival/looter games use this family.

Chosen: **exponential per-level requirement** with a hard `maxLevel`, all in config — the
family is a tuning knob, not an architecture decision, because level derivation is a pure
function we can swap.

**Kill attribution.** Two standard models: *killing blow* (credit the damager whose hit
dropped HP to 0 — simple, exploit-resistant) and *damage share* (split by contribution —
fairer in groups, needs a per-victim damage ledger). Starting with **killing blow**; the
service keeps a per-victim "credited" guard so exactly one award fires per death. A damage
ledger can be added inside the same service later without touching call sites.

## 2. Roblox specifics

- **Server-authoritative or it's worthless.** XP must only ever be granted by server code
  observing server events. No RemoteEvent may carry an XP amount or an "I did X" claim —
  this game's entire Tier 2 effort exists because remotes trusted clients. The XP service
  therefore exposes **no remotes at all**; its API is server-module-to-server-module.
- **Replication via player attributes** (`XP`, `Level`) — same pattern as the vitals rewrite:
  free join-in-progress state, client UI just listens to `GetAttributeChangedSignal`.
  (Classic alternatives: `leaderstats` folder — only needed for the built-in player list,
  which this game's custom UI doesn't use; IntValue objects — legacy.)
- **Persistence:** the community-standard answer in 2026 is a session-locked profile module
  (ProfileStore) holding ONE document per player, especially since Roblox moved DataStore
  limits to per-experience budgets (shared across all servers). We *had* ProfileStore and
  scrapped it with the home-base loop. Decision: **do not re-adopt it for one stat.** XP
  rides the existing `DataSaveSystem` (attribute + per-stat DataStore, BindToClose flush,
  registered in `PlayerStatsInfo`) exactly like Caps. When a profile consolidation happens
  later (Tier 3 item 6 — DataStore hardening), XP migrates with all other stats; the
  scrapped `PlayerProfileService` (git history before `3bedb0e`) already contains the
  legacy-attribute migration code to crib from.
- **Attribution mechanics:** the classic Roblox pattern is a `creator` ObjectValue tag on
  the victim's humanoid + `Humanoid.Died`. We can do better: **both** damage paths in this
  game are already server-validated handlers with the attacking `Player` in scope
  (`MeleeReceiver.Hit`, `GunReceiver` post-`validateTag`), so attribution is a direct call
  after `TakeDamage` — no tag instances, no Died-listener races. `GunReceiver` even has a
  dormant `--TODO: implement kill banner & xp bar` at exactly that spot.

## 3. Integration map (this repo)

| Concern | Decision |
|---|---|
| Config (curve + award values) | `ReplicatedStorage/XPSystem_ScriptStorage/Data/XPConfig.lua` — shared so client UI can render the curve |
| Pure math | `XPSystem_ScriptStorage/Sim/XPCurve.lua` — level/progress from total XP; TestEZ-covered |
| Authority | `ServerScriptService/XPSystem_Server/XPService.lua` — `award()`, `notifyDamageDealt()`, attributes, level-up signal |
| Bootstrap | `XPSystem_Server/Main.server.lua` |
| Persistence | `PlayerStatsInfo.ATTRIBUTE_XP` + `getPersisted()` (DataSaveSystem re-pointed to it; `getAll()` keeps its pickup-wiring meaning for CapsAndAmmoPickUp) |
| Kill hooks | one line after each `TakeDamage` in `MeleeReceiver` + `GunReceiver` |
| Tests | `tests/specs/XPCurve.spec.lua`, `tests/specs/XPConfig.spec.lua` |

**The expandability contract:** a future action grants XP by (1) adding a key to
`XPConfig.awards`, (2) calling `XPService.award(player, "TheKey")` from the server code that
validated the action. Nothing else. `award` is also where per-source rate limits, streak
multipliers, or diminishing returns would slot in later.

**Deliberately deferred:** client XP-bar/level-up UI (attributes are already listenable);
damage-share attribution; assist XP; XP loss on death; per-source rate limits; ProfileStore
consolidation; kill banner (the GunReceiver TODO's other half).

**Known seams:**
- An award before `StatsLoaded` is dropped with a warning (the load would overwrite it
  anyway — same race as M14's caps pickups). Acceptable for a scaffold; a pending-award
  queue is the fix if it ever matters.
- NPC deaths not caused by a player (starvation, falls, other NPCs) award nothing — correct.
- `maxLevel` caps the level, not XP accrual: total XP keeps counting past the cap so a
  later cap raise retro-levels correctly.

Sources: [Roblox DataStore best practices](https://create.roblox.com/docs/cloud-services/data-stores/best-practices),
[ProfileStore save-system guide](https://kitsblox.com/blog/roblox-save-system-profilestore),
[2026 per-experience DataStore limits](https://gmmarket.me/community/post/roblox-datastore-in-2026-the-new-per-experience-limit-explained-migration-plan),
[modular XP/level/rank system (DevForum)](https://devforum.roblox.com/t/advanced-modular-xp-level-rank-system-with-data-saving/4193600),
[leveling-system design thread (DevForum)](https://devforum.roblox.com/t/how-would-i-go-about-creating-a-leveling-system/4017586).
