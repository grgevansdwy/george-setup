---
name: fanout
description: Build a plan in parallel. Reads the Work units table of a docs/plans/PLAN_*.md, runs independent units at the same time in isolated worktrees (fan-out), then merges and verifies each wave (fan-in). Use after /interview when the plan says fan-out is worth it.
disable-model-invocation: true
argument-hint: "[plan file or TASK_NAME] [--max N] [--yes]"
---

# /fanout — parallel build from a plan

Input: $ARGUMENTS (plan path or TASK_NAME; empty = the newest `docs/plans/PLAN_*.md` whose status isn't Done). `--max N` caps parallel workers per wave (default 4). `--yes` skips the go/no-go question.

Current state:
!`echo "branch: $(git branch --show-current 2>/dev/null)"; git status --porcelain 2>/dev/null | head -20; b=$(jq -r '.worktree.baseRef // empty' ~/.claude/settings.json .claude/settings.json .claude/settings.local.json 2>/dev/null | tail -1); echo "worktree.baseRef: ${b:-fresh (default)}"`

## 0. Preconditions (stop and tell the user if any fails)
1. **Read the plan.** It needs a "Work units" table with ID, Owns, Depends on and Verify. If it's missing, or the plan says fan-out isn't worth it, say so and offer to implement serially instead.
2. **Feature branch.** If you're on the default branch (`main`/`master`), create `feat/<task-slug>` and switch to it.
3. **Clean, committed tree.** Workers branch from your committed `HEAD`, so uncommitted work is invisible to them. If the tree is dirty, ask to commit it first (e.g. `chore(<task-slug>): plan`).
4. **Worktree base must be `head`.** If `baseRef` above isn't `head`, workers would start from `main` without your branch. Ask the user to set `"worktree": {"baseRef": "head"}` in `.claude/settings.json` (or `.claude/settings.local.json`), then continue.

## 1. Schedule waves
- Turn "Depends on" into waves: a wave is every unit whose dependencies are all done. Keep each wave to at most `--max` units; split bigger waves.
- **Ownership check:** units in the same wave must not own the same file. If two do, move one to a later wave, and tell the user.
- Show the schedule as a short table (wave → units → owned files), and the rough cost: one worker per unit, each with its own context. Unless `--yes` was passed, ask "Start wave 1?".

## 2. Fan-out (per wave)
Spawn one **implementer** subagent per unit, **all in a single message** so they actually run in parallel. Each prompt must be self-contained, because workers don't see this conversation. Include:
- the plan path, the unit's full row, and the task slug (for the branch name `fanout/<task-slug>/<ID>`)
- the interface contracts from the plan, and anything earlier waves produced that this unit relies on
- "Only edit the files you own. Report anything else under *Needs outside my unit*."

Wait for every worker in the wave to finish before starting the fan-in. If a worker reports BLOCKED, don't retry it blindly: read why first.

## 3. Fan-in (per wave)
1. Collect the reports. Make a table: unit → status → branch → checks.
2. Spawn one **integrator** subagent with: the feature branch name, the DONE/PARTIAL branches in ID order, every "Needs outside my unit" item, the interface contracts, and the verify commands. It merges, resolves conflicts and runs the wave's checks.
3. If the integrator reports failures it couldn't fix, stop and show the user. Options: retry the unit with the failure as context, fix it here serially, or drop it from the plan.
4. Only start the next wave once this wave's integration is green. The next wave's worktrees branch from the new `HEAD`, so they see everything merged so far.

## 4. Finish
- Run the full verification from CLAUDE.md (tests, lint, typecheck) on the feature branch.
- Update the plan file: per-unit status, and `Status: Built — <YYYY-MM-DD>` at the top.
- **Clean up worker worktrees.** Each worker leaves its worktree under `.claude/worktrees/` (they hold commits, so Claude Code's sweep keeps them). For each one listed by `git worktree list` whose `HEAD` is already merged (`git merge-base --is-ancestor <its HEAD> HEAD`), run `git worktree remove <path>` and then `git branch -d <its branch>`. Never use `--force`. Leave unmerged ones in place and list them.
- Report in this shape, then suggest `/deep-review` and then `/recap`:
```
Built <task> in <n> waves (<k> units, <m> parallel at most)
| Unit | Status | Commit | Notes |
Integration: <conflicts resolved / fixes>
Checks: <command> → <result>
Left over: <skipped units, follow-ups, stale fanout/* branches>
```

## Rules
- Never push, and never merge into the default branch. The user does that.
- Don't let the main conversation do workers' jobs. If you're tempted to "just fix it quickly", hand it to a worker or the integrator so this context stays small.
- If a fan-out looks wrong half-way through (contracts drifting, many conflicts), stop and re-plan with the user. Re-planning beats pushing through.
