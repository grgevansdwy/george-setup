---
name: interview
description: Interview the user about a feature or task until the requirements are clear, then run /spec to write the human-readable spec (and record decisions), then have the planner subagent write docs/plans/PLAN_<TASK_NAME>.md with parallel work units, and explain both in plain language. Use before starting any non-trivial work.
disable-model-invocation: true
argument-hint: "<what you want to build>"
---

# /interview — requirements → spec → plan

Topic from the user: $ARGUMENTS

Choose `TASK_NAME` in UPPER_SNAKE_CASE from the topic (e.g. `USER_AUTH`). The spec and the plan share it.

## 1. Interview (keep asking until it's clear)
- Before asking, look quickly at the code involved so your questions are specific to this codebase, not generic. Also skim `docs/DECISIONS.md` if it exists, so you don't re-ask something already decided.
- For a large or unfamiliar area, send 2-3 **explorer** subagents in parallel first (one per area, in a single message), and keep their findings for the planner.
- Ask in rounds of 1–4 focused questions (use the AskUserQuestion tool when available, with concrete options and a recommended default).
- Cover: goal and who it's for, scope and non-goals, what must never go wrong, inputs and outputs, edge cases and error handling, data and schema changes, UI/UX if relevant, performance, security and permissions, testing expectations, and constraints (deadlines, libraries to use or avoid).
- When there are several reasonable approaches, show them with their trade-offs and let the user choose. Each choice becomes a decision in step 2.
- **Keep asking** until you could hand this to another engineer without them needing to ask anything. Then summarize the requirements back and get a "yes".

## 2. Spec (invoke /spec)
- Invoke the **spec** skill with `TASK_NAME`. It works from the requirements and choices confirmed above. If you can't invoke it, read `.claude/skills/spec/SKILL.md` and follow it here.
- It writes `docs/plans/SPEC_<TASK_NAME>.md`, runs `/architecture-review` when the work is structural, asks about any decision still open before M1, and records locked decisions in `docs/DECISIONS.md`.
- Wait for it to finish before planning. The plan builds on the spec, not the other way round.

## 3. Plan (delegate)
- Run the **planner** subagent. Pass it the spec path, the explorers' findings, and the relevant file paths you already found. Ask it to fill in the **Work units** table, so the plan can be built in parallel with `/fanout`.
- Write the planner's output to `docs/plans/PLAN_<TASK_NAME>.md`. Add at the top:
  ```
  Status: Planned — <YYYY-MM-DD>
  Spec: docs/plans/SPEC_<TASK_NAME>.md
  ```
- Do **not** start implementing.

## 4. Explain
Tell the user in plain language:
- What will be built, in 2–3 sentences
- The decisions that were locked (IDs and one line each), and anything still open
- The milestones, and the steps of the first one, one line each
- The files that will change
- Risks or open questions
- The paths to the spec and the plan
- Whether it's worth fanning out, and if so the waves (e.g. "U0 first, then U1-U3 in parallel")

End by asking how to build it: `/fanout` (parallel, uses more tokens, faster for 3+ independent units) or step by step here.
