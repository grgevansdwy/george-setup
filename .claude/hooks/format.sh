#!/usr/bin/env bash
# PostToolUse (Edit|Write|MultiEdit): auto-format the edited file.
# Only uses a formatter the PROJECT has opted into (config file / dependency),
# so a globally installed tool never reformats a repo that doesn't use it.
# gofmt and rustfmt are the language standard, so they always apply.
# Never blocks: always exits 0.

if ! command -v jq >/dev/null 2>&1; then
  echo "format.sh: jq not installed, skipping auto-format" >&2
  exit 0
fi

file=$(jq -r '.tool_input.file_path // empty')
[ -z "$file" ] || [ ! -f "$file" ] && exit 0

root=${CLAUDE_PROJECT_DIR:-$(git -C "$(dirname "$file")" rev-parse --show-toplevel 2>/dev/null || pwd)}
has() { command -v "$1" >/dev/null 2>&1; }
exists() { for f in "$@"; do [ -e "$root/$f" ] && return 0; done; return 1; }
mentions() { [ -f "$root/$1" ] && grep -q "$2" "$root/$1"; }

uses_prettier() {
  exists .prettierrc .prettierrc.json .prettierrc.js .prettierrc.cjs .prettierrc.mjs .prettierrc.yaml .prettierrc.yml .prettierrc.toml prettier.config.js prettier.config.cjs prettier.config.mjs node_modules/.bin/prettier \
    || mentions package.json '"prettier"'
}
uses_ruff()  { exists ruff.toml .ruff.toml || mentions pyproject.toml '\[tool\.ruff'; }
uses_black() { mentions pyproject.toml '\[tool\.black'; }

case "$file" in
  *.js|*.jsx|*.ts|*.tsx|*.mjs|*.cjs|*.json|*.css|*.scss|*.html|*.md|*.yaml|*.yml)
    if uses_prettier; then
      # --no-install: use the project's prettier only, never download one.
      if [ -x "$root/node_modules/.bin/prettier" ]; then "$root/node_modules/.bin/prettier" --write "$file" >/dev/null 2>&1
      elif has prettier; then prettier --write "$file" >/dev/null 2>&1
      elif has npx; then (cd "$root" && npx --no-install prettier --write "$file" >/dev/null 2>&1)
      fi
    fi ;;
  *.py)
    if uses_ruff && has ruff; then ruff format -q "$file" 2>/dev/null
    elif uses_black && has black; then black -q "$file" 2>/dev/null
    fi ;;
  *.go)  has gofmt   && gofmt -w "$file" 2>/dev/null ;;
  *.rs)  has rustfmt && rustfmt "$file" 2>/dev/null ;;
  *.sh|*.bash) exists .editorconfig && has shfmt && shfmt -w "$file" 2>/dev/null ;;
esac

exit 0
