# Into the Wild (working title)

A crafting/exploring RPG board game for Android, built with Godot 4.
You are stranded on an unexplored island full of magic, creatures and wonder.
The Guardians will not let you become a colonizer — you win by integrating
into the island's harmony. Kindness is a strategy, not a decoration.

**Playable prototype** — local pass-and-play, 1–4 players, placeholder art.

## Run it

1. Install [Godot 4.4 or newer](https://godotengine.org/download) (standard build).
2. Open Godot → Import → select this folder's `project.godot`.
3. Press **F5**. Menu → set player count → *Wash Ashore*.

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

## Read next

- `GDD.md` — the full game design, distilled from the designer's spec
- `AGENTS.md` — conventions + roadmap for AI coding agents (Orca / Claude Code)

## Workflow

This repo is built for agent-driven development: open it in Orca, point your
agents at `AGENTS.md`, and run parallel lanes (gameplay / UI / content).
All game content is data-driven in `data/*.json` — most design changes need
no code at all.
