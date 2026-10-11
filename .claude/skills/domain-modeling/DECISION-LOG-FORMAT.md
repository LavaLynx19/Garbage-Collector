# Decision Log Format

Decision records live in the project's `ARCHITECTURE.md`, under a `## Decision Log` section at the end of the file. Add the section lazily: only when the first entry is needed. Append new entries at the bottom; past entries stay as written.

`ARCHITECTURE.md` is an ARCH-phase artifact. During DESIGN, list candidate decisions for the user in the phase summary instead of writing entries.

## Template

```md
### {Short title of the decision}

{1-3 sentences: what's the context, what did we decide, and why.}
```

That's it. An entry can be a single paragraph. The value is in recording *that* a decision was made and *why*, not in filling out sections.

## Optional fields

Only include these when they add genuine value. Most entries won't need them.

- **Status** line (`proposed | accepted | deprecated | superseded by "<title>"`): useful when decisions are revisited. To supersede, append a new entry and mark the old one; keep both.
- **Considered Options**: only when the rejected alternatives are worth remembering
- **Consequences**: only when non-obvious downstream effects need to be called out

## Single source of truth

The rest of `ARCHITECTURE.md` (stack, alternatives, data model, topology, API contract) describes the current design. The Decision Log records decisions that land after or outside those sections. A decision already covered with its rationale in those sections needs no entry. Elsewhere, point to an entry by its heading rather than restating its rationale.

## When to offer an entry

All three of these must be true:

1. **Hard to reverse**: the cost of changing your mind later is meaningful
2. **Surprising without context**: a future reader will look at the code and wonder "why on earth did they do it this way?"
3. **The result of a real trade-off**: there were genuine alternatives and you picked one for specific reasons

If a decision is easy to reverse, skip it: you'll just reverse it. If it's not surprising, nobody will wonder why. If there was no real alternative, there's nothing to record beyond "we did the obvious thing."

### What qualifies

- **Architectural shape.** "We're using a monorepo." "The write model is event-sourced, the read model is projected into Postgres."
- **Integration patterns between contexts.** "Ordering and Billing communicate via domain events, not synchronous HTTP."
- **Technology choices that carry lock-in.** Database, message bus, auth provider, deployment target. Not every library: just the ones that would take a quarter to swap out.
- **Boundary and scope decisions.** "Customer data is owned by the Customer context; other contexts reference it by ID only." The explicit no-s are as valuable as the yes-s.
- **Deliberate deviations from the obvious path.** "We're using manual SQL instead of an ORM because X." Anything where a reasonable reader would assume the opposite. These stop the next engineer from "fixing" something that was deliberate.
- **Constraints not visible in the code.** "We can't use AWS because of compliance requirements." "Response times must be under 200ms because of the partner API contract."
- **Rejected alternatives when the rejection is non-obvious.** If you considered GraphQL and picked REST for subtle reasons, record it; otherwise someone will suggest GraphQL again in six months.
- **Prototype verdicts.** The question a prototype answered and what it settled.
