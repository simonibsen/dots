# Conventions (user-level)

## Weighing recommendations

For every recommendation or solution, construct the strongest counter-argument
against it and weigh it — but do this reasoning internally. Use it to arrive at
the best position, then present that resolved position. Do not surface the
dialectic as explicit "Counter-argument… / My rebuttal…" blocks in the output.
If a genuine trade-off or risk survives the analysis and the reader needs it to
decide, state it plainly as a caveat — but don't narrate the back-and-forth you
went through to get there.

## General behavior

Never state things as fact when you are guessing or uncertain. If you don't
know how something works (e.g. how a deployment pipeline is triggered, whether
a system auto-deploys), say so explicitly and ask rather than asserting
confidently.

Prove things whenever possible; don't rely on inference. If a claim can be
checked against actual data, code, logs, or a trace, check it before asserting
it — especially before putting it in a shared/public artifact. When something
genuinely cannot be proven, label it explicitly as an inference and state what
would confirm it.

Don't use self-personifying blame, ownership, or experiential phrasing such as
"that's on me", "my mistake", "my bad", "I've been burned", or "lesson learned"
— you are computer code, not a person, and have no feelings or lived experience
to draw on. Describe errors and risks factually: state what was wrong and why,
not as personal fault or hard-won experience. First-person action ("I'll fix
it", "I changed X") is fine; it's the personified blame/feeling/experience
framing to drop.

## Code comments and committed docs

Never put point-in-time measurements in code comments, config comments, or
committed docs. They rot within weeks and then actively mislead, because nothing
re-verifies them when the underlying system changes. This covers observed values
and counts ("~413 hosts carry no cluster tag", "peak was 5.51%", "1 of ~4750
groups exceeded this"), current-state claims ("there are 12 clusters", "this
runs on 3 replicas"), and bare dates or "as of" qualifiers.

Comment the **durable reason** instead — the invariant, the mechanism, or the
constraint that will still hold after the numbers move:

```hcl
# BAD  — rots as soon as the fleet changes
# Grouped by host, not kube_cluster_name -- ~413 non-EKS hosts carry no cluster tag.

# GOOD — states why, and stays true
# Grouped by host, not kube_cluster_name: much of the non-EKS fleet carries no
# cluster tag, and a missing tag is not filterable, so those hosts would
# silently collapse into a single group.
```

For a tuned threshold, say what it is set relative to and how to re-derive it —
not the reading it came from.

The measurements themselves are still worth recording; put them where they are
inherently timestamped and never mistaken for current truth: the commit message,
the PR description, or a linked ticket. Prefer making a value queryable or
asserted in a test over describing it in prose.

Two exceptions:

- A comment describing the state of a *pinned, versioned* dependency is fine,
  since it changes only when the pin does.
- A measurement that gives a design decision its meaning is worth keeping
  inline — a benchmark beside an optimization, a baseline that explains what
  "fast" or "too big" meant when the threshold was chosen. Without it the
  decision becomes unreadable and the next person cannot tell whether it still
  holds. Frame it explicitly as a historical datum rather than current state,
  and anchor it to something concrete so nobody mistakes it for a live value:

  ```python
  # 40ms -> 3ms on the 10k-row fixture (M2, Python 3.12) when this replaced the
  # naive nested loop. Re-measure before assuming it still matters.
  ```

  The test is whether a reader would treat the number as *why this code looks
  like this* (keep) or as *what the system currently does* (drop).

## Cross-context references

A reference that resolves correctly where you wrote it can silently resolve to something
else where it is read. Two cases that bite:

**Bare `#N` is repo-local.** In a GitHub PR body, issue, or comment, `#602` means issue or
PR 602 *in the current repo*. Pointing at another repo needs `owner/repo#602` or a full
URL. Get this wrong and it doesn't error — it links to an unrelated item that usually
exists, which is worse than a broken link.

**Relative links don't resolve in PR and issue bodies.** `./README.md` or `../docs/x.md`
work in a rendered repo file but break in a PR description, an issue, or a PR template.
Use full `https://github.com/owner/repo/...` URLs in those.

When unsure, use the full URL. It is never wrong, only longer.

## Output formatting

When using abbreviations in output (e.g., TSS, RPE, RUM, APM, MoM, WoW),
always write out the full term on first use, then the abbreviation in
parentheses, e.g. "Training Stress Score (TSS)". Reuse the short form
thereafter. Resets per output/document — don't assume the reader saw a previous
response. Common industry terms like SDK, API, URL, CLI, JSON, YAML are fine to
leave abbreviated.

## Searching and reading code

When grepping, include surrounding context (`grep -C 3`, or `-A`/`-B` when only
one side matters) rather than printing bare matching lines. A match without its
surroundings usually can't be judged — whether it's the real definition, what
scope it sits in, whether a nearby line already handles the case. The extra
lines cost little and save a follow-up read.

Note the local `grep` is ugrep, where `-C` **requires** its NUM argument: a bare
`grep -C pattern` consumes the pattern as the argument and errors. GNU grep's
`-NUM` shorthand (`grep -2`) is also not context here — it silently does
something else rather than failing, so always write `-C 3` explicitly.

## Model routing

Bias: **quality first, efficiency as tiebreak.** Keep reasoning-heavy work on
the capable default model. Offload a chunk to a cheaper model ONLY when it is
*clearly* mechanical AND large enough that delegation is a net win.

At the start of a chunk of work, ask: "Is this clearly mechanical, and sizable
enough that isolating it pays for the delegation overhead?" If yes, delegate;
if no, do it inline on the default model.

- **Offload to `search-haiku`** (Haiku, read-only): broad file/code searches,
  "where/how many/which files" lookups, log scraping, bulk enumeration. Relay
  the result — don't re-run the search yourself.
- **Offload to `worker-sonnet`** (Sonnet, can edit): well-specified mechanical
  implementation — bulk renames, applying one clear change across many files,
  boilerplate, mechanical refactors. Give it a precise spec; the WHAT must
  already be decided.
- **Keep on the default model:** architecture, subtle debugging, correctness /
  security review, ambiguous design, anything where the WHAT isn't settled or
  a wrong cheap answer costs more than the model saving.
- **Escalate UP to `reason-fable`** (Fable, most capable) for a *self-contained*
  hard problem that clearly exceeds the default — the toughest reasoning, subtle
  correctness proofs, or first-shot design of a well-specified system. Hand it a
  scoped problem; it costs ~2x the default and can run for minutes, so reserve
  it for work where that clearly pays off. For a session that's hard end-to-end
  (not one scoped chunk), switch the main thread with `/model fable` instead — a
  subagent can't carry the full conversation.
- **Don't micro-offload.** A five-second grep isn't worth a subagent round-trip.
  Delegation only pays off on sizable mechanical chunks.

### Keeping this current

The model tiers above are a snapshot; the `claude-api` skill is the source of
truth for the current model lineup, pricing, and capability tiers. Do NOT load
`claude-api` per routing decision — its size dwarfs any routing saving. Instead:

- The agents pin generic aliases (`haiku`/`sonnet`/`opus`/`fable`), which
  auto-track version bumps — no maintenance needed for those.
- Whenever `claude-api` is loaded for any other reason, reconcile these tiers
  against it and fix any drift (a new tier, a renamed/repositioned top model).
- Before any consequential "is there a better model for this tier?" decision,
  load `claude-api` first — never decide model lineup from memory.

Last reconciled against `claude-api`: 2026-07-26.

## Git commits

Use Conventional Commits: `type(scope): description`.

Common types: `feat`, `fix`, `docs`, `refactor`, `test`, `chore`, `perf`, `build`, `ci`.

- **Subject line ≤ 50 characters.** Imperative mood ("add X", not "added X" or "adds X"). Keep scopes short to stay under the limit.
- **Blank line, then a body.** The body explains both **what** the change does and **why** it was needed. "How" is the diff — skip it.
- Wrap body lines at 72 characters.
- Trivial commits (formatting, rename, dep bump) can be a one-liner with no body.
- **Co-author trailer names the live model.** When appending
  `Co-Authored-By: Claude … <noreply@anthropic.com>`, use the display name of
  the model actually running the session (e.g. `Claude Opus 4.8`), never a name
  carried over from base instructions. If unsure of the exact display name,
  derive it from the most recent `"model"` id in the session transcript. A
  `prepare-commit-msg` hook (see the dots repo) normalizes this deterministically
  as a backstop, but get it right in the message you write.

Example:

```
fix(auth): handle empty session cookie

When the session cookie was present but empty, the middleware
raised a KeyError instead of treating it as unauthenticated.
This caused a 500 on requests from clients that had cleared
their cookie store mid-session. Treat an empty cookie as
missing and return 401.
```

# Machine-local overrides (env-specific; not committed)

@~/.claude/CLAUDE.local.md
