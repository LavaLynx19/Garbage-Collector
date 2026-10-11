# PLAN.md Implementation Checklist

Every project `PLAN.md` must carry an `## Implementation Checklist` section so progress, blockers, and deferred work are visible at a glance without re-reading the full plan. (Enforced advisorily by the `plan-checklist-check` hook.)

## Purpose
- The plan body is the source of truth for the **spec** (tasks, acceptance criteria).
- The checklist is the source of truth for **progress** (done, pending, blocked, deferred).
- The two stay in sync on every edit — adding a task means adding a checklist line; removing one means removing its line.

## Where it lives
Insert `## Implementation Checklist` near the top of PLAN.md. Group entries by phase or milestone so the checklist mirrors the plan's numbering.

## Status markers
| Marker | Meaning | When to use |
|--------|---------|-------------|
| `- [x]` | done | code is merged or verified working |
| `- [ ]` | pending | not started or in progress |
| `- [~]` | blocked | waiting on a named dependency |
| `- [>]` | deferred | intentional future scope |

## Required suffixes
- `[~]` entries MUST end with `→ blocked by: <unblocker>` — name the file, decision, or upstream dependency.
- `[>]` entries MUST end with `→ defer until: <milestone>` — a concrete milestone, never a vague "later".
- `[x]` and `[ ]` entries should reference the plan-body section where the spec lives.

## Update rules
1. Whenever the plan body changes, update the checklist in the same edit. Stale checklists are worse than none.
2. When an item is implemented, flip `[ ]` → `[x]`. Do not delete the line — the checklist doubles as a build log.
3. When a blocker appears, flip to `[~]` with `→ blocked by:`; flip back when resolved.
4. When work is intentionally postponed, flip to `[>]` with `→ defer until:` — never silently drop it.
5. One atomic unit of work per line, matching the plan body's granularity.

## Exemptions
Trivial single-task plans (typo fixes, one-line changes) don't need a checklist — there is nothing to track.
