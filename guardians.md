# Guardian System — 6 Elementals, Chain Economics, Master Guardian, Dark Mirror

**Verdict:** NEEDS_WORK  ·  **Lane:** systems  ·  **Confidence:** medium  ·  **Platform:** both

**Conclusion:** The 6 elemental Guardians form a 3-step give-back chain (U→R→L) gated at Duality ≥+8, paying a tier-mirrored VP ladder (3/9/27, +15 on completion = 54 VP) plus one bounded, non-stacking passive blessing each; only 3 of 6 chains should be drawn active per game because the craft-budget/deck-EV math shows one full chain already consumes ~70-90% of a standard 15-action game. The Master Guardian's Absolute Challenge is a 3-stage Fate-deck fight (F 9/10/11, stacking with global Island Rage) that only a permanent +3 gear/skill bonus can clear, which is what actually sets the length ceiling. Dark players get a symmetric "Corrupt Gate" alternative (reusing the existing 1.5× CE premium from quests.md §2F) that pays the same VP at worse CE-efficiency and never grants a blessing — not a locked door, just a permanently worse-ROI mirror.

---

## Guardian System — full proposal

Builds on quests.md §2B (one Guardian quest per element, 3-step chain sketch), spec §4/§7/§14, and canon `victory.json` / `duality.json`. Nothing here is applied — it's a proposal for Tessa to accept, adjust, or reject, and it creates one new file, `canon/guardians.json`, that doesn't exist in canon yet.

### 1. The 6 elemental Guardians

Each Guardian sits behind its element's Guardian Gate tile (spec §4's "top tier," reachable only at Duality **+8 to +10**, the `max_light` band — this is the existing gate, not a new one). Gate condition is identical for all six: **Duality ∈ [+8, +10], checked at every step, not just once at chain start** — a player who drifts back to Neutral mid-chain loses access until they climb back. This is deliberate: it's what makes the chain a *sustained* commitment, reinforcing spec §6's "nudge medium players to pick a side."

Blessings are all: passive, permanent, capped at **once per round**, and scoped to a stat outside the core CE/VP economy (Energy, informational peeks, craft-cost trims, Rage setback mitigation, Spirit resources) — never a flat CE/gather multiplier, so they can't compound with each other or with themselves across a season of rounds into a runaway engine. See §5 for why the action-economy math makes this doubly safe.

| Guardian | Identity | Blessing (passive, once/round) | Why it's bounded |
|---|---|---|---|
| **Wood** (Jungle) — *Replant the Grove* | Patient renewal; gives without being asked | **Root and Branch** — Care-phase Sleep restores +3 Energy instead of +2 (still capped at the Energy cap of 5) | Touches Energy only, never CE/VP; a resilience QoL effect, not an engine piece |
| **Grain/Sun** (Meadow) — *Feed the Hungry* | Hospitality, communal sustenance | **Open Table** — when you Consume/Cook in Care phase, you may also restore 1 Energy to one other player at your tile, free | A *giving* mechanic — helps the table, not your own economy; reinforces pillar 3 rather than boosting the holder |
| **Stone/Fire** (Mountain/Volcano) — *The Forged Offering* | Sacrifice, transformation through fire | **Tempered Hands** — your first Craft action each round ignores 1 Common-tier requirement in its budget | A flat, small, once/round craft discount — doesn't touch fight numbers (keeps this clear of the Q9 balance question entirely) |
| **Water/Sky** (Lake/Beach) — *Carry the Tide* | Cleansing, healing corrupted ground | **Clear Currents** — once per round, ignore the Rage-band extra-discard penalty (`rage.json setback_discard`) on one setback you suffer | Pure risk mitigation; never generates CE or VP |
| **Ether/Moon** (Swamp) — *Dream Vigil* | Hidden knowledge, shared vision | **Second Sight** — once per round, peek the top card of any ring deck before committing to explore/gather there | Informational only — reduces variance, grants zero material value |
| **Spirit** (Shrine) — *The Lost Wisp* | The earned element itself; escort and care | **Guiding Light** — once per round, the first time you gain Light from any trigger, also gain 1 Spirit Mote | Spirit is earned-not-gathered (I14) already outside the CE ladder — this blessing stays outside it too |

None of the six is a combat-power buff. That's deliberate: giving the Light-committed player better fight stats would muddy the theme (Light = non-violence) and add a second, orthogonal lever onto the already-open Q9 fight-balance question. The route to the Master Guardian's own combat requirement (§4) runs through ordinary gear/skill progression, not through Guardian blessings.

### 2. Chain structure: U → R → L, rising give-back, VP + blessing on completion

Each Guardian's chain is 3 steps, matching quests.md's existing sketch, with the give-back escalating in **kind**, not just size — cost, forfeiture, then a public act:

| Step | Tier | Give-back | VP | Material reward cap | Duality |
|---|---|---|---|---|---|
| 1 | Uncommon | Spend 1 Uncommon resource of that element (destroyed/donated) | **3 VP** | ≤4.5 CE (T1 single-draw EV) | `guardian_giveback` +2 Light (existing trigger) |
| 2 | Rare | Spend 1 Rare resource of that element **+ forfeit 2 already-banked VP** (must hold ≥2 VP to attempt) | **9 VP** (net +7 after forfeit) | ≤9.3 CE (T2 single-draw EV) | `guardian_giveback` +2 Light |
| 3 | Legendary | Craft and spend 1 Legendary item of that element (54 CE budget, I11) **+ perform the chain's public board-changing act** (e.g. Wood: permanently improve the Grove tile for all players — quests.md already has this pattern per element) | **27 VP** | ≤13.03 CE (T2 draw2keep1 EV — best-documented ceiling; no dedicated top-tier deck exists yet, flagged below) | `guardian_giveback` +2 Light |
| **Completion** | — | — | **+15 VP bonus** → chain total **54 VP** | — | Unlocks the Guardian's blessing, permanently |

**Working assumption, flagged for Q6:** VP here mirrors the existing 3x tier ladder (U=3, R=9, L=27 — literally I1's numbers) rather than inventing an unrelated scale. This keeps the proposal internally consistent and legible against CE, but it is *not* a resolution of Q6 — real Way 1/2 VP thresholds are still unset. Recommendation once they exist: tune them so one completed chain (54 VP) is a major pillar of the Enlightened Path (roughly 40-60% of its threshold) without being solely sufficient — matching `victory.json`'s existing "medium" VP-threshold label for Way 2.

The completion bonus (+15, landing on 54 total) exists specifically so **stopping at step 2 isn't a trap** — step VP is proportionate at every stage (3, then 9, then 27), so a player who never finishes the chain still walked away with real value, not a dead "medium" zone. The chain only *gates the blessing* behind full completion, not the VP.

### 3. How many chains active per game — 3 of 6, and here's the arithmetic

quests.md §4 leaves this open. Computing it from the game's own numbers:

- Standard mode = **~15 main actions/player** (economy-engine.md, confirmed by `python -m sim`).
- R-step give-back (~18 CE-equivalent, matching the R craft budget in I11) at inner-ring yield **15.03 CE/action** (sim output) ≈ 2-3 gather actions.
- L-step give-back is an actual **54 CE craft** (I11) — at T2 draw2keep1 EV **13.03 CE/action** (decks.json, confirmed by sim) that's ~4-5 productive inner gathers, plus 1 Craft action, plus travel and the Quest action itself ≈ 6-7 actions.
- U-step is cheap by comparison (~2 actions).
- Sum for one chain's three steps alone: **~10-12 actions**, before counting the actions spent climbing to and holding Duality ≥+8 in the first place (`give_back_light`, `befriend_creature`, etc. — a further 2-5 actions).

**One full chain already consumes roughly two-thirds to nearly all of a standard game's 15 actions.** A second full chain (another 10-12+ actions) categorically does not fit. That means:

- **All 6 active** would mean at most 1-2 ever get finished at a real table — the other 4-5 are set dressing that inflates setup/component count for no payoff.
- **1 active** removes the character-affinity choice spec §3 promises ("element affinities differ per character") and makes one character's affinity strictly best at Way 2 every game.
- **3 active** (drawn/selected at setup, fixed for the game — not a refreshing row like the 3-card common-quest session draw, since Guardians are board fixtures) preserves the "3, not all 6" shape the game already uses for common quests (spec §7), gives real choice, and comfortably supports up to 3 players each chasing a different Guardian without collision — while still allowing two players to race the same one if they choose.

### 4. Master Guardian's Absolute Challenge

Spec §14: resides at the 4D board's third ring; defeating it triggers the endgame loop; it sets the length ceiling. Entry already requires non-negative Duality (spec §13's Dark Path Exclusion applies to the whole 4D board, not something this proposal adds).

**Design: 3 sequential Fate-deck checks, one per ring crossed, F = 9 / 10 / 11**, attempted in one visit (a single dramatic Quest action resolving all three draws in sequence; failing any stage stops the attempt and expels you back to the main board — reusing the exact "loses balance → expelled" mechanic spec §13 already defines for the 4D board, so no new no-elimination exception is needed).

The math behind 9/10/11: Fate deck numeric cards top out at **6** (fate.json); the largest single-check boost purchasable with Energy is **+2** (energy.json: 2 Energy = +2, the next tier is a *redraw*, not more points). So the "Energy-only, zero-gear" ceiling on any single check is **6 + 2 = 8**. Any F above 8 categorically cannot be cleared by luck and Energy alone — it requires a real permanent bonus (b) from gear, skills, affinity, or companion perks:

- F=9 needs b≥1 (matches the game's own worst-case Legendary creature, F 7-9 per creatures.md — consistency check, not a new number)
- F=10 needs b≥2
- F=11 needs b≥3 — **three times** the permanent-bonus investment the hardest normal fight in the game ever demands

That escalation is what actually controls pacing: a player cannot rush the Master Guardian early; they need real accumulated gear/skill progression first, which itself costs turns. And it stacks with the existing global **Island Rage `fight_modifier`** (rage.json: +1 F per 3 Rage, max +3 at Rage 9-10) — a violent table raises the effective F for *everyone* attempting the Challenge, since Rage is a shared island-wide stat. This is the theme landing entirely through mechanics (pillar 1): nobody prints "the island resists violence," the fight number just gets harder for the whole table when the table has been violent. It also means Rage mitigation (Guardian quest steps and Give Back Light actions, both of which already reduce Rage -1 per spec §5b) has real value even for players who never touch the Guardian-VP path.

Full win probability against F=9/10/11 can't be computed exactly yet: 2 of the Fate deck's 12 cards are the still-undefined Spirit/Wild specials (GDD Q1). The 9/10/11 sizing above only accounts for the 10 numeric cards and is a lower bound on difficulty — flagging the Q1 dependency rather than asserting a number that isn't fully computable.

### 5. What a Dark player sees instead — not a locked door

Canon already sketches the mirror: `duality.json`'s `max_dark` band (-10 to -8) unlocks a **Corrupt Gate**, and quests.md §2F already establishes the pattern (Dark alternative quest choices, no give-back required, **1.5x CE material premium**, shuts down Guardian blessings). This proposal applies that existing pattern specifically to each Guardian step rather than inventing a separate system:

- A Max-Dark player (-10 to -8) approaching a Guardian Gate tile finds it's the *same tile*, flipped: the **Corrupt Gate**, offering that element's Dark-mirror step.
- Requirement: same resource type, but no give-back, no public act — a pure extraction/desecration act instead.
- Cost: **1.5x the Light step's material cap** (reusing quests.md's existing figure).
- Reward: **the same VP** as the mirrored Light step (3 / 9 / 27) — no completion bonus, no blessing, ever.

Computed effect on the Q9 tension (F2 found violence is currently +9 CE / +9% more profitable than kindness): paying 1.5x the input cost for the *same* VP output is a **33% worse VP-per-CE efficiency** than the Light chain for an identical VP number. That's a real, computed counterweight to F2's finding — not a full resolution of Q9 (that needs the fight-loot math too), but a piece of it that a Dark player can see and reason about, rather than a wall. Neutral players (-7 to +7) get neither gate — that's correct as-is; spec §6 explicitly wants the system to "nudge medium players to pick a side," and this is where that nudge lives.

### 6. Budget compliance summary

- Material rewards at every step are capped at that ring's single-draw EV as printed in `decks.json` (4.5 / 9.3 / 13.03 CE) — computed from canon, not asserted, and safely under economy §3.4's "≤1 draw of the ring tier" rule.
- VP is the dominant reward at every step (3-27 VP vs 4.5-13 CE material) — VP stays primary throughout, as economy §3.4 requires.
- No blessing touches the CE gather/craft numbers the sim and `test_economy.py`/`test_baseline.py` check — I13 (income ahead of sinks) and I12 (baseline reproducibility) should not need re-verification, but are listed as touched for review since six new passive effects are still six new things to check against the baseline.


---

## Adversarial review

**Verdict:** NEEDS_WORK

**Math error found:** (1) §5's Dark Corrupt Gate cost is defined as 1.5x the step's `material_cap_ce`, which the proposal's own §2 table defines as the Light chain's REWARD cap, not its give-back COST. At step 3 the real Light cost is 54 CE (I11 Legendary craft budget, stated explicitly) vs. Dark's 1.5x13.03=19.545 CE — Dark is ~2.8x cheaper for identical 27 VP, not "33% worse efficiency" as claimed. (2) §3's R-step action-cost math cites "~18 CE-equivalent, matching the R craft budget in I11" for a step that only requires spending one raw Rare resource card (9 CE per I1's tier ladder, or 9.3 CE to acquire per the proposal's own T2-single-draw-EV citation used elsewhere in the same document) — I11's 18 CE is the budget for crafting a full Rare-tier item, not the value of a raw Rare card, roughly doubling the stated R-step action cost.

**Pillars blocked:** Duality (kindness advantageous, never forced) — as computed in §5, the Dark Corrupt Gate is ~2.8x cheaper in CE than the Light give-back for identical VP at the Legendary step (19.5 CE vs 54 CE for 27 VP), making Dark the dominant-efficiency route to Guardian VP rather than a 'worse-ROI mirror,' which worsens F2's already-open Q9 imbalance instead of counterweighting it.

**Physical problem:** None fatal — a 3-stage sequential Fate-draw boss fight and per-step Duality checks are both hand-computable at the table. The one table-level hazard is rules ambiguity, not computability: energy.json's spend menu doesn't state whether the same boost option can be applied more than once to a single check, so two players could legally resolve the Absolute Challenge differently unless that's pinned down before printing.


Verified against GDD.md, canon/*.json, quests.md, creatures.md, economy-engine.md, and `python -m sim` / `pytest -q` (all 30 tests pass, unaffected since nothing is applied yet). Most of the proposal's arithmetic is genuinely computed from canon, not asserted — but two of the load-bearing numbers are wrong, and one of them inverts the exact effect (§5's Q9 counterweight) the proposal is built to demonstrate.

**1. MATH — the Dark "Corrupt Gate" cost is computed against the wrong baseline, and at the highest-value step this makes Dark drastically CHEAPER than Light for the same VP.**
§2's own step table defines `material_cap_ce` as the REWARD cap you *receive* on the Light chain (economy §3.4's "≤1 draw of ring tier" rule) — 4.5 / 9.3 / 13.03 CE for steps 1/2/3. §5 then defines the Dark alternative's COST as "1.5x the Light step's material cap," i.e. 1.5× that same reward-cap number: 6.75 / 13.95 / 19.545 CE. But the Light chain's actual give-back COST at step 3 is not 13.03 CE — it's an explicit 54 CE Legendary craft (I11), stated two paragraphs earlier in the same table. So at step 3: Dark pays **19.5 CE** for 27 VP; Light pays **54 CE** (plus a public act, plus holding Duality ≥+8) for the same 27 VP. That's Dark at roughly **36% of Light's cost for identical output — Dark is ~2.8x more CE-efficient, not "33% worse."** The §5 claim ("a real, computed counterweight to F2's finding") is backwards at exactly the step carrying half the chain's pre-bonus VP and the single largest CE number in the whole proposal. The fix is mechanical (multiply 1.5x against the Light step's actual give-back cost — 4.5-ish / 9 / 54 CE — not the reward cap), but as written the "Numbers set" entry for `dark_mirror.cost_multiplier` ships an inverted number.

**2. MATH — the R-step action-cost estimate cites the wrong invariant.** §3's chain-count arithmetic states "R-step give-back (~18 CE-equivalent, matching the R craft budget in I11)." But step 2 as defined in §2 doesn't craft anything — it says "Spend 1 Rare resource of that element," a single card worth 9 CE by I1's own tier ladder (R=9), or ~9.3 CE to acquire via a T2 draw (the proposal's own reward-cap logic for that very step). I11's 18 CE is the budget for *crafting a full Rare-tier item* — irrelevant here, unlike step 3 where a craft really is specified. This overstates the R-step's action cost roughly 2x (2-3 actions vs. a more realistic ~1). It doesn't overturn the top-line conclusion (the 54 CE Legendary step alone dominates the 15-action budget), but it's a citation error inside a section explicitly claiming to be "computed from the game's own numbers," not estimated.

**3. Unverified assumption doing heavy lifting in §4.** The Master Guardian sizing (F=9/10/11) rests on "the largest single-check boost purchasable with Energy is +2." energy.json's spend table lists three cost-tiers of options with no stated "once per check" or "pick one" restriction, and the actions.json turn model says Energy may be "spent anytime on your turn." If a player may apply the 1-Energy/+1 option repeatedly to the same check (nothing in canon forbids it), a player at the 5-Energy cap could add +5 to one draw, making the "energy-only ceiling" 11, not 8 — clearing F=11 with zero permanent gear bonus and defeating the "this is what actually sets the length ceiling" claim. This is a pre-existing canon ambiguity, not one the proposal introduced, but the proposal treats one reading as settled fact to derive its headline pacing number; it should either cite an explicit "one boost per check" rule or flag this as an open dependency the way it correctly flags Q1.

**4. Degenerate play — no stated exclusivity between a step's Light and Dark versions for the same player.** §3 explicitly allows "two players to race the same [Guardian]," which implies chain progress is tracked per-player rather than as a single consumable board card. Nothing in §5 states that completing a step's Light give-back locks out that player from later swinging Dark and also claiming the Corrupt Gate mirror of the *same* step (or vice versa) — each pays VP independently. Absent an explicit "one side per step per player, permanently" rule, a Duality-swinging player could double-dip VP on a step.

**Minor:** "3 active chains... comfortably supports up to 3 players... without collision" glosses over the game having 4 characters (GDD §2); a 4th player has no non-colliding Guardian by construction. Also, "Duality checked at every step" is described as forcing "sustained commitment," but as written it only requires being at +8..+10 at the discrete moments each Quest action resolves — a player can legally dip to Neutral between steps and re-climb just before each one, which is a real design choice but is described as tighter than it is.

**What's actually solid:** the blessing design is clean — every one of the six is explicitly routed outside CE/VP (Energy, peeks, craft-discount, setback mitigation, informational, Spirit-only) specifically so it can't compound into a runaway engine, and that reasoning is sound and well-argued. The core structural insight of §3 — that a single Legendary give-back (54 CE, I11) at T2 draw2keep1 EV (13.03 CE/action, confirmed by `python -m sim` to the second decimal) consumes 4-5 gather actions plus a craft and quest action, so one full chain eats most of a 15-action standard game (`modes.json: turns_per_player: 15`, confirmed) — is correctly derived and survives even after correcting finding #2, and it's the right call (3 of 6, not all 6 or 1). The Fate-deck ceiling analysis (deck max 6, per fate.json's `[1,2,2,3,3,4,4,5,5,6]`) and the creature-F cross-check (Legendary creatures F 7-9, confirmed in creatures.md) are both accurately cited. I1, I13, I14 are correctly not broken by the mechanism as designed, though I13 (income ahead of sinks) is asserted rather than sim-verified for an actual Guardian-chasing action profile — the proposal itself flags this appropriately rather than overclaiming.


**Strongest part:** The passive-blessing design: all six blessings are deliberately routed outside the CE/VP economy (Energy, informational peeks, a bounded craft discount, setback mitigation, or Spirit-only), explicitly so none can compound with itself or each other into a runaway engine — this cleanly sidesteps the balance risk that usually comes with "unlock a permanent bonus" mechanics, and the reasoning for why is stated, not just asserted. The §3 chain-count conclusion (3 of 6 active) is also well-earned: the Legendary step's 54 CE give-back against sim-confirmed T2 draw2keep1 EV (13.03 CE/action, matched to two decimals by `python -m sim`) correctly shows one full chain consumes most of a standard 15-action game, which is the right basis for capping active chains below 6.


## Numbers proposed

| Target | Old | New | Why |
|---|---|---|---|
| `canon/guardians.json (new file) — chains[].steps[].vp_reward` | unset (OPEN, GDD Q6) | U=3 VP, R=9 VP, L=27 VP | mirrors the existing 3x tier ladder (I1: C=1,U=3,R=9,L=27) onto VP so the number is derived, not invented, and stays legible against CE — flagged as a WORKING ASSUMPTION pending Q6's real VP scale |
| `canon/guardians.json — chains[].completion_bonus_vp` | unset | +15 VP (total chain = 3+9+27+15 = 54 VP) | rewards finishing over stopping at step 2 without making intermediate steps worthless (avoids a dead 'medium' zone per spec §6); 54 echoes the Legendary craft budget (54 CE, I11) as a deliberate mnemonic, not a new mechanic |
| `canon/guardians.json — chains[].steps[1].vp_forfeit` | unset | -2 VP, prerequisite: banked VP ≥2 | literalizes quests.md's 'VP-removal moments' as the R-step's escalating give-back — net step value stays positive (9-2=7) but requires the player to have something to lose |
| `canon/guardians.json — meta.active_chains_per_game` | OPEN (quests.md §4: 'all 6 or a drawn subset?') | 3 of 6, drawn/selected at setup, fixed for the game | craft-budget math: R-step needs ~18 CE (2-3 inner gathers @15.03 CE/action), L-step needs 54 CE (~4-5 inner gathers @13.03 CE draw2keep1 + 1 craft), so one full chain costs ~10-12 of 15 total actions before gate-access overhead — a second full chain cannot fit in a standard game, so 6 simultaneous chains would only ever see 1-2 actually finished; 3 preserves the spec §7 'draw 3, not all' pattern and gives up to 3 players a non-colliding Way-2 target |
| `canon/duality.json — bands[max_light].guardian_chain_gate (clarifying note, not a new band)` | implicit ('Guardian Gate unlocked' at +8..+10) | codified: every Guardian Quest step (not just the Gate tile itself) requires Duality in [+8,+10] at the moment the Quest action resolves | closes a gap — without this, a player could spike to +8 once, do the whole chain, then drift back to Neutral; checking per-step keeps the 'sustained kindness' cost real and reinforces spec §6's 'nudge medium players to pick a side' |
| `canon/guardians.json — chains[].steps[].material_cap_ce` | unset (economy §3.4 only states the rule, not values) | U step ≤4.5 CE (T1 single-draw EV), R step ≤9.3 CE (T2 single-draw EV), L step ≤13.03 CE (T2 draw2keep1 EV — best-documented ceiling; no dedicated 'Guardian realm' deck exists yet) | computed directly from decks.json's own claimed_ev fields rather than inventing a new number, honoring the ≤1-draw-of-ring-tier budget in economy §3.4 |
| `canon/guardians.json — master_guardian.stages[].F (or canon/fate.json note)` | unset (spec §14 names the Absolute Challenge, no numbers) | 3 sequential Fate-deck checks, F = 9 / 10 / 11, plus Island Rage's existing fight_modifier (+0..+3) stacks on all three | Fate deck max numeric card=6, max single-check Energy boost=+2 (energy.json spends table) → the 'energy-only' ceiling is 8. Any F>8 categorically requires a real permanent gear/affinity bonus (b). F=9/10/11 needs b≥1/2/3 respectively — b≥1 already matches the existing L-tier creature ceiling (F=7-9), so stage 3 deliberately demands 3x the permanent-bonus investment of the hardest normal fight in the game, which is what turns 'defeat the Master Guardian' into a real late-game gate rather than a lucky roll |
| `canon/guardians.json — dark_mirror.cost_multiplier` | already canon at the quest-type level (quests.md §2F: 1.5x CE premium) | applied specifically to each Guardian step: Dark alt pays 1.5x the step's material_cap_ce for the SAME VP, no give-back, no blessing ever | computed Q9-aware: same VP at 1.5x input cost = 33% worse VP/CE efficiency than the Light chain for identical VP, which is a real (if partial) counterweight to F2's +9 CE fight-vs-befriend advantage without arbitrarily cutting the Dark VP number |