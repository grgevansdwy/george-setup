---
name: cleanup-all
description: Repo-wide version of /cleanup. Finds dead code, unused imports/exports/dependencies, and debug statements across the whole codebase, reports first, then applies only what the user approves.
disable-model-invocation: true
argument-hint: "[optional: directory to limit to]"
---

# /cleanup-all — repo-wide tidy

Scope: the whole repo, or the directory given in "$ARGUMENTS". Skip vendored, generated, and build directories (node_modules, dist, build, .venv, vendor, migrations, generated clients).

Because this touches many files, **report first, then apply only after the user approves.**

## 1. Find (prefer real tools over guessing)
- **Unused imports/locals**: the project linter (eslint, `ruff check --select F401,F841`, `go vet`, `cargo clippy`, `tsc --noUnusedLocals --noEmit`).
- **Unused exports/files/deps**: `npx --no-install knip`, `vulture`, `deadcode`, or `cargo udeps` if available. Otherwise use Grep to check references, and mark those findings "unverified".
- **Debug statements**: grep for `console.log`, `debugger`, `print(`, `breakpoint()`, `pdb.set_trace`, `dbg!`, `var_dump`, and others, excluding tests and real logging.
- **Commented-out code blocks** (not explanatory comments).

Running the explorer subagent for searching is fine if the repo is large.

## 2. Report
Group findings by confidence:
```
## Safe to remove (tool-verified)
- `path:LINE` — <what>
## Probably dead (grep-verified, check for dynamic use)
- `path:LINE` — <what>
## Debug statements
- `path:LINE`
```
Then ask: "Apply all safe, safe + probable, or pick?"

## 3. Apply what was approved
- Don't change behavior or refactor beyond deletion.
- Run lint, type-check and tests afterwards and report the results. If something breaks, revert that specific removal.
