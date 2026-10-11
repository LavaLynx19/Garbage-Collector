#!/usr/bin/env bash
# PostToolUse hook: auto-format files after Edit/Write.
# Reads the hook payload JSON from stdin (Claude Code hook protocol).
set -euo pipefail

input=$(cat)
FILE=$(printf '%s' "$input" | jq -r '.tool_input.file_path // empty')

if [[ -z "$FILE" ]] || [[ ! -f "$FILE" ]]; then
  exit 0
fi

# Format JS/TS/JSX/TSX with prettier
if [[ "$FILE" =~ \.(js|ts|jsx|tsx)$ ]]; then
  npx prettier --write "$FILE" 2>/dev/null || true
fi

# Format Go with gofmt
if [[ "$FILE" =~ \.go$ ]]; then
  gofmt -w "$FILE" 2>/dev/null || true
fi

# Format Python with ruff (per rules/python.md), fall back to black
if [[ "$FILE" =~ \.py$ ]]; then
  ruff format --quiet "$FILE" 2>/dev/null || python3 -m black --quiet "$FILE" 2>/dev/null || true
fi

exit 0
