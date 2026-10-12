---
name: spec
description: Write the human-readable spec for a feature or project (goal, never-go-wrong rules, scope, decisions, milestones) to docs/plans/SPEC_<TASK>.md, and record every locked decision in docs/DECISIONS.md. /interview calls this once requirements are confirmed; also use it when the user asks for a spec.
argument-hint: "<task or TASK_NAME>"
---

# /spec — what we're building and why

Input: $ARGUMENTS, plus the confirmed requirements and the user's choices from this conversation (when /interview called you).

Decisions already on record:
!`if [ -f docs/DECISIONS.md ]; then grep -E '^\| D[0-9]+' docs/DECISIONS.md | tail -40; else echo "(no docs/DECISIONS.md yet)"; fi`

## 1. Requirements first
If you weren't called from /interview and the goal, scope or never-go-wrong rules aren't clear from this conversation, ask 1-2 rounds of questions first (AskUserQuestion when available, with your recommendation as the first option). Never invent a requirement.

## 2. Draft
- Fill in `${CLAUDE_SKILL_DIR}/template.md` and write it to `docs/plans/SPEC_<TASK_NAME>.md`. Use UPPER_SNAKE_CASE, the same TASK_NAME /interview uses for the plan. Create `docs/plans/` if needed.
- **Size it to the work.** A small feature is half a page: Goal, Never go wrong, Scope, Decisions, Milestones. A new system or service gets every section, still 2 pages at most. Delete sections that don't apply.
- **Write for a human.** Plain sentences. No code and no file-by-file detail, because that's the plan's job.
- Every never-go-wrong rule names the test that proves it.
- Never fill a gap silently. Anything undecided goes under Open decisions, with 2-3 options and your recommendation.
- Respect decisions already on record (above). If this work needs to change one, say so as a new decision that supersedes it.

## 3. Architecture check (only when it applies)
If the work adds or changes architecture, invoke the `architecture-review` skill on the draft spec. That means a new service or component, a data model or schema, where state lives, an external integration, auth or permissions, or an LLM or agent component. It runs in a fresh context and returns a scored review.
- Fix what's clearly wrong in the draft.
- Turn real disagreements into Open decisions, with the review's argument as one option.
- Its PROPOSED DECISIONS are candidates, not decisions. Only the user locks them.

Skip this step for ordinary features inside the existing structure.

## 4. Lock decisions
1. Ask the user about every Open decision needed before M1, in one round, recommendation first. Move each answered one to the Decisions table.
2. Record each locked decision in `docs/DECISIONS.md`. If the file doesn't exist, create it from `${CLAUDE_SKILL_DIR}/decisions-template.md`.
   - Append one `## D<n>` entry per decision with the next free number, and add a row to the index.
   - Source: **Owner** (the user picked it here), **Interview** (confirmed during /interview), or **Review** (proposed by /architecture-review and accepted by the user).
   - When a decision replaces an older one, set the old index row to "Superseded by D<n>". Never edit an old entry's body.
3. Put the IDs in the spec's Decisions table (`Ref` column).

## 5. Hand off
- Keep `Status: Draft — <date>` at the top. Change it to `Approved — <date>` when the user approves the spec.
- Report the spec path, the decisions recorded (IDs and one line each), and any open decisions left for later milestones.
- When /interview called you, go straight back to its next step (the planner). Don't plan or implement here.
