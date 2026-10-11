# Garbage Collector for a Language Runtime (JVM / Go GC Style)

**Status:** DESIGN phase — README draft, awaiting approval. Terms are defined in [CONTEXT.md](CONTEXT.md).

## Problem

Prove objects unreachable and reclaim them while a mutator keeps rewriting the object graph, budgeted in pause time rather than throughput — and measure honestly how each collector design trades pauses against mutator cost.

## Goals

1. Build three collector stages over one minimal heap and allocator: stop-the-world mark-sweep → generational → concurrent marking.
2. Measure every stage on the same workloads: full pause distribution, throughput, allocation vs reclamation rate.
3. Measure a reference-counting baseline once against mark-sweep on the same workloads (with its cycle-handling cost visible).
4. Compare the final stage against Go's collector on the same workloads and machine.
5. Make heap corruption fail fast and close to its cause.

## User stories

- As the experimenter, I run a named workload against a chosen stage and get a pause histogram plus throughput, reproducibly.
- As the experimenter, I switch stages without changing workload code.
- As the experimenter, I run any workload in stress mode with the heap verifier and get an immediate, localized failure if a root is missed or an invariant breaks.
- As the experimenter, I drive the mutator past what the collector can reclaim and see assists slow it, then the backstop fire, then a clear out-of-memory error — never silent corruption.
- As the experimenter, I run the same workloads ported to Go and compare pause distributions side by side.

## Constraints

- **Roots:** precise only, via handles. No conservative stack scanning.
- **Mutators:** one mutator thread in v1, but safepoints are real polls designed to extend to N threads.
- **Overload policy:** mutator assists; backstop is stop-the-world full collection, then out-of-memory.
- **Heap size:** default live heap 1–2 GB; stretch up to ~4 GB. The harness refuses any run whose expected heap footprint exceeds ~50% of physical RAM.
- **Benchmark machine:** the user's M4 Pro (macOS, arm64, 24 GB). The cloud sandbox (Linux x86-64) is for correctness runs only; its timings are never reported.
- **Comparison runs** (Go vs this collector) run sequentially, never concurrently.
- **Stack:** not chosen here — decided in ARCHITECTURE with alternatives. Whether a language can enforce handle discipline at compile time is one selection criterion.

## Scope

**In v1:** the three stages, RC baseline, workloads, stress mode, heap verifier, measurement harness, Go comparison (as a milestone after the concurrent stage).

**Deferred:** multiple mutator threads; weak references and finalizers; wrapping the collector in a bytecode VM.

**Out:** conservative/Boehm-style collection; comparison against JVM collectors.

## Success criteria

**Correctness (every stage, gate before moving on):**
- Every workload passes in stress mode at N=1 with the heap verifier on, with zero verifier failures.
- Overload runs end in either recovery or a clean out-of-memory error, never corruption.

**Performance — all three lenses, reported per stage:**
- **(a) Reference bars:** generational stage p99.9 pause ≤ 50 ms; concurrent stage p99.9 pause < 1 ms. Stop-the-world mark-sweep is the measured baseline. Judged at both 1 GB and 2 GB live heap.
- **(b) Go comparison:** final-stage pause distribution and throughput shown side by side with Go on identical workloads.
- **(c) Relative improvement:** each stage beats the previous stage's p99.9 pause by at least 2× while losing no more than 10% throughput.

**How (a) and (c) are judged:** per workload, never pooled. Each workload declares up front which stages it is expected to pass; a miss on a declared exception is reported (with its cause) but does not fail the stage, and the declaration may be tightened after a fix and retest. A miss on an undeclared case fails the stage.

**Measurement integrity:** pauses reported as full distributions (p50/p99/p99.9/max), never averages alone; the harness avoids coordinated omission.

## Seed brief

**Skills/Tools:** Rust/C/C++/Zig, HdrHistogram, perf / Instruments (suggestion only — stack is chosen in ARCH)

**Design Approach:** Concurrent reclamation with a live mutator — proving objects unreachable while application threads keep rewriting the object graph, budgeted in pause time rather than throughput.

**Contrasts With:** #22 — vacuum knows which tuple versions are dead from transaction IDs; a collector must prove unreachability in a graph that changes underneath it. Also #24 — LMAX removes contention by refusing to share state; a collector has no such option, since it shares the heap with every running thread.

**The Project:** Build a garbage collector over a minimal heap and allocator, driven by synthetic mutator workloads (long-lived caches, short-lived garbage, deep linked structures, bursty allocation), progressing from stop-the-world mark-sweep to a generational collector to concurrent marking — measuring pause distribution and throughput at every step. Wrapping it in a bytecode VM is a natural extension, but the collector, not the language, is the point.

**Topics Used:**
*   **Tracing Fundamentals:** Root sets (stacks, registers, globals), the tri-color invariant, and mark-sweep vs mark-compact vs copying (Cheney) collection.
*   **Generational Collection:** The weak generational hypothesis, nursery/tenured spaces, promotion policies, and remembered sets or card tables for old→young pointers.
*   **Barriers:** Write barriers (Dijkstra incremental-update vs Yuasa SATB) and read barriers, and what each costs on the mutator's hot path.
*   **Safepoints & Root Scanning:** Stopping threads at known-safe points, precise vs conservative stack scanning, and pointers that live only in registers.
*   **Allocation Path:** Bump allocation with thread-local buffers vs size-class free lists, fragmentation, and relocating objects without breaking references.
*   **Measurement:** Pause-time distribution rather than averages, allocation rate vs reclamation rate, and avoiding coordinated omission in the harness.

**Tradeoffs to Wrestle With:**
*   When is a 200ms stop-the-world pause cheaper overall than a concurrent collector's barrier tax on every pointer write?
*   The mutator allocates faster than the collector reclaims — what should the runtime do, and what does the program see?
*   Conservative (Boehm-style) vs precise collection — what does precision buy, and what does it demand from the rest of the runtime?
*   Reference counting vs tracing — which fits your workload, and how do you handle cycles?
*   How do you test this at all, when heap corruption surfaces thousands of allocations after the bug that caused it? (See #30.)
