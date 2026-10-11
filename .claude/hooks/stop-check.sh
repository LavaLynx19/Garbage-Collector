#!/bin/bash
# Stop hook: advisory PLAN.md reminder. Never blocks.
# Exits 0 unconditionally so hook bugs cannot wedge the session.

set +e

REMINDER="Before finishing: did you complete exactly one PLAN.md task? Are there failing tests? If in CODE phase, verify the current task's acceptance criteria."

# 1. No PLAN.md → nothing to verify against.
if [[ ! -f "PLAN.md" ]]; then
  exit 0
fi

# 2. No transcript path → can't tell what happened this turn. Stay silent.
TRANSCRIPT="${CLAUDE_TRANSCRIPT_PATH:-}"
if [[ -z "$TRANSCRIPT" || ! -f "$TRANSCRIPT" ]]; then
  exit 0
fi

# 3. Inspect the most recent assistant turn for Edit/Write tool use.
# Transcript is JSONL: one JSON object per line. We look at the tail to
# avoid scanning huge transcripts.
RECENT=$(tail -n 200 "$TRANSCRIPT" 2>/dev/null)
if [[ -z "$RECENT" ]]; then
  exit 0
fi

# Look for Edit or Write tool_use entries in the tail. jq is preferred;
# fall back to grep so a missing jq does not break the hook.
if command -v jq >/dev/null 2>&1; then
  EDITED=$(printf '%s\n' "$RECENT" | jq -r 'select(.type=="tool_use") | .name' 2>/dev/null | grep -E '^(Edit|Write|NotebookEdit)$' | head -n1)
else
  EDITED=$(printf '%s\n' "$RECENT" | grep -oE '"name":"(Edit|Write|NotebookEdit)"' | head -n1)
fi

if [[ -z "$EDITED" ]]; then
  # Idle / discussion / read-only turn → no reminder.
  exit 0
fi

# 4. CODE-phase edit happened → emit advisory reminder.
echo "$REMINDER"
exit 0
