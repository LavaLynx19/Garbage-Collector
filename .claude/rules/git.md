# Git Discipline

- Never `git commit` or `git push` unless the user explicitly asked in this session (the harness `ask` rules also prompt).
- Never commit directly to `master`/`main` — create a feature branch first with a short descriptive slug.
- Destructive operations (`push --force`, `reset --hard`, `clean -f`, `checkout -- .`) are deny-listed in `.claude/settings.json` — do not attempt workarounds; ask the user.
