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
- **Skills:** `/interview`, `/explain`, `/review`, `/cleanup`, `/cleanup-all`, `/recap`
- **Subagents:** `code-reviewer`, `explorer`, `test-writer`, `debugger`, `planner`
- **Hooks:** multi-language auto-format, a dangerous-command blocker, secret and lockfile protection, and desktop notifications
- **Templates:** `CLAUDE.md` (WHAT/WHY/HOW), `CLAUDE.local.md`, `.mcp.json` example (read-only and read-write split), plus `SPEC.md`, `SPEC-DETAILED.md`, `DECISIONS.md`, `DESIGN.md` and `BRAIN.md`. The whole `templates/` folder is copied into your project, so it's still there after you delete this clone

See [INSTRUCTIONS.md](INSTRUCTIONS.md) for the full install procedure, the CLAUDE.md rules, and the day-to-day cheat-sheet.

## Requirements
`bash` and `jq`. The formatters are optional. Prettier, ruff and black run only if the project is configured for them; gofmt and rustfmt run on Go and Rust files whenever they're installed. Test the hooks with `bash .claude/hooks/selftest.sh`.
