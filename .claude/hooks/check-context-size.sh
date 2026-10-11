#!/usr/bin/env bash
# UserPromptSubmit hook: measures session transcript size and injects a
# `/compact` reminder via additionalContext when the transcript crosses
# the three layered thresholds.
#
# Paired with .claude/rules/context-management.md — that rule defines what
# "Notice / Pause / Block" mean in behavioral terms.
set -euo pipefail

input=$(cat)
transcript=$(printf '%s' "$input" | jq -r '.transcript_path // empty')

if [[ -z "$transcript" || ! -f "$transcript" ]]; then
  exit 0
fi

bytes=$(wc -c < "$transcript" | tr -d ' ')

# Thresholds in bytes of JSONL transcript. Bash arithmetic is integer-only,
# so 1.8 MB is written as (18 * 1024 * 1024) / 10.
# Calibrated empirically: 97.3k context tokens corresponded to a 1.8 MB transcript
# (~18.5 bytes/token, JSON encoding overhead). Assumes a 1M-context model variant.
T1=$(( (18 * 1024 * 1024) / 10 ))   # 1.8 MB -> Layer 1 Notice  (~100k ctx tokens)
T2=$((   5 * 1024 * 1024 ))         # 5 MB   -> Layer 2 Pause   (~270k ctx tokens)
T3=$((  10 * 1024 * 1024 ))         # 10 MB  -> Layer 3 Block   (~540k ctx tokens)

# Human-readable size for the warning message: MB if >=1MB, else KB.
if (( bytes >= 1024 * 1024 )); then
  size=$(awk -v b="$bytes" 'BEGIN { printf "%.1f MB", b / 1048576 }')
else
  size="$(( bytes / 1024 )) KB"
fi

if (( bytes >= T3 )); then
  msg="CONTEXT LAYER 3 (block): session transcript is ~${size}, near auto-compaction. Do NOT start any new multi-step work. Ask the user to run /compact, or to explicitly say 'continue without compacting'. Trivial replies and single small reads are still allowed."
elif (( bytes >= T2 )); then
  msg="CONTEXT LAYER 2 (pause): session transcript is ~${size}. Before starting any NEW multi-step task (Agent spawn, multi-file refactor, broad exploration), pause and recommend the user run /compact. Finishing the current task and answering one-off questions are still fine."
elif (( bytes >= T1 )); then
  msg="CONTEXT LAYER 1 (notice): session transcript is ~${size}. End your next response with: 'Context is filling up — consider /compact at a good stopping point.'"
else
  exit 0
fi

jq -n --arg ctx "$msg" '{
  hookSpecificOutput: {
    hookEventName: "UserPromptSubmit",
    additionalContext: $ctx
  }
}'
