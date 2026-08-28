# Into the Wild — Game Design Spec (context file)

> Single game, two builds: **physical boardgame** + **digital (PC/app)**. Shared design core; constraints differ (physical = hand-computable/shuffleable; digital = hidden state, real-time logic, heavy math/RNG). Every system must work or be explicitly adapted for both.

## 1. Concept & Theme
- Players are castaways from a sinking ship, landed on an unknown island.
- Genre: crafting / exploring / life-sim RPG, engine-builder with player interaction.
- Core theme: **taking care of others is also taking care of yourself**; kindness and fairness are productive.
- Central tension: it is competitive, but winning requires giving back and helping competitors → competing is a deliberate struggle.
- Island is alive: nature, spirits, creatures, and Guardians react to player behavior.

## 2. Setup & Modes
- Board: **hexagonal board** made of small hexagonal tiles, mostly unexplored (face-down) at start.
- Players start at **opposite ends** of the board.
- **Co-op mode**: players start at the same end, or in pairs (2v2) at opposite ends.
- Each player gets a unique **character card** + a personal **player board**.
- **Starting loadout (Standard) — salvage draft:** deal 2× player-count salvage cards face-up from the shipwreck pool; snake-draft 2 per player. Ties to the shipwreck origin and adds an opening decision.
- **Starting loadout — salvage draft:** deal 2× player-count salvage cards face-up from the shipwreck pool; snake-draft 2 per player. Energy starts at 2.

## 3. Characters
- Each character is unique: personality, skills, affinities, starting stats.
- One **unique signature ability** only that character can learn/use — their "ace up the sleeve," lasts the whole game.
- One **unique weakness/drawback** only that character has → deliberate trade-off.
- Characters are **balanced against each other**: none is strictly stronger; different but equal.
- Different creatures/personalities interact differently with different characters.
- Player-board starting variables (differ per character): **move speed**, **item carry capacity**, **base state/elements**, **base abilities**, **element affinities**.

## 4. Board Tiles & Elements
- Tiles have different textures/colors by **element**.
- Each element = different **event** + different **resources** found when a player arrives.
- Resources usage: **eat, drink, craft items, craft potions, trade** with other players.
- **Tier structure by board location (risk/reward):**
  - **Outer ring (T1):** basic elements/terrain only.
  - **Inner / center (T2):** harder version of each element/terrain — requires certain items/skills to cross, or move very slowly. Yields better items/resources, stronger creatures, bigger events/Guardians, more victory points.
  - **Guardian realm (top tier):** reachable **only with a high Light level on the Path of Duality** — the realm of the island Guardian who interacts only with kind players.

## 5. Two Currencies / Tracks
### Victory Points (VP)
- Earned via actions, private goals, quests for the island Guardians.
- Special quest completions can also **remove/take away** VP at certain moments.

### Light Points (the Path of Duality track)
- **Mechanic: a single track from -10 (Max Dark) to +10 (Max Light).**
- **Instant Shifts:** Markers shift immediately when players make choices with a Duality aspect (e.g., Gifting: `+1 Light`; Exploiting: `+1 Dark`; using a Fork resource's Dark option: `-1 Light`).
- **Path of Duality Bands:**
  - **Max Light (+8 to +10):** Guardian Gate unlocked. Creatures always use the *Gift* reaction. Duality world events are highly positive.
  - **Light (+3 to +7):** Standard befriend options available.
  - **Neutral (-2 to +2):** Creatures offer a *Demand* challenge. Choosing to help gives `+1 Light` instantly; exploiting gives `+1 Dark` and extra loot.
  - **Dark (-7 to -3):** Setback penalties apply: `-1 Move Speed` and `+1 F` (Fight difficulty) on all creature fights. Creatures auto-Bite or attack.
  - **Max Dark (-10 to -8):** Corrupt Gate unlocked. Double negative effects apply, but unlocks Dark Quests.
- **Hypocrisy Penalty:** Light is judged relative to success. If a player's `VP` exceeds their `Light level` by **5 or more points**, they suffer `-1 Energy` gain during the Care phase for every 5 points of disparity. (Max Dark players are exempt from this penalty).
- **Opting Dark:** A player may choose to go dark — refuse to help others, raid caches, use traps. The game heavily punishes this (bad luck, minus stats, hostile encounters), but victory remains possible via Way 3.

### 5b. Island Rage Track (The Tension Engine)
- **Mechanic:** A track from 0 (Peaceful) to 10 (Enraged) representing the island's defense.
- **Rage Increases:**
  - **Temporal Decay:** Increases by +1 at the start of every game round.
  - **Exploitation:** Increases by +1 whenever any player exploits a tile (+1 Dark), crafts a Dark Kit item, or casts a Dark spell.
- **Rage Penalties:**
  - **Creature Hostility:** Global Fight Numbers ($F$) for all creatures increase by $+1$ for every 3 Rage levels (rounded down; max $+3$ at 9-10 Rage).
  - **Severe Setbacks:** When resolving a creature Bite or Event setback at Rage level 5 or higher, the player must discard 1 card (in addition to the standard setback). At Rage level 9-10, they must discard 2 cards.
- **Rage Mitigation:** Completing a Guardian Quest step or performing a Give Back Light action reduces the Rage track by -1 immediately.

## 6. Path of Duality — Balance Design (Light vs Dark)
- Kind players get **big advantages**: creature rewards, more Guardian points, some Guardians interact only with them.
- Game must still be **winnable while evil/dark**, but only by going **FULL dark + very selfish**.
- **Medium is the worst place to be** — system actively **nudges medium players to pick a side**.
- Dark side: heavily punished — bad luck, minus stats, hostile encounters. You must NOT do kind things (no gifting); you can attack/raid/pillage, but get punished for it.
- Net: dark path is **possible but very hard to pull off** — should *feel* much harder via observed statistics so players rarely choose it.

### Damage model — no HP
- Players have **no health points** and cannot be eliminated. Attacks, hostile creatures, and dark events cause **setbacks only**: lose resources, lose energy, lose Light/board position, or damage a crafted item. Never death, never a fully skipped turn.

## 7. Quests
### Common quests (per session)
- Each session: draw **3 cards** from a common deck — quests **any** player can do.
- **Tiered VP:** card 1 = easy, card 2 = medium, card 3 = hard.
- **No first-come bonus** (would unbalance asymmetric starts; players start equal-but-different).
- **Redraw rule:** if players agree the draw is unfairly unbalanced, redraw on majority vote.
  - Fairness-as-mechanic: the deciding vote goes to player(s) who **do NOT own the game** (less experience → fairer). If among those a non-owner exists, **that person decides**.

### Guardian / spirit quests (victory path)
- Win condition route: complete quests for **island spirits/Guardians**.
- Typically requires **making an item** whose crafting involves actions **both for and against** the player — slightly difficult, always requires **giving something back**.

## 7b. Mathematical / Tier System (recursive, 4 tiers)
- Four classes applied uniformly across **resources, items, abilities, skills**: **Common → Uncommon → Rare → Legendary**.
- Recursive matching: elements/resources map into these tiers; items, skills, and results all stay **in sync** across the 4 tiers.
- **Skills tied to tiers:** a Common skill needs Common-class items; skills can be **leveled up during the game**.
- Every character **can learn any skill**, but **cannot learn every skill within one game** (time/resource limited).
- Any skill or item a player creates/learns also has **3 versions**: base **Common**, **Uncommon/Rare**, **Legendary** — synced with resources and the other tiered systems.

## 8. Randomness & Luck Mitigation / Engine Profile
- Primarily an **engine-builder** with a twist of crafting + exploring + giving back, plus **player interaction**.
- Luck elements & mitigation:
  - **Resource deck** draw during resource-gathering.
  - **Event/encounter card** draw when meeting a creature, forest, or island Guardian.
  - **Fate Cards (Physical/Digital):** Fights use a **12-card Fate Deck** (containing values: 1, 2, 2, 3, 3, 4, 4, 5, 5, 6, and two special "Spirit/Wild" cards). Drawing from this deck ensures a normal distribution of outcomes and allows strategic card-counting. The digital version uses an identical distribution.
  - **Perceived Chance Mitigation (Energy Focus):** After drawing a Fate Card or rolling, players may spend Energy to boost the result: spend `1 Energy` for `+1` to the check, `2 Energy` for `+2`, or `3 Energy` to redraw/reroll.

## 8b. Creature Encounters
**Principle: kindness is a choice, violence is a gamble.**

Every creature card shares one chassis; each fills it uniquely:

1. **Demand** — what the creature wants (an element, food, a Rare, an act). Meet it = **auto-befriend, no dice**: 1 ring-deck draw + 1 Light + favor token (economy §3.3).
2. **Light-band reaction column** — card has 3 printed columns (Light / Neutral / Dark); your current band picks which applies. Light: creature helps/guides. Neutral: the spec §5 small challenge + choose up-or-down fork (help it = Light, exploit it = Dark + more loot). Dark: hostile — treats you as prey.
3. **Fight number** — fight = draw a **Fate Card (1d6 equivalent) + element affinity/gear** vs this number (plus any Island Rage modifiers). Win: 2 loot draws + Dark lean. Lose: printed setback (steal, scatter, chase-off — no HP, per §6 damage model) plus any Island Rage setbacks.
4. **Love / Distrust icons** — each creature names one character it loves (advantage on the encounter) and one it distrusts (disadvantage). Delivers §3's per-character creature reactions.

**Prototype-test (not committed): Temper/companion track** — creatures persist on the board; each later visit where you meet the demand earns a favor; 3 favors = **companion** (small permanent passive). Adds relationship continuity; costs physical tracking. Decide after paper playtest.

## 9. Turn Structure & Action Rules
**A turn has 2 phases, in order:**
1. **Care phase (Bonus-only):** Drink potions, eat food for Energy, meditate (requires 1 Energy to unlock *Learning* this turn), trade/gift cards. Sleep (optional: skip action phase for `+2 Energy`).
2. **Main action phase:** Choose exactly 1 of the 6 actions (Move/Explore/Gather, Craft, Magic, Learning, Quest, Give Back Light) and fully resolve it.

Then pass to the player on their **left**.
- **Duality shifts:** Adjust Duality marker immediately when a Duality action/choice occurs.
- **Multi-step actions:** Fully complete one step/element before moving to the next.
- **Resource commitment:** If an action card lists spending resources, the player **must** spend them, and **cannot reverse** afterward.
- **Decision lock:** Once a **luck/card/event element** has resolved during the action, the choice **cannot be reversed**. Before any luck/card/event triggers, a player may change their action at the cost of `1 Light point` (it made others wait).

## 10. Resource Gathering / Exploration (detailed)
- Action **Explore**: player moves up to their **max move speed** (max distance per action).
- **Move then gather:** within the one Move/Explore/Gather action, a player may move up to speed and then gather at the tile where movement ends.
- If movement crosses an **unexplored (face-down) tile**, that tile **ends movement** and triggers the **Event deck** + **Resource deck**.
- Some cards have **special events that trigger immediately on draw**; any subsequent cards drawn are **paused until the current event is resolved**.
- If the Event draw yields a **creature card**, it triggers that creature's listed events.
- **Each creature's event is printed on its card** and applies **immediately** on draw.

## 11. Victory Conditions
**Three ways to win.** Routes 1 & 2 are statistically equal; route 3 (dark) is statistically harder. Players need **not** declare which they're chasing; whichever they reach first.

### Way 1 — The Capable Path (VP-based)
- **High VP threshold** + **lower Light threshold** on the Path of Duality.
- Metaphor: *successful and a decent person.*

### Way 2 — The Enlightened Path
- **Maxed-out Light** on the Path of Duality + **medium VP threshold**.
- Metaphor: *a beautiful yet capable soul, recognized as such by the island Guardian.*

### Way 3 — The Dark Path
- **Maxed-out Dark** end of the Path of Duality + **maxed-out VP**.
- Evil can win too, but **harder** — you are **alone** (refuse to help others, no group quests, refuse to give up resources / do self-negative acts).
- Should be **statistically harder** (not by much), but should **feel** much harder so players rarely pick it.

### 4D Board Victory Modifications
- **Collective Viability Constraint:** If the 4D Board is built, a player can only win if *every* active player still has a viable path to win (i.e., no player has been reduced to an unwinnable/elimination state, keeping the possibility of victory open for everyone). This shifts the emphasis to collective success and ensures kindness remains optimal.

### Tie-breakers (Ways 1 & 2, in order)
  1. Tie within same Light level → **higher Light level wins** (kindness beats success).
  2. Still tied → more **VP from Guardian quests** wins (rewards cooperation).
  3. Still tied → **shared victory** (cooperation is a core point).

### House rule (optional, for frequent groups)
- If someone won via the Dark path, they **may not choose Dark the next round**.
- Opt-in per playgroup; not default.

## 12. Core Engine Loop
- **"One more turn" driver:** exploration into the unknown — new tiles, events, better gear, new skills, and the pull of giving back.
- **Turn loop:** Care → Action → pass left.
  - **Care phase (bonus-only):** No forced eating, no skip-turn. Food/potions fill the **energy boost meter** (cap 5, start 2) spent to amplify actions; gear equips give passive boosts; meditate for learning access; **trading window** (only time players may trade). Cannot return to Care after starting Action. See `economy-engine.md` §5.
  - **Action phase:** Choose ONE of 6 actions (Move/Explore/Gather, Craft, Magic, Learning, Quest, Give Back Light). Fully resolve before passing. Duality shifts apply immediately upon choice.
- **Two-phase game:** main board play → option to build 4D Board (Ascended Board) opens mid-game when majority of players reach the center.

## 13. Ascended (4D) Board
- **Trigger:** Majority of players reach the center of the main board $\rightarrow$ opens the **option to build** the 4D Board (second board played next to the main board).
- **Structure:** Slightly smaller board, structured in **three concentric rings**. Same hex-tile system. Deeper rings (closer to the center) are progressively more difficult.
- **Rewards 2x+ & Equal Distribution:**
  - High-risk, high-reward: rewards, perks, and bonuses are doubled or more (2x+) compared to the main board.
  - When operating on the 4D board, active players receive equal amounts of resources, perks, and bonuses (fair, balanced payouts).
- **Dark Path Exclusion:**
  - Players on the Dark path (negative Duality points) **cannot enter or do anything** on the 4D board.
- **Setback & Duality Double/Amplified:**
  - Negative aspects, penalties, and setbacks are **doubled** on this board.
  - Active players must maintain intense balance to stay in 4D.
  - **Amplified Setbacks on Targeted Active Players:** If a player disadvantages (attacks, steals from, or targets) an active player on the 4D board, the impact/setback on the targeted player is **amplified** (extremely severe). If a player loses their balance (Duality drops below 0 / neutral), they cannot stay in 4D and are immediately expelled to the main board.
- **Dedicated 4D Event Deck:**
  - A separate Event Deck placed next to the board containing location-specific creatures, treasures, resources, Guardians, and challenges.
- **Special Side Challenge:**
  - A separate challenge next to the board that is extremely difficult but highly lucrative.
  - Rewards significant Duality/Lightness points and resources, but requires a high Duality/Light threshold to attempt/complete.

### The Balancer
- Appears if **no player** is on the Dark path (no negative Duality points) when the creation of the 4D board begins.
- Acts as a counterweight challenge to everyone taking the positive path.
- Strength scales based on how far each player has gone into positive Duality:
  - Each player gets a **separate Balancer** whose strength scales individually.
  - If a player passes a positive Duality threshold, their Balancer's strength is **multiplied** for them.

## 14. Endgame Trigger & Loop Preventer
- **Master Guardian:** Resides at the center (third ring) of the 4D Board.
- **Absolute Challenge:** The ultimate endgame trial presented by the Master Guardian.
- **Victory Loop:**
  - Defeating the Master Guardian triggers the end-of-game loop: all players have **exactly one more round** to play, after which the game ends.
  - **Loop Preventer:** If the standard victory conditions (§11) are met by any player *before* the Absolute Challenge is completed, this also triggers the final round and ends the game (preventing infinite loops).

## 15. The Elements (Architecture Base)
- The **elements are the foundation** of all systems: resources, skills, creatures, magic, and items are all built on them.
- **5 core elements** (ring terrains) + **1 special element (Spirit)** that lives in scattered special tiles, not a ring terrain.

| # | Element | Domain | Terrain | Color |
|---|---------|--------|---------|-------|
| 1 | Wood | Earth | Jungle | Green |
| 2 | Grain / Grass | Sun | Meadow | Gold |
| 3 | Stone / Fire | Fire | Mountain & Volcano | Red |
| 4 | Water / Air | Sky | Lake / Beach | Blue |
| 5 | Ether (mushroom / magic) | Moon | Swamp | Purple |
| 6 | Spirit | Soul / Duality | Special tiles | White / Prismatic |

- Each terrain tile belongs to one element → governs the resources gathered, creatures encountered, magic available, and craftable items there.
- **Spirit** is earned (kind acts, balance, Guardian quests, meditation), not gathered by skill; it ties to the Path of Duality and Guardians.

## 16. Resources & Special Tiles
- **Common resources = fixed staples** — guaranteed from terrain, NOT in any deck. Represented physically by **wooden tokens** (unlimited carry capacity).
- **Uncommon → Rare → Legendary = Resource deck cards** — drawn, named cards. Hand size limit is **7 cards**; players must use, trade, gift, or discard excess cards at the end of their turn to prevent hoarding.
- **Carry Limits:** Limits only apply to **special items** (crafted tools, gear, weapons, vessels). Standard limit is 3 equipped/active items plus 2 backpack slots (total 5), adjusted by each character's profile.
- **Public Buildings & Material Refining:** Players can construct shared buildings (Benches, Forges, Kilns, Apothecary Huts) on explored hexes. These are public; any player on that tile can use them. Advanced crafting requires *refined* resources (e.g., Copper Ore $\rightarrow$ Copper Ingot), which can *only* be refined at these public buildings. Building a public structure is a Give Back Light action (`+2 Light`).
- **Two resource decks by ring:** T1 (outer: 75% U / 25% R) and T2 (inner: 40% U / 45% R / 15% L); Ascended has its own. Inner-ring gather = draw 2 keep 1.
- **Value math:** 3× per tier (C=1, U=3, R=9, L=27 CE). Full economy: `economy-engine.md`.
- **Dual-nature resources** behave differently by Path of Duality:
  - *Fork* — choose Light or Dark use at point of use (Dark = stronger but Light penalty).
  - *Aligned* — good for one path, penalty in the wrong hands (e.g. Pure Light rots for Dark, Voidcap corrupts Light).
- **Special / unique terrain tiles** — scattered, high-event, cross-element or Spirit-linked (shrines, ruins, shipwreck, moonwell, caldera, Guardian gate, blighted ground, etc.).
- **Full lists:** see `resources.md`.
