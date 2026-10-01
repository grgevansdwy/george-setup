---
name: review
description: Run the code-reviewer subagent on the current changes in a fresh context (the two-Claude review pattern) and present MUST FIX / SHOULD FIX / CONSIDER findings. Use after implementation and before /recap.
disable-model-invocation: true
argument-hint: "[optional: files, branch, or commit range]"
---

# /review — fresh-eyes review

Target: "$ARGUMENTS" (empty = uncommitted changes; if there are none, the current branch vs main).

## 1. Delegate
Run the **code-reviewer** subagent. Give it:
- The target above
- A one-paragraph summary of what the change is meant to do (from this conversation or the latest `docs/plans/PLAN_*.md`), so it can judge intent
- **Not** your reasoning or excuses for shortcuts. The point is an unbiased second opinion.

## 2. Present
Show the reviewer's report unchanged. Then add:
- Which findings you agree with, and any you think are wrong (with a reason)
- A question: "Fix the MUST FIX items now?" (also offer the SHOULD FIX items)

Don't apply fixes until the user says to.

## Tip
For the strongest version of this pattern, run the review in a completely separate Claude session (Session A implements, Session B reviews), so it shares no context at all.
