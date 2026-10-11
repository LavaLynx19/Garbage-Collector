---
paths:
  - "**/*.py"
  - "**/pyproject.toml"
  - "**/requirements*.txt"
---
Formatter: ruff format. Linter: ruff check. Use type hints on public APIs. Deps: uv for venv+deps; pin in pyproject.toml. Tests: pytest, fixtures over setup/teardown. Prefer stdlib; no deps without tradeoff discussion.
