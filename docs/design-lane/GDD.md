# Into the Wild — Game Design Document

> **Status:** section 14 of 19 (see `projects/into-the-wild/SEED-STATE.md`).
> **Builds:** physical boardgame **and** digital (PC/app), one shared design core.
> **This file is the map, not the territory.** It indexes the design corpus, states
> the invariants nothing may break, and holds the open questions. The detailed
> systems live in the files linked below; the *numbers* live in `canon/*.json`.

---

## 1. Pillars

From `projects/into-the-wild.md`. Every decision must serve at least one, and break none.

1. **Subtlety** — themes land through mechanics, never stated in text.
2. **Balance** — three viable victory paths, no dominant strategy.
3. **Duality** — kindness is mechanically advantageous but never forced.
4. **Depth** — one 4-tier recursive system across resources, items, skills, abilities.

Core theme: *taking care of others is also taking care of yourself.* The central
tension is that the game is competitive, yet winning requires giving back.

## 2. The corpus

| Area | File | State |
|---|---|---|
| Full spec (16 sections) | `into-the-wild-spec.md` | authoritative |
| Economy, faucets/sinks, sim claims | `economy-engine.md` | authoritative, now executable |
| Resource lists, 6 elements, special tiles | `resources.md` | complete |
| Action definitions | `actions/actions-v1-draft.md` | v1 draft |
| Quests | `quests.md` | brainstorm, unbalanced |
| Creatures | `creatures.md` | large draft |
| Items / crafting | `items-crafting.md`, `items/*.md` | draft |
| Objects, commons | `objects-catalog.md`, `commons-catalog.md` | draft |
| Characters (4) | `characters/*/` | complete, no numbers |
| Co-design persona | `persona-translator.md` | process doc |
| Progress ledger | `projects/into-the-wild/SEED-STATE.md` | 14/19 |

**Machine-readable canon:** `canon/*.json` — tiers, decks, elements, actions,
duality, rage, energy, crafting, fate, victory, modes. Every file carries a
`$source` pointing back at the doc it was extracted from.

## 3. Invariants

These are enforced by `pytest`, not by good intentions. Changing one means
changing its test in the same commit, deliberately.

| # | Invariant | Enforced by |
|---|---|---|
| I1 | Tier ladder is exactly 3× — C=1, U=3, R=9, L=27 CE | `test_canon.py::test_tier_ladder_is_3x` |
| I2 | Commons are off-deck tokens; U/R/L are cards | `test_canon.py::test_only_common_is_off_deck` |
| I3 | Deck compositions sum to 1 and match print counts | `test_canon.py::test_print_counts_match_composition` |
| I4 | The Duality track −10…+10 is fully tiled, no gaps or overlaps | `test_canon.py::test_duality_bands_tile_the_whole_track` |
| I5 | The Rage track 0…10 is fully tiled and monotonically worse | `test_canon.py::test_rage_penalties_are_monotonic` |
| I6 | Exactly 6 main actions, choose 1 | `test_integrity.py::test_there_are_exactly_six_main_actions` |
| I7 | Every Duality/Rage trigger named in an action exists in its table, same delta | `test_integrity.py` (3 tests) |
| I8 | Exploiting a tile costs Light **and** raises Rage | `test_integrity.py::test_exploiting_a_tile_costs_light_and_raises_rage` |
| I9 | Inner ring strictly out-yields outer ring | `test_economy.py::test_inner_ring_pays_for_its_access_cost` |
| I10 | Bank conversion always burns value, so player trade stays better | `test_economy.py::test_bank_conversion_always_burns_value` |
| I11 | Craft budgets follow the ladder: 3 / 6 / 18 / 54 CE | `test_economy.py::test_craft_budgets_follow_the_tier_ladder` |
| I12 | The §11 baseline (98.3 CE, 4.15 R, 0.97 L) is reproducible | `test_baseline.py` (5 tests) |
| I13 | Income stays ahead of sinks | `test_baseline.py::test_sinks_do_not_exceed_faucets` |
| I14 | 6 elements, 5 of them ring terrains; Spirit is earned | `test_canon.py::test_six_elements_five_ring_terrains` |
| I15 | Every `OPEN` marker in canon cites a GDD question | `test_integrity.py::test_open_questions_are_tagged_not_silently_dropped` |

Run them: `python -m pytest` · Report: `python -m sim`

## 4. What the harness already found

**F1 — the published baseline assumes a pacifist.** `economy-engine.md` §11 states
its action mix (7 gathers, 3 explores, 2 creatures) but never its ring split, so
98.3 CE was not reproducible from the doc. `sim/montecarlo.py` solves for it:
**4 gathers outer / 3 inner, 2 explores outer / 1 inner, 2 creatures outer, always
befriended** → 98.40 CE, 4.14 rares, 0.98 legendaries. Match.

The recovered fight rate is **0.0**. The balance verification was run on a player
who never fights.

**F2 — CONTESTED. The sim does not implement the fight rule the spec defines.**
`sim/montecarlo.py` models a fight as a guaranteed 2 loot draws. Spec §8b does not:
a fight is a Fate Card draw against the creature's printed Fight number — **win** =
2 draws, **lose** = a setback. `economy-engine.md` §3.3 compressed that to "Fight:
2 draws (loot)" and the sim was built from that line, so the harness measures a
mechanic the game does not have.

Holding the mix fixed and changing only the creature choice:

| Behaviour | Lifetime income | vs baseline |
|---|---|---|
| Always befriend | 98.40 CE | — |
| Always fight — **as the sim currently models it** | 107.40 CE | +9.00 |
| Always fight — with real Fate-draw resolution | ~93–97 CE | −1.6 to −5.1 |

So the headline "violence pays +9 CE" is a **simulator artifact**, not a design
defect. But it does not fully self-fix: the reviewing pass showed the first
correction used F-range *midpoints* rather than the actual roster distribution in
`creatures.md` (Common: 17 creatures at F3, 8 at F4). Re-derived from the roster,
the gap is −1.31 / −3.10 / **+0.41** CE depending on how the Fate Deck's two Wild
cards resolve (Q1) — and a player who fights **only Common creatures** earns
5.36–5.97 CE per encounter against befriending's 4.50 under two of the three
readings. Cherry-picked violence still pays.

Two concrete gaps this exposed, neither disputed:
- `sim/montecarlo.py` must implement the specified combat resolution. **economy lane.**
- `canon/duality.json` has `befriend_creature: +1` but **no `fight_creature` trigger
  at all**, while every doc asserts fighting causes a "Dark lean". The invariant
  tests missed it because a trigger that is never named cannot be checked for.
  **systems lane.**

## 5. Open questions

Numbered so canon can cite them. `OPEN` markers in `canon/*.json` must reference one.

| Q | Question | Blocks |
|---|---|---|
| Q1 | The 12-card Fate Deck has 2 "Spirit/Wild" cards with no defined resolution. What do they do? | fight math, `canon/fate.json` |
| Q2 | Give Back Light grants "a small VP reward" — how much? | VP scale, Way 1 vs Way 2 parity |
| Q3 | Ascended deck composition is "~2× T2 EV" with no card list. | 4D board economy |
| Q4 | Legendary skill learning cost is unspecified (C=3, U=6, R=18 exist). | skill trees, `canon/crafting.json` |
| Q5 | Hot Spring / Geyser "energy refill" — flat value or to cap? | energy meter |
| Q6 | **No numeric VP or Light thresholds exist for any of the 3 victory paths.** Ways 1 and 2 must be statistically equal; that is unverifiable until numbers exist. | everything downstream of victory |
| Q7 | "Every active player still has a viable path to win" (4D collective-viability gate) has no operational test. Physical players must be able to check it by hand. | 4D board, endgame |
| Q8 | Should the recovered ring split (F1) be adopted as the documented baseline assumption in `economy-engine.md` §11? | economy provenance |
| Q9 | **Fight-vs-befriend.** F2 is contested — see §4. Two undisputed fixes: implement real Fate-draw combat in the sim, and add the missing `fight_creature` Duality trigger. Open: Common-tier fights may still out-earn befriending. | pillar 3, spec §6, Way 3 |
| Q10 | Creature `Temper/companion` track (spec §8b) is marked "prototype-test, not committed". Decide in or out — it changes creature card layout. | creature cards, content lane |

| Q11 | **Does Way 3 exist at all?** Spec §13 bars Dark players from the 4D board; §14 puts the Master Guardian at its centre; Q7's viability gate lives there. Three proposals each assumed Way 3 works. Combined with canon it may be structurally unwinnable. | Way 3, endgame |
| Q12 | Care-phase gifting has **no cap** — `gift_card` grants +1 Light per gift with no per-phase or per-card limit. Two players can pass a card back and forth. One rule closes holes in three proposals. | Q6 Way 2 parity, Q7 |

Questions **Q6, Q9, Q11** are the ones that gate real progress. Q1–Q5 are fill-in-the-blank.

## 6. Working agreement

See `AGENTS.md` for lane ownership, the canon-vs-prose rule, and the conflict protocol.
