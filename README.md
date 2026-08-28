# Into the Wild (working title)

A crafting/exploring RPG board game for Android, built with Godot 4.
You are stranded on an unexplored island full of magic, creatures and wonder.
The Guardians will not let you become a colonizer — you win by integrating
into the island's harmony. Kindness is a strategy, not a decoration.

**Playable prototype** — local pass-and-play, 1–4 players, placeholder art.

## Repository map

```
game/               the Godot 4 project (open this in Godot)
  data/             all game content + balance (JSON) — data-driven
  scenes/           thin .tscn shells (root node + script only)
  scripts/          GDScript: autoload/ core/ systems/ game/ ui/
  tests/            headless smoke test
GDD.md              the digital game design authority (v0.2 canon synthesis)
AGENTS.md           conventions + roadmap for AI coding agents
docs/
  art-direction.md  approved art style + asset list
  design-lane/      the physical/board-game design corpus: spec, economy
                    engine, item/creature catalogs, proposals, reviews,
                    and generated/ content drops not yet wired into game/
tools/
  engine-analyzer/  Vite + React app for inspecting the design-lane economy
.github/workflows/  CI: headless smoke test + Android debug APK
```

## Run it

1. Install [Godot 4.4 or newer](https://godotengine.org/download) (standard build).
2. Open Godot → Import → select `game/project.godot`.
3. Press **F5**. Menu → set player count → *Wash Ashore*.

Headless smoke test (same check CI runs):

```sh
godot --headless --path game res://tests/smoke.tscn
```

## Android debug APK

Every push and pull request builds a debug APK via GitHub Actions
(`.github/workflows/android-debug.yml`). Grab it from the workflow run's
**artifacts**. To build locally: install the Android export templates for
your Godot version, then

```sh
godot --headless --path game --export-debug "Android Debug" build/into-the-wild-debug.apk
```

## What works in v0.1

- Procedural hex island: Tier 1 outer terrain, harsher Tier 2 inner rings,
  the light-gated Sanctum at the center, Guardian sites scattered in Tier 2
- Turn engine: one action per turn (Explore / Gather / Craft / Give / Offer),
  switching a chosen action costs 1 Light, luck locks your action in
- Exploration: face-down tiles flip on entry → resource draw + event/creature draw
- The Light track: your karma band = Light relative to your VP; creatures
  react by band (gift / reward / challenge / take / attack)
- Crafting with 4 rarity tiers; Give (+Light); Offerings at Guardian sites (+VP)
- 4 unique characters, each with a unique skill and a unique weakness
- Two victory paths (Light and full Dark), autosave, pass-and-play
- Character select, quest engine, trading, action cards, creature challenges,
  dark raiding, skill tree, base building (Phases 1–3)

## Read next

- `GDD.md` — the full digital game design, distilled from the designer's spec
- `AGENTS.md` — conventions + roadmap for AI coding agents
- `docs/design-lane/` — the wider design corpus both builds draw from
