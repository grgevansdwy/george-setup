#!/usr/bin/env bash
# Notification: desktop alert when Claude needs permission or is idle.
# macOS -> osascript, Linux -> notify-send, anything else -> no-op.

msg="Claude needs you"
if command -v jq >/dev/null 2>&1; then
  m=$(jq -r '.message // empty' 2>/dev/null)
  [ -n "$m" ] && msg=$m
fi
project=$(basename "${CLAUDE_PROJECT_DIR:-$PWD}")
msg=${msg//\"/\'}

case "$(uname -s)" in
  Darwin) osascript -e "display notification \"$msg\" with title \"Claude Code\" subtitle \"$project\"" >/dev/null 2>&1 ;;
  Linux)  command -v notify-send >/dev/null 2>&1 && notify-send "Claude Code ($project)" "$msg" ;;
esac

exit 0
