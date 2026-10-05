# INSTRUCTIONS: installing this Claude Code harness into a project

> **For the user:** clone this repo next to your project, open Claude Code **in your project**, and say:
> *"Read `<path-to-this-repo>/INSTRUCTIONS.md` and install the harness into this project."*
>
> **For the agent:** follow Part A step by step. Part B covers how to write CLAUDE.md, and Part C is the day-to-day guide you'll hand to the user at the end.
>
> **No user available?** If you're running headless or as a subagent, wherever a step says to ask, choose the safest default: keep the existing file, skip optional steps, and mark anything you couldn't check as unverified. List every assumption in the A9 report.

## What gets installed

All of it is project-level, under `<target>/.claude/`. **Never write to `~/.claude/`.**

| Piece | Path | What it does |
|---|---|---|
| Settings | `.claude/settings.json` | Wires up the hooks and adds `permissions.deny` rules |
| Hook: format | `.claude/hooks/format.sh` | After each Edit/Write, formats the file, but only with a formatter the project has opted into: prettier, ruff or black need a config file or dependency. gofmt and rustfmt always apply |
| Hook: block-dangerous | `.claude/hooks/block-dangerous.sh` | Blocks commands like `rm -rf /` and `~`, force push, `reset --hard`, `clean -f`, `DROP TABLE`, and `curl … \| sh` |
| Hook: protect-files | `.claude/hooks/protect-files.sh` | Blocks edits to `.env*` (templates are allowed), keys, lockfiles and `.git/` |
| Hook: notify | `.claude/hooks/notify.sh` | Shows a desktop notification when Claude needs you (macOS and Linux) |
| Self-test | `.claude/hooks/selftest.sh` | Runs test cases against every hook. It isn't attached to any hook event |
| Subagents | `.claude/agents/*.md` | `code-reviewer`, `explorer`, `test-writer`, `debugger`, `planner` |
| Skills | `.claude/skills/*/SKILL.md` | `/recap`, `/cleanup`, `/cleanup-all`, `/interview`, `/explain`, `/review` |
| Project memory | `CLAUDE.md` | **Written for each project** from `templates/CLAUDE.md.template` (see Part B) |
| Personal memory | `CLAUDE.local.md` | Created from the template and gitignored |
| MCP (optional) | `.mcp.json` | Only if the user asks for it, adapted from `templates/mcp.json.example` |
| Templates | `templates/` | The whole folder, copied as it is (see A2). Blank `SPEC.md`, `SPEC-DETAILED.md`, `DECISIONS.md` and `DESIGN.md` to copy from when starting a piece of work, `BRAIN.md` as the architecture baseline they refer to, and the install-time templates above |

**The `templates/` folder must stay in the target.** The user may delete this repo once the install is done, so the target needs its own copy. Nothing installed in the target may point back to a path inside this repo.

Don't copy `README.md`, `INSTRUCTIONS.md`, or any PDF into the target.

---

# Part A: Install procedure

Throughout this section, `SRC` is this repo's root (where this file is) and `TGT` is the target project root. Give the user a short status update after each step.

### A1. Preflight
1. Find `TGT`. It's the current working directory unless the user named another one. Confirm it's a project root, which usually means it has `.git/` or a manifest file. **Stop if `TGT` is `SRC` or is inside `~/.claude`.**
   - The session should run in `TGT`. If it's running in `SRC`, SRC's own hooks are live in your session, which is harmless but means the dangerous-command blocker also applies to your own commands.
2. Run `git -C "$TGT" status --porcelain`.
   - Modified or staged files (anything except `??` lines) mean there's uncommitted work. Warn the user and suggest committing first so the install is easy to undo. Continue only if they agree.
   - Untracked files (`??` lines) are fine.
   - If `TGT` isn't a git repo, warn that the install can't be undone with git and ask whether to continue.
3. Check the tools the hooks need:
   - `jq` is required by the hooks. If it's missing, tell the user how to install it (`brew install jq` or `apt install jq`). The hooks still run without it, but they skip their checks and warn.
   - Note which formatters the project **is configured for**: prettier config or dependency, `[tool.ruff]` or `ruff.toml`, `[tool.black]`, a Go or Rust project. Also check whether each one is installed. Any formatter that is configured but not installed goes into A9 as a follow-up.
4. List what's already in `TGT/.claude/` and `TGT/templates/`, plus `TGT/CLAUDE.md`, `TGT/CLAUDE.local.md` and `TGT/.mcp.json`. **Nothing that already exists may be silently overwritten.**

### A2. Copy hooks, agents and skills
The units to copy are:
- each hook script in `SRC/.claude/hooks/`
- each agent file in `SRC/.claude/agents/`
- each skill **directory** in `SRC/.claude/skills/`

Create any missing directories, and copy with `cp -p` so file permissions are kept. For each unit:
- If it doesn't exist in `TGT`, copy it.
- If it exists and is identical, skip it.
- If it exists and is different, show the user a short diff and ask: keep theirs, replace with ours, or install ours under a new name (e.g. `review-harness`).

When you rename something:
- For a skill, rename the directory **and** the `name:` in its frontmatter.
- For an agent, rename the file and its `name:`, then update every skill that calls it by name. `/review` calls `code-reviewer`, `/interview` calls `planner`, and `/explain` and `/cleanup-all` call `explorer`.
- Use the new names in the CLAUDE.md you write and in the cheat-sheet you give the user.

Then run `chmod +x "$TGT"/.claude/hooks/*.sh`.

**Templates folder.** Copy every file in `SRC/templates/` to `TGT/templates/`, using the same copy / skip / ask rule per file. This copy is what keeps the templates available after `SRC` is deleted, so don't skip it and don't replace it with a symlink or a path back to `SRC`.
- If `TGT/templates/` already exists and belongs to the project (Django, Jinja or email templates, for example), don't mix our files into it. Ask the user where to put them, and use `.claude/templates/` if they have no preference or aren't available.
- Wherever the folder ends up, use that path in the CLAUDE.md you write and in the A9 report.

### A3. Merge settings.json
- If `TGT/.claude/settings.json` doesn't exist, copy `SRC/.claude/settings.json`.
- If it does exist:
  1. **Check for conflicting hooks first.** Look at every existing `PostToolUse` group whose `matcher` mentions `Edit` or `Write`. If its command runs a formatter (prettier, ruff, black, eslint --fix, biome and so on), ask before adding ours, so files don't get formatted twice. If the user says no, remove the `format.sh` group from the merge input.
  2. **Merge** with the command below. It keeps all existing keys (including `permissions.allow`) and their order. It appends SRC's deny rules that aren't already there, and appends each SRC hook group unless an identical one already exists. "Identical" means a JSON-equal group, so after merging, check that our hook scripts don't appear twice:
     ```bash
     tmp=$(mktemp) && jq -s '
       def addnew($xs): reduce $xs[] as $x (.; if index([$x]) then . else . + [$x] end);
       .[0] as $t | .[1] as $s
       | $t
       | .permissions = (($t.permissions // {}) | .deny = ((.deny // []) | addnew($s.permissions.deny // [])))
       | .hooks = reduce (($s.hooks // {}) | to_entries[]) as $e (($t.hooks // {});
           .[$e.key] = ((.[$e.key] // []) | addnew($e.value)))
     ' "$TGT/.claude/settings.json" "$SRC/.claude/settings.json" > "$tmp" \
     && jq . "$tmp" >/dev/null && mv "$tmp" "$TGT/.claude/settings.json"
     ```
- If `TGT/.claude/settings.local.json` exists, leave it alone. It's personal.

### A4. Adapt to the stack
Look at the manifests (`package.json`, `pyproject.toml`, `go.mod`, `Cargo.toml`, `Gemfile`, `composer.json`, `Makefile`, CI config) and then:
1. **Formatter.** `format.sh` runs prettier, ruff or black only if the project is configured for them, and gofmt and rustfmt always. If the project uses something else, edit the matching `case` branch. For example: biome (`npx --no-install biome format --write`), `eslint --fix`, `dprint`, `clang-format`, `mix format`, `dotnet format`. If the project has no formatter config, leave `format.sh` as it is: it won't touch JS or Python files. You can suggest adding a formatter in A9.
2. **Protected files.** Add any project-specific lockfiles or generated files to `protect-files.sh`, such as generated API clients or `schema.prisma` migrations folders if they should never be hand-edited.
3. **Dangerous commands.** Add project-specific destructive commands to `block-dangerous.sh` if relevant, such as `prisma migrate reset`, `rails db:drop` or `terraform destroy`.
4. Make a note of the **test, lint and build commands**. They go into CLAUDE.md in A5.

### A5. Write CLAUDE.md (see Part B for the rules)
1. **Investigate before asking.** Read the manifests, the top two levels of the directory tree, the README, CI workflows, existing docs, and two or three representative source and test files.
2. **Interview the user** only about what the code can't tell you. Ask in one round of up to 4 questions, using AskUserQuestion if it's available:
   - The product's purpose and its users (the WHY)
   - Conventions or "never do X" rules the team has
   - Things Claude or other AI tools have gotten wrong in this repo before
   - Anything in your draft that you're unsure about
3. Fill in `SRC/templates/CLAUDE.md.template` and write it to `TGT/CLAUDE.md`.
   - If `TGT/CLAUDE.md` **already exists**, don't replace it. Merge into it: keep all existing content, add missing sections in WHAT/WHY/HOW order, and show the user the diff.
4. Check it: under 200 lines, no template comments left over, and no secrets.
   - **Commands must be real.** Use commands from the manifests, scripts, Makefile or CI. Don't invent them. If a command doesn't exist (for example, no lint or build step), write `none configured`.
   - Run the test and lint commands if they're cheap. If one can't run because the right environment can't be found (wrong Python or Node version, missing virtualenv), keep it in CLAUDE.md, add `(unverified)` next to it, and list it in A9.
5. For a large monorepo, add short `CLAUDE.md` files in the key subdirectories (e.g. `apps/web/CLAUDE.md`) rather than letting the root file grow. Claude loads those automatically when it works in that directory.

### A6. Personal files and .gitignore
1. If `TGT/CLAUDE.local.md` doesn't exist, copy `SRC/templates/CLAUDE.local.md.template` there. Fill in anything personal the user mentioned during the install (local ports, preferences). Otherwise leave the template as it is, comments included, as a starting point for them.
2. Make sure `TGT/.gitignore` contains these lines, adding only the missing ones:
   ```
   CLAUDE.local.md
   .claude/settings.local.json
   ```
3. Make sure `.claude/settings.json`, `.claude/hooks/`, `.claude/agents/`, `.claude/skills/`, `templates/` and `CLAUDE.md` are **not** gitignored. They're meant to be shared with the team.

### A7. MCP servers (optional, so ask first)
Ask: *"Do you want any MCP servers (database, GitHub, internal APIs)?"*
- If the answer is no, skip this step.
- If yes, create or merge `TGT/.mcp.json` from `SRC/templates/mcp.json.example`, keeping only the servers they want. Use `${ENV_VAR}` placeholders, **never real credentials**.
- **The read-only vs read-write pattern:** set up two connections to the same resource, one with read-only credentials and one with read-write. Then limit which subagents can use each through their `tools:` frontmatter. For example, give `code-reviewer` and `explorer` `mcp__db-readonly__*`, and give only the main session or an implementer agent access to `mcp__db-readwrite__*`.
- Tell the user that project MCP servers ask for approval the first time they're used, and that the environment variables have to be set in their shell.

### A8. Verify
Run these from `TGT`, then report the results:
```bash
bash .claude/hooks/selftest.sh      # tests every hook; ends with ALL PASSED
ls .claude/agents .claude/skills
ls templates                        # must match SRC/templates file for file
wc -l CLAUDE.md
```
**Heads-up:** the `block-dangerous` hook may be active in your own session, either from SRC's settings or from TGT's after A3. It checks the **whole Bash command line**, including heredocs and `echo` strings. So never type test cases like a force push or `rm -rf` into a Bash command, because your own call will be blocked. Use `selftest.sh`, which keeps the cases inside the script. If you add project-specific rules in A4, add matching cases to `selftest.sh` with the Write or Edit tool.

### A9. Report to the user
Finish with:
1. What was **installed**, what was **merged**, and what was **skipped**, with the reason for each skip.
2. Any **manual follow-ups**, such as installing `jq` or a formatter, setting MCP env vars, or reviewing the CLAUDE.md diff.
3. **"Restart Claude Code (or run `/hooks` and `/agents` to check) so the new hooks, agents and skills load."**
4. A short cheat-sheet: the "Typical feature loop" block from Part C, plus one line pointing to Part C of `SRC/INSTRUCTIONS.md` for the full reference. Use the renamed skill names if anything was renamed.
5. A suggestion to commit the changes, e.g. `chore: add Claude Code harness`. Don't commit unless the user says to.

---

# Part B: Rules for writing CLAUDE.md

CLAUDE.md is Claude's **persistent memory for the project**. It's loaded at the start of every session. Claude's built-in system prompt already uses up part of its instruction budget, and it reliably follows only about 150–200 instructions in total, so every line has to count.

### Structure: WHAT / WHY / HOW
1. **WHY**: the purpose of the project, its users and the business context. Big-picture context leads to better small decisions.
2. **WHAT**: the codebase map. Stack and versions, directory structure, key modules and their roles.
3. **HOW**: working instructions. Exact build, test and lint commands (including how to run a single test), code-style specifics, and workflow.
4. **What Claude gets wrong** (optional, and it grows over time). Each time Claude repeats a mistake, add one specific line.

### Do
- Keep it **under 200 lines**.
- Make every line specific and checkable. Good: *"Use `pnpm`, never `npm`"*. Bad: *"Use the right package manager."*
- List the exact commands with the right flags.
- Use the file hierarchy to keep each file small:

| File | Scope | In git? |
|---|---|---|
| `~/.claude/CLAUDE.md` | Every project, for you only | n/a (user-level, this harness doesn't touch it) |
| `./CLAUDE.md` | This project, the whole team | Yes, commit it |
| `./CLAUDE.local.md` | This project, you only | No, gitignore it |
| `./src/api/CLAUDE.md` | Loaded only when working in that directory | Yes |

### Don't
1. **Put everything in one file.** Move area-specific details into subdirectory CLAUDE.md files.
2. **Document what Claude already does right.** Leave out generic best practices like "write tests" or "handle errors".
3. **Write vague instructions.** "Keep code clean" changes nothing.
4. **Rely on CLAUDE.md to enforce behavior.** It's advice, not a guarantee. If something *must* always or never happen (formatting, blocking a command, protecting a file), make it a **hook** in `.claude/settings.json`.
5. **Store secrets**, or anything that changes often, such as current tasks. Use `docs/plans/` for that.
6. **Duplicate the README.** Link to it, or summarize only what Claude needs.

### Which tool for what

| Need | Use |
|---|---|
| Facts and conventions Claude should always know | `CLAUDE.md` |
| Know-how or a workflow needed only sometimes (auto or `/name`) | Skill (`.claude/skills/<name>/SKILL.md`) |
| Something that must happen every time, with no judgment | Hook (`.claude/settings.json`) |
| A focused job in a fresh, isolated context, or on a cheaper model | Subagent (`.claude/agents/<name>.md`) |
| Access to external systems (DB, GitHub, APIs) | MCP server (`.mcp.json`) |

---

# Part C: Day-to-day usage (cheat-sheet for the user)

### Typical feature loop
```
/interview add password reset   → Q&A, then docs/plans/PLAN_PASSWORD_RESET.md
(implement step by step)
/review                         → fresh-context code review: MUST FIX / SHOULD FIX / CONSIDER
/cleanup                        → strip debug logs, unused imports and dead code from the diff
/recap                          → update README/CLAUDE.md/docs, then git add + commit (no push)
```

### Skills
| Command | What it does |
|---|---|
| `/interview <topic>` | Keeps asking questions until the requirements are clear, has the planner write `docs/plans/PLAN_<TASK>.md`, then explains the plan |
| `/explain <thing>` | Uses the explorer to trace the code, then explains it with a beginner-friendly template. Claude can also run this on its own |
| `/review [target]` | Runs code-reviewer on your diff in a fresh context (the two-Claude pattern) |
| `/cleanup [files]` | Removes dead code, unused imports and debug statements, **only in the current changes** |
| `/cleanup-all [dir]` | The same across the whole repo. It reports first and applies only what you approve |
| `/recap [hint]` | Syncs the docs with the code, then stages and **commits** (never pushes) |

### Subagents
Claude uses these automatically when they fit, or you can ask by name: *"use the debugger subagent on the failing login test"*.

| Agent | Model | Can edit? | Job |
|---|---|---|---|
| `code-reviewer` | inherit | no | Reviews a diff: MUST FIX / SHOULD FIX / CONSIDER |
| `explorer` | haiku | no | "How does X work?" with `path:line` citations |
| `test-writer` | sonnet | yes (told to edit tests only, not enforced) | Writes and runs tests in the project's existing style |
| `debugger` | inherit | no | Reproduces a bug, tests hypotheses, reports the root cause with evidence. Doesn't fix |
| `planner` | inherit | no | Writes a step-by-step implementation plan. No code |

### Hooks (always on)
- Files are auto-formatted after each edit.
- Destructive shell commands are blocked, and Claude is told why. If you really mean it, run the command yourself with `! <command>`.
- Edits to `.env`, keys, lockfiles and `.git/` are blocked. `permissions.deny` also blocks *reading* the common `.env` and key files. That list doesn't cover every name (for example `.env.staging`), so add your own in `settings.json` if needed.
- `bash .claude/hooks/selftest.sh` checks that all the hooks still work.
- You get a desktop notification when Claude is waiting on you.

### Templates (`templates/`)
This folder lives in your project and stays there after the harness repo is deleted. Copy a file out of it when you need one, and leave the original blank.

| File | Use it for |
|---|---|
| `SPEC.md` | The 1-2 page spec for the human: goal, never-go-wrong list, constraints, flow, milestones |
| `SPEC-DETAILED.md` | The build spec for the coding agent: structure, data model, interfaces, milestone plans |
| `DECISIONS.md` | The append-only decision log that the two specs reference by ID (`D1`, `D2`, …) |
| `DESIGN.md` | A short design write-up: architecture, key decisions, failure handling, tradeoffs |
| `BRAIN.md` | The architecture baseline Claude reads when reviewing a design or drafting `SPEC.md` |
| `CLAUDE.md.template`, `CLAUDE.local.md.template`, `mcp.json.example` | Used during the install. Kept so you can redo or extend that setup later |

### Tips
- **Two-Claude review:** for the most honest review, implement in session A and run `/review` in a brand-new session B.
- **Ask to be interviewed:** "Interview me about …, and keep asking until you're sure."
- When Claude repeats a mistake, add one line under "What Claude gets wrong" in CLAUDE.md. If it *must never* happen, make it a hook instead.
- Run `/hooks`, `/agents`, and `/memory` in Claude Code to inspect what's loaded.
