# Architecture

**Status:** ARCH in progress — sections are added as each decision is settled. Requirements: [README.md](README.md). Terms: [CONTEXT.md](CONTEXT.md).

## 1. Implementation languages

**Decision:** three implementations of the full stage progression, built in sequence — **C** (lead), then **Rust**, then **Zig**. Each finishes all three stages before the next starts. Performance gates apply to C only; Rust and Zig are correctness-gated and their performance is reported alongside C's (README → Success criteria).

| | C (lead) | Rust | Zig |
|---|---|---|---|
| Handle discipline | Runtime only (stress mode + heap verifier) | Can be compile-time via lifetimes/branding | Runtime only |
| Collector core | Natural fit; closest to GC literature | Mostly `unsafe` | Natural fit; explicit allocators |
| Bug tooling (macOS arm64) | ASan (manual poisoning for custom heap), TSan, UBSan | Miri, sanitizers | Debug-build safety checks |
| HdrHistogram | `HdrHistogram_c` | native crate | via C interop |
| Risk | No safety net | Borrow checker fights a mutating graph | Pre-1.0: breaking releases, small ecosystem |

**Why C leads:** least abstraction between design and memory, mature sanitizers on the benchmark machine, and the other two ports then translate a working, measured design instead of discovering it.

**Why Rust before Zig:** Rust forces a redesign of the mutator/collector boundary (lifetimes, `unsafe` scoping) — more learning while the design is fresh; Zig is close to C and ports mostly mechanically.

**Rejected — Go as an implementation language:** a collector hosted on Go's runtime inherits Go's own GC, scheduler and signal-based preemption jitter, which would contaminate exactly the sub-millisecond pause tail being measured, and would make the Go comparison non-independent. Go remains the comparison runtime only.

**Open:** exact toolchain versions for each language (pinned when that implementation starts).
