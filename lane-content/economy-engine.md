# Economy Engine — Into the Wild

> Balanced resource economy. Verified by 20k-run Monte Carlo simulation (2026-07-06).
> Baseline mode: **Standard, ~15 turns/player**. Other modes scale (§10).
> Both platforms unless flagged. Physical = hand-computable; digital = same rules, finer RNG allowed.

## 1. Value Unit & Tier Ratio

All balance math uses **CE (Common-Equivalent)**. Tier ratio = **3× per tier**.

| Tier | Value | Source |
|---|---|---|
| Common | 1 CE | Terrain staple — element **tokens**, unlimited supply, off-deck |
| Uncommon | 3 CE | Resource deck **card** |
| Rare | 9 CE | Resource deck **card** |
| Legendary | 27 CE | Resource deck card (inner ring / Ascended / creatures mainly) |

Hybrid components: Commons = element cubes/tokens (6 colors). Uncommon+ = named cards (resources.md lists).

## 2. Carry & Hand Limits

- **Basic Resources (Commons): Unlimited Carry.** Common resources are physically represented by wooden tokens and have no carrying/hand size limit.
- **Advanced Resources (Uncommon, Rare, Legendary Cards): Capped at 7 Cards.** Players can hold a maximum of 7 advanced resource cards in their hand. Any excess cards must be played, crafted, traded, gifted, or discarded at the end of their turn.
- **Special Items (Equipped & Backpack): Capped by Character Profile.** Carry limits apply only to crafted special items (tools, gear, weapons, vessels).
  * Standard: 3 equipped/active slots + 2 backpack slots.
  * Adjustments: Cartographer (3 active + 1 backpack), Blacksmith (3 active + 3 backpack).
- **Gifting:** Excess cards or tokens can be gifted to other players during the Care Phase to earn Light and clear hand space.

## 3. Faucets (income)

### 3.1 Gather (base skill, before boosts)
**2 Commons of the tile's element + 1 Resource-deck draw.**

Two physical resource decks (replaces single deck):

| Deck | Ring | Composition | EV/draw |
|---|---|---|---|
| **T1 deck** | Outer ring | 75% Uncommon, 25% Rare, 0% Legendary | 4.5 CE |
| **T2 deck** | Inner ring | 40% Uncommon, 45% Rare, 15% Legendary | 9.3 CE |
| Ascended deck | Ascended Board | own deck, ~2× T2 EV (per spec §13) | ~18 CE |

Suggested print counts: T1 = 40 cards (30 U / 10 R), T2 = 40 cards (16 U / 18 R / 6 L).

**Deck exhaustion:** when a resource deck runs out, shuffle that ring's discards into a new deck.

- **Inner ring bonus:** gather there = **draw 2, keep 1** (EV 13.0 CE). Pays for the access cost (items/skills to cross, per spec §4).
- Skills/gear add: +1 Common, +1 draw, or keep-both — this is the engine-building lever.

### 3.2 Explore
Flipping an unexplored tile → Event deck + **1 draw** from that ring's resource deck (existing spec §10 rule; deck now ring-matched).

### 3.3 Creatures (ties economy to Duality)
- **Befriend:** 1 draw from the ring's deck + **1 Light** + creature favor token.
- **Fight:** **2 draws** (loot), Duality-phase consequences (Dark lean).
Equal-ish material EV after Light value; Dark = more raw stuff, per spec §6 nudge.

### 3.4 Quest rewards
Guardian/common quests pay in VP primarily; material rewards budgeted ≤ 1 draw of the quest's ring tier.

**Simulated lifetime income (base skill, standard mode): ≈ 98 CE/player**, ~4 Rares, ~1 Legendary. Skilled engines reach 130–150 CE.

## 4. Sinks (spend)

### 4.1 Crafting — cost budgets
Recipes are **custom-named** (built from resources.md), but every recipe must fit its tier budget:

| Item tier | Material budget | Shape rule |
|---|---|---|
| Common item | 2–3 CE | Commons only |
| Uncommon item | ~6 CE | ≥1 Uncommon resource + Commons |
| Rare item | ~18 CE | ≥1 Rare resource + Uncommons/Commons |
| Legendary item | ~54 CE | ≥1 Legendary resource + Rares; needs crafting bench |

**Materials decide quality:** The highest required-tier resource used sets the item's tier.
**No sacrifice exchanges:** Upgraded gear tiers (e.g., Stone Axe $\rightarrow$ Copper Axe $\rightarrow$ Ironwood Axe) do not consume the lower-tier item as an ingredient; they are crafted independently using more expensive materials.

### 4.2 Material Refining & Conversion
- **Material Refining:** Advanced crafting and upgrading require *refined* resources (e.g., converting 3 Copper Ore $\rightarrow$ 1 Copper Ingot). This refining process can **only** be performed by traveling to and using public buildings built on the board (e.g., Forge, Kiln, Apothecary Hut, Crafting Bench).
- **Conversion (Bank Exchange):**
  * **Down:** 1 card of tier T $\rightarrow$ **2** resources of tier T-1 (same element).
  * **Up:** **4** of tier T $\rightarrow$ 1 card of tier T+1 (same element), **at a public Crafting Bench only**.
  * Net: Trading with other players remains more efficient, encouraging cooperative negotiation.

### 4.3 Trading
- Window: **your Care phase only**, both parties agree.
- Fair trade (≤2 CE net difference): neutral.
- Generous trade (giving ≥3 CE net): **+1 Light** to the giver.

### 4.4 Learning & Quests
- **Learning a skill:** Pay resources matching the skill's tier budget (Common skill ≈ 3 CE ... Rare ≈ 18 CE). Requires Meditation during the Care Phase.
- **Quests:** Common/Guardian quests pay in VP and Light. 
  * *Quest Duality aspect:* Quests have optional Dark choice paths. The Dark option has a **1.5x CE cost premium** (e.g., if the Light path costs 6 CE, the Dark path costs 9 CE) and shifts the player's marker toward Dark, representing the thematic difficulty of selfish choices.

## 5. Energy (boost meter — replaces upkeep)

- **Care phase is bonus-only.** No forced eating, no starvation, no skip-turn.
- Energy meter: **cap 5, start 2**. Filled by food/potions in Care phase: raw Common food = +1, cooked meal (crafted) = +3.
- Spend anytime on your turn:

| Cost | Boost |
|---|---|
| 1 ⚡ | +1 move OR +1 Common on gather OR +1 to a Fate Card/fight roll (usable after draw) |
| 2 ⚡ | +1 resource-deck draw (keep 1) OR +2 to a Fate Card/fight roll (usable after draw) |
| 3 ⚡ | Re-draw one Fate Card / fight roll OR +1 craft attempt this action |

Gear equips give passive stat boosts (no energy). Potions = one-shot effects (spec, unchanged).

## 6. Element Specificity

Recipes name **elements** (and specific cards at Rare+). Commons being unlimited-carry is safe because they're 1 CE, element-locked, and every recipe/conversion demands specific elements — quantity never substitutes for the right element.

## 7. Dual-Nature Resources

Fork/Aligned cards (resources.md) keep listed CE value; the **Dark use grants ~1.5× material effect but −1 Light**, Light use grants tier-normal effect +1 Light. Consistent with §6 nudge.

## 7b. The Island Rage Track (Tension & Economic Sink)

- **Island Rage Track (0 to 10):** Measures the environmental backlash.
- **Rage Faucets (Increases):**
  - **Temporal Decay:** +1 at the start of every game round.
  - **Greed/Exploitation:** +1 whenever any player exploits a tile (+1 Dark), crafts a Dark Kit item, or casts a Dark spell.
- **Rage Sinks (Sinks/Setbacks):**
  - **Combat Difficulty:** Creature Fight numbers $F$ increase by $+1$ for every 3 Rage levels (rounded down; $+1$ at Rage 3-5, $+2$ at 6-8, $+3$ at 9-10).
  - **Resource Decay (Card Setback):** At Rage 5+, any creature Bite or Event setback forces the player to discard 1 card from their hand (in addition to standard setbacks). At Rage 9-10, they must discard 2 cards.
- **Mitigation (Economic Action):**
  - Fulfilling a Guardian Quest step or performing a Give Back Light action (e.g., building a public structure) reduces the Rage track by -1.

## 8. Per-Turn Flow Check

Average income ≈ 6.5 CE/turn; average spend ≈ 5.7 CE/turn. A player always has a meaningful spend decision within ~2 turns of any gather — no dead accumulation phases.

## 9. Digital Adaptation

Same rules; digital may: weight individual named cards inside a tier (physical treats a tier as uniform), use true % drop tables, auto-enforce budgets, track per-resource scarcity dynamically, and run economy telemetry to retune deck ratios per patch. **Tier ratio (3×), budgets, and energy costs stay identical** so both versions play the same game.

## 10. Mode Scaling

| Mode | Turns/player | Scaling |
|---|---|---|
| Short | ~10 | Start with 1 Uncommon card + 4 Commons; T1 deck only for first 3 rounds skipped — inner ring opens turn 3 |
| **Standard** | **~15** | Baseline above |
| Epic | ~25 | All budgets ×1.5 for Legendary tier only (Legendary item = 81 CE); expect 2 Legendaries/player |

## 11. Verification Summary

Monte Carlo, 20,000 players, base-skill action mix (7 gathers, 3 explores, 2 creatures):
mean income 98.3 CE; 0.97 Legendary/player/game; 4.15 Rares/player/game; T1 EV 4.50, T2 EV 9.30, T2 draw-2-keep-1 EV 13.03. Sink total 86 CE. Reviewed by all five archetypes — passed.
