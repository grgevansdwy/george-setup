---
name: cleanup
description: Remove dead code, unused imports, debug statements, and leftover TODO noise from the current uncommitted changes only. Use before committing.
disable-model-invocation: true
argument-hint: "[optional: specific files]"
---

# /cleanup — tidy the current changes

Scope: only lines changed in the working tree (`git diff HEAD` plus untracked files from `git status --porcelain`). If the user named files in "$ARGUMENTS", limit it to those. **Do not touch code outside the diff.**

## Remove
1. **Debug statements** added in this diff: `console.log`/`debugger`, `print(`/`pprint`/`breakpoint()`/`pdb`, `fmt.Println` used for debugging, `dbg!`, `var_dump`, etc. Keep intentional logging that goes through the project's logger.
2. **Unused imports and variables** introduced by the diff. Use the project's linter if available (eslint, ruff, go vet, cargo clippy, tsc --noUnusedLocals) rather than guessing.
3. **Dead code** in the diff: commented-out code blocks, unreachable branches, functions added but never called.
4. **Temporary scaffolding**: hard-coded test values, `TODO: remove`, stray scratch files that were created during the session (ask before deleting files).

## Don't
- Don't refactor, rename, or reformat beyond what's listed above.
- Don't change behavior. If something might be used dynamically (reflection, string imports, framework conventions, public exports), leave it and mention it.

## Then
- Run the project's lint/type-check/test command if it is known (CLAUDE.md, package.json, Makefile) and report the result.
- Report:
```
Removed:
- `path:LINE` — <what>
Left alone (unsure):
- `path:LINE` — <why>
Checks: <command> → <result>
```
