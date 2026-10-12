# george-setup: a plug-in Claude Code harness

A project-level `.claude/` setup (skills, subagents, hooks, settings and a workflow) that you can drop into any repo. An agent installs it and writes a `CLAUDE.md` tailored to that project.

This README is the guide for humans. [INSTRUCTIONS.md](INSTRUCTIONS.md) is the install procedure, written for the agent that does the install.

- [Quick start](#quick-start)
- [The workflow](#the-workflow)
- [Reference](#reference): every skill, subagent, workflow, hook, setting and template

---

## Quick start

**You need** `git`, `bash` and `jq`. The parallel features need the project to be a git repository. Formatters are optional.

**1. Clone this repo next to your project and open Claude Code in your project:**
```bash
git clone <this-repo> ~/george-setup
cd /path/to/your-project
claude
```

**2. Tell Claude:**
> Read `~/george-setup/INSTRUCTIONS.md` and install the harness into this project.

The agent copies the files, merges them with any `.claude/` setup you already have, adapts the hooks to your stack, asks you a few questions to write `CLAUDE.md`, and checks that everything works. Nothing is written to `~/.claude`, and nothing existing is overwritten without asking.

**3. Restart Claude Code** so the new hooks, agents and skills load. Run `/hooks` to confirm.

**4. Commit the result**, so your team gets the same setup and parallel workers can see it:
```bash
git add .claude CLAUDE.md templates .worktreeinclude .gitignore
git commit -m "chore: add Claude Code harness"
```

After that you can delete `~/george-setup`. Everything the harness needs lives in your project.

To check the hooks at any time: `bash .claude/hooks/selftest.sh`.

---

## The workflow

A feature goes through five commands. Each one hands a file or a branch to the next.

```
/interview add password reset
   │  asks questions until the requirements are clear
   │  writes docs/specs/SPEC_PASSWORD_RESET.md   ← 1-2 pages, for you to sign off
   │  writes docs/plans/PLAN_PASSWORD_RESET.md   ← the build plan, split into work units
   ▼
/fanout
   │  builds the independent units in parallel, each in its own git worktree
   │  merges each wave into your feature branch and runs the checks
   │  (or build step by step in the session when the plan says fan-out isn't worth it)
   ▼
/deep-review
   │  four reviewers in parallel (correctness, security, tests, design)
   │  a verifier tries to refute each serious finding, so you only see the real ones
   ▼
/cleanup
   │  strips debug logs, unused imports and dead code from the diff
   ▼
/recap
      updates README, CLAUDE.md and docs to match the code, then commits (never pushes)
```

Three files carry the work between steps:

| File | Written by | For | What it holds |
|---|---|---|---|
| `docs/specs/SPEC_<TASK>.md` | `/interview` → `/spec` | You | Goal, never-go-wrong list, constraints, flow, open decisions, milestones |
| `docs/DECISIONS.md` | `/decisions` | You and Claude | The append-only log of every big decision, with IDs the spec cites (`D1`, `D2`, …) |
| `docs/plans/PLAN_<TASK>.md` | `/interview` → `planner` | Claude | Ordered steps, files to change, and the work units `/fanout` runs in parallel |

Hooks run the whole time without being asked: files are formatted after each edit, destructive commands and edits to secrets are blocked, and Claude can't say "done" while the project's fast checks fail.

### Which tool for which job

| Shape of the work | Use | Why |
|---|---|---|
| A feature with 3+ independent pieces | `/interview` → `/fanout` | One worktree per unit, then a merge-and-verify step per wave |
| A small or tightly coupled change | `/interview`, then build in the session | Fan-out costs more than it saves here |
| A design you want checked before building | `/architecture-reviewer <design>` | Scores it against a fixed baseline and names the rule each problem breaks |
| Questions about the code ("how does X work?") | `/explain` | Read-only, traced through the real code with `path:line` citations |
| Review before merging | `/deep-review`, or built-in `/code-review high` | Different lenses catch different bugs, and the verifier drops false alarms |
| A bug whose cause is unclear | `/investigate <symptom>` | Tests competing hypotheses in parallel instead of anchoring on the first idea |
| Sweep the whole repo for one concern | `/audit <concern>` | A script holds the plan, so dozens of agents don't flood your context |
| One mechanical change across many files | built-in `/batch <instruction>` | Many worktree agents, each opening its own PR |
| Two unrelated tasks at once | `claude -w <name>` in a second terminal | Separate sessions in separate worktrees |

Fan-out multiplies token use, because each worker has its own context. It pays off when the units are truly independent. For a small or tightly coupled change, one session is faster and cheaper.

---

## Reference

### Skills (`.claude/skills/`)

Skills are commands you type as `/name`. Claude can also run the ones marked **auto** on its own when they fit.

**Plan**

| Skill | What it does |
|---|---|
| `/interview <topic>` | Asks questions until the requirements are clear, then writes the spec and the build plan and explains the plan in plain language. |
| `/spec <topic>` (auto) | Fills the bundled spec template into `docs/specs/SPEC_<TASK>.md`, the 1-2 page document you sign off on. `/interview` calls it for you. |
| `/decisions <decision>` (auto) | Appends a decision (options, choice, reason, how reversible) to the append-only log `docs/DECISIONS.md` and returns its ID. |
| `/architecture-reviewer [design]` (auto) | Reviews a design, especially for an LLM or agent system, against a baseline of principles, defaults and 25 red flags, and returns a scored critique. |

**Build**

| Skill | What it does |
|---|---|
| `/fanout [plan] [--max N] [--yes]` | Builds a plan's work units in parallel, one `implementer` per unit in its own worktree, then has the `integrator` merge and verify each wave. |
| `/investigate <symptom>` | Reproduces a bug, then runs one `debugger` per hypothesis in parallel and compares the evidence to find the root cause. |
| `/explain <thing>` (auto) | Traces how a feature, flow or file works and explains it in a beginner-friendly format with `path:line` citations. |

**Review and ship**

| Skill | What it does |
|---|---|
| `/deep-review [target] [--quick]` | Runs parallel reviewers with different lenses, verifies every serious finding, and gives one MUST FIX / SHOULD FIX / CONSIDER report. |
| `/cleanup [files]` | Removes debug statements, unused imports and dead code, only in your current uncommitted changes. |
| `/cleanup-all [dir]` | Does the same across the whole repo, reporting first and applying only what you approve. |
| `/recap [hint]` | Brings the docs in line with the code, then stages and commits. It never pushes. |

### Subagents (`.claude/agents/`)

Subagents do one focused job in a fresh context, so the main conversation stays small. The skills above call them, Claude uses them on its own when they fit, and you can ask by name: *"use the debugger subagent on the failing login test"*.

| Agent | Model | Can edit? | What it does |
|---|---|---|---|
| `planner` | inherit | no | Reads the code and writes the implementation plan, including the parallel work units table. |
| `explorer` | haiku | no | Answers "how does X work?" and "where is Y?" with `path:line` citations, cheaply enough to run several at once. |
| `implementer` | sonnet | yes, in its own worktree | Builds one work unit of a plan, runs that unit's checks, and commits to a `fanout/<task>/<ID>` branch. |
| `integrator` | inherit | yes | Merges one wave's unit branches into the feature branch, resolves conflicts, and runs the checks. |
| `code-reviewer` | inherit | no | Reviews a diff it didn't write, optionally through one lens, and reports MUST FIX / SHOULD FIX / CONSIDER. |
| `verifier` | inherit | no | Tries to refute other agents' findings against the real code and marks each CONFIRMED, REFUTED or UNVERIFIED. |
| `debugger` | inherit | no | Reproduces a failure, tests a hypothesis, and reports the root cause with evidence, without fixing it. |
| `test-writer` | sonnet | yes | Writes and runs tests in the project's existing framework and style. |

"inherit" means the agent uses whatever model your session is on.

### Workflow (`.claude/workflows/`)

| Workflow | What it does |
|---|---|
| `/audit <concern>` | A saved script that sends one agent to each file to look for a concern, then has independent agents try to refute every finding. Watch it with `/workflows`. |

### Hooks (`.claude/hooks/`)

Hooks are scripts Claude Code runs automatically. Unlike instructions in `CLAUDE.md`, they can't be skipped or forgotten.

| Hook | Runs | What it does |
|---|---|---|
| `block-dangerous.sh` | Before every shell command | Blocks destructive commands such as `rm -rf /`, force push, `git reset --hard`, `DROP TABLE` and `curl … \| sh`, and tells Claude why. |
| `protect-files.sh` | Before every file edit | Blocks edits to `.env` files, keys, lockfiles and `.git/`. |
| `format.sh` | After every file edit | Formats the edited file, but only with a formatter the project is configured for (prettier, ruff, black), plus gofmt and rustfmt. |
| `verify-gate.sh` | When Claude or a parallel worker is about to finish | Runs the project's fast checks and sends Claude back to fix failures before it can say "done". |
| `notify.sh` | When Claude needs you | Shows a desktop notification on macOS and Linux. |
| `selftest.sh` | Only when you run it | Runs test cases against every hook above and ends with `ALL PASSED`. |

If a hook blocks something you really meant to do, run it yourself in the prompt with `! <command>`.

The verify gate lets Claude stop on the second try, so a check that can't pass never traps it in a loop. In the main session it only runs when files changed.

### Settings (`.claude/settings.json`)

| Setting | What it does |
|---|---|
| `permissions.allow` | Lets safe git commands (`status`, `diff`, `log`, `add`, `commit`, `switch`, `merge`, …) and `jq` run without a permission prompt, which matters once several agents run at once. |
| `permissions.deny` | Refuses `rm -rf` on `/` and `~`, force push and `git reset --hard`, and refuses *reading* `.env`, `.pem` and `.key` files. |
| `worktree.baseRef: "head"` | Makes parallel workers start from your current branch instead of the default branch, so they can see your work. |
| `hooks` | Connects each hook script above to the event that triggers it. |

The deny list doesn't cover every secret file name (`.env.staging`, for example). Add your own if you need to.

### Templates (`templates/`)

The installer fills these in once for your project. The folder is copied into your project so you can redo or extend the setup later.

| Template | Becomes | What it's for |
|---|---|---|
| `CLAUDE.md.template` | `CLAUDE.md` | The project memory Claude loads every session: why the project exists, the codebase map, and the exact commands. |
| `CLAUDE.local.md.template` | `CLAUDE.local.md` | Your personal notes for this project (local ports, preferences), gitignored. |
| `verify.sh.example` | `.claude/verify.sh` | The fast checks (typecheck, lint, quick tests) the verify gate runs. |
| `worktreeinclude.example` | `.worktreeinclude` | The gitignored files, such as `.env`, to copy into every worktree so parallel workers can run the app. |
| `mcp.json.example` | `.mcp.json` | An optional MCP server setup showing the read-only and read-write connection split. |

Two more templates live inside the skills that use them: `.claude/skills/spec/template.md` (the spec) and `.claude/skills/decisions/template.md` (the decision log).

### What ends up in your project

```
your-project/
├── CLAUDE.md                  project memory, written for your codebase
├── CLAUDE.local.md            your personal notes (gitignored)
├── .worktreeinclude           files copied into each worktree
├── .mcp.json                  only if you asked for MCP servers
├── templates/                 the install-time templates
├── .claude/
│   ├── settings.json          permissions, worktree base, hook wiring
│   ├── verify.sh              your project's fast checks
│   ├── skills/                the 11 skills
│   ├── agents/                the 8 subagents
│   ├── hooks/                 the 6 hook scripts
│   └── workflows/             /audit
└── docs/                      created as you work
    ├── specs/SPEC_<TASK>.md
    ├── plans/PLAN_<TASK>.md
    └── DECISIONS.md
```

### Tips

- **Commit before you fan out.** Workers branch from your committed `HEAD`, so uncommitted work is invisible to them.
- **Review in a fresh session.** For the most honest review, build in one session and run `/deep-review` in a brand-new one.
- **Too many permission prompts during `/fanout`?** Add the commands workers keep asking about to `permissions.allow`, or run the built-in `/fewer-permission-prompts`.
- **Leftover `fanout/*` branches** mean a unit wasn't merged. `git branch --list 'fanout/*'` shows them.
- **When Claude repeats a mistake**, add one line under "What Claude gets wrong" in `CLAUDE.md`. If it must never happen, make it a hook instead.
- **To see what's loaded and running**, use `/hooks`, `/memory`, `/tasks` and `/workflows` in Claude Code.
