# george-setup: a plug-in Claude Code harness

A project-level `.claude/` setup (skills, hooks, subagents and settings) that you can drop into any repo. An agent installs it and writes a `CLAUDE.md` tailored to that project.

## Install into your project
```bash
git clone <this-repo> ~/george-setup
cd /path/to/your-project
claude
```
Then tell Claude:
> Read `~/george-setup/INSTRUCTIONS.md` and install the harness into this project.

The agent copies the files, merges them with any `.claude/` setup you already have, adapts the hooks to your stack, interviews you to write `CLAUDE.md`, and checks that everything works. Nothing is written to `~/.claude`.

## What's inside
- **Skills:** `/interview` (which runs `/spec`), `/architecture-review`, `/explain`, `/cleanup`, `/cleanup-all`, `/recap`, plus the parallel (fan-out / fan-in) ones: `/fanout`, `/deep-review`, `/investigate`
- **Subagents:** `code-reviewer`, `explorer`, `test-writer`, `debugger`, `planner`, plus `implementer` (works in its own git worktree), `integrator` (merges parallel work) and `verifier` (fact-checks other agents' findings)
- **Workflow:** `/audit`, a saved dynamic workflow that fans out one agent per file and verifies every finding
- **Hooks:** multi-language auto-format, a dangerous-command blocker, secret and lockfile protection, a verify gate that won't let Claude say "done" while the fast checks fail, and desktop notifications
- **Settings:** an allowlist for safe git commands (fewer permission prompts, which matters a lot once several agents run at once) and `worktree.baseRef: "head"` so parallel workers start from your branch
- **Specs and decisions:** `/spec` writes a short human-readable spec per task and keeps an append-only `docs/DECISIONS.md`; `/architecture-review` checks designs against `BRAIN.md`. Both carry their templates inside the skill, so nothing extra is copied into your project
- **Install-time templates** (`templates/`, never copied into your project): `CLAUDE.md` (WHAT/WHY/HOW), `CLAUDE.local.md`, `.mcp.json` example (read-only and read-write split), `verify.sh.example` and `worktreeinclude.example`

See [INSTRUCTIONS.md](INSTRUCTIONS.md) for the full install procedure, the CLAUDE.md rules, and the day-to-day cheat-sheet.

## Requirements
`git`, `bash` and `jq`. Parallel features (`/fanout`, worktree subagents, `/batch`) need a git repository. The formatters are optional. Prettier, ruff and black run only if the project is configured for them; gofmt and rustfmt run on Go and Rust files whenever they're installed. Test the hooks with `bash .claude/hooks/selftest.sh`.
