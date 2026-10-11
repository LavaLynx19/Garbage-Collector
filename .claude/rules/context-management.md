# Context Management — `/compact` Reminders

Long sessions silently drift toward the harness's auto-compaction cliff. This rule defines a three-layer escalation that prompts the user to run `/compact` at known stopping points.

## How the signal arrives
A hook at `.claude/hooks/check-context-size.sh` (registered in `.claude/settings.json`) runs on every `UserPromptSubmit`, reads the session transcript size in bytes, and (above threshold) injects a `CONTEXT LAYER N` line as `additionalContext`. The hook is the **objective source of truth** for which layer is active — when that line appears in context, act on it immediately.

Hook bytes-of-transcript is not the same as token count, but it scales monotonically with context, so it's a reliable trend.

## The three layers

| Layer | Hook trigger | My behavior |
|-------|-------------|-------------|
| **1 — Notice** | transcript ≥ 1.8 MB (~100k ctx tokens) | Append one line to the end of the next response: *"Context is filling up — consider `/compact` at a good stopping point."* Mention once per crossing, not every turn. |
| **2 — Pause** | transcript ≥ 5 MB (~270k ctx tokens) | Before starting any **new multi-step task** (Agent spawn, multi-file refactor, broad codebase exploration, long-running tool sequence), stop and recommend `/compact`. Wait for the user to run it or say "continue". Finishing the current task, answering one-off questions, single edits — still fine. |
| **3 — Block** | transcript ≥ 10 MB (~540k ctx tokens) | Stop before any non-trivial new work. Ask explicitly: *"Context is near the auto-compaction cliff. Run `/compact` or say 'continue without compacting' to proceed."* Trivial replies and single small reads remain allowed. |

## Hook vs rule precedence
- The hook's injected line determines the layer. Honor it on the turn it appears.
- This rule explains what "Notice / Pause / Block" mean behaviorally — without it the injected one-liner would be opaque.
- If the hook hasn't fired yet (first turn of a session, transcript path missing, hook misconfig), use rough self-judgment for Layer 1 only. Do NOT pre-empt Layer 2/3 on a guess — they require the objective signal.

## Reset
`/compact` either truncates the transcript or starts a fresh segment, so byte-count naturally drops below T1 and the hook goes silent again. After running `/compact`, the next turn should not carry a layer warning.

## Context Efficiency (subagents)
Transcript growth is driven mostly by file dumps from broad searches. Keep the main context lean:
- **Broad or uncertain searches** (scope unknown, multiple naming conventions, "where is X handled?") → fan out to an **Explore subagent** and keep only its conclusion; the file excerpts stay out of the main transcript.
- **Known-file lookups** (you know the file, symbol, or query name) → read directly, and read only the relevant range of large files instead of the whole file.
- Never paste whole large files (schemas, lockfile fragments, generated docs) into the conversation when a targeted excerpt answers the question.

This complements global CLAUDE.md → FILE DISCIPLINE (targeted line ranges, `ls` before opening files).

## Calibration
The 1.8 MB / 5 MB / 10 MB thresholds were calibrated empirically: one session showed 97.3k context tokens at a 1.8 MB transcript (≈ 18.5 bytes/token, including JSON encoding overhead). The values assume a **1M-context model variant**. On a 200k-context session, T3 = 10 MB will never fire before auto-compaction — if you regularly use a 200k model here, lower T2/T3 (rough mapping: T2 ≈ 2 MB, T3 ≈ 3 MB for a 200k window). Edit `.claude/hooks/check-context-size.sh` and keep the table above in sync.

## What this rule is NOT
- Not a built-in Claude Code event — there is no native "context size" hook, the script computes it from the transcript file.
- Not a guarantee — auto-compaction can still fire if calibration is off.
- Not a reason to refuse work — Layer 3 still allows trivial responses.
