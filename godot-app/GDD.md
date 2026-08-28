# Into the Wild — Game Design Document

*Working title. v0.1 — distilled from the designer's spec (Aug 2026).*

Notation: **[SPEC]** = the designer's rule, as given. **[TUNE]** = a proposed
number/detail filled in to make it buildable — a starting value, not a decision.
Config values live in `data/config.json`.

---

## 1. Vision

**[SPEC]** A crafting/exploring RPG in board-game form, combining the
designer's favorite board games and PC games (RPGs, crafters, exploration)
with a spiritual view on life.

Players are stranded on an unknown, unexplored island full of magic,
creatures, resources and wonder. The island's Guardian spirits want to keep
it that way: players must not become colonizers, but integrate into the
harmony of the island. Through play, players discover that taking care of
others is also a way of taking care of themselves — and that they themselves
evolve over the course of the game.

**Design pillars**

1. *Winning and giving back at the same time.* It is a competitive game in
   which kindness is materially costly and strategically strong. "How can you
   win if you have to help your competitor?" is the intended tension.
2. *Fairness as a mechanic.* Equal-but-different starts; unfair random draws
   can be voted away; the least-invested player gets the deciding voice.
3. *The island reacts to who you are.* One karma system (the Light track)
   flows through creatures, guardians, luck and access to the world.
4. *Engine-builder heart, adventure skin.* Primarily an engine-building and
   player-interaction game; luck exists but is contained (decks + one small
   dice element in creature encounters).

## 2. Core fantasy & tone

Wonder, integration, reciprocity. The island is a character. Dark play is
possible and legal — the island simply *answers how you treat it*.

## 3. Players & format

- **[SPEC]** Competitive with strong co-op elements: group quests exist,
  helping others is rewarded, yet there is one winner (with shared-win
  tiebreak, §10.3).
- **[TUNE]** Digital v1: local pass-and-play, 1–4 players. (Online multiplayer
  and AI opponents are out of scope for v1 — see AGENTS.md roadmap.)

## 4. The island (the board)

### 4.1 Shape
**[SPEC]** A hexagonal board of small hexagonal tiles, mostly face-down
(unexplored). Tiles are explored by moving onto them.

### 4.2 Rings and tiers
**[SPEC]** Outer part of the island: basic (Tier 1) terrain elements. Toward
the center, a band **three rings thick** of Tier 2 terrain — extreme versions
of the same elements. Tier 2 requires certain items/skills to cross, or you
move very slowly. Tier 2 holds better resources, more powerful creatures,
events and guardians: an explicit risk/reward system.
**[TUNE]** Board radius 6: rings 4–6 = Tier 1, rings 1–3 = Tier 2, ring 0 =
Sanctum.

### 4.3 The Sanctum
**[SPEC]** An innermost tier reachable **only** with a high Light track —
the realm of the island Guardian, who only interacts with kind players.

### 4.4 Elements
**[SPEC]** Several elements, each with its own tile color/texture, its own
event table and its own resource table. Each element has a harsher Tier 2
terrain version.
**[TUNE]** v1 ships 6 placeholder elements (Forest/Deepwood, Waters/Wildwaters,
Stone Hills/Highcrag, Wind Plains/Stormfields, Embercrag/Caldera, Spirit
Grove/Sanctum) — all names and colors editable in `data/elements.json`.

## 5. The Light track (karma system)

### 5.1 Earning and losing Light
**[SPEC]** Light points are gained by acts that benefit other players while
literally disadvantaging yourself, and by completing group quests with other
players. (Also lost by selfish acts, attacking, and by changing your declared
action — §9.3.)

### 5.2 Light relative to success
**[SPEC]** The system pushes players to stay *above a certain Light level in
relation to their Victory Points*. Falling a certain amount below it brings
negative effects: worse stats, worse luck, and creatures that attack instead
of help.
**[TUNE]** `expected_light = VP × 0.4`; band = Light − expected_light:
≤ −6 Dark, −5..−2 Shadowed, −1..+1 Neutral, +2..+5 Kind, ≥ +6 Radiant.

### 5.3 How the island answers each band
**[SPEC]** Creature encounters by band:
- **Very high (Radiant):** the creature gives you a gift.
- **Good (Kind):** it helps/rewards you.
- **Neutral:** it gives you a *small challenge* that decides whether you go
  up or down on the Light track — a nudge to choose a side.
- **Bad (Shadowed):** it takes something from you.
- **Dark:** it attacks you — "obviously, you're not a nice person."

### 5.4 The intended balance of Light vs Dark
**[SPEC]**
- Kind players get real advantages: creatures reward them, guardians give
  more points, some guardians *only* interact with them.
- Dark play must be *possible* to win but demand going **full dark** and full
  selfish: no giving, raiding and attacking allowed — and punished (bad luck,
  minus stats, hostile encounters).
- The middle is deliberately uncomfortable: the game nudges Neutral players
  to pick a side.
- Statistically, dark should be only *slightly* harder — but the visible
  feedback should make it *feel* much harder, so it isn't chosen casually.

## 6. Resources, items, skills — the four classes

### 6.1 Rarity classes
**[SPEC]** A recursive mathematical system with four classes — **common,
uncommon, rare, legendary** — applied consistently to resources, items,
abilities and skills, all in sync.

### 6.2 Items and skills have versions
**[SPEC]** Every item/skill has a base (common) version plus uncommon, rare
and legendary versions, in sync with the same four tiers.
**[TUNE]** v1 implements the class system for resources and recipes;
item/skill *versioning* (upgrade paths) is a roadmap item.

### 6.3 Skills
**[SPEC]** Skills map to the four classes; a skill's common version needs
common items, and skills can be leveled up during a game. Every character can
learn any skill — but not *all* skills within one game (time is the limit).
**[TUNE]** Skill learning/leveling engine is a roadmap item; the data shape
exists in recipes/characters.

### 6.4 Uses of resources
**[SPEC]** From gathered resources players can eat, drink, craft items, craft
potions, and trade with each other.
**[TUNE]** v1: craft + give (trade UI is a roadmap item; eat/drink exists as
flavor via the Simple Meal item — a survival/nourishment module is an open
design question, not yet a rule).

## 7. Characters

**[SPEC]** Each player gets a unique character card:
- distinct personality, skills, affinities and starting stats
  (move speed, backpack size, base state, elemental affinities);
- **one unique skill** only they can ever use — their ace up the sleeve;
- **one unique weakness** only they have — the trade-off;
- characters are *balanced against each other*: different but equal, no
  character strictly stronger ("equal but different" — also the start rule);
- **[SPEC]** different creatures interact differently with different
  characters (personality chemistry). **[TUNE]** v1 ships the Listener's
  band-shift as the first instance; a general chemistry table is roadmap.

v1 roster (all placeholder flavor, `data/characters.json`): Wayfarer (fast,
Pathfinder / Restless), Tender (giver, Open Hands / Soft Step), Forgekeeper
(maker, True Temper / Heavy Gear), Listener (creature-whisperer, Kindred
Tongue / Daydrift).

## 8. Turn structure & actions

### 8.1 Turns
**[SPEC]** On your turn you choose **one action** from several, do it fully,
then pass to the player on your left. Multi-step actions complete one step
fully before the next.

### 8.2 Explore & movement
**[SPEC]** Exploring moves you up to your move speed. The moment your
movement takes you onto a face-down tile, that tile **ends your movement**,
is flipped, and triggers the **resource deck** and the **event deck**.
Tier 2 tiles cost more movement unless you have the right item/skill (§4.2).

### 8.3 Events & creatures
**[SPEC]** Some event cards trigger immediately when drawn, and no further
cards are drawn until the event resolves. If the draw is a creature, the
creature's own listed event applies immediately (per the encounter band
table, §5.3). Creature encounters contain the game's one small dice-roll
element.

### 8.4 Committing to actions
**[SPEC]** Resources used by an action (to create, give back, or fulfill a
quest) are spent and cannot be reversed once used as listed.

### 8.5 Common quests
**[SPEC]** Each session, three cards are drawn from a common deck — an easy,
a medium and a hard quest — open to **every** player. No first-finisher
bonus: players start as equals, just different. If the majority agrees the
draw is unfairly balanced, redraw. Because fairness is the point: the
players who do **not** own the game decide close calls; if a non-owner is
present, that person decides.
**[TUNE]** v1 displays the three quests; automatic progress-tracking and the
redraw vote are roadmap items.

### 8.6 Guardian quests
**[SPEC]** Guardians grant quests — usually crafting an item whose making is
partly *against* your own interest, or tasks built around giving something
back. Completing them yields VP (and these VP are the second tiebreaker,
§10.3). **[SPEC]** At special moments, VP can be *taken away* for the
un-completion/abandonment of certain quests. **[TUNE]** marked `revoke_vp`
in quest data; enforcement is roadmap.

### 8.7 The five Action Cards — v2 design update
**[SPEC — designer update, Aug 2026.]** This supersedes the flat action list
in v0.1 (which stays in code as a placeholder until the card engine lands —
roadmap #1). Each player runs **five action cards**; taking a turn means
playing one of them. **Action cards have asymmetric properties based on
character class**, and a **neutral balanced option** is available. A card's
**level decides what the action offers** (Ark Nova-style).

1. **Explore** *(cards)* — movement · resource gathering · special resource ·
   draws from the **Explore deck** (creatures, recipes, skills, guardian) ·
   creature card draws.
2. **Building / Crafting** — homebase · items · potions · **blueprint start**.
3. **Creatures (Animals)** — play a creature · use **familiar** · get a
   **bonus from sets** (set collection).
4. **Learning / Magic** — carries a passive **Sponsor** element. Skill-tree
   unlock · take a recipe card from the recipe deck · look through the deck ·
   unlock the character's **unique ability** · a skill unlock **costs energy
   based on the skill**.
5. **Guardian** — carries an **Association (community)** element. **Worker
   placement where the action's level decides which slots are available**
   (as in Ark Nova) · **blueprint complete** · **level up actions** · get
   **guardian challenges**.

**Free actions [SPEC]:**
- **Selfcare** — a free action: *move an action card* and *eat a food item*.
- **Trading** — becomes a free perk **after level 3**.

## 9. Choice, luck & the cost of hesitation

- **[SPEC]** The game is primarily an **engine builder** with a unique twist
  of crafting, exploring and giving back; luck lives in the resource deck,
  the event deck, and a small dice element in creature encounters.
- **[SPEC]** 9.2 Once any luck-based element has resolved during your chosen
  action (card drawn, event triggered), you **cannot** reverse the choice.
- **[SPEC]** 9.3 Before any luck has resolved, you *may* change your chosen
  action — but it costs **1 Light**, "because it makes the other players
  wait."

## 10. Victory

### 10.1 Path of Light
**[SPEC]** Reach the Victory Point threshold while at/above the Light
threshold. Statistically equal to the alternative; players never have to
declare which path they pursue and may drift between them — whichever
completes first wins. **[TUNE]** VP ≥ 20 with Light ≥ +8.

### 10.2 Path of Dark
**[SPEC]** The dark road does not use the Light threshold — it demands the
**absolute extremities of both tracks**: the entire darkness path *and* the
entire VP path. Choosing dark means refusing to give, accepting negative
resource effects, raiding and being punished for it. Slightly harder
statistically; *observably* much harder. **[TUNE]** VP ≥ 24 with Light at
the track minimum (−12).

### 10.3 Ties
**[SPEC]** If players finish in the same round: the higher **Light** level
wins — *being kind beats being successful*. Still tied: most VP earned from
**Guardian quests** wins. Still tied: it is a **shared victory** — because
cooperation is the point of this game.

### 10.4 House rule (optional, for regular groups)
**[SPEC]** A group that plays together often can opt in: whoever won by the
dark path cannot choose the dark path in the next session.

## 11. Systems summary (v1 implementation status)

| System | Status in v0.1 |
|---|---|
| Action-card system (5 leveled cards, class asymmetry) | 🔜 v2 design (§8.7) — roadmap #1 |
| Hex island, rings, tiers, Sanctum gate | ✅ playable |
| Explore / flip / resource + event decks | ✅ playable |
| Light track, bands, creature reactions | ✅ playable |
| Craft (4 rarity classes), Give, Offer | ✅ playable |
| Characters w/ unique skill + weakness | ✅ 4 shipped |
| Two victory paths + autosave | ✅ playable |
| Quest engine (progress, revoke, votes) | 🔜 roadmap |
| Base building, trading, skill leveling | 🔜 roadmap |
| Item/skill versions, creature chemistry | 🔜 roadmap |
| Nourishment (eat/drink) module | ❓ open design question |
| Online play / AI opponents | 🔜 post-v1 |

## 12. Open questions for the designer

1. Nourishment: is eating/drinking a survival *requirement* (hunger clock) or
   only a benefit (buffs)?
2. Base building: what does a base *do* — storage, crafting bonuses, spawn
   point, VP?
3. Player-vs-player raiding (dark path): what exactly can be taken, and what
   is the defender's counterplay?
4. Group quests: how do 2+ players formally join one quest and split rewards?
5. Session length target (minutes) — this drives all thresholds in
   `config.json`.
6. Action-card strength (§8.7): an Ark Nova-style slot row where the played
   card returns to the weakest slot (Selfcare's "move an action card"
   suggests this), fixed per-card levels raised by Guardian → *level up
   actions*, or both combined?
7. **Energy** (§8.7) is a new resource that pays for skill unlocks — how is
   it gained, stored, capped?
8. What exactly are the passives — **Sponsor** on Learning/Magic and
   **Association (community)** on Guardian?
9. Trading unlocks "after level 3" — level of *what*: the Guardian card, the
   homebase, or the player?
10. The Explore deck now contains creatures, recipes, skills AND guardian
    cards (§8.7) — does it replace the separate event deck of v0.1, or sit
    alongside it?
