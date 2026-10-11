---
paths:
  - "**/*.go"
  - "**/go.mod"
  - "**/go.sum"
---
Formatter: gofmt. Linter: golangci-lint. Deps: go modules. Tests: go test, table-driven. Errors: explicit checks, no panic in library code. Prefer stdlib; no deps without tradeoff discussion.
