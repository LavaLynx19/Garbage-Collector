#!/usr/bin/env bash
# PostToolUse hook: enforces .claude/rules/design-plan-checklist.md -- every
# project PLAN.md must carry an `## Implementation Checklist` section.
# Warns the model (block + reason) when the section is missing.
set -euo pipefail

input=$(cat)
path=$(printf '%s' "$input" | jq -r '.tool_input.file_path // empty')

[[ "$(basename "$path" 2>/dev/null)" == "PLAN.md" ]] || exit 0
[[ -f "$path" ]] || exit 0

if grep -q '^## Implementation Checklist' "$path"; then
  exit 0
fi

jq -n --arg reason "Plan file ${path} is missing the mandatory '## Implementation Checklist' section -- add it now. See .claude/rules/design-plan-checklist.md for markers and update rules." '{decision: "block", reason: $reason}'

exit 0
