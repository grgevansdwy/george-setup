#!/usr/bin/env bash
# Stop / SubagentStop: don't let Claude say "done" while the project's fast checks fail.
# Runs .claude/verify.sh (written per project at install time) in the directory Claude
# is working in. That's the worktree for isolated subagents, because the hook's `cwd`
# follows Claude while $CLAUDE_PROJECT_DIR stays on the main checkout.
#
#   verify-gate.sh            main session: only runs when there are uncommitted changes
#   verify-gate.sh --always   subagents: always runs (workers commit before they stop)
#
# Exit 2 = block stopping and show the failure (stderr) to Claude. Anything else lets it stop.

always=0; [ "$1" = "--always" ] && always=1
input=$(cat)

if ! command -v jq >/dev/null 2>&1; then
  echo "verify-gate.sh: jq not installed, checks skipped" >&2
  exit 0
fi

# Second stop in a row after we already blocked once: let it go, so a check that
# can't be fixed never traps Claude in a loop. It already saw the failure.
[ "$(printf '%s' "$input" | jq -r '.stop_hook_active // false')" = "true" ] && exit 0

dir=$(printf '%s' "$input" | jq -r '.cwd // empty')
[ -n "$dir" ] && [ -d "$dir" ] || dir=$PWD

check="${CLAUDE_PROJECT_DIR:-$dir}/.claude/verify.sh"
[ -f "$dir/.claude/verify.sh" ] && check="$dir/.claude/verify.sh"   # a worktree's own copy wins
[ -f "$check" ] || exit 0                                            # project has no fast checks yet

if [ $always = 0 ] && git -C "$dir" rev-parse --git-dir >/dev/null 2>&1; then
  if git -C "$dir" diff --quiet HEAD 2>/dev/null && [ -z "$(git -C "$dir" ls-files --others --exclude-standard 2>/dev/null)" ]; then
    exit 0   # nothing changed this turn (Q&A, reading code): don't slow it down
  fi
fi

if command -v timeout >/dev/null 2>&1; then run=(timeout 280 bash "$check"); else run=(bash "$check"); fi
out=$(cd "$dir" && "${run[@]}" 2>&1)
status=$?
[ $status = 0 ] && exit 0

{
  echo "Fast checks failed (.claude/verify.sh, exit $status) in $dir."
  echo "Fix them before finishing, or explain clearly why they can't pass yet:"
  printf '%s\n' "$out" | tail -40
} >&2
exit 2
