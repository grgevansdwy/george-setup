---
name: spec
description: Write the 1-2 page human-readable spec for a feature or project to docs/specs/SPEC_<TASK_NAME>.md by filling in the bundled template. Called by /interview once the requirements are confirmed. Also use when the user asks for a spec or to update one.
argument-hint: "<task name or topic>"
---

# /spec — requirements → spec file

Topic: $ARGUMENTS

The spec is for the **human**: short, readable in five minutes, and the thing they sign off on. The build plan for the agent is a separate file (`docs/plans/PLAN_<TASK_NAME>.md`, written by the planner).

## 1. Inputs
- Use the requirements and decisions already confirmed in this conversation (normally by `/interview`).
- If you were called directly and something a section needs is unknown, ask for it in one round of up to 4 questions. Don't invent requirements.

## 2. Write the file
- Choose `TASK_NAME` in UPPER_SNAKE_CASE from the topic (e.g. `USER_AUTH`). If `/interview` already chose one, use the same.
- Read the template at `${CLAUDE_SKILL_DIR}/template.md` and fill it into `docs/specs/SPEC_<TASK_NAME>.md` (create `docs/specs/` if needed). Leave the template itself blank.
- If the spec file already exists, update it in place and tell the user what changed. Don't overwrite it.

## 3. Rules for filling it in
- **1-2 pages.** Details belong in the plan, not here.
- **No blanks, no leftovers.** Fill every section, or delete it if it doesn't apply. Remove the `<…>` hints and empty table rows. If no model is involved, drop the Model row and the `(code)` / `(model)` markers.
- **Never go wrong:** 3-5 items, each one checkable by a test.
- **Decisions:** every big-picture decision gets a one-line reason. Record each one with the **decisions** skill and put the returned ID (`D1`, `D2`, …) in the Ref column.
- **Never fill a gap silently.** Anything undecided goes under Open decisions with 2-3 options and a recommendation. Anything you assumed goes under Assumptions to confirm.
- **Milestones:** M1 is a thin end-to-end slice, then deepen. Each milestone says what to build, how to test it, and what success means.
- **Architecture choices:** for an LLM or agent system, or whenever the design isn't obvious, load the **architecture-reviewer** skill and cite its IDs (`P3`, `CF-1`, …) in the reasons.

## 4. Report
Tell the user the path, the open decisions, and the assumptions that need a yes or no. Do **not** start implementing.
