# Top-Level UI Assessment (loading / title / death screens)

Research report requested 2026-07-08. Scope: the **session-flow UI only** — the loading
screen, the main-menu/title screen, and the death screen. *Not* the inventory, hotbar,
looting, shop, HUD, or any other in-game UI.

**Verdict: no rewrite, and no efficiency-driven refactor is warranted.** There is a small
amount of developer-time debt (one real bug, some duplication, dead scaffolding) worth a
targeted Tier-1-style cleanup someday, but nothing here justifies restructuring.

---

## What it is

~760 lines of one-shot flow code:

| File | Lines | Role |
|------|-------|------|
| `ReplicatedFirst/LoadingScreenScripts/ExecuteLoadingScreen.client.lua` | 3 | entry — requires + inits the manager |
| `ReplicatedFirst/LoadingScreenScripts/LoadingScreenManager.lua` | 145 | preload spinner, random messages, timer, fade-out |
| `ReplicatedFirst/LoadingScreenScripts/Components/` | ~50 | `LoadingScreenMessages`, `TextManager` |
| `StarterPlayerScripts/PlayerFlow/Main_PlayerFlow.client.lua` | 50 | orchestrates loading → nuke scene → title screen → gameplay |
| `.../PlayerFlow/Components/MainMenu/MainMenuManager.lua` | 225 | title-screen state, nuke cutscene, button wiring, music |
| `.../MainMenu/Components/` | ~230 | `ButtonsPanelManager`, `RightPanelManager`, `References_MainMenu` |
| `StarterCharacterScripts/InitDeathScreen.client.lua` | 183 | death fade, respawn/title buttons |

All of it runs **once per session** (the death screen once per life). Nothing runs
per-frame during gameplay, so **runtime efficiency is a non-issue** — the premise that an
efficiency refactor could help doesn't apply. The GUIs themselves live in the Studio place
(`MainMenu`, `DeathScreen`, `LoadingScreen` ScreenGuis); these scripts only drive them.

---

## Findings

### 1. Real bug — death-screen connection leak (worth a BUGS.md entry)

`InitDeathScreen.client.lua` runs in **StarterCharacterScripts** (re-executes every life),
but the `DeathScreen` ScreenGui is `ResetOnSpawn = false` (persists across lives). Every
life's `humanoid.Died:Once` handler calls `ButtonsManager.connectButtonEvents(...)`, which
appends new `MouseEnter`/`MouseLeave`/`MouseButton1Click` connections into the module-level
`buttonConnections` table **without ever disconnecting the previous life's connections**.

After N deaths the respawn/title buttons carry N stacked click handlers. Consequences:
- The italic/normal `FontFace.Style` toggle (used as the click state) flips N times per
  click, so the `clickCallbackTbl[buttonName](toggle)` boolean becomes unreliable.
- N `RespawnPlayerCharacter:FireServer()` calls per respawn click — currently masked by the
  server's V1 1/s respawn rate limit, but it's firing redundantly.

Fix shape: disconnect + clear `buttonConnections` at the top of `connectButtonEvents` (or
move the wiring out of the per-life `Died` handler). Low severity because the rate limit
hides the user-visible symptom, but it's a genuine leak.

### 2. Duplication — two near-identical button panels

The death screen's `ButtonsManager` (hover-grow, click font-toggle, staggered reveal
tweens, plus a local `Map` helper) is a copy-paste of the main menu's
`ButtonsPanelManager`. A single shared "staggered button panel" component would serve both
and is where the `Map` helper should live once.

### 3. The loading screen is theatrical, not functional

`LoadingScreenManager` preloads exactly **2 assets** (its own `RadiationSymbol` image +
`Sound`), `task.wait(5)` unconditionally, then shows a "percentage" computed over those 2
assets. It is a timed splash, not a real load gate. If genuine load coverage is ever
wanted, feed `ContentProvider:PreloadAsync` a meaningful asset list — but that's a content
decision, not a code problem.

### 4. Dead / half-finished scaffolding

- Empty functions: `MainMenuManager.setState`, `openGameMenuVersion`, `closeGameMenu`.
- Empty Promise `onCancel` cleanup bodies in `playNukeScene` / `openTitleScreenVersion`.
- `playNukeScene` resolves its Promise *before* the 5s fade-to-black tween completes (the
  caller `:await()`s a resolve that doesn't correspond to the visual finishing).
- Death screen's `titleScreen` button is a `print("not ready yet")` stub.
- Debug `print`s on every menu button click (`ButtonsPanelManager`, `MainMenuManager`).
- Commented-out cutscene / reset-button / safe-area-inset blocks left inline.

---

## Recommendation

1. File the **death-screen connection leak** (finding 1) into BUGS.md — it's the only
   correctness issue.
2. Treat findings 2–4 as an optional, low-priority cleanup batch (dedupe the button panel,
   delete dead functions and debug prints) in the Tier-1 mechanical style. No architecture
   changes, no rewrite.
3. Leave the loading screen as-is unless real preload coverage becomes a goal.

Efficiency was the stated motivation for the question; there is no efficiency win to be had
here because none of this code is hot. The value in touching it is code hygiene, not speed.
