---
name: recap
description: Update the project's markdown docs (README.md, CLAUDE.md, docs/*.md) to reflect recent changes, then stage and commit everything. Run after finishing a feature or whenever you want to commit.
disable-model-invocation: true
argument-hint: "[optional commit message hint]"
---

# /recap — sync docs with the code, then commit

The user asked to recap. Extra input from the user (may be empty): $ARGUMENTS

## 1. Understand what changed
- `git status --porcelain` and `git diff HEAD --stat` for uncommitted work.
- `git diff HEAD` for details (read selectively if it is large).
- `git log --oneline -10` for recent context.
- If there is nothing to commit and no docs are stale, say so and stop.

## 2. Update the docs that exist (don't create new doc files unless clearly needed)
Check each of these if it exists and update only what is now wrong or missing:
- **README.md**: features, setup/usage commands, env vars, API surface.
- **CLAUDE.md**: tech stack, directory map, build/test commands, conventions, "what Claude gets wrong". Rules:
  - Keep it **under 200 lines**. If it's over, tighten it or move details to a subdirectory `CLAUDE.md`.
  - Add only facts Claude can't easily infer from the code. No vague rules ("write clean code").
  - Never put secrets in it.
- **docs/*.md, DESIGN.md, ARCHITECTURE.md, CHANGELOG.md**: update the sections the change affects. For CHANGELOG, add an entry under Unreleased.
- **docs/plans/PLAN_*.md**: if a plan was just completed, mark it done at the top (`Status: Done — <date>`).

Keep edits small and factual. Don't rewrite docs for style.

## 3. Commit
- Never stage secrets: review `git status` and skip `.env*` (except `.env.example`), keys, and large generated files. Warn the user if any are untracked and not gitignored.
- `git add -A` (excluding anything flagged above).
- Write a Conventional Commit message: `type(scope): summary` (feat, fix, refactor, docs, test, chore), plus a short body listing the main changes. Use the user's hint from $ARGUMENTS if given.
- `git commit`. **Do not push.** Don't amend or rewrite existing commits.
- If a pre-commit hook fails, fix the issue and create a new commit attempt. Do not use `--no-verify`.

## 4. Report
```
Docs updated: <files + one-line what changed each>
Commit: <hash> <message subject>
Not committed: <anything skipped and why, or "nothing">
```
