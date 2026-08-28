---
name: into-the-wild
type: other
status: launched
created: 2026-06-22
graduated: 2026-06-22
paul_initialized: true
path: GameGrammarCLI
---

# Into the Wild

## Ideation Summary

A hexagonal tile-based board game about castaways on a living island. Engine-building, crafting, exploring, player interaction. Path of Duality system mechanically rewards kindness, punishes darkness. Three victory paths.

## Core Value

Exploration is fun, growth happens through self-care, winning and kindness coexist, projecting darkness returns darkness — all communicated through play, never words.

## Type

Board game design (physical first, digital later).

## Status

Graduated to PAUL. Foundation phase — game flow, engine, core systems.

## Key Design Pillars

1. **Subtlety** — themes land through mechanics, never stated
2. **Balance** — three viable victory paths, no dominant strategy
3. **Duality** — kindness is mechanically advantageous but not forced
4. **Depth** — 4-tier recursive system across all game elements

## Systems to Design

- [ ] Game flow and turn structure
- [ ] Resource/element system (tied to hex terrain)
- [ ] 4-tier progression (Common → Legendary)
- [ ] Path of Duality (Light/Dark track)
- [ ] Character asymmetry and balance
- [ ] Event/creature encounters
- [ ] Quest system (common + Guardian)
- [ ] Action economy (6 action types)
- [ ] Victory condition math (3 paths)
- [ ] Card designs (all decks)

## References

- `into-the-wild-spec.md` — full game spec
- `actions/actions-v1-draft.md` — action definitions
- `persona-translator.md` — AI co-design persona
- `GameGrammarCLI/` — generation tool (installed globally as `gamegrammar`)
