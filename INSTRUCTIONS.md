# INSTRUCTIONS: installing this Claude Code harness into a project

> **This file is written for the agent doing the install.** The human guide (quick start, workflow, and a reference for every skill, subagent, hook and setting) is `README.md`.
>
> Follow Part A step by step. Part B covers how to write CLAUDE.md, and Part C is the cheat-sheet you hand to the user at the end.
>
> **No user available?** If you're running headless or as a subagent, wherever a step says to ask, choose the safest default: keep the existing file, skip optional steps, and mark anything you couldn't check as unverified. List every assumption in the A9 report.

## What gets installed

All of it is project-level, under `<target>/.claude/`. **Never write to `~/.claude/`.**

| Piece | Path | What it does |
|---|---|---|
| Settings | `.claude/settings.json` | Wires up the hooks, adds `permissions.allow` (safe git commands) and `permissions.deny` rules, and sets `worktree.baseRef: "head"` so parallel workers start from your branch |
| Hook: format | `.claude/hooks/format.sh` | After each Edit/Write, formats the file, but only with a formatter the project has opted into: prettier, ruff or black need a config file or dependency. gofmt and rustfmt always apply |
| Hook: block-dangerous | `.claude/hooks/block-dangerous.sh` | Blocks commands like `rm -rf /` and `~`, force push, `reset --hard`, `clean -f`, `DROP TABLE`, and `curl … \| sh` |
| Hook: protect-files | `.claude/hooks/protect-files.sh` | Blocks edits to `.env*` (templates are allowed), keys, lockfiles and `.git/` |
| Hook: notify | `.claude/hooks/notify.sh` | Shows a desktop notification when Claude needs you (macOS and Linux) |
| Hook: verify-gate | `.claude/hooks/verify-gate.sh` | On `Stop` (and on each parallel worker's stop), runs the project's fast checks in `.claude/verify.sh` and sends Claude back to fix failures before it can say "done" |
| Fast checks | `.claude/verify.sh` | **Written for each project** from `templates/verify.sh.example` (see A4) |
| Worktree copy list | `.worktreeinclude` | Gitignored files (like `.env`) copied into every worktree Claude creates, from `templates/worktreeinclude.example` |
| Self-test | `.claude/hooks/selftest.sh` | Runs test cases against every hook. It isn't attached to any hook event |
| Subagents | `.claude/agents/*.md` | `code-reviewer`, `explorer`, `test-writer`, `debugger`, `planner`, plus the fan-out trio `implementer`, `integrator`, `verifier` |
| Skills | `.claude/skills/*/` | `/interview`, `/spec`, `/decisions`, `/architecture-reviewer`, `/explain`, `/cleanup`, `/cleanup-all`, `/recap`, and the parallel ones `/fanout`, `/deep-review`, `/investigate`. Each is a directory: `SKILL.md` plus any supporting file (`spec` and `decisions` each carry a `template.md`) |
| Workflows | `.claude/workflows/*.js` | `/audit`: a saved dynamic workflow that fans out one agent per file and verifies every finding |
| Project memory | `CLAUDE.md` | **Written for each project** from `templates/CLAUDE.md.template` (see Part B) |
| Personal memory | `CLAUDE.local.md` | Created from the template and gitignored |
| MCP (optional) | `.mcp.json` | Only if the user asks for it, adapted from `templates/mcp.json.example` |
| Templates | `templates/` | The whole folder, copied as it is (see A2). These are the install-time templates named above: `CLAUDE.md.template`, `CLAUDE.local.md.template`, `mcp.json.example`, `verify.sh.example` and `worktreeinclude.example`. The spec and decision-log templates are not here: they live inside the `spec` and `decisions` skills |

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
- each skill **directory** in `SRC/.claude/skills/`, with everything in it (`cp -Rp`). `spec/template.md` and `decisions/template.md` must arrive with their `SKILL.md`, or those skills have nothing to fill in
- each workflow script in `SRC/.claude/workflows/`

Create any missing directories, and copy with `cp -p` so file permissions are kept. For each unit:
- If it doesn't exist in `TGT`, copy it.
- If it exists and is identical, skip it.
- If it exists and is different, show the user a short diff and ask: keep theirs, replace with ours, or install ours under a new name (e.g. `fanout-harness`).

When you rename something:
- For a skill, rename the directory **and** the `name:` in its frontmatter.
- Skills also call each other by name: `/interview` calls `spec`, `spec` calls `decisions` and `architecture-reviewer`, and `architecture-reviewer` and `/recap` point to `spec` and `decisions`. Update those mentions when you rename one. Those three must stay model-invocable (no `disable-model-invocation: true`), or the calls stop working.
- For an agent, rename the file and its `name:`, then update every skill that calls it by name. `/deep-review` calls `code-reviewer` and `verifier`, `/interview` calls `planner` and `explorer`, `/fanout` calls `implementer` and `integrator`, `/investigate` calls `debugger`, `explorer` and `test-writer`, and `/explain` and `/cleanup-all` call `explorer`.
- Don't name any skill `review`: Claude Code's built-in `/review` is an alias of its multi-agent `/code-review`, and a project skill with that name collides with it.
- Use the new names in the CLAUDE.md you write and in the cheat-sheet you give the user.

Then run `chmod +x "$TGT"/.claude/hooks/*.sh`.

**Templates folder.** Copy every file in `SRC/templates/` to `TGT/templates/`, using the same copy / skip / ask rule per file. This copy is what keeps the templates available after `SRC` is deleted, so don't skip it and don't replace it with a symlink or a path back to `SRC`.
- If `TGT/templates/` already exists and belongs to the project (Django, Jinja or email templates, for example), don't mix our files into it. Ask the user where to put them, and use `.claude/templates/` if they have no preference or aren't available.
- Wherever the folder ends up, use that path in the CLAUDE.md you write and in the A9 report.

### A3. Merge settings.json
- If `TGT/.claude/settings.json` doesn't exist, copy `SRC/.claude/settings.json`.
- If it does exist:
  1. **Check for conflicting hooks first.** Look at every existing `PostToolUse` group whose `matcher` mentions `Edit` or `Write`. If its command runs a formatter (prettier, ruff, black, eslint --fix, biome and so on), ask before adding ours, so files don't get formatted twice. If the user says no, remove the `format.sh` group from the merge input.
  2. **Check for an existing Stop hook** that runs tests or checks. If there is one, ask whether `verify-gate.sh` should replace it, so checks don't run twice at the end of every turn.
  3. **Merge** with the command below. It keeps all existing keys and their order. It appends SRC's allow and deny rules that aren't already there, adds `worktree.baseRef` only if the target doesn't set it, and appends each SRC hook group unless an identical one already exists. "Identical" means a JSON-equal group, so after merging, check that our hook scripts don't appear twice:
     ```bash
     tmp=$(mktemp) && jq -s '
       def addnew($xs): reduce $xs[] as $x (.; if index([$x]) then . else . + [$x] end);
       .[0] as $t | .[1] as $s
       | $t
       | .permissions = (($t.permissions // {})
           | .allow = ((.allow // []) | addnew($s.permissions.allow // []))
           | .deny = ((.deny // []) | addnew($s.permissions.deny // [])))
       | (if $s.worktree then .worktree = ($s.worktree + ($t.worktree // {})) else . end)
       | .hooks = reduce (($s.hooks // {}) | to_entries[]) as $e (($t.hooks // {});
           .[$e.key] = ((.[$e.key] // []) | addnew($e.value)))
     ' "$TGT/.claude/settings.json" "$SRC/.claude/settings.json" > "$tmp" \
     && jq . "$tmp" >/dev/null && mv "$tmp" "$TGT/.claude/settings.json"
     ```
  4. If the target already sets `worktree.baseRef` to anything other than `"head"`, tell the user that `/fanout` needs `"head"` (otherwise parallel workers start from the default branch and can't see the feature branch).
- If `TGT/.claude/settings.local.json` exists, leave it alone. It's personal.

### A4. Adapt to the stack
Look at the manifests (`package.json`, `pyproject.toml`, `go.mod`, `Cargo.toml`, `Gemfile`, `composer.json`, `Makefile`, CI config) and then:
1. **Formatter.** `format.sh` runs prettier, ruff or black only if the project is configured for them, and gofmt and rustfmt always. If the project uses something else, edit the matching `case` branch. For example: biome (`npx --no-install biome format --write`), `eslint --fix`, `dprint`, `clang-format`, `mix format`, `dotnet format`. If the project has no formatter config, leave `format.sh` as it is: it won't touch JS or Python files. You can suggest adding a formatter in A9.
2. **Protected files.** Add any project-specific lockfiles or generated files to `protect-files.sh`, such as generated API clients or `schema.prisma` migrations folders if they should never be hand-edited.
3. **Dangerous commands.** Add project-specific destructive commands to `block-dangerous.sh` if relevant, such as `prisma migrate reset`, `rails db:drop` or `terraform destroy`.
4. Make a note of the **test, lint and build commands**. They go into CLAUDE.md in A5.
5. **Allow the project's own commands** so Claude (and every parallel worker) doesn't stop for a permission prompt each time. Add the real ones to `permissions.allow` in `TGT/.claude/settings.json`, e.g. `"Bash(npm test *)"`, `"Bash(npm run lint*)"`, `"Bash(pnpm *)"`, `"Bash(uv run pytest*)"`, `"Bash(make test*)"`. Only add commands that are safe to run unattended. Never allow deploy, publish, migrate-reset or anything that touches production. With parallel subagents, every unapproved command becomes a prompt in your main session, so this step matters more than it looks.
6. **Write `.claude/verify.sh`** from `templates/verify.sh.example`. Keep only the fast checks this project really has (typecheck, lint, a quick unit-test run), aiming for under 60 seconds, then `chmod +x` it. Run it once. If there's nothing fast to run, skip the file: `verify-gate.sh` does nothing without it.
7. **Write `.worktreeinclude`** from `templates/worktreeinclude.example`, listing only gitignored files that exist and that the app or tests need (usually `.env`, `.env.local`). Each worktree is a fresh checkout, so without this, parallel workers can't run anything that reads env files. Add the dependency install command to CLAUDE.md, since workers need to run it in each new worktree.

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
   .claude/worktrees/
   ```
3. Make sure `.claude/settings.json`, `.claude/hooks/`, `.claude/agents/`, `.claude/skills/`, `.claude/workflows/`, `.claude/verify.sh`, `.worktreeinclude`, `templates/` and `CLAUDE.md` are **not** gitignored. They're meant to be shared with the team, and worktrees only contain committed files, so `verify.sh` must be committed for parallel workers to run it.

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
ls .claude/agents .claude/skills .claude/workflows
ls .claude/skills/spec/template.md .claude/skills/decisions/template.md
[ -f .claude/verify.sh ] && bash .claude/verify.sh && echo "verify.sh OK"
jq -r '.worktree.baseRef' .claude/settings.json   # should print head
ls templates                        # must match SRC/templates file for file
wc -l CLAUDE.md
```
**Heads-up:** the `block-dangerous` hook may be active in your own session, either from SRC's settings or from TGT's after A3. It checks the **whole Bash command line**, including heredocs and `echo` strings. So never type test cases like a force push or `rm -rf` into a Bash command, because your own call will be blocked. Use `selftest.sh`, which keeps the cases inside the script. If you add project-specific rules in A4, add matching cases to `selftest.sh` with the Write or Edit tool.

### A9. Report to the user
Finish with:
1. What was **installed**, what was **merged**, and what was **skipped**, with the reason for each skip.
2. Any **manual follow-ups**, such as installing `jq` or a formatter, setting MCP env vars, or reviewing the CLAUDE.md diff.
3. **"Restart Claude Code (or run `/hooks` to check) so the new hooks, agents and skills load. If you've never opened Claude Code interactively in this project, do it once and accept the trust prompt: until the folder is trusted, headless runs (`claude -p`) ignore the project's `permissions.allow` rules and the hooks inside agent files, including the implementer's verify gate."**
4. The cheat-sheet from Part C, plus one line pointing to `SRC/README.md` for the full reference. Use the renamed skill names if anything was renamed.
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

# Part C: Cheat-sheet to hand to the user

Give the user this block at the end of the install (A9), adjusted for any renamed skills. Keep it this short. The full reference for every skill, subagent, hook and setting is in `SRC/README.md`, which is written for them.

### Typical feature loop
```
/interview add password reset   → Q&A, then docs/specs/SPEC_PASSWORD_RESET.md (for you to sign off)
                                  and docs/plans/PLAN_PASSWORD_RESET.md (work units for the build)
/fanout                         → builds independent units in parallel worktrees, merges each wave, runs checks
   (or implement step by step here when the plan says fan-out isn't worth it)
/deep-review                    → 4 parallel reviewers (correctness, security, tests, design) + a verifier
/cleanup                        → strip debug logs, unused imports and dead code from the diff
/recap                          → update README/CLAUDE.md/docs, then git add + commit (no push)
```

### Also worth knowing
- `/architecture-reviewer <design>` critiques a design before you build it. `/decisions <decision>` logs a decision in `docs/DECISIONS.md`.
- `/investigate <symptom>` for a bug with an unclear cause, `/explain <thing>` for "how does X work?", `/audit <concern>` to sweep the whole repo.
- **Commit before you fan out.** Parallel workers branch from your committed `HEAD`, so uncommitted work is invisible to them.
- Destructive commands and edits to secrets or lockfiles are blocked by hooks. If you really mean it, run the command yourself with `! <command>`.
- When Claude repeats a mistake, add one line under "What Claude gets wrong" in CLAUDE.md. If it *must never* happen, make it a hook instead.
