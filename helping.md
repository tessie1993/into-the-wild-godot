# Public Buildings & the Helping-Players Dynamic

**Verdict:** NEEDS_WORK  ·  **Lane:** systems  ·  **Confidence:** medium  ·  **Platform:** both

**Conclusion:** Buildings and the free-rider problem resolve: a builder isn't a charity donor, they're buying access to Uncommon+ crafting they need themselves (canon/actions.json already gates U+ craft behind Bench/Forge adjacency) — the +2 Light/VP is a bonus on top of self-interest, not the whole case. The Give Back Light Light-reward is correctly priced (3 CE/Light, matching the existing gift market rate) only for the two 6‑CE buildings; the three 18‑CE buildings are 3x overpriced in Light terms at the printed flat +2, so I recommend scaling VP instead of Light to fix it. The Storm Comes quest works as a pooled (not per-player) threshold with deliberate slack so one holdout can't sink the table — that keeps it a real choice, not compulsion. Gift-farming is a real, currently-open exploit: unlimited reciprocal gifting produces unbounded free Light; closing it needs two changes (cards-only, and each physical card earns gift-Light once in its lifetime).

---

## Buildings & the Helping-Players Dynamic

### 0. What already exists that changes the shape of this problem

`canon/actions.json` (craft action) already requires: Uncommon/Rare crafting must happen **on or adjacent to a Crafting Bench or Forge**; Legendary requires **bench + a player-built Workshop**. This is load-bearing and was easy to miss reading spec §16 alone (which frames buildings as only gating *refined resources*). In practice: **without a Bench or Forge on the board, nobody — not even the builder — can craft anything Uncommon tier or above.** Three of the four item tiers (18 of the 4-tier depth system, pillar 4) are dead until someone builds. That single fact does most of the work in the free-rider question below.

### 1. Building catalogue

| Building | Domain (proposed) | Cost | Gates craft-adjacency (U/R)? | Refines | Who may use |
|---|---|---|---|---|---|
| **Bench** (Crafting Bench) | Wood / general | **6 CE** (U budget) | Yes | Wood raws (e.g. Resin→Varnish) | any player on the tile |
| **Kiln** | Grain/Sun | **6 CE** (U budget) | No — refining-only | Grain/Sun raws (Grain→Flour, Honey→Wax) | any player on the tile |
| **Forge** | Stone/Fire | **18 CE** (R budget) | Yes (alt to Bench) | ore→ingot (Copper Ore→Copper Ingot, per crafting.json's own example) | any player on the tile |
| **Apothecary Hut** | Water/Ether | **18 CE** (R budget) | No — refining-only | Water/Ether raws (Mushroom/Kelp→Tincture) | any player on the tile |
| **Workshop** (new) | — | **18 CE** (R budget), must sit on a tile that already has a Bench | Legendary-tier, paired with Bench | — | any player on the tile |

Costs match I11's ladder exactly (6/18, i.e. U/R budgets) rather than inventing new numbers — a building costs the CE budget of the crafting tier it unlocks access to. All five are built via the existing `give_back_light` action (n6), which already lists "build a shared Crafting Bench" among its acts; Kiln/Forge/Apothecary Hut/Workshop just need adding to that acts list.

### 2. The free-rider problem, computed

**Thesis: it works, but not for the reason spec §16 implies.** It is not "kind stranger pays so everyone else benefits." It is "a player who needs Uncommon+ crafting pays for the thing they need, and everyone else gets to use it too as a side-effect." That reframing is the actual mechanical expression of pillar 3 — *taking care of others is also taking care of yourself* — not a slogan bolted onto the action.

**Raw CE comparison, builder vs. free-rider, for a Bench:**

| | CE spent | Light | VP (proposed) | Rage (table-wide) | Own U+ crafting unlocked |
|---|---|---|---|---|---|
| Builder | −6 | +2 | +1 | −1 | immediately, on their own tile |
| Free-rider | 0 | 0 | 0 | −1 (free) | only by traveling to the builder's tile |

In pure CE, the free-rider is strictly ahead (0 vs. −6) and still gets the table-wide Rage relief for free. That's real, and I'm not going to pretend otherwise — it's the correct outcome for pillar 3 (kindness must never be *forced*, and a rational CE-maximizer is allowed to free-ride).

What the free-rider gives up is **Light and VP**, which are not flavor — `canon/victory.json` makes Way 2 (Enlightened) Light-gated and Way 1's tiebreaker is "higher Light wins." A player who only ever free-rides is opting out of an entire victory path and a tiebreaker, in exchange for CE they were probably going to spend on gathering/crafting anyway. That is exactly the intended tension (mirrors F2/Q9: Dark/selfish play is materially richer, Light/cooperative play wins a different way) — I'd call this **consistent with, not a fix for,** Q9's open imbalance, so it inherits that risk rather than solving it.

**Is the Light/VP reward actually priced right, though?** Computed the "market rate" from *existing* Light triggers: gifting an Uncommon card = 3 CE/Light (the cheapest card, so the rational floor); a minimum generous trade = 3 CE/Light also. So **3 CE per Light is the going rate.**

| Building | Cost | Flat +2 Light rule (as printed in spec §16) | CE/Light | vs. market rate (3) |
|---|---|---|---|---|
| Bench / Kiln | 6 CE | +2 Light | **3.0** | matches |
| Forge / Apothecary Hut / Workshop | 18 CE | +2 Light | **9.0** | **3x worse** |

That's a real, computed problem: at the printed flat +2 Light, a Light-maximizing player strictly prefers gifting six separate Uncommon cards (18 CE → 6 Light) over building a Forge (18 CE → 2 Light). The 18-CE buildings are still worth building **for their utility** (Rare-tier access nobody else provides), but they are a bad deal specifically as a "kindness" play, which undercuts the pillar. Two fixes, pick one:

- **Recommended — scale VP, not Light:** keep the printed +2 Light flat (leave spec §16's number alone), but scale the *VP* reward with cost tier: 1 VP per 6 CE given back → Bench/Kiln = 1 VP, Forge/Apothecary Hut/Workshop = 3 VP. Smaller swing on the Duality track (which the +2 Light already sits well within), one new small table, resolves GDD Q2 in the process.
- **Alternative — scale Light too:** Forge-tier buildings grant +3 Light instead of +2 (18/3 = 6 CE/Light — still worse than the 3 CE/Light floor but only 2x, not 3x). Bigger single-action Duality swing to weigh: the current largest single trigger is `dark_quest` at −3; +3 would tie it, +6 (to fully match the 3 CE/Light rate) would be the single largest swing in the game and I'd flag that as risky without more playtesting.

I recommend the VP option — it doesn't touch the Duality table at all, and Q2 needs an answer regardless.

### 3. The Storm Comes, computed

Spec text: *"every player contributes X CE by round N or ALL take a setback."* Read literally — every individual player, not a pool — one holdout punishes the whole table regardless of what anyone else did. That's a single player able to force a bad outcome on everyone else purely by declining, which is compulsion pressure dressed as an island event, not a free choice with stakes. I'm proposing a **pooled threshold** instead, which keeps the "storm hits if you don't prepare" fiction but removes the single-defector veto:

- **X = 6 CE/player** (Uncommon budget — one item's worth, a real but modest ask)
- **N = round 6** of Standard mode (~15 rounds) — by then a player has banked roughly 39 CE (6 × 6.5 CE/turn average), so X is ≈15% of banked wealth, not a hoarding-breaker
- **Pooled threshold Y = ceil(0.75 × P × X)** — computed per table size:

| Players (P) | Full pool if everyone pays | Threshold Y (75%) | Slack (defection room) |
|---|---|---|---|
| 2 | 12 CE | 9 CE | 3 CE (~0.5 player-shares) |
| 3 | 18 CE | 14 CE | 4 CE (~0.7 shares) |
| 4 | 24 CE | 18 CE | 6 CE (~1.0 share — one full defector, table still succeeds) |
| 5 | 30 CE | 22 CE | 8 CE (~1.3 shares) |
| 6 | 36 CE | 27 CE | 9 CE (~1.5 shares) |

At P=4 (typical table), the pool absorbs exactly one player contributing nothing without failing — the design brief's "or ALL take a setback" stays true (mass defection still fails everyone) without one person being able to unilaterally sink three cooperative players. Below P=3 there's less slack, which is fine — small tables genuinely can't out-cooperate a holdout as easily, and that's an emergent, not designed-in, property.

**Numbers:**
- Contribute (paid ≥6 CE into the pool): **+2 Light, +1 VP**, applied immediately on paying in (encourages early giving, matches how `give_back_light` already resolves instantly)
- Pool reaches Y by round N: quest succeeds. Non-contributors get **−1 Duality** (Dark drift, as the brief specifies) but **no setback** — they benefited from others' generosity, which costs them standing, not tempo. This is the "advantageous, never forced" line: defecting is a real, viable choice with a real cost, not a trap.
- Pool misses Y: **every player** (contributors included) takes the Storm Setback: **discard 1 resource-deck card of choice + lose 2 Energy (min 0)**. Contributors keep the Light/VP they already banked — sunk, not clawed back. No HP, no elimination, no skipped turn — compliant with the standing constraints.

EV check: a defector who free-rides on a successful pool nets 0 CE / −1 Duality; a contributor nets −6 CE / +2 Light / +1 VP. In raw CE the defector is ahead, same shape as the building case — deliberately consistent rather than a special-cased exception.

### 4. Gift-farming — confirmed exploitable, here's why and the fix

Checked it directly: `canon/duality.json`'s `gift_card` trigger is +1 Light per gift, in the Care phase, with **no cap and no scope restriction**, and `economy-engine.md` §2 explicitly extends it to "cards **or tokens**." Nothing in the corpus stops two players from gifting the same item back and forth every Care phase.

- **Token version is the worse hole.** Commons are unlimited-supply, fungible wooden cubes — physically identical, so there is no way to mark "this cube already scored" (unlike a named card). Two players sitting on adjacent tiles could gather 2 Commons/turn each and swap tokens every Care phase for unbounded +1 Light/round each, forever, for a trivial 1-CE-per-round cost that regenerates every turn.
- **Card version is real but boundable.** A → B gifts Card X (+1 Light to A), next Care phase B → A gifts Card X back (+1 Light to B). Repeats indefinitely at zero net CE cost (same card, no value actually left the pair's combined economy).

**Fix (two parts, both needed):**
1. **Cards only.** Restrict `gift_card`'s Light bonus to named Uncommon+ cards; Commons stop earning Light on gift (they can still be gifted freely for hand-space/goodwill, just no Duality shift — consistent with the existing rationale in §2, which ties gifting-for-Light to hand-space relief, a problem Commons don't even have since they're unlimited-carry).
2. **Once per card, ever.** The first time a specific physical card is gifted for Light, mark it (a small sticker/token under it works physically; a boolean flag digitally). A marked card can still be freely traded/re-gifted for its game function, but never earns Light again for anyone. This caps the "back and forth" case at exactly **+1 Light total**, not infinite — the second (return) gift earns nothing, so there's no longer a loop to exploit, only a single legitimate transfer.

This doesn't touch `generous_trade_3ce` (multi-item trades), which is a smaller, harder-to-execute version of the same hole — flagged as an open risk above rather than fixed here, since it needs a rolling-window/per-pair cap that adds real bookkeeping and the assignment's specific example (a single card back and forth) is fully closed by the above.

### 5. Cross-reference

The pooled-contribution mechanic for Storm Comes is the same shape as "Build the Bridge" and "Raise the Beacon" (quests.md §2C) — I'd reuse it there rather than inventing a third pattern: any of those public-works quests can be built from partial contributions summing to a threshold, with the same "one Give Back Light action per contribution" resolution the building catalogue above already uses.


---

## Adversarial review

**Verdict:** NEEDS_WORK

**Math error found:** Storm Comes threshold table: Y = ceil(0.75×P×X) with X=6 gives ceil(22.5)=23 at P=5, not the printed 22; the dependent "slack" cell is off by 1 CE as a result (should be 7 CE / ~1.17 shares, not 8 CE / ~1.3 shares). All other rows (P=2,3,4,6) are correct. Separately, Workshop's price (18 CE) contradicts the proposal's own stated pricing rule ("cost = CE budget of the tier it unlocks") since it unlocks Legendary tier (54 CE budget per I11) at a 1:3 ratio versus every other building's 1:1 ratio — a real inconsistency between the stated rule and the applied number, not just a rounding slip.

**Physical problem:** Card-marking fix for gift-farming: "once per card, ever" is ambiguous between per-game and permanent-across-replays (sticker vs. token-underneath give different answers, and the proposal never picks one); and canon/decks.json confirms multiple physically-identical duplicate cards exist per resource name (T1: 30 Uncommon prints from a small name set) with no serial numbering anywhere in the corpus, while decks.json's own exhaustion rule reshuffles discards into a new deck — the fix never says what happens to a card's mark when it re-enters that shuffle among indistinguishable duplicates, which is exactly where a hand-tracked mark breaks.


Verified against GDD.md, canon/actions.json, canon/duality.json, canon/crafting.json, canon/decks.json, canon/victory.json, canon/rage.json, economy-engine.md, quests.md, and tests/test_integrity.py + test_economy.py, plus `python -m pytest -q` (30/30 pass, unaffected by this proposal since it's a numbers-only doc).

STRONGEST PART: the building free-rider reframe and the gift-farming diagnosis are both genuinely well-sourced, not asserted. `actions.json`'s craft action really does gate Uncommon+ crafting behind "on or adjacent to a Crafting Bench or Forge" — I checked it directly, and it really is easy to miss from spec §16 alone, which frames buildings as gating only refined resources. The 3 CE/Light "market rate" is correctly derived from I1's own tier ladder (C=1,U=3,R=9,L=27 — Uncommon is the cheapest *card*, since I2 makes Commons off-deck tokens), so the claim that Forge/Apothecary Hut/Workshop are 3x overpriced in Light terms at a flat +2 is real arithmetic, not assertion (18/2=9 vs 6/2=3). And the gift-farming exploit is confirmed exploitable exactly as described: `duality.json`'s `gift_card` trigger has no cap or scope field (unlike `generous_trade_3ce`, which does have a condition), and economy-engine.md §2 literally says "cards or tokens," so unbounded reciprocal gifting for +1 Light/Care-phase is real. Good, specific detective work.

FOUR concrete problems, in order of what the review checklist asks for:

1. MATH ERROR in the Storm Comes threshold table. Y = ceil(0.75 × P × X) with X=6: at P=5, 0.75×5×6 = 22.5, and ceil(22.5) = 23 — the table prints **22**. That's not a rounding-convention choice, it's arithmetically wrong given the formula stated one paragraph earlier. It also silently corrupts the derived "slack" cell: with the correct Y=23, slack is 30−23=7 CE (~1.17 shares), not the printed "8 CE (~1.3 shares)." Every other row (P=2,3,4,6) checks out exactly, which makes this look like a one-off transcription slip rather than a systemic error — but the proposal explicitly frames this table as "computed per table size," so it needs a real fix, not a caveat.

2. INTERNAL INCONSISTENCY in Workshop pricing vs. the proposal's own stated rule. Section 1 states the pricing principle as "a building costs the CE budget of the crafting tier it unlocks access to," and calls this "matching I11's ladder exactly." Workshop unlocks Legendary-tier crafting (I11 budget = 54 CE) but is priced at 18 CE (Rare budget) — a 1:3 ratio, versus Forge's 1:1 (18 CE building unlocking the 18 CE Rare budget). The Numbers-set justification for this (keep Bench+Workshop+item under one player's solo lifetime income) is a defensible design choice on its own, but it directly contradicts the blanket rule stated as the rationale for all five costs, and the contradiction isn't acknowledged. It also compounds into the VP-scaling fix: Forge, Apothecary Hut, and Workshop all get the same "3 VP" reward under the proposed tier bucketing, even though Workshop delivers proportionally far more value (unlocks a 54-CE tier) for the same nominal 18-CE "given back" — which undercuts the very logic ("reward should track CE actually given back") used to justify scaling VP by cost tier in the first place.

3. PHYSICAL FEASIBILITY gap in the flagship gift-farming fix — this matters because the proposal claims "Claims physically feasible: true." "Each physical card may earn gift-Light exactly once in its lifetime" is ambiguous between "for this game" and "for as long as the physical component exists across every future replay of the box," and the proposal's own suggested implementations span both readings: a sticker is a permanent, irreversible mark that would progressively strip gift-Light eligibility from the deck across a group's entire ownership of the game (never flagged as a risk), while a token-underneath is naturally session-scoped. More seriously: `canon/decks.json` shows T1 alone prints 30 Uncommon and 10 Rare cards from a much smaller set of resource names (e.g. Copper Ore), meaning multiple physically-identical duplicate cards exist in the shared deck, with no serial numbering anywhere in the corpus. `decks.json` also specifies "exhaustion: shuffle that ring's discards into a new deck." The fix never addresses what happens to a card's mark when it's discarded and reshuffled among indistinguishable duplicates — a detachable token can't survive that by hand, and a permanent mark reintroduces problem (1). As specified, "mark this exact physical card, forever" is not obviously executable at a physical table with the components this game actually has.

4. Unaddressed asymmetry in the Storm Comes numbers (Duality pillar, minor). The proposal specifies non-contributors take −1 Duality only "quest succeeds (pool ≥ Y)"; it is silent on non-contributors' Duality when the quest fails. Read literally, a defector who correctly predicts the pool will fail pays nothing at all — no CE, no Duality shift, same universal setback as a contributor who spent 6 CE. That's strictly the best outcome in the whole payoff table for a purely selfish agent, and it sits oddly next to the proposal's framing of the pooled fix as removing compulsion "while keeping it a real choice" — the fix does solve the single-holdout-veto problem it targets, but leaves a related, uncomputed incentive to hope for (or engineer) failure that the write-up doesn't acknowledge.

Two smaller notes: the proposal's own "invariants touched" list cites I8 (exploit_tile costs Light and raises Rage), but nothing in this proposal touches the exploit_tile trigger at all — that citation looks like a misattribution, not a real interaction (I checked test_integrity.py's actual I8 test, which only concerns move_explore_gather's exploit_tile duality/rage pair). And the Storm-Comes contribution reward table lists only "+2 Light, +1 VP" while claiming to reuse the give_back_light action's resolution exactly — but give_back_light also carries a −1 Rage sink per `rage.json`, which the Storm Comes numbers omit and never address for stacking across multiple contributors in one event.

None of this breaks a named invariant or a pillar outright — the core reasoning (self-interest resolves the free-rider "problem," the gift-farming loop is real, pooling averts a single-holdout veto) is sound and well-evidenced. But there's a genuine arithmetic error, a self-contradicting pricing rule, an unflagged physical-production risk in the one fix explicitly marked "physically feasible," and an uncomputed incentive gap — enough concrete, fixable problems that this shouldn't go in as-is.


**Strongest part:** The building free-rider reframe (self-interest via the craft-adjacency gate already in actions.json, not charity) and the gift-farming exploit diagnosis (unbounded reciprocal Light from an uncapped, unscoped gift_card trigger, correctly quoted from duality.json and economy-engine.md §2) are both directly verified against source text rather than asserted, and the 3 CE/Light market-rate derivation from I1's tier ladder is correct arithmetic.


## Numbers proposed

| Target | Old | New | Why |
|---|---|---|---|
| `canon/crafting.json refining.buildings — add a cost_ce field per building` | unspecified (buildings list exists, no costs) | Bench 6 CE, Kiln 6 CE, Forge 18 CE, Apothecary Hut 18 CE | Costs must fit the crafting-budget ladder (I11). Setting cost = the CE budget of the crafting tier each building gates: Bench/Kiln open Uncommon-tier access (6 CE budget) at the point most players first need it; Forge/Apothecary Hut open Rare-tier access/refining (18 CE budget), built later once Rare crafting matters. |
| `canon/crafting.json budgets[legendary].bench — new building 'Workshop' to satisfy 'bench_and_workshop'` | no buildable object exists anywhere in the corpus that satisfies this requirement | Workshop, 18 CE, must be built on a tile that already has a Bench | crafting.json already requires bench_and_workshop for Legendary crafts but nothing builds a Workshop. Pricing it at Rare budget (not Legendary's 54) keeps total infra+item cost (Bench 6 + Workshop 18 + item 54 = 78 CE) inside one player's ~98.4 CE lifetime income if solo, while still making group-splitting clearly the smarter play — computed: 78/98.4 = 79% of lifetime income for a single Legendary craft, solo. |
| `canon/actions.json give_back_light.reward (resolves GDD Q2) — VP amount` | 'small VP reward — amount UNSPECIFIED (GDD Q2)' | provisional rate: 1 VP per 6 CE given back, rounded → Bench/Kiln = 1 VP, Forge/Apothecary Hut/Workshop = 3 VP | Q2 is explicitly open and buildings are the clearest Give-Back-Light case to anchor it. Rate chosen so the 6-CE tier (already Light-correctly-priced) also gets a token VP, and the 18-CE tier gets 3x the VP to partially offset its worse Light-per-CE rate (computed below). Marked provisional — the absolute VP scale is gated on Q6. |
| `canon/duality.json shifts[gift_card] — restrict scope and add a per-card cap` | trigger 'gift_card', delta +1, phase 'care', no scope restriction; economy-engine.md §2 explicitly extends it to 'cards or tokens' | gift_card Light applies to named Uncommon+ cards only (excludes Common tokens); each physical card may earn gift-Light exactly once in its lifetime (mark it on first use) | Computed exploit: two players can gift the same item back and forth every Care phase for unbounded +1 Light each, forever, at zero net CE cost. Tokens make it worse because they're fungible and physically unmarkable (can't tag 'this cube already scored'), so excluding them is the only clean physical fix; card-marking caps the reciprocal-gift case at exactly +1 Light total instead of infinite. |
| `quests.md §2C 'The Storm Comes' — X (per-player ask) and N (deadline round)` | 'every player contributes X CE by round N or ALL take a setback' — X, N unspecified | X = 6 CE/player (Uncommon budget); N = round 6 of Standard mode (~15 rounds); pooled threshold Y = ceil(0.75 × P × X) rather than a strict per-player requirement | A literal per-player 'everyone or nobody' reading lets a single holdout punish the whole table — that reads as forced cooperation, against pillar 3. Pooling with a 75% threshold tolerates roughly one full free-rider's share before the group fails (computed: P=4 → full pool 24 CE, threshold 18 CE, 6 CE / 1.0 player-share of slack), so the quest stays a genuine collective test, not a single-player veto. X=6 CE by round 6 is ≈15% of the ≈39 CE proxy banked wealth by then — a real but not crushing ask. |
| `quests.md §2C 'The Storm Comes' — reward/penalty numbers` | 'Contributors gain Light; free-riders drift Dark' — no numbers | Contribution (immediate, on paying in): +2 Light, +1 VP. Quest succeeds (pool ≥ Y): non-contributors get -1 Duality (Dark drift), no setback for anyone. Quest fails (pool < Y): ALL players discard 1 resource-deck card of choice + lose 2 Energy (min 0); already-earned Light/VP from contributing is not clawed back. | Matches the existing gift/generous-trade Light rate (3 CE/Light) so contributing isn't a worse deal than just gifting a card instead. The failure penalty avoids HP/elimination/skipped-turn (constraint compliance) while still being a real cost. Free-riding when the quest still succeeds is deliberately not punished with a setback — only a Duality cost — because pillar 3 forbids compelling the choice, it can only make the kind choice pay better. |