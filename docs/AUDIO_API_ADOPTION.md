# Adopting Roblox's New Audio API

Research report requested 2026-07-08. How the game plays sound today, what the new Audio
API offers, the migration facts specific to this codebase, and a recommended adoption path.

**Recommendation: worth adopting, but it is a Tier-3-sized, place-heavy workstream.**
Sequence it *after* the vitals playtest gates close, on its own branch, migrated bus-by-bus
with a playtest per batch. Do **not** fold it into the bugfix workstream.

---

## How the game plays sound today (all legacy `Sound`)

- **Bus tree** in `SoundService`: `0 - Master` → `Music` / `Game` (→ `Ambience`) /
  `Interface` / `Menu`, all legacy `SoundGroup`s. `Utility/Sound/SoundGroupManager.lua`
  caches their default volumes and tweens bus volume for mute/duck/restore (used by the
  settings menu and the loading→menu handoff).
- **Main playback path:** `Utility/PlaySoundUtil.lua` — clone the Sound → optional
  `PitchShiftSoundEffect` randomization → parent to a BasePart/GUI (or spawn a throwaway
  anchored Part at a `Vector3` for positional 2D-in-3D) or `SoundService:PlayLocalSound`
  for 2D → `Debris:AddItem(clone, TimeLength)`. Required by **~40 files**, client and
  server (doors, footsteps, pickups, tool drops, the `PlaySound` remote, menus, death
  screen, etc.).
- **Effect tweening:** `Utility/SoundUtil.lua` and
  `VitalsSystem_ScriptStorage/SharedComponents/SoundUtility.lua` tween
  `PitchShiftSoundEffect` (pitch up/down, track-switch warble) and `EqualizerSoundEffect`
  (muffle) — used heavily by the menu and vitals SFX.
- **Time-synced SFX:** breathing (`StaminaManager`) and heartbeat (`Health/.../health_sfx`)
  read `Sound.TimePosition` / `Sound.TimeLength` to drive GUI pulses and markers. (This is
  the subsystem the 2026-07-08 breathing-pulse bug lived in.)
- **All Sound instances live in the Studio place**, not the repo — inside tool models,
  ScreenGuis, and under SoundService. The repo only references them by name/path.

## Where the API is (as of mid-2026)

Out of Studio beta since **September 2024** and actively expanded since: `AudioFilter`,
`AudioLimiter`, directional / angle attenuation, occlusion + diffraction, environment-based
reverb, `AudioAnalyzer` spectrum, `AudioPlayer.Volume`. Model is a wiring graph:

```
AudioPlayer → Wire → [effect nodes] → AudioEmitter (3D)  ─┐
                                     → (direct)           ─┴→ AudioListener → AudioDeviceOutput
```

`AudioPlayer` is the `Sound` analogue; a `Wire` connects nodes; `AudioEmitter` places audio
in 3D; `AudioListener` (on the camera) + `AudioDeviceOutput` is what makes it audible.
Legacy `Sound` is **not deprecated** — both systems coexist indefinitely.

## Migration facts specific to this codebase

1. **`SoundGroup`s do not work with the new API.** The entire bus tree must be rebuilt as
   an `AudioFader` chain. This is a clean 1:1 remap: `SoundGroupManager` becomes a
   fader-graph manager, and the settings menu tweens `AudioFader.Volume` instead of
   `SoundGroup.Volume`. This is the single biggest structural change.
2. **Every legacy effect has a direct replacement:** `PitchShiftSoundEffect` →
   `AudioPitchShifter`, `EqualizerSoundEffect` → `AudioEqualizer` / `AudioFilter`. So
   `SoundUtil` / `SoundUtility` port node-for-node.
3. **`TimePosition` / `TimeLength` exist on `AudioPlayer`** → the breathing / heartbeat GUI
   sync ports unchanged.
4. **Most of the work is in the place, not the repo.** Each Sound in a tool model / GUI
   needs an AudioPlayer+Wire+Emitter graph built around it in Studio. The good news: the
   repo already centralizes playback behind `PlaySoundUtil` / `SoundUtil` /
   `SoundGroupManager`, so swapping *their internals* migrates most of the ~40 call sites
   for free. The positional anchored-Part hack in `PlaySoundUtil` becomes an
   `AudioEmitter`.

## Recommended adoption path (incremental, by bus)

1. **Stand up the graph:** `AudioListener` on the camera, an `AudioDeviceOutput`, and an
   `AudioFader` tree mirroring today's SoundGroup hierarchy.
2. **Swap the utility internals:** extend `PlaySoundUtil` / `SoundUtil` to drive AudioPlayer
   graphs behind their current signatures, so call sites don't change.
3. **Migrate in order of increasing surface:**
   - **2D UI / menu sounds first** (simplest — direct to output, no emitters).
   - **Music + ambience next** (gains environment reverb).
   - **3D world audio last** (tools, footsteps, doors, pickups — biggest payoff from
     occlusion + directionality, and the largest instance count in the place).
4. **Do the deferred C14 work in the same stroke:** the sound-whitelist / rate-limit
   redesign (BUGFIX_STRATEGY design Q8 — `PlaySound` remote currently only type-guarded)
   fits a name-keyed server-side play path, which the new graph model supports naturally.

## Why adopt (and why not now)

**Wins that fit a survival game:** occlusion/diffraction and directional audio, environment
reverb, real mixing buses with limiters, and no clone-per-play churn (the current
`PlaySoundUtil` clones + Debris-collects every one-shot). **Cost:** place-heavy, touches
audio everywhere, and audio bugs are feel-bugs that need human playtesting. That combination
makes it a standalone Tier-3 effort, not something to interleave with the remote-hardening /
vitals work in flight.

Sources:
- https://devforum.roblox.com/t/roblox-audio-api-exits-beta-enhanced-sound-controls-now-available/3153454
- https://devforum.roblox.com/t/new-audio-api-features-directional-audio-audiolimiter-and-more/3282100
- https://devforum.roblox.com/t/a-simple-guide-to-the-audio-api/3132049
- https://create.roblox.com/docs/reference/engine/classes/AudioPlayer
