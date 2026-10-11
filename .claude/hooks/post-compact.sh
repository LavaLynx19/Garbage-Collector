#!/bin/bash
# PostCompact hook: re-inject critical context after context compression

echo "=== POST-COMPACTION CONTEXT RELOAD ==="

# Show current project CLAUDE.md
if [[ -f "CLAUDE.md" ]]; then
  echo ""
  echo "PROJECT RULES:"
  cat CLAUDE.md
fi

# Show current phase task from PLAN.md
if [[ -f "PLAN.md" ]]; then
  echo ""
  echo "ACTIVE PLAN (first unchecked task):"
  grep -n "^\- \[ \]" PLAN.md | head -3
fi

# Show git context
BRANCH=$(git branch --show-current 2>/dev/null)
if [[ -n "$BRANCH" ]]; then
  echo ""
  echo "BRANCH: $BRANCH"
  echo "UNCOMMITTED FILES: $(git status --short 2>/dev/null | wc -l | tr -d ' ')"
fi

echo "=== END CONTEXT RELOAD ==="
