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

## 2. Workload sharing across runtimes

**Decision:** seeded generators. A workload is a language-neutral parameter file (object sizes, lifetimes, graph shape, allocation rate, seed). Each runtime (C, Rust, Zig, Go) has one generic **driver** that expands it into an operation stream on the fly.

**Considered:**
- *Trace replay* — identical ops guaranteed, but multi-GB trace streaming in the measured path dilutes the barrier cost the throughput criterion must expose, and workloads cannot react to heap state. Kept only as a debugging aid (below).
- *Native code per runtime* — most realistic, but every workload costs four ports and versions drift. Kept only as one sanity program (below).

**Equivalence guarantees:**
- **Fingerprint:** every driver folds each operation into a running hash; the harness compares fingerprints across runtimes and invalidates any run whose fingerprint differs.
- **Record mode:** a driver can dump its first N operations to a small trace file so two diverging drivers can be diffed. Never enabled in measured runs.

**Driver rules:**
- Generation is integer-only: a bit-exact portable PRNG (SplitMix64 / xoshiro256** class) and integer or table-driven sampling. No floating-point math library calls — `log`/`exp` differ across C, Rust, Zig and Go libms and silently break equivalence.
- Drivers keep their own bookkeeping off the collected heap. Mandatory for Go (driver allocations would load the collector under test); applied to all drivers for symmetry.

**Sanity program:** one hand-written, realistic program ported natively to all four runtimes, to catch behaviour that statistical workloads miss. It is the single exception to "workloads are defined once" (README → Constraints), is reported but never gated, and is not fingerprinted (its four versions are equivalent by review, not by hash).

The sanity program is an **LRU cache under a skewed (hot-key) request load**: long-lived entries with steady churn, old→young pointer writes on every entry update (exercising generational barriers and remembered sets), and eviction that can react to heap pressure.

**Open:** when the sanity program is built.
