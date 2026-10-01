#!/usr/bin/env bash
# PreToolUse (Edit|Write|MultiEdit): stop edits to secrets, lockfiles and git internals.
# Exit 2 = block and show the reason (stderr) to Claude.

if ! command -v jq >/dev/null 2>&1; then
  echo "protect-files.sh: jq not installed, file not checked" >&2
  exit 0
fi

file=$(jq -r '.tool_input.file_path // empty')
[ -z "$file" ] && exit 0
name=$(basename "$file")

block() { echo "Blocked by .claude/hooks/protect-files.sh: $file is protected ($1). Ask the user to change it manually." >&2; exit 2; }

# Secrets: .env, .env.local, .env.production ... but templates are fine
case "$name" in
  .env.example|.env.sample|.env.template) ;;
  .env|.env.*) block "environment secrets" ;;
  *.pem|*.key|*.p12|*.pfx|id_rsa*|id_ed25519*) block "private key / certificate" ;;
esac

# Lockfiles: change them via the package manager, not by hand
case "$name" in
  package-lock.json|yarn.lock|pnpm-lock.yaml|bun.lockb|poetry.lock|uv.lock|Pipfile.lock|Cargo.lock|go.sum|Gemfile.lock|composer.lock)
    block "lockfile, update it through the package manager" ;;
esac

# Git internals
case "$file" in
  */.git/*|.git/*) block "git internals" ;;
esac

exit 0
