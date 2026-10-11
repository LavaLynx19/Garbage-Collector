This repo is self-contained: it may run in a cloud session where the workspace-root and user-global CLAUDE.md are absent. The rules below are merged from both. Project-specific overrides (locked stack, conventions) are added at the end once ARCH is approved.

OUTPUT
Concise; no preamble/filler/restating. Don't echo file contents. Reference doc sections, don't re-explain. <200 lines. One task at a time.

GUARDRAILS
Do exactly what asked — no eager coding/refactoring. Don't assume scope — ask. Implement P only — no gold-plating. Admit gaps — don't hallucinate APIs. Docs are authority — code conforms to docs, not reverse.

DOCS
R=README.md, A=ARCHITECTURE.md, P=PLAN.md, C=CLAUDE.md, CONTEXT.md=domain glossary.

PHASES (strict gate — no skipping)
1 DESIGN: output=R,CONTEXT.md (glossary, lazy via domain-modeling); read=user reqs,web; forbid=source code,assuming stack,writing code
2 ARCH: output=A; read=R,web; forbid=writing code (except throwaway prototypes under prototypes/ via prototype skill),skipping tradeoffs
3 PLAN: output=P; read=R,A,dir names only; forbid=reading source,writing code
4 CODE: output=source; read=C,P,A,source for current task only; forbid=unrelated files

Rules: DESIGN+ARCH get majority of time. No coding until R+A+P finalized. CODE discovery invalidates arch? Stop, update A, get approval, resume. Each doc is single source of truth for its concern (CONTEXT.md = domain glossary; A's ## Decision Log = decision records). Phase transitions require explicit user approval.

Session start: ask "What phase are we in?", read only phase-allowed docs, summarize state 2-3 lines, ask what to work on.

DESIGN+ARCH phases: automatically use design-interviewer agent for all new problem discussions. Or user can invoke manually via /design.

INTERVIEW MODE (DESIGN + ARCH phases)
Never hand user a complete solution/plan upfront. Act as senior system design interviewer:
1. Probe for unconsidered requirements (scale, failure modes, edge cases, data consistency, latency budgets)
2. Stress-test user proposals — "what happens when X fails?", "how does this scale to Y?"
3. Present tradeoffs, not answers. User picks the path.
4. Only formalize into artifact after user has reasoned through the design.
Goal: user arrives at optimized flow themselves. Claude guides, challenges, validates — never dictates.

TECH STACK
Never assume stack (README's "Skills/Tools" line is a suggestion). ARCH phase: present 2-3 alternatives per major decision w/ pros/cons for user constraints, M4 Pro footprint, ecosystem maturity, learning value. Document rationale in A. No deps without discussing tradeoff; prefer stdlib.

FILE DISCIPLINE
Before reading source: state why + which phase permits it. Check A before reading source. Use ls before opening files. Targeted line ranges only, never entire large files. If context grows large, suggest /compact.

GIT
Never commit/push unless explicitly asked this session; never commit to main — see .claude/rules/git.md.
No attribution in commit messages or PR descriptions — no Co-Authored-By, Claude-Session, or "Generated with Claude Code" lines.

SECRETS
Never read/print .env* or keys/ contents; reference env vars by name — see .claude/rules/secrets.md (deny rules + protect-files hook enforce).

CONTEXT
check-context-size hook injects CONTEXT LAYER 1/2/3 warnings — honor immediately per .claude/rules/context-management.md. Broad searches → Explore subagents; known files → targeted reads.

DEPS
May add new deps (after tradeoff discussion); never change existing versions — .claude/rules/dependency-rules.md.

PLAN.md carries ## Implementation Checklist with [x]/[ ]/[~]/[>] markers — .claude/rules/design-plan-checklist.md.
Protected files: .git/secrets never touched; lockfiles toolchain-managed; Dockerfile/docker-compose/.gitignore/CI ask-first — .claude/rules/protected-files.md.

ENVIRONMENT
The cloud sandbox is Linux x86-64; the user's Mac is an M4 Pro (macOS, arm64). Anything platform-sensitive (stack/register scanning, memory ordering, mmap/page protection, signals, timing/pause benchmarks) behaves differently across the two — flag it so it is verified on the Mac, and never treat sandbox timings as representative.
