# Conventions (user-level)

## Output formatting

When an acronym or abbreviation appears in output, expand it on first use:
give the full meaning, then the short form in parentheses, e.g.
"Training Stress Score (TSS)". Subsequent uses of the short form are fine.

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
