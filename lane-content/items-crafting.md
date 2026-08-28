# Items & Crafting — Into the Wild

> Status: **brainstorm draft** (2026-07-06) — not balanced, not simulated.
> Cost budgets from `economy-engine.md` §4.1: Common 2–3 CE, Uncommon ~6, Rare ~18, Legendary ~54. Materials decide item tier.
> Both platforms unless flagged.

## 1. Item Categories

| Category | Role | Notes |
|---|---|---|
| Tools | Unlock verbs (chop, mine, fish, light) | Axe, pick, net, lantern |
| Gear / wearables | Passive slots | Boots (+move), cloak, backpack upgrades (+2/+4) |
| Weapons & wards | Creature fight vs. befriend aids | Ward = Light-flavored "weapon", repels instead of harms |
| Consumables | One-shot: food (energy), potions, incense | Budget = 1× tier value |
| Buildings / benches | Shared board pieces | Give-Back-Light play; ~18 CE |
| Spirit items | Offerings, relics, talismans | Only craftable with earned Spirit resources |
| Vessels / terrain keys | Raft, canoe, climbing kit | Items as T2 access keys (spec §4) |
| Dark kit | Snares, poisons, disguises | From Fork resources' dark side |
| Signal items | Flare, drum, beacon | Affect other players' options: invite, warn, lure |

## 2. Recipe Shapes

| Shape | Pattern | Purpose |
|---|---|---|
| Mono-element | All one color | Simple; teaches system (C/U items) |
| Pair-element | 2 elements, thematic logic | Fire+Water = glass; Wood+Ether = wand |
| Anchor + filler | 1 named Rare+ card + Commons | Follows "materials decide quality" rule |
| Choice slot | "Any Uncommon of element X" | Reduces deck-luck frustration (physical-friendly) |
| Fork-input | Same recipe, Light/Dark output by dual-resource use | Nightshade → healing draught OR poison vial |
| Spirit-gated | Materials + minimum Light level | Earned, not bought |
| Independent Tiering | Craft from scratch using higher-tier resources | Upgrade chains (Axe -> Copper Axe -> Ironwood Axe) do not exchange items |
| Group | Ingredients from ≥2 players | Crafting as kind act; feeds Care theme |
| Hidden recipes | Discover by experimenting | **Digital only**; physical prints all recipes on cards |

## 3. Catalog Files (full item lists per category)

| File | Contents |
|---|---|
| `items/tools.md` | 4 tool chains (axe/pick/fishing/light, 4 tiers each, from-scratch), standalone tools, vessels, signals |
| `items/gear.md` | Wearables, backpack line (+2/+4/+6) |
| `items/weapons-wards.md` | Fight route vs. protect route, mirrored |
| `items/consumables.md` | Food (energy) + potions, 1× tier budget |
| `items/buildings.md` | Shared builds incl. **Crafting Bench** (Legendary/up-conversion gate) |
| `items/spirit-items.md` | Light-track engine, ✦ spirit-gated Legendaries |
| `items/dark-kit.md` | Fork dark-side items; −1 Light on dark use, not craft |

Rules locked: **independent tiering** (no item exchange), items **permanent**, dark cost **on use**.

## 3b. Named Items & Concrete Recipes (seed examples)

| Item | Element | Tier | CE Cost | Recipe Ingredients | Effect |
|---|---|---|---|---|---|
| **Fishbone Needle** | Water | C | 2 CE | 1 Fish (C) + 1 Shell (C) | Repair / craft aid |
| **Stone Axe** | Fire | C | 3 CE | 2 Sticks (C) + 1 Stone (C) | Unlock chop: +1 Wood Common on gather |
| **Honeyglass Lens** | Sun+Fire | U | 6 CE | 1 Honey (U) + 1 Quartz (U) | Reveal adjacent face-down tile |
| **Sporelight Lantern** | Ether | U | 6 CE | 1 Glowcap (U) + 1 Hardwood (U) | Enter swamp T2 at full speed |
| **Bloodvine Snare** | Wood | R | 18 CE | 1 Bloodvine† (R) + 1 Resin (U) + 6 Commons | Fork: Heal-splint OR rob a player |
| **Stormcaller Drum** | Sky | R | 18 CE | 1 Bottled Wind† (R) + 1 Bamboo (U) + 6 Commons | Move a creature card to any tile |
| **Guardian's Cradle** | Spirit | L | 54 CE | 1 Pure Light† (L) + 2 Rares + 9 Commons | Revive/shield any player once (needs gifting) |
| **Voidcap Mask** | Ether | L | 54 CE | 1 Voidcap† (L) + 2 Rares + 9 Commons | Hide your Light level (flip track marker) |

## 4. Signature & Quest Items

- **Guardian offerings** — recipes that consume VP or Light as an ingredient; "give something back" made literal.
- **Character signature gear** — one recipe per character, only they can craft it, uses their affinity element.
- **The Balancer's Bane** — group recipe needing every player's contribution; only way to soften the Balancer.
- **Dark victory item** — Legendary craftable only at max Dark, needs stolen ingredients; makes Way 3 tangible.

## 5. Open Threads

- Fork-input and group recipes are the strongest expression of the Duality/Care core — develop first.
- TBD: recipe counts per tier, exact costs vs. budgets, tool-vs-skill overlap (does axe duplicate a gather skill?), how sacrifice chains sync with the 3-version item rule (spec §7b).
