---
name: decisions
description: Record an architecture or product decision in the project's append-only decision log, docs/DECISIONS.md, and return its ID (D1, D2, …). Use when a decision is locked or reversed while writing a spec or reviewing an architecture, or when the user says "log this decision" or asks why something was decided.
argument-hint: "<the decision and the reason>"
---

# /decisions — append to the decision log

Decision to record: $ARGUMENTS

## 1. Find the log
- The log is `docs/DECISIONS.md`. If the project already keeps a `DECISIONS.md` somewhere else (e.g. the repo root), use that one.
- If there isn't one, create `docs/DECISIONS.md` from the template at `${CLAUDE_SKILL_DIR}/template.md`: keep the header, the constraint questions and the index, and use the `D1` block for the first entry. Leave the template itself blank.
- If "$ARGUMENTS" is a question about a past decision rather than a new one, read the log and answer from it. Don't write anything.

## 2. Append the entry
- The new ID is the highest existing `D<n>` plus one.
- Copy the entry block from the template and fill in every field. Use today's date in `YYYY-MM-DD`.
- **Source** is who made the call: Owner (the user), Critique (came out of a review) or Agent (you chose it). If you chose it, say so in your report so the user can overrule it.
- Don't invent the options or the reason. If you don't know them, ask.
- Add a row to the index.

## 3. Changing a decision
The log is **append-only**. Never edit or delete an old entry. To change a decision:
1. Append a new entry with `Replaces: D<old>`.
2. In the index, change the old row's status to `Superseded by D<new>`. That status cell is the only thing you may touch in an old decision.

## 4. Report
Give the ID and a one-line summary, so the caller (the spec, a review, the user) can cite it.
