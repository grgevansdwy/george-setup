---
name: deep-review
description: Parallel code review. Fans out several code-reviewer subagents, each with a different lens, in fresh contexts, then fans in through a verifier that tries to refute every serious finding, and presents one deduplicated MUST FIX / SHOULD FIX / CONSIDER report. Use after implementation and before /recap.
disable-model-invocation: true
argument-hint: "[files, branch, or commit range] [--quick]"
---

# /deep-review — fan-out review, fan-in verification

Target: "$ARGUMENTS" (empty = uncommitted changes; if there are none, the current branch vs the default branch). `--quick` = one reviewer, no verification pass (the old single-reviewer `/review`).

Diff size right now:
!`git diff HEAD --shortstat 2>/dev/null; b=$(git symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null || echo main); git diff "$b"...HEAD --shortstat 2>/dev/null || true`

## 1. Brief (one paragraph, no excuses)
Write a one-paragraph summary of what the change is meant to do, from this conversation or the latest `docs/plans/PLAN_*.md`. Leave out your reasoning and any shortcuts you took. The reviewers should judge the code, not your story about it.

## 2. Fan-out
Spawn these **code-reviewer** subagents **in a single message** so they run in parallel. Give each the target, the brief and its lens:

| Lens | Focus |
|---|---|
| correctness | logic, edge cases, error paths, async and concurrency, data and migrations |
| security | injection, authz, secrets, unsafe input handling, path traversal, dependency risk |
| tests | are the changed behaviours actually asserted? missing cases, tests that can't fail |
| design | consistency with CLAUDE.md and existing patterns, needless complexity, dead code, naming |

Scale it to the diff:
- Small diff (under ~150 changed lines): use `--quick` behaviour with one full-lens reviewer, and skip step 3.
- Large diff (over ~800 lines or 15 files): also **shard** by area (for example frontend / backend / data), giving each shard the correctness lens, so no reviewer has to hold the whole diff.

## 3. Fan-in
1. **Merge and dedupe.** The same `path:LINE` and problem from two lenses is one finding. Keep the higher severity, and note which lenses found it (agreement is a signal).
2. **Verify.** Send every MUST FIX and SHOULD FIX to the **verifier** subagent. Batch about 8 findings per verifier, and run the batches in parallel.
3. **Filter.** Drop REFUTED findings and keep a one-line list of them. Keep UNVERIFIED ones but mark them. Apply any severity changes.

## 4. Present
```
## Deep review: <one-line summary>
Reviewers: <lenses/shards run> · Findings: <raw> → <after dedupe> → <confirmed>

### MUST FIX
- `path:LINE` — <problem>. <failing scenario>. Fix: <suggestion>. [lenses] [confirmed|unverified]
### SHOULD FIX
- ...
### CONSIDER
- ...
### Refuted (not shown above)
- <one line each>

### Verdict
<SHIP | SHIP AFTER MUST FIX | NEEDS REWORK> — <one sentence>
```
Then say which findings you disagree with and why, and ask: "Fix the MUST FIX items now?" Don't apply fixes until the user says to.

## Tips
- Claude Code's built-in `/code-review` is also multi-agent (`/code-review high`, `--fix`). Use it when you don't need this report format or the verifier pass. `/simplify` covers reuse and simplification.
- For the most independent review, run `/deep-review` in a brand-new session that didn't write the code.
