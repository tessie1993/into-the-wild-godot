# SEED State: into-the-wild

## Meta
- **Type:** board-game (deep rigor, application-depth)
- **Started:** 2026-06-22T01:12:00Z
- **Last Updated:** 2026-07-07T00:55:00Z
- **Position:** Section 14 of 19 — "Endgame Trigger"

## Gathered Data

### Project Name
into-the-wild

### Core Description
Hexagonal tile board game about castaways on a living island. Engine-building, crafting, exploring with Path of Duality. Themes communicated through mechanics, never stated.

### Sections Completed
| Section | Status | Summary |
|---------|--------|---------|
| Core Loop | complete | Exploration-driven engine loop. Turn: Care → Action → Duality → pass left. Two-phase game: main board + buildable 4D Board. |
| Element/Terrain System | complete | 5 base elements (architecture root for resources/skills/creatures/magic/items): Wood/Earth/Jungle/green, Grain/Sun/Meadow/gold, Stone-Fire/Mountain-Volcano/red, Water-Air/Sky/Lake-Beach/blue, Ether/Moon/Swamp/purple. |
| Resource Economy | complete | 6th element Spirit added (white/prismatic, earned not gathered). Common=staple off-deck; uncommon→legendary=deck cards. Dual-nature resources (fork + aligned) tie to Path of Duality. Special/unique tiles defined. Full lists in resources.md. Balanced engine (faucets/sinks, 2 ring decks, sim-verified) in economy-engine.md. |
| 4-Tier Progression | partial | 3× value per tier (C=1/U=3/R=9/L=27 CE); materials decide item quality. Math in economy-engine.md. |
| Path of Duality | complete | Single track from -10 to +10. Shifts happen instantly upon Duality-aspect actions/choices. Bands define world/creature reactions. |
| Action Economy | complete | Choose 1 of 6 actions per turn. Detailed in actions-v1-draft.md. |
| Turn Flow | complete | Simplified 2-phase turn: Care (bonus only) and Action. Duality is integrated immediately. |
| Character System | complete | 4 castaways defined in separate characters/ folders, with unique skills (no values), perks, signature items, and skill tree drafts. |
| Creature/Event System | pending | — |
| Victory Math | partial | Collective-viability gate: once 4D Board built, no solo win unless every active player still has a viable path to win. Spec §11. |
| Guardians | pending | — |
| Quests and Challenges | pending | — |
| Items (crafting, items, potions) | pending | — |
| Consumables | pending | — |
| Buildings | pending | — |
| Helping Players Dynamic | pending | — |
| Energy System | complete | Care phase bonus-only. Energy = boost meter (cap 5, start 2), filled by food/potions, spent to amplify actions. No upkeep/starvation. |
| Ascended Board | complete | 3-ring board. 2x rewards (fairly distributed)/penalties. Dark path excluded. Targeted player setbacks amplified. Special side challenge & Event Deck. Scaled Balancer checks positive paths. |
| Endgame Trigger | complete | Master Guardian absolute challenge triggers final round victory loop. Standard victory triggers final round early to prevent infinite loops. |

### Raw Responses
Core Loop: Exploration drives "one more turn" — unknown tiles, events, better gear/skills, giving-back perks. Turn loop: Care (eat/sleep/meditate) → Action (1 of 6) → Duality shifts → pass left. 4D Board option opens when majority reach center. High-risk 3-ring board: double rewards (equal distribution) and double penalties. Dark path excluded. Targeted active players take amplified setbacks. Master Guardian absolute challenge triggers final round. Standard victory triggers final round early to prevent infinite loops.
Victory Math: 4D collective-viability gate — after the 4D Board is built, a player can only win if every active player still has a viable path to victory (nobody locked out). Reinforces "you win only if anybody can win."
Element/Terrain System: 5 elements are the architecture base — all resources, skills, creatures, magic, items derive from them. 1 Wood/Earth/Jungle/green, 2 Grain-Grass/Sun/Meadow/gold, 3 Stone-Fire/Fire/Mountain-Volcano/red, 4 Water-Air/Sky/Lake-Beach/blue, 5 Ether/Moon/Swamp/purple. Each terrain tile = one element, governing its resources/creatures/magic/items.
Resource Economy: Added 6th element Spirit (white/prismatic, soul/duality, special tiles, earned not gathered). Resource model: common = fixed staple (off-deck), uncommon→rare→legendary = Resource deck cards (many options). Dual-nature resources: (A) fork — Light vs Dark use chosen at use, dark stronger but Light penalty; (B) aligned — good for one path, penalty in wrong hands (Pure Light, Voidcap, Soul Ember, Phoenix Ember). Special/unique tiles brainstormed (shipwreck, ruins, shrine, sacred grove, crystal cave, moonwell, caldera, guardian gate, blighted ground, etc.). Full tables → resources.md.
