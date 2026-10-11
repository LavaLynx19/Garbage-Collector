---
name: design
description: Launch system design interview for a problem statement. Use during DESIGN or ARCHITECTURE phases.
argument-hint: "[problem statement]"
model: opus
context: fork
agent: design-interviewer
allowed-tools: Read, WebSearch, WebFetch, AskUserQuestion
effort: high
---
Start a system design interview for: $ARGUMENTS

Current project context:
- Branch: !`git branch --show-current 2>/dev/null || echo 'no git'`
- Existing docs: !`ls *.md 2>/dev/null || echo 'none'`
- Project structure: !`ls -d */ 2>/dev/null || echo 'empty'`
