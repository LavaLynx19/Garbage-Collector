---
paths:
  - "**/*.js"
  - "**/*.ts"
  - "**/*.jsx"
  - "**/*.tsx"
---
Prefer stdlib/built-ins. No unnecessary dependencies. Use async/await over callbacks. No var — use const/let. Strict error handling in async functions. No any type in TypeScript. No default exports — use named exports. SECURITY — never use axios@1.14.1 or axios@0.30.4 (supply-chain compromise via plain-crypto-js@4.2.1, RAT). If either is present in package.json/package-lock.json, remove and upgrade. Always delete node_modules/plain-crypto-js if present.
