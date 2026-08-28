be precise, concise , and only do what user asks

## Project Instructions
- Speak as little as possible, be concise
- No long explanations or verbose tables unless asked
- Get to the point fast
- When summarizing user's words (e.g. raw responses, SEED-STATE entries), keep it short and concise — compress, don't expand

---

# Working agreement — Into the Wild

Read `GDD.md` first. It holds the pillars, the invariants, and the open questions.

## The gate

```
python -m pytest      # 62 checks — must stay green
python -m sim         # economy report
```

Every lane runs this before handing work back. A red suite is not "a test problem",
it is a design contradiction that the tests caught. Fix the design or change the
invariant deliberately, in the same commit, with the reason in the message.

## Canon beats prose

Numbers live in `canon/*.json`. Prose lives in the `.md` files. When they disagree,
canon is right and the prose is stale — but **both must be updated in the same
commit**. Never leave a number in only one of the two places.

Every canon file carries `$source`, naming the doc it came from. If you add a
field, add its source. If a value is unknown, mark it `OPEN` and cite a GDD
question id (`GDD Q7`); `test_integrity.py` fails on untagged unknowns.

## Lanes and ownership

Lanes run in parallel. **A lane edits only the files it owns.** Touching another
lane's file means stopping and saying so, not editing across the line.

| Lane | Owns | Never touches |
|---|---|---|
| **systems** | `into-the-wild-spec.md`, `actions/`, `canon/{actions,victory,duality,rage,fate}.json` | economy numbers, catalogs |
| **economy** | `economy-engine.md`, `canon/{tiers,decks,crafting,energy,modes}.json`, `sim/`, `tests/` | spec prose, catalogs |
| **content** | `creatures.md`, `quests.md`, `items/`, `items-crafting.md`, `objects-catalog.md`, `commons-catalog.md`, `resources.md`, `characters/`, `canon/elements.json` | any rule, any number outside its own tier budget |
| **auditor** | nothing — read-only | everything |
| **translator** | nothing — proposes, never commits | everything |

**Shared, needs Tessa's explicit approval to edit:** `GDD.md`, `AGENTS.md`,
`projects/into-the-wild/SEED-STATE.md`.

**content is the safe parallel lane** — it adds catalog entries within existing
tier budgets and can run alongside anything. systems and economy both move
numbers, so run them together only when their canon files are genuinely disjoint.

## Conflict protocol

1. If your change would touch a file you do not own, stop and report it. Do not edit.
2. If your change breaks an invariant in GDD §3, stop. Invariants change only by
   Tessa's decision, never as a side effect.
3. If two lanes need the same file, the one holding the design question wins;
   the other waits or works from a proposal.
4. Merge order when lanes land together: **economy → systems → content**. Numbers
   settle first, rules cite settled numbers, content fills settled rules.

## Design discipline (from `persona-translator.md`)

- **Declare your mode.** BRAINSTORM (divergent, no judgement, no numbers) or
  DESIGN (convergent, compute don't assert). Never mix them in one pass.
- **Three lenses on every system:** does the math hold · does it create meaningful
  choices · does it feel good to play. Math serves play, not the reverse.
- **Dual platform, always.** Physical = hand-computable, shuffleable, hideable by
  hand. Digital = hidden state, real-time logic, heavy RNG. State which you assume;
  when something works on one only, flag it and give the adaptation.
- **Show the work.** Never assert a probability, EV or "this is balanced". Compute
  it — the sim is right there — or say you have not.
- **Nothing becomes canon without Tessa's explicit apply.** Propose; she authors.

## Conventions

- Every change to a number states: exact target, old value, new value, why.
- Themes land through mechanics, never through printed text (pillar 1).
- No HP anywhere. Setbacks only, never elimination, never a fully skipped turn.
- Keep `SEED-STATE.md`'s section table honest — it is the progress ledger (14/19).
