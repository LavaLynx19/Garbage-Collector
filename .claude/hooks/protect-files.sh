#!/usr/bin/env bash
# PreToolUse hook: hard-enforces .claude/rules/protected-files.md and
# .claude/rules/secrets.md.
#
# Two tiers:
#   HARD (deny): .git/ internals, auto-generated lockfiles, .env secrets,
#     keys/ material -- never touched, no exceptions.
#   SOFT (ask): .github/, .gitignore, Dockerfile, docker-compose.yml --
#     legitimate to edit in this workspace, but only with explicit user
#     confirmation.
#
# Covers:
#   - Edit/Write/NotebookEdit calls targeting protected paths
#   - Bash commands that perform write-shaped operations (rm, mv, tee,
#     sed -i, redirection, ...) against protected paths
#   - Bash commands that reference .env secret files (any access would put
#     secrets into the transcript); .env.example/.env.sample stay allowed
#   - Bash commands that reference the keys/ folder (private key material)
#
# Read-only access to protected files (cat, grep, git diff) is untouched.
# Paired with the permissions deny/ask entries in .claude/settings.json --
# this hook covers the gap those rules can't: shell-based writes and reads.
set -euo pipefail

input=$(cat)
tool=$(printf '%s' "$input" | jq -r '.tool_name // empty')

# Anchored at a path boundary so e.g. "myDockerfile.md" does not match.
HARD='(\.git/|package-lock\.json|yarn\.lock|pnpm-lock\.yaml|go\.sum)'
SOFT='(\.github/|\.gitignore|Dockerfile|docker-compose\.yml)'
# Secret env files: .env plus common environment suffixes. Template files
# (.env.example, .env.sample) intentionally do not match.
ENVFILE='\.env(\.(local|dev|development|stage|staging|prod|production|test))?'
# Private key / cert material: any access would put secrets in the transcript.
KEYSDIR='keys/'

decide () {
  jq -n --arg decision "$1" --arg reason "$2" '{
    hookSpecificOutput: {
      hookEventName: "PreToolUse",
      permissionDecision: $decision,
      permissionDecisionReason: $reason
    }
  }'
  exit 0
}
deny () { decide "deny" "$1"; }
ask ()  { decide "ask"  "$1"; }

case "$tool" in
  Edit|Write|NotebookEdit)
    path=$(printf '%s' "$input" | jq -r '.tool_input.file_path // .tool_input.notebook_path // empty')
    [[ -z "$path" ]] && exit 0
    hard_re="(^|/)${HARD}"
    soft_re="(^|/)${SOFT}"
    env_re="(^|/)${ENVFILE}$"
    keys_re="(^|/)${KEYSDIR}"
    if [[ "$path" =~ $env_re ]]; then
      deny "Secret env file ($path) -- never read or write .env contents. See .claude/rules/secrets.md."
    fi
    if [[ "$path" =~ $keys_re ]]; then
      deny "Key material ($path) -- never read or write keys/ contents. See .claude/rules/secrets.md."
    fi
    if [[ "$path" =~ $hard_re ]]; then
      deny "Protected file ($path) -- see .claude/rules/protected-files.md. Never modify it; create an implementation guide instead."
    fi
    if [[ "$path" =~ $soft_re ]]; then
      ask "Sensitive file ($path) -- confirm with the user before modifying. See .claude/rules/protected-files.md."
    fi
    ;;
  Bash)
    cmd=$(printf '%s' "$input" | jq -r '.tool_input.command // empty')
    [[ -z "$cmd" ]] && exit 0
    # 0) Any reference to a secret env file (read OR write) -- secrets must
    #    not enter the conversation transcript.
    env_re="(^|[/[:space:];|&\"'=])${ENVFILE}([[:space:]\"';|&]|$)"
    if [[ "$cmd" =~ $env_re ]]; then
      deny "Command references a .env secret file -- secrets must not enter the conversation. Reference variable names, not values. See .claude/rules/secrets.md."
    fi
    # 0b) Any reference to the keys/ folder (read OR write) -- private key
    #     material must not enter the conversation transcript.
    keys_re="(^|[/[:space:];|&\"'=])${KEYSDIR}"
    if [[ "$cmd" =~ $keys_re ]]; then
      deny "Command references the keys/ folder -- private key material must not enter the conversation. See .claude/rules/secrets.md."
    fi
    # 1) Redirection into a protected path: "> go.sum", ">> .gitignore"
    redir_hard="[>]{1,2}[[:space:]]*[^[:space:];|&]*${HARD}"
    redir_soft="[>]{1,2}[[:space:]]*[^[:space:];|&]*${SOFT}"
    if [[ "$cmd" =~ $redir_hard ]]; then
      deny "Command redirects output into a protected file -- see .claude/rules/protected-files.md."
    fi
    if [[ "$cmd" =~ $redir_soft ]]; then
      ask "Command redirects output into a sensitive file -- confirm with the user first. See .claude/rules/protected-files.md."
    fi
    # 2) Destructive command whose arguments include a protected path.
    #    Bounded by command separators so reads in earlier pipe stages pass.
    destr='(^|[;|&][[:space:]]*)(sudo[[:space:]]+)?(rm|mv|tee|truncate|chmod|chown|ln)[[:space:]][^;|&]*'
    if [[ "$cmd" =~ ${destr}${HARD} ]]; then
      deny "Command performs a write-shaped operation on a protected file -- see .claude/rules/protected-files.md."
    fi
    if [[ "$cmd" =~ ${destr}${SOFT} ]]; then
      ask "Command performs a write-shaped operation on a sensitive file -- confirm with the user first. See .claude/rules/protected-files.md."
    fi
    # 3) In-place sed/perl edits of a protected path.
    inplace='(sed[[:space:]]+-[^[:space:]]*i|perl[[:space:]]+[^;|&]*-[^[:space:]]*i)[^;|&]*'
    if [[ "$cmd" =~ ${inplace}${HARD} ]]; then
      deny "In-place edit of a protected file -- see .claude/rules/protected-files.md."
    fi
    if [[ "$cmd" =~ ${inplace}${SOFT} ]]; then
      ask "In-place edit of a sensitive file -- confirm with the user first. See .claude/rules/protected-files.md."
    fi
    ;;
esac

exit 0
