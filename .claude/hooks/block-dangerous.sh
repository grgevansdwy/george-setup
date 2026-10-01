#!/usr/bin/env bash
# PreToolUse (Bash): block destructive shell commands.
# Exit 2 = block and show the reason (stderr) to Claude.
# This is a safety net, not a sandbox; permissions.deny in settings.json backs it up.

if ! command -v jq >/dev/null 2>&1; then
  echo "block-dangerous.sh: jq not installed, command not checked" >&2
  exit 0
fi

cmd=$(jq -r '.tool_input.command // empty')
[ -z "$cmd" ] && exit 0

block() { echo "Blocked by .claude/hooks/block-dangerous.sh: $1. Ask the user to run it themselves if it is really intended." >&2; exit 2; }

# rm with recursive + force flags (any order/form) aimed at /, ~, $HOME, *, . or ..
if echo "$cmd" | grep -qE '(^|[;&|[:space:]])(sudo[[:space:]]+)?rm[[:space:]]'; then
  rm_args=$(echo "$cmd" | sed -E 's/.*(^|[;&|[:space:]])rm[[:space:]]+//' | sed -E 's/[;&|].*//')
  recursive=0; force=0; risky=0
  set -f  # don't let * glob into filenames while splitting
  for tok in $rm_args; do
    tok=${tok//[\"\']/}
    case "$tok" in
      --recursive) recursive=1 ;;
      --force) force=1 ;;
      --*) ;;
      -*) [[ "$tok" == *[rR]* ]] && recursive=1; [[ "$tok" == *f* ]] && force=1 ;;
      '/'|'/*'|'~'|'~/'|'~/*'|'$HOME'|'$HOME/'|'$HOME/*'|'*'|'.'|'..'|'./'|'../'|'./*') risky=1 ;;
    esac
  done
  set +f
  [ $recursive = 1 ] && [ $force = 1 ] && [ $risky = 1 ] && block "recursive force delete of a root/home/wildcard path"
fi

# Force push (but --force-with-lease is allowed)
if echo "$cmd" | grep -qE '\bgit\s+push\b' && echo "$cmd" | grep -qE '(\s--force(\s|$)|\s-[a-zA-Z]*f[a-zA-Z]*(\s|$)|\s\+[^ ]+)'; then
  block "git force push (use --force-with-lease if you must)"
fi

# Hard reset / clean that throws away work
echo "$cmd" | grep -qE '\bgit\s+reset\s+--hard\b' && block "git reset --hard discards uncommitted work"
echo "$cmd" | grep -qE '\bgit\s+clean\s+-[a-zA-Z]*f' && block "git clean -f deletes untracked files"

# Destructive SQL
echo "$cmd" | grep -qiE '\b(drop\s+(table|database|schema)|truncate\s+table)\b' && block "destructive SQL statement"

# Pipe-to-shell installs
echo "$cmd" | grep -qE '\b(curl|wget)\b[^|]*\|\s*(sudo\s+)?(ba|z)?sh\b' && block "piping a download into a shell"

# Disk-level destruction
echo "$cmd" | grep -qE '\b(mkfs|dd\s+if=.*of=/dev/)' && block "disk-level write"

exit 0
