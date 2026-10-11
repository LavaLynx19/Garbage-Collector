---
name: new-project
description: Bootstrap a new project with phase-gate artifacts in correct order
argument-hint: "[project name]"
model: opus
allowed-tools: Read, Write, Bash, WebSearch, AskUserQuestion, Skill
effort: high
---
Create a new project called "$ARGUMENTS" following this exact order. Do not skip steps.

1. Create directory: $ARGUMENTS/
2. README.md — problem statement, goals, user stories, constraints, success criteria
   - Sharpen domain terms with the domain-modeling skill; it creates CONTEXT.md (glossary) once the first term resolves
3. ARCHITECTURE.md — tech research w/ 2-3 alternatives per decision, trade-offs, chosen stack w/ rationale, data model, system topology, API contract
   - `## Decision Log` at the end, appended as later decisions land (format: domain-modeling's DECISION-LOG-FORMAT.md)
4. PLAN.md — phased implementation checklist, verification per phase, commit sequence, project structure
5. CLAUDE.md — project-specific overrides:
   - Languages and frameworks locked
   - Coding patterns and conventions
   - Database and external service constraints
   - Key file references
   - What overrides from global CLAUDE.md
6. Source code — only after 1-5 are finalized and approved

Each file = single source of truth for its concern. Don't duplicate across files.
Use INTERVIEW MODE for steps 2 and 3 — probe the user, don't dictate solutions.
