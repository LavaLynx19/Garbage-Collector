# Secrets in Context

Never read, print, or echo secrets into the conversation — the transcript persists on disk and may sync. Concretely:

- Never open or `cat`/`grep`/`source` `.env*` files (template files like `.env.example`, `.env.sample` are fine). Enforced by `Read(.env*)` deny rules and the `protect-files` hook.
- Never read the `keys/` folder (private keys / certs) — not via the Read tool, not via `cat`/`grep`/`head`/etc. Enforced by the `Read(keys/**)` deny rule and the hook's `keys_re` check.
- Reference environment variables by NAME (`process.env.NEO4J_PASSWORD`, `os.Getenv("NEO4J_PASSWORD")`), never by value.
- If debugging requires a secret's value, ask the user to check it themselves (e.g. via `! <command>` in the prompt).
