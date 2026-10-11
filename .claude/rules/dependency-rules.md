# Dependency Version Protection

## Rule
You may ADD new dependencies but NEVER change the version of an existing package.

## Why
Version changes can break working builds. Only dedicated dependency-update changes should bump versions.

## Applies To
- `dependencies` / `devDependencies` in `package.json` (hard-enforced by the `dependency-version-guard` hook)
- `go.mod` require blocks and `pyproject.toml` dependencies (rule-enforced; same principle, no hook yet)

## Allowed
```json
{ "new-package": "^2.0.0" }
```

## Forbidden
```json
{ "pg": "^9.0.0" }
```
Changing pg from ^8.13.0 to ^9.0.0 is NOT allowed.

Relates to global CLAUDE.md TECH STACK rule: no new deps without discussing the tradeoff; prefer stdlib.
