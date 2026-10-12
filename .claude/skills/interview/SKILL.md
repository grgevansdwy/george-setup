---
name: interview
description: Interview the user about a feature or task until the requirements are clear, then have the planner subagent write docs/plans/PLAN_<TASK_NAME>.md and explain the plan in plain language. Use before starting any non-trivial work.
disable-model-invocation: true
argument-hint: "<what you want to build>"
---

# /interview — requirements → plan file

Topic from the user: $ARGUMENTS

## 1. Interview (keep asking until it's clear)
- Before asking, look quickly at the code involved so your questions are specific to this codebase, not generic.
- Ask in rounds of 1–4 focused questions (use the AskUserQuestion tool when available, with concrete options and a recommended default).
- Cover: goal and who it's for, scope and non-goals, inputs and outputs, edge cases and error handling, data and schema changes, UI/UX if relevant, performance, security and permissions, testing expectations, and constraints (deadlines, libraries to use or avoid).
- When there are several reasonable approaches, show them with their trade-offs and let the user choose.
- **Keep asking** until you could hand this to another engineer without them needing to ask anything. Then summarize the requirements back and get a "yes".

## 2. Plan (delegate)
- Run the **planner** subagent. Pass it the confirmed requirements, the user's decisions, and the relevant file paths you already found. Ask it to fill in the **Work units** table, so the plan can be built in parallel with `/fanout`.
- For a large or unfamiliar area, first send 2-3 **explorer** subagents in parallel (one per area, in a single message) and pass their findings to the planner, so the planner doesn't have to read everything itself.
- Choose `TASK_NAME` in UPPER_SNAKE_CASE from the topic (e.g. `USER_AUTH`).
- Write the planner's output to `docs/plans/PLAN_<TASK_NAME>.md` (create `docs/plans/` if needed). Add at the top:
  ```
  Status: Planned — <YYYY-MM-DD>
  ```
- Do **not** start implementing.

## 3. Explain
Tell the user in plain language:
- What will be built, in 2–3 sentences
- The steps, in order, one line each
- The files that will change
- Risks or open questions
- The path to the plan file
- Whether it's worth fanning out, and if so the waves (e.g. "U0 first, then U1-U3 in parallel")

End by asking how to build it: `/fanout` (parallel, uses more tokens, faster for 3+ independent units) or step by step here.
