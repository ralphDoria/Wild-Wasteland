# Vitals Rewrite Plan (Tier 3, sanctioned rewrite)

Branch: `vitals-rewrite` (off `fable-5-gonna-fix-it-all` @ `adc0eb1`). Started 2026-07-06.

**Status (2026-07-07):** all four batches are code-complete and committed — V0 `0b0beba`,
V1 `9d3b3ea`, V2 `72c2c41`, V3 `9da834a`. Per the verification policy NONE are "done":
the spec suite has not yet run in-engine and every batch's playtest gate is OPEN
(PLAYTEST_VERIFICATION.md → Tier 3). Current per-batch state lives in CLAUDE.md.

This is the second of the two sanctioned rewrites in BUGFIX_STRATEGY.md ("Approach"): the
vitals subsystem is client-authoritative **and** incomplete (no food/drink restore path), so
it is rebuilt server-authoritative rather than retrofitted. Presentation code (heartbeat/
breathing SFX, saturation, GUI sync) is genuinely good game-feel work and is **kept** —
it becomes a pure view layer.

## Bugs this kills structurally

| Bug | How it dies |
|-----|-------------|
| C9 (client-authoritative hunger/thirst damage) | The `hungerThirstDamage` remote is deleted; the server simulates decay and applies starvation damage itself. |
| M13 (damage-thread metatable leaks/collisions) | No damage threads at all — one Heartbeat tick handles every player. |
| M12 (no restore path; dead `currentValue`) | Server state is the single source of truth with a `restore()` API; consumables call it. |
| M11 (hunger/thirst share one threshold event) | No shared module-level BindableEvent; each view instance tracks its own threshold section. |
| C16 (free instant respawn) | `RespawnPlayerCharacter` validates the sender is actually dead + rate limit. |
| C2 (arbitrary WalkSpeed remote) | Replaced by a validated movement-**intent** remote; the server sets WalkSpeed itself from Config (Batch V2). |
| M7 (staminaChanged fires new,new) / M10 (no clamp) | Stamina math moves into the pure, spec-tested `VitalsSim`; the client manager becomes prediction + view (Batch V2). |
| M8/M9 already fixed in Tier 1 | Preserved — presentation math keeps dividing by the stat max. |

## Architecture (echoes NPC System v2: central data, one scheduler, data-driven config, pure spec'd math)

- **`VitalsSystem_ScriptStorage/Data/VitalsConfig.lua`** (shared) — all numbers: max values,
  decay rates, starvation damage, thresholds, stamina drain/regen/cooldown/costs, tick
  interval. Version-controlled and shape-tested like `CombatStats`/`ConsumableStats`.
- **`VitalsSystem_ScriptStorage/Sim/VitalsSim.lua`** (shared, pure) — `decay`,
  `findThresholdSection` (generalized from HungerThirstManager), `staminaStep`,
  `applyStaminaCost`. No Roblox APIs → directly TestEZ-testable; shared verbatim by the
  server sim and the client prediction so they can't drift.
- **`VitalsSystem_Server/VitalsService.lua`** — plain-data registry `{[Player]: state}`,
  ONE Heartbeat accumulator ticking at `tickInterval` (1 s — these stats change slowly).
  Decays hunger/thirst, applies starvation damage directly to the humanoid, resets state on
  CharacterAdded, cleans up on PlayerRemoving. Public mutation API (`restore`) for
  consumables/buffs — the vitals twin of `NPCDamageAPI`.
- **Replication = player attributes.** `player:SetAttribute("Hunger"|"Thirst", value)` —
  free replication, join-in-progress state, `GetAttributeChangedSignal` for the client.
  No custom wire protocol, no remotes on the read path.
- **Client managers become views.** Same `.new()/.Destroy()` surface (VitalsManager
  untouched), but driven by attribute changes instead of local `task.wait` loops. All
  SFX/VFX logic kept; module-level cross-instance state fixed.

## Batches (each gated per the verification policy)

### V0 — shared config + pure sim + specs (no behavior change)
`VitalsConfig.lua`, `VitalsSim.lua`, `VitalsConfig.spec.lua`, `VitalsSim.spec.lua`.
Numbers preserve current behavior exactly: hunger 100 max / -1 per 4 s, thirst 100 max /
-1 per 3 s, both 1 dmg/s at zero; thresholds {0, .1, .25, .5, 1}; stamina 100 max,
drain 5/s, regen 10/s after 0.5 s cooldown, jump/swing cost 10.
**Gate:** spec suite green (in-engine via `test.project.json`).

### V1 — server-authoritative hunger/thirst + respawn gate
- `VitalsService` + rewritten `VitalsSystemReceivers.server.lua` (init service; respawn
  remote gated: sender must be dead, 1 s rate limit; `hungerThirstDamage` handler deleted).
- Client `HungerThirstManager` rewritten as attribute-driven view: GUI bar, threshold
  rumble sound (plays on *downward* crossings only, so future restores don't rumble),
  low-value color lerp — all kept, now per-instance.
- The Studio-side `hungerThirstDamage` RemoteEvent becomes inert (no listener); removal
  from the place is optional cleanup later.
**Gate:** PLAYTEST_VERIFICATION.md → Tier 3 Vitals V1 (decay visible, starvation kills,
restore-on-respawn, dead remote does nothing, respawn gate).

### V2 — stamina authority + movement intent (replaces `ChangeHumanoidWalkSpeed`)
- Server: stamina joins `VitalsService` state. New validated `MovementIntent` remote
  (mode ∈ {Default, Sprint, Crouch}); server sets the sender's own humanoid WalkSpeed from
  `Data/Config`, with Sprint gated on server stamina > 0. Drain only while mode == Sprint
  AND the server observes horizontal velocity (no drain while standing — matches today).
  Jump cost charged on `Humanoid.StateChanged` → Jumping; melee swing cost charged in the
  swing-replication receiver (already rate-limited by `swingCooldown`).
- Client: `StaminaManager` keeps its RenderStepped sim as **prediction** feeding the bar,
  breathing SFX, and ActionManager gating; reconciles to the replicated `Stamina`
  attribute (snap when divergence > tolerance). `Sprint`/`Crouch` fire intent instead of
  WalkSpeed. `MovementAndStaminaSystem_Server/Main.server.lua`'s trusting handler dies.
- Kills C2 for real (Tier 1 couldn't delete it — Sprint/Crouch legitimately used it).
**Gate:** sprint/crouch/jump feel unchanged; speedhack via old remote impossible; stamina
bar smooth; actions still gate at thresholds.

### V3 — restore path (the missing feature, M12)
- `ConsumableStats` entries gain `restores = {Hunger=n, Thirst=n, Health=n}`.
- `ConsumableReceiver.heal` (Batch 5, already validated) calls
  `VitalsService.restore(player, stats.restores)` — the consume/cooldown/ownership flow
  already exists; it just needs somewhere to write.
- Add first food/drink consumables when designed.
**Gate:** eating/drinking visibly refills the stats; spam still capped by `useCooldown`.

### Cleanup (with V2/V3 as they land)
Delete dead code: old client decay loops (gone in V1), `MovementAndStaminaSystem_Server`
handler (V2 — also removed the empty `SprintReceiver.lua` stub, L5), unused Studio remotes
noted for place cleanup. Update BUGS.md entries.

**Place cleanup (Studio-side, optional — do while connected for the playtests):**
these RemoteEvents now have no server listener and can be deleted from the place:
- `ReplicatedStorage.VitalsSystem_Storage.hungerThirstDamage` (inert since V1)
- `ReplicatedStorage.MovementAndStaminaSystem_Storage.Remotes.ChangeHumanoidWalkSpeed`
  (inert since V2)

No place additions are needed: the `MovementIntent` remote is created at runtime by
`MovementAndStaminaSystem_Server/Main.server.lua`.

## Deliberate decisions

- **Attributes over remotes** for replication: 4 slow numbers/player; attribute writes are
  cheap, reliable, and stateful for join-in-progress. If stamina at 1 Hz reconciliation
  ever feels coarse, only then consider a faster channel.
- **Intent-based movement** instead of hardening the WalkSpeed remote: the server should
  never accept a number for WalkSpeed; it accepts *what the player wants to do* and looks
  the number up itself.
- **Health stays on `Humanoid.Health`** — already server-owned; damage/heal already flow
  through validated receivers. Only its presentation is (later, optionally) tidied.
- **Per-life reset**: hunger/thirst reset to max on CharacterAdded, matching today's
  per-life client objects. Persistence across deaths would be a design change — not here.
- **Perf**: one server tick per second for all players replaces 2 task.wait loops +
  N damage threads per player; client loses per-frame zero-duration Tween creation
  (view sets properties directly) and one of three render-step bindings.
