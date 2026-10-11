#!/usr/bin/env bash
# PostToolUse hook: hard-enforces .claude/rules/dependency-rules.md.
#
# After an Edit/Write to the repo-root package.json, diffs dependencies +
# devDependencies against HEAD. Adding new packages is allowed; changing the
# version of an existing package is blocked (the model is prompted to revert).
set -euo pipefail

input=$(cat)
path=$(printf '%s' "$input" | jq -r '.tool_input.file_path // empty')
root="${CLAUDE_PROJECT_DIR:-$(pwd)}"

# Only guard the repo-root package.json.
if [[ "$path" != "$root/package.json" && "$path" != "package.json" ]]; then
  exit 0
fi
[[ -f "$root/package.json" ]] || exit 0

head_json=$(git -C "$root" show HEAD:package.json 2>/dev/null) || exit 0
old_deps=$(printf '%s' "$head_json" | jq '(.dependencies // {}) + (.devDependencies // {})' 2>/dev/null) || exit 0
new_deps=$(jq '(.dependencies // {}) + (.devDependencies // {})' "$root/package.json" 2>/dev/null) || exit 0

changed=$(jq -n --argjson old "$old_deps" --argjson new "$new_deps" '
  [ $old | keys[] | select($new[.] != null and $new[.] != $old[.]) |
    "\(.): \($old[.]) -> \($new[.])" ] | join(", ")')

if [[ "$changed" != '""' ]]; then
  jq -n --argjson c "$changed" '{
    decision: "block",
    reason: ("dependency-rules.md violation: version of existing package(s) changed (" + $c + "). Adding new packages is fine; changing existing versions is never allowed -- revert the version change.")
  }'
fi

exit 0
