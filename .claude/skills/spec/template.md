Status: Draft — <YYYY-MM-DD>

# <Task or project>: SPEC

> For the human: what we're building and why. Half a page for a small feature, 1-2 pages at most for a new system.
> The build plan (how, file by file, parallel work units) goes in `PLAN_<TASK>.md`. Decision history goes in `docs/DECISIONS.md`.
> Delete any section that doesn't apply. Don't write "n/a".

## 1. Goal
<2-3 sentences: what it does, for whom, and what "done" looks like.>

## 2. Never go wrong
<3-5 rules that must hold no matter what. Each one names the test that proves it.>
1. <rule> — tested by: <test>
2.
3.

## 3. Scope
- **In:** <what this work covers>
- **Out (non-goals):** <what it deliberately doesn't do>

## 4. Constraints
<Only the ones that shape the design. One line each.>
- **Response time:** <how long the caller waits for a reply>
- **Task lifetime:** <how long one task lives, including waiting>
- **Volume / cost:** <requests per day, acceptable cost per task>
- **Data shape:** <size, structure, change rate, exact codes vs prose>
- **Output consumer:** <person, program, auditor>

## 5. Decisions
Only decisions this work makes or changes. The existing stack lives in CLAUDE.md. Every row links to its entry in `docs/DECISIONS.md`.

| Decision | Choice | Reason | Ref |
|---|---|---|---|
| | | | D# |

## 6. Flow
<Numbered end-to-end steps. Note which steps run in parallel and where work pauses or resumes.>
1.
2.
3.

<If the work includes LLM or agent steps: mark every step (code) or (model), and fill this table. Otherwise delete it.>

| Sub-problem | Approach (code / single call / agent loop / RAG / tool / MCP) | Why |
|---|---|---|
| | | |

## 7. Safety
- **Gates and approvals:** <what needs a human or a check before it happens>
- **Permissions:** <who or what may do what>
- **Data handling:** <secrets, personal data, retention>
- **Prompt-injection handling:** <LLM work only>

## 8. Open decisions
| Decision | Options | Recommendation | Needed before |
|---|---|---|---|
| | | | M1 |

## 9. Milestones
M1 is always a thin end-to-end slice (fakes are fine). Each milestone is planned and built, then reviewed before the next starts.

| # | Goal | Needs from you (keys, access, data) | How to test | Success means |
|---|---|---|---|---|
| M1 | Thin end-to-end slice | | | |
| M2 | | | | |

## 10. Assumptions to confirm
-
