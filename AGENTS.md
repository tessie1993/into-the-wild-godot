# AGENTS.md — read this before touching code

Instructions for AI coding agents (Claude Code, Codex, etc.) working on this
repo, typically orchestrated in parallel via Orca. Humans welcome too.

## What this is

*Into the Wild* — a Godot 4 crafting/exploring RPG board game for Android.
**`GDD.md` is the design authority.** Rules marked **[SPEC]** are the
designer's decisions: never change their intent without asking. **[TUNE]**
values are placeholders: adjust freely, but keep them in `data/config.json`,
never hardcoded.

## Ground rules

1. **GDScript, statically typed.** `var x := 3`, typed params and returns.
   No C#. Format with 4-width tabs (Godot default), `snake_case` files.
2. **Data-driven first.** Game content (elements, characters, creatures,
   quests, recipes, balance numbers) lives in `data/*.json`. If a change can
   be data-only, make it data-only.
3. **Rules in systems, not scenes.** `Game` (autoload) + `scripts/systems/`
   own the rules; `scripts/game/game.gd` and `scripts/ui/` are views. UI is
   built in code — do not add complexity to `.tscn` files.
4. **Signals over lookups.** Cross-cutting notifications go through
   `EventBus` (autoload). Don't add node-path spaghetti.
5. **Skill/weakness hooks** are marked with `# SKILL —` / `# WEAKNESS —`
   comments at their call sites. When adding a character, follow that
   pattern; when the count grows past ~6, refactor to a data-driven ability
   system.
6. **Every PR/commit**: run the game (F5), play one full turn of each action,
   and note it in the commit message. If you cannot run Godot, say so
   explicitly in the commit body.
7. **Don't invent Google Play policy answers** (data safety, ratings). Flag
   for the human.

## Layout

```
game/            the Godot 4 project — everything the app ships
  data/          all content + balance (JSON)
  scenes/        thin .tscn shells (root node + script only)
  scripts/
    autoload/    event_bus.gd, game_state.gd   ← global state + turn engine
    core/        hex.gd, island_tile.gd, player_state.gd, board.gd
    systems/     decks.gd, karma.gd, crafting.gd, quest_engine.gd, …
    game/        game.gd (play scene: board render, action UI, encounters)
    ui/          main_menu.gd, character_select.gd
  tests/         smoke.gd — headless boot + one turn of each action
docs/design-lane/  design corpus (physical + digital); generated/ holds the
                   raw content drops — the converter (below) integrates them
tools/drop-converter/   convert.py maps generated/ drops into game/data/
                   (creatures_wild, items_catalog, wild_deck,
                   quests_bottleneck). Edit drops or mappings there and
                   re-run it; never hand-edit its outputs in game/data/.
tools/engine-analyzer/  Vite/React economy inspector for the design lane
```

## How to run / test

- Editor: open `game/project.godot` in Godot **4.4+**, F5.
- Headless smoke test (what CI runs — as a scene so autoloads are live):
  `godot --headless --path game res://tests/smoke.tscn`
- CI: `.github/workflows/android-debug.yml` imports the project, runs the
  smoke test, and exports a signed Android **debug APK** artifact on every
  push and pull request (non-gradle export; gradle only becomes necessary
  for the Play Billing plugin at ship time).
- Android export (later phases): Gradle build **must** stay enabled — the
  Play Billing plugin requires it. Target SDK **36**.

## Orca lane suggestions

Run parallel worktrees that don't touch the same files:

- **Lane A — systems:** quest engine, trading, base building
  (`scripts/systems/`, `data/quests.json`)
- **Lane B — UX:** character-select screen, tile info panel, animations,
  juice (`scripts/ui/`, `scripts/game/game.gd`)
- **Lane C — content:** more creatures/events/recipes/characters
  (`data/` only — zero code risk)

## Roadmap (ordered)

1. **Action-card engine** — implement GDD §8.7 (the v2 design): five leveled
   action cards per player (Explore, Building/Crafting, Creatures,
   Learning/Magic, Guardian), options gated by card level per
   `data/actions.json`, per-class asymmetry with a neutral baseline, free
   actions (Selfcare; Trading after lvl 3), Guardian worker-placement slots.
   The v0.1 flat actions in `game.gd` are the placeholder this replaces.
   Blocked on design answers to GDD §12 Q6–Q10 — ask, don't guess.
2. **Quest engine** — track common-quest progress automatically; guardian
   quests granted at Offer; `revoke_vp` enforcement (GDD 8.5–8.6); redraw
   vote UI (majority; non-owner decides — GDD 8.5).
2. **Character select** screen (currently auto-assigned in JSON order).
3. **Trading** between players on the same/adjacent tile (GDD 6.4).
4. **Creature micro-challenges** — replace the coin-flip in
   `game.gd/_creature_challenge` with per-creature choices (GDD 5.3).
5. **Base building** action + base upgrades (GDD 8.7; design Q2 open).
6. **Skill learning/leveling** with the 4 rarity classes (GDD 6.3) and
   item/skill versioning (GDD 6.2).
7. **Dark-path raiding** action + counterplay (design Q3 open).
8. **Tiebreakers** for simultaneous finishes (GDD 10.3) once round-end
   simultaneity exists.
9. **Juice pass**: tweens, particles, SFX, screen shake; tile-flip animation.
10. **Android polish**: pinch zoom, safe areas, back button, haptics.
11. **Ship prep** (see the Prompt-to-Play-Store guide): icon/splash, signed
    AAB (target SDK 36), Play Console closed testing, then the official
    `godot-google-play-billing` plugin for the one unlock IAP.

## Things that look like bugs but are rules

- Switching your chosen action before luck resolves costs 1 Light (GDD 9.3).
- Flipping a face-down tile ends your movement immediately (GDD 8.2).
- The Sanctum refusing entry is the Light gate (GDD 4.3).
- The Wayfarer being unable to repeat an action is their weakness (GDD 7).
- A free app can never become paid on Google Play — pricing model is
  free + one unlock IAP, decided up front.
