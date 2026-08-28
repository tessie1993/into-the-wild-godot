# Fan-out synthesis — decision brief

# DECISION BRIEF — Into the Wild, six-question review synthesis

All six proposals came back **NEEDS_WORK**. None is dead; none is applicable as-is. The reviews are unusually high quality — every kill-shot is a verified arithmetic or citation error, not taste.

---

## 1. RANKING — what each actually unblocks

The Q6/Q7/Q9 gating flag is **confirmed, but the internal order matters and Q7 is weaker than billed**:

1. **Q6 (VP scale)** — gates the most by a wide margin. Four of the other five proposals silently depend on a VP order of magnitude: Q7's Reach Card (`vp_reach_per_round` is OPEN pending Q6), the Guardian VP ladder, the buildings VP-scaling fix, and Q2 (give-back VP). The hypocrisy penalty (`duality.json`) makes VP-scale a forced move, not a preference: VP must share Light's order of magnitude or that rule is dead text.
2. **Q9 (fight-vs-befriend)** — gates the creature lane (Q1's resolution and Q9's exploit are coupled — see conflicts #2) and the Guardians' Dark Mirror pricing. Its structural half (sim doesn't implement specified combat; `fight_creature` trigger missing from canon) is uncontested and can ship now.
3. **Q7 (viability gate)** — flagged as gating, but it's actually *downstream*: it cannot resolve for any Way until Q6 lands, and its ceiling number is wrong for the 4D-board context it governs. It gates the 4D board/endgame only, and nothing else in this batch waits on it. **Demote it below Q9.**
4. **creatures (Q1/Q10)** — Q1 is nearly done but must wait for the Q9 decision (its auto-win reading is the exploit-enabling one). Q10=OUT can be decided today.
5. **helping (buildings)** — self-contained; mostly waits on Q6's VP scale for its reward numbers.
6. **guardians** — most blocked: needs Q6's scale AND Q9's Dark-pricing answer before its two headline numbers mean anything.

## 2. READY TO APPLY (surviving components; all six are systems-lane)

- **Q9 structural fixes** — wire real Fate-draw combat into `sim/montecarlo.py`; add the missing `fight_creature` Duality trigger to canon. Reviewer verified both gaps directly; no objection. *Systems.*
- **Q6's core insight** — VP and Light must share an order of magnitude (hypocrisy-penalty argument verified, including the penalty-firing table). The *insight*, not the 14/7/16 numbers. *Systems.*
- **Q10 = OUT** (cut Temper/companion track) — 3 of its 4 legs sound; drop the bogus I3 citation. Cheap now, expensive later. *Systems (content-lane consequence: creature card layout freezes without the track).*
- **Q1 mechanism shape** (band-based Wild resolution, zero new card text) — Light/Neutral math verified exact. Apply *after* deciding the auto-win question under Q9 (conflict #2).
- **Helping's two diagnoses** — the builder-self-interest reframe (U+ craft gating in `actions.json` verified) and the gift-farming exploit (confirmed real: `gift_card` has no cap). Diagnoses, not yet fixes. *Systems.*
- **Guardians: 3-of-6 active chains** — the 54-CE-consumes-a-game derivation survives its neighboring errors. Also the blessing design (all six routed outside CE/VP). *Systems.*

## 3. NEEDS ANOTHER PASS — the objection that must be answered

| Proposal | The load-bearing objection |
|---|---|
| **Q9** | P(win) computed from F-range *midpoints*, not the roster's actual F distribution (Common: 17×F3, 8×F4). Corrected: gap shrinks to −1.31/−3.10/**+0.41** CE, and Common-only cherry-pick fighting (5.36–5.97 CE) **beats** befriend (4.50) under 2 of 3 Q1 readings. "Honor the spec and it self-fixes" is false at the Common tier; a numerical lever (likely raising Common printed F toward the guide) is probably load-bearing. |
| **Q6** | Way2 build sums to 7, not 8 (lands exactly on the bar); an unsourced "creature-quest Light bonus"; Way3 opportunity-cost cites a `dark` band effect that doesn't exist in `max_dark`; **Rage never priced** (builds differ by 2 net Rage); Way3's descent-to-−8 precondition cost entirely missing. Thresholds must be re-derived with Rage and the Dark-unlock cost in the ledger. |
| **Q7** | `light_reach_per_round=3` derived from *main-board* deltas, but the gate only fires when the 4D board (spec §13: rewards 2x+) is active → real ceiling ≥6. Care-phase trades have no per-phase cap → up to N−1 Light. Way 3 never derived, and §13's Dark Path Exclusion (Dark players barred from 4D board) never engaged. The "fully derived" number is wrong for the only context it governs. |
| **creatures** | Dark-column fight table omits the dark band's existing "+1 F on all creature fights" (16.7-pt overstatement); base `>=` comparison makes Dragonglass Edge's "win ties" a no-op on the game's most expensive item; ring-tier assumption unflagged and sign-flipping for the Rare-tier EV claim. |
| **guardians** | Corrupt Gate priced at 1.5× the *reward cap* instead of the Light chain's *actual cost* → Dark pays 19.5 CE where Light pays 54 CE for the same 27 VP — **Dark is ~2.8× cheaper**, inverting the proposal's own purpose and worsening F2. Also: R-step cost cites the wrong invariant (~2× overstated); Energy stacking on the Master Guardian check unresolved (could add +5, not +2); no Light/Dark same-step exclusivity (VP double-dip); 3 chains vs 4 characters. |
| **helping** | ceil(22.5)=23, table prints 22 (P=5 row + slack cell); Workshop price contradicts its own stated pricing rule (18 CE unlocking a 54-CE tier); the "once per card, ever" gift fix is not physically executable (indistinguishable duplicates + reshuffle rule); defector-on-failure pays nothing (best selfish outcome); Storm omits give_back_light's −1 Rage. |

## 4. CROSS-CUTTING CONFLICTS (the proposals have not seen each other)

1. **Q6 vs Guardians — direct VP-scale contradiction, the big one.** Q6's entire thesis is a *small* VP faucet (1–8 per source, thresholds 14/7/16, "not the 3× CE ladder") forced by the hypocrisy penalty. Guardians independently built a **3/9/27 +15 = 54 VP** ladder — explicitly the CE-mirror scale Q6 rejects. One Guardian Legendary step (27 VP) nearly doubles Q6's *entire Way1 threshold* (14); a completed chain (54 VP) is ~4× it. Worse, under Q6's own mechanism a Guardian-chain finisher at Light ≈ +8–10 eats `floor((54−10)/5)` ≈ **−8 VP of hypocrisy penalty for maximally pious play** — the penalty punishing exactly the behavior Guardians reward. These two cannot both ship. (Buildings' proposed 1–3 VP and Q6's 1/2/4/8 faucet *are* compatible — Guardians is the outlier.)
2. **creatures-Q1 vs Q9 — opposite calls on the same open variable.** Creatures *resolves* Q1 as Light-band = wild **auto-win**. Q9's reviewer shows wild=auto-win is precisely the reading where the fight-vs-befriend gap flips positive (+0.41) and Common-tier cherry-picking is strongest (5.97 vs 4.50), and explicitly recommends *against* auto-win. Note the interaction is subtler than either saw: creatures' band-gating plus Q9's proposed Dark-leaning `fight_creature` trigger is partially self-correcting (habitual fighters drift out of the auto-win band) — but only if that trigger's delta is big enough, and nobody has computed the equilibrium. Resolve jointly, not in either lane alone.
3. **Q6-Way3 / Q7 / Guardians vs spec §13's Dark Path Exclusion — nobody owns Way 3.** Q6 sets Way3 at Light ≤−8; `max_dark` is where Dark Quests *unlock* (descent unpriced); Q7's gate lives on the 4D board that Dark players **cannot enter**; Q7 never derives a Dark-direction reach; Guardians' Corrupt Gate pays Guardian VP to Dark players but its board location vs the exclusion is unstated — and canon's endgame puts the Master Guardian at the 4D board's center, which Dark players can't reach. Three proposals each assume Way 3 works; combined with canon, it may be structurally unwinnable. This is a new open question none of the six surfaced alone.
4. **Care-phase gifting — three proposals, three different assumed rule-states.** Q6 flags free Care-phase Light as its Way2 loophole; Q7's ceiling silently assumes *one* trade per Care phase (uncapped in canon → up to N−1 Light); helping proposes the fix (cards-only, once-per-card) but its physical implementation fails review. Until one canonical gifting cap exists, Q6's Way2 parity and Q7's Reach Card are both built on sand. One rule closes holes in three proposals.
5. **Rage is priced by nobody and touched by everybody.** Q6's builds differ by 2 net Rage un-noted; helping's Storm Comes drops give_back_light's −1 Rage sink; Guardians stacks Island Rage onto the Master Guardian fight; Q9's bite costs ignore Rage's fight-band penalties. `round_start` +1 Rage/round means any turn-count comparison that ignores Rage sinks is comparing different games.
6. **Tie-break convention:** creatures assumes `>=` (defender loses ties) globally, which no other fight-touching proposal states and which kills the Dragonglass Edge's printed ability. Q9's corrected sim math must use whichever is chosen — a one-line ruling that changes every P(win) in two proposals.

## 5. THE ONE DECISION FIRST

**Fix the VP order of magnitude: total game VP lives on a ~0–20 track sharing Light's scale (Q6's insight, minus its specific numbers).** One sentence, no arithmetic required to decide it, and canon already forces it — the hypocrisy penalty is nonsense at any other scale.

Why it unlocks the most: it instantly invalidates-or-rescales the Guardian 3/9/27/54 ladder (conflict #1, the worst contradiction) *before* that proposal gets a second pass; it gives Q7 its missing `vp_reach_per_round` input; it fixes the buildings VP-scaling numbers; it answers Q2; and it converts Q6's remaining work from "invent a scale" to "re-run the reachability arithmetic with Rage and the Way3 descent priced." Every other decision in this batch either doesn't block the others (Q10, tie-break rule) or needs computation that itself needs this scale.

Second decision, same sitting: **rule on Q1's wild card jointly with Q9** (recommendation from the evidence: not auto-win, or auto-win only with a Dark-leaning `fight_creature` trigger strong enough to push repeat fighters out of the band — and someone must compute that equilibrium). Third: assign an owner to the new Way-3/4D-exclusion question (conflict #3) — it's currently no one's, and it may make an entire victory path impossible.