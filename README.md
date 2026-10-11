# Garbage Collector for a Language Runtime (JVM / Go GC Style)

**Status:** DESIGN phase — not started. Everything below is the seed brief (project #35 from the ideas list), not agreed requirements. Goals, user stories, constraints and success criteria are written here during the DESIGN interview.

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
