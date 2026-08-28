# Creature/Event system closure — Fate Deck wild resolution, fight math, Rage extremes, companion-track verdict

**Verdict:** NEEDS_WORK  ·  **Lane:** systems  ·  **Confidence:** high  ·  **Platform:** both

**Conclusion:** Q1 resolved: Spirit/Wild resolves by the drawing player's Duality band (Light/Max Light = auto-win, Dark/Max Dark = auto-loss, Neutral = redraw) — this is hand-computable, needs zero new card text, and gives every Light-band player a guaranteed 16.7% floor so the top end is never literally unwinnable for them. Fight math and Rage interaction are fully computed below. Q10: recommend OUT — cut the Temper/companion track from both builds; it adds an untracked persistent-state layer and stacks unpriced permanent economy on top of the still-open F2/Q9 imbalance.

---

## 1. Encounter resolution procedure (exact, not prose)

On any creature encounter (Event draw, or explore-triggered per spec §10):

```
0. Apply static Love/Distrust context for the current character (♥: -1 F on
   any Fight vs this creature, printed bonus applies; ✗: +1 F, cannot become
   companion under the old draft — moot now Q10=OUT).

1. Player declares ONE of three intents BEFORE any card is drawn
   (decision lock, spec §9 — changing after this point costs 1 Light):

   (a) MEET THE DEMAND  — legal in any Duality band, always.
       -> pay the printed Demand cost
       -> +1 ring-deck draw (creature's own ring)
       -> +1 Light
       -> place a favor token on the card (flavor-only marker, no mechanical
          effect post-Q10; may be omitted entirely without changing outcomes)
       -> no dice. Encounter ends.

   (b) ACCEPT YOUR BAND'S REACTION COLUMN — no cost declared, no dice:
       - band ∈ {light, max_light}  -> resolve the printed GIFT text.
                 (max_light: no extra roll; this band already carries
                 "creatures always use Gift reaction" per duality.json)
       - band ∈ {dark, max_dark}    -> resolve the printed BITE text.
                 (max_dark: double the Bite's stated magnitude, per
                 duality.json's "double negative effects")
       - band == neutral            -> forced sub-choice, no unique printed
                 text needed (uses the Demand/Gift fields already on the card):
                 · MEET  -> identical to 1(a) above (+1 Light)
                 · EXPLOIT -> +1 ring-deck draw (same single draw as
                   befriend, NOT stacked to 2 — see open_risks) + 1 Dark,
                   no favor token, no Demand cost paid, creature is not
                   re-encounterable for befriend this game.
       Encounter ends.

   (c) FIGHT — legal in any Duality band (this is the "violence is a choice"
       lever; a Light-band player may still choose to fight a Gift creature).
       -> draw 1 Fate Card (see §2 below for Spirit/Wild)
       -> compare: card_value + gear_bonus + affinity_bonus  VS
                   printed_F + rage_f_bonus(current Rage)
       -> WIN  (>=): 2 loot draws from the creature's ring + Duality -1
                (new fight_win shift, spec §8b "Dark lean")
       -> LOSE (<):  resolve the printed BITE text (same text as 1b-dark)
                + if Rage >= 5: discard 1 extra card from hand
                + if Rage >= 9: discard 2 extra cards from hand
       Encounter ends.
```

Physical-feasibility note: this collapses the "three printed reaction
columns" framing in spec §8b down to what actually needs unique print space
— **Demand + Gift + Bite** (2 texts, matching the creatures.md draft as
already written) — plus **F, ♥/✗**. Neutral is a fixed procedural rule
(read off the reference card/rulebook, identical for all 100 creatures), not
a third block of bespoke prose. No card needs 3 written columns; the
assignment's own "that's a lot of printed text" concern is resolved by
removing the printed Neutral column rather than shrinking it.

## 2. Fate Deck math (Q1 closed)

Deck: `1,2,2,3,3,4,4,5,5,6` (10 numeric cards) + 2 Spirit/Wild, 12 total.

P(numeric card value ≥ k), mass out of 12:

| k≥ | 1 | 2 | 3 | 4 | 5 | 6 |
|---|---|---|---|---|---|---|
| P | 83.3% | 75.0% | 58.3% | 41.7% | 25.0% | 8.3% |

**Proposed Wild resolution** (canon delta above): Light/Max Light auto-win,
Dark/Max Dark auto-lose, Neutral redraw (renormalize over the 10 numeric
cards). Resulting win probability by printed F, **no gear, no affinity, 0
Rage**:

| F | Light/MaxLight | Neutral | Dark/MaxDark |
|---|---|---|---|
| 1 | 100.0% | 100.0% | 83.3% |
| 2 | 91.7% | 90.0% | 75.0% |
| 3 | 75.0% | 70.0% | 58.3% |
| 4 | 58.3% | 50.0% | 41.7% |
| 5 | 41.7% | 30.0% | 25.0% |
| 6 | 25.0% | 10.0% | 8.3% |
| 7–9 | **16.7% (floor)** | 0.0% | 0.0% |

The 16.7% Light-band floor at F≥7 exists purely because 2/12 draws are
guaranteed wins under this band regardless of F — this is what keeps "the
top end" from being literally unwinnable (see §3).

Actual printed F values in the 100-creature draft (creatures.md): **C** avg
3.32 (25 cards, mostly F3), **U** avg 4.48 (27 cards), **R** avg 5.64 (28
cards, mostly F5–6), **L** avg 7.45 (20 cards, 12 of them exactly F7). Since
the Fate Deck's numeric ceiling is 6, **every Legendary fight is
mathematically unwinnable via the plain draw** (Neutral/Dark band, no gear)
— confirmed by creature #100's own draft text, "F 9 — practically
unfightable." This reads as intentional, not broken, but it means gear is
not optional at that tier — it's the only door in.

## 3. Gear-gating check + Rage top-end

Weapons (items/weapons-wards.md): Common +1, Uncommon +2, Rare +3, Legendary
+5 fight bonus.

Worst realistic case: Legendary creature F=9, Rage 9–10 (+3 to F) → effective
F=12. Needed card value = 12 − gear − affinity:

| Loadout | needed | P(win), Neutral band |
|---|---|---|
| No gear | 12 | 0% |
| Legendary weapon (+5) only | 7 | 0% |
| Legendary weapon + ♥ affinity (+1) | 6 | **10%** (redraw-adjusted) |
| Same loadout, Light band | 6 | **25%** (10% numeric + 16.7% wild floor, minus double-count) |

So the absolute extreme is **not unwinnable** — but only with top-tier gear
(54 CE Legendary weapon) plus favorable affinity. Without that gear it is a
genuine wall at max Rage, for anyone in Neutral or Dark band. Read this as
the closed loop it looks like: Rage climbing punishes exactly the players
most likely to have caused it (exploiting tiles, dark kits, dark spells all
raise Rage and are Dark-coded acts), and the only way out is the two
existing Rage sinks (Guardian quest step / Give Back Light, −1 each) or
investing in gear — both already-priced economic levers, so nothing new
needs to be added to close this, it just needed the wild-card rule defined
to be checkable at all.

Mid-tier sanity check, Rage 6–8 (+2 to F), Rare creature F=6 → effective F=8:
no gear = 0% (Neutral/Dark), Rare weapon (+3) → need 5 → 30% (Neutral,
redraw-adjusted). Reasonable — hard but not a wall, matches "possible but
very hard" for Dark path per spec §6.

## 4. A finding for economy/Q9 (flagged, not claimed as resolved)

`sim/economy.py::creature_yield_ce()` currently has **no loss branch** —
fight is modeled as always-win, 2 draws, which is where F2's "+9.00 CE
always-fight" headline comes from. Plugging in the win probabilities above
(illustrative Bite costs, not exhaustive — economy lane should price all
100 printed Bites):

- Common tier (F3, Neutral, no gear, 70% win, Bite ≈ −1 CE):
  `E[fight] = 0.70·(2·4.5) + 0.30·(−1) = 6.0 CE` vs `E[befriend] = 4.5 CE`
  → fighting still net-positive (+1.5 CE), but nowhere near the naive +9.
- Rare tier (F5–6 avg, Neutral, no gear, ~20% win, Bite ≈ −3 CE):
  `E[fight] = 0.20·9 + 0.80·(−3) = −0.6 CE` → **negative** — fighting a Rare
  creature unarmed is a losing bet once real loss risk is modeled, the
  opposite of F2's "violence pays" framing at that tier.

This doesn't resolve Q9 (which needs a full Monte Carlo re-run with real
Bite costs pulled from creatures.md), but it says the F2 number is an
upper bound, not the realistic EV, and that upper bound only holds at the
easiest tier.

## 5. Q10 — Temper/companion track: **OUT**

Reasoning:
- **I3 tension**: keeping a creature "in play" pulls a real card out of a
  fixed-composition deck indefinitely with no accounting for it — either the
  deck shrinks (breaking I3's printed composition) or a new "in-play zone"
  component is invented that nothing else in the corpus has.
- **Physical load**: the game already asks a human to track Duality, Rage,
  Energy (cap 5), hand limit (7), backpack (5 slots). A 6th persistent
  system — per-creature favor counts across up to 100 possible creatures,
  plus a companion slot with a swap rule — is real incremental table
  bookkeeping for a system that's explicitly still "prototype-test."
- **Unpriced economy**: companion perks are permanent passives
  (`economy-engine.md §3.3` prices only the immediate befriend reward, not
  companions) stacked on top of the still-open F2/Q9 gap. Adding a second
  unpriced permanent-bonus layer before the first is settled compounds risk.
- **Cheap to cut**: it was never committed (spec §8b says so explicitly),
  digital loses nothing (state tracking is free there, so nothing stops a
  later digital-only revival), and the chassis (Demand/Gift/Bite/Fight)
  fully stands without it — nothing else in the corpus depends on it.

Recommend: strip the rule from spec §8b (canon delta above); leave the
already-written "Companion (3♥)" cells in creatures.md untouched as
unwired reference prose (zero cost to leave them, content lane's call
whether to strip later).

## 6. What this does and doesn't close

Closes: Q1 (Wild resolution), the reaction-column ambiguity (exact
procedure above), the "3 columns = too much text" physical concern, Q10.
Contributes to but does not close: Q9 (fight_win Duality shift + the
illustrative EV check above are inputs, not the answer — needs a real
Monte Carlo with Bite costs). Does not touch: F number values themselves
(validated as workable given gear-gating is made explicit, not changed),
tier ladder, deck composition, victory thresholds.

Pytest: no invariant in GDD §3 is broken by any of the above — verified by
inspection against I1–I15; the two canon deltas (fate.json, duality.json)
are additive (fill an `OPEN` marker, add one shift trigger) and the spec
deltas are prose-only. `python -m pytest -q` was green (62 checks) going in
and nothing here changes tier ladder, deck composition, print counts,
Duality/Rage tiling, action count, or baseline economy inputs.

---

## Adversarial review

**Verdict:** NEEDS_WORK

**Math error found:** Dark/MaxDark column of the §2 F-probability table omits duality.json's existing "+1 F on all creature fights" dark-band effect: e.g. at printed F=3 the table shows 58.3% (raw, unadjusted), but with the band's own +1F applied it should be the F=4 row, 41.7% — a 16.7-percentage-point overstatement carried through every Dark/MaxDark entry in that table.

**Invariants broken:** I3 cited but not actually applicable as implemented (test_print_counts_match_composition only checks canon/decks.json's T1/T2/ascended decks, not creature cards) — a citation error in the Q10 rationale, not a broken test.

**Pillars blocked:** Balance (moderate) — the Dark/MaxDark fight-math omission and the unchecked ring-assumption in the Q9 illustration both bias the write-up toward making the Dark path look easier/more survivable than canon (dark band's existing +1F penalty) or the more conservative ring assumption would actually show, which matters directly for the still-open Q9 CE-parity question this proposal explicitly says it only partially touches.

**Physical problem:** The Dragonglass Edge (Legendary weapon, 54 CE, items/weapons-wards.md) prints "win ties automatically" as its distinguishing ability, but the proposal's base Fight comparison is already `>=` for every player — making that printed ability a dead no-op on the game's most expensive craftable item, which the proposal itself relies on in its worst-case gear-gating example without noticing the conflict.


Verified against GDD.md, canon/fate.json, canon/duality.json, canon/rage.json, canon/decks.json, items/weapons-wards.md, creatures.md, and by running `pytest -q` (62 tests green, matches the claim) and `python -m sim` (T1=4.50, T2=9.30, baseline 98.40/4.14/0.98, always-fight 107.40 — all match the doc's own claims to the reported precision). The proposal's core arithmetic mostly checks out, but I found one real internal math bug, one physical/content conflict it didn't catch, one weak invariant citation, and one unflagged assumption that can flip a headline claim.

CONFIRMED CORRECT (recomputed independently):
- Deck mass table (P(numeric≥k) out of 12) — exact.
- Light/Max Light column of the F-probability table — exact for every F, including the 16.7% floor (2/12 wild-autowin) at F≥7.
- Neutral column, including the "redraw among the 10 numeric cards" renormalization — exact for every F.
- Gear bonuses (C+1/U+2/R+3/L+5) — match items/weapons-wards.md verbatim.
- Rage f_bonus and setback_discard thresholds — match canon/rage.json's ranges exactly ([0,2]/[3,5]/[6,8]/[9,10] and [0,4]/[5,8]/[9,10]).
- Creature F averages by tier — I parsed all 100 rows of creatures.md myself: C=3.32 (n=25), U=4.481 (n=27), R=5.643 (n=28), L=7.45 (n=20, 12 exactly F7). All match the proposal's stated figures exactly, and creature #100 does carry "F 9 — the game's wall. Practically unfightable" as cited.
- Economy §4 arithmetic (6.0 CE Common, −0.6 CE Rare) is correctly derived from the win% and inputs it chose.
- pytest count (62) and sim baseline numbers match.

REAL BUG — MATH (§1/§2): the Dark/MaxDark column of the Fight-probability table silently drops an existing canon rule. `duality.json`'s "dark" band already carries `"+1 F on all creature fights"` as one of its printed effects (predates this proposal, source: spec §5/§6). The proposal's own Fight formula (`printed_F + rage_f_bonus(current Rage)`) never adds this band F-penalty, and the Dark/MaxDark column in §2's table is numerically identical to "raw printed F, no adjustment" (I checked: F=3 gives 58.3%, which is exactly the raw numeric mass — it should be the F=4 row, 41.7%, once the dark band's own +1F is applied). That's a 16.7-point overstatement of Dark-band win odds at that F, and it's inconsistent with the proposal's own selective use of `duality.json`'s "double negative effects" clause elsewhere in the same document (invoked explicitly to double Bite magnitude for max_dark, but not invoked to double/apply the dark band's F penalty). This directly contradicts the conclusion's claim that "Fight math ... [is] fully computed below" — it isn't, for the Dark column specifically.

REAL BUG — PHYSICAL/CONTENT CONFLICT (§4/§5): items/weapons-wards.md's Legendary weapon, the Dragonglass Edge (54 CE, Fire tier), has printed ability text "+5 fight; **win ties automatically**." But the proposal's base Fight resolution already uses `>=` for everyone ("compare... WIN (>=)"). Under that rule ties already auto-win for every player, with or without this weapon — so the Dragonglass Edge's unique, headline ability becomes a complete no-op. This wasn't caught anywhere in the proposal despite it directly auditing this same weapon's +5 bonus in the worst-case gear table. Either the base comparison needs to be strict `>` (creature wins ties, matching what would make this item's text meaningful) or the card text needs to be struck — as written, the single most expensive craftable item in the game (the "only door in" to Legendary fights per the proposal's own framing) loses its distinguishing ability silently.

WEAK CITATION (§5, invariants): the Q10=OUT rationale cites "I3 tension" — but I read `tests/test_canon.py::test_print_counts_match_composition` directly: it iterates only `canon/decks.json`'s entries (T1/T2/ascended resource decks). Creatures aren't tracked as a deck in canon at all (no creature-deck entry exists in decks.json), so I3 as actually implemented has nothing to do with companion persistence. This doesn't sink the Q10 recommendation — the other three reasons (physical tracking load, unpriced permanent-passive economy stacking on the open Q9 gap, cheap-to-cut-now) are sound on their own — but the I3 citation itself is not grounded in what the invariant actually checks.

UNFLAGGED ASSUMPTION (§4): the illustrative EV calc uses the same 4.5 CE (T1/outer) per-draw rate for both the Common-tier AND Rare-tier fight-vs-befriend comparison. But per economy-engine.md §3.3 and canon/decks.json, "ring" (outer T1 = 4.5 CE, inner T2 = 9.3 CE) is a board/tile property, not tied to a creature's own C/U/R/L rarity — I found no canon rule pinning Rare creatures to the outer ring. If Rare creatures skew toward the inner ring (a plausible read, given "deeper rings are progressively more difficult"), the Rare-tier calc becomes `0.20*(2*9.3) + 0.80*(-3) = +1.32 CE` — positive, not the stated −0.6 CE — which reverses the proposal's own headline claim that "fighting a Rare creature unarmed is a losing bet." The proposal already (appropriately) flags the Bite-cost sampling as illustrative/non-exhaustive, but doesn't flag this ring-assumption as the more consequential, sign-flipping uncertainty.

WHAT'S GENUINELY SOUND: the Q1 procedure is a strong piece of design work — it correctly makes the previously-OPEN Wild card resolvable with zero new printed text, gives a verified, non-zero win floor to Light-band players at any F (closing the "literally unwinnable" risk), and its Light/Neutral math is exactly right. The Q10 cut is well-reasoned on 3 of its 4 legs and doesn't break any pillar (kindness-always-available-at-a-price for the Meet-the-Demand option is correctly grounded in creatures.md's own "Kindness is always available at a price" line, not a new smuggled-in rule as I initially suspected before checking). None of the findings above are fatal to Q1 or Q10 — they're contained, fixable defects (correct the Dark-column formula, resolve the tie-break/comparison-operator conflict with the Dragonglass Edge, drop or correct the I3 citation, and re-run the illustrative EV with the ring assumption stated or checked) rather than a broken foundation.


**Strongest part:** The Q1 Wild-card resolution procedure: the Light/Neutral band probability math is independently re-derivable and exact at every F value, it requires zero new printed card text (reuses the existing Demand/Gift/Bite chassis plus one memorized procedural rule), and it correctly closes the "literally unwinnable at the top end" risk for Light-band players with a verified 16.7% floor — while still leaving Legendary fights a real, intentional gear-gated wall (confirmed against creatures.md's own "practically unfightable" text on creature #100).


## Numbers proposed

| Target | Old | New | Why |
|---|---|---|---|
| `canon/fate.json specials[0].effect` | "OPEN — Spirit/Wild resolution unspecified (GDD Q1)" | "Band-dependent: Light/Max Light band = automatic win (skip the F comparison entirely); Dark/Max Dark band = automatic loss; Neutral band = set the Wild aside face-up and draw again from the remaining numeric cards (reshuffle after resolving). Printed once on the Duality track component, not on individual creature cards." | Closes GDD Q1. Makes the Fate Deck's win probability fully computable (see proposal), gives every Light-band player a non-zero win floor at any Fight number (guarantees the top end is never literally unwinnable for kind players), and gives Dark-band players a real, math-backed extra cost for staying Dark — contributing to (not resolving) Q9. |
| `canon/duality.json shifts[] — new entry` | (no fight_win trigger exists; a fight win currently carries $0 Duality delta anywhere in canon) | { "trigger": "fight_win", "delta": -1, "phase": "action", "source": "spec §8b, 'Win: 2 loot draws + Dark lean'" } | Spec §8b's own text says a fight win carries a 'Dark lean' but no canon file prices it — a fight win is currently completely free of Duality cost, which is inconsistent with the printed rule and widens the F2/Q9 gap further than documented. This is a partial, cheap contribution to Q9, not a resolution of it. |
| `into-the-wild-spec.md §8b — 'Prototype-test (not committed): Temper/companion track' line` | "Prototype-test (not committed): Temper/companion track — ... 3 favors = companion ... Decide after paper playtest." | "Temper/companion track: OUT of v1 core rules, both builds (GDD Q10). Chassis is Demand + Gift/Bite + Fight only. The printed 'Companion (3♥)' cell in creatures.md stays as unwired reference prose for a possible future/digital-only module, not part of physical card function." | Resolves Q10. Companion persistence requires pulling a card out of fixed deck composition indefinitely (tension with I3), adds a 6th kind of per-player tracked state on top of Duality/Rage/Energy/hand-limit/backpack, and its permanent passives are entirely unpriced against economy-engine §3.3 — compounding the already-open F2/Q9 risk rather than reducing it. Digital loses nothing by cutting now; it can be re-added later without breaking 'one shared design core' since it was never committed. |