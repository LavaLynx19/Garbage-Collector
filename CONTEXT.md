# Garbage Collector

A tracing garbage collector over a minimal heap, exercised by synthetic programs and measured by pause-time distribution. This glossary fixes the vocabulary used across README, ARCHITECTURE and PLAN.

## Language

### Program side

**Mutator**:
The program whose allocations and pointer writes the collector must keep up with; here, a synthetic workload driving the heap.
_Avoid_: Application, client, user thread

**Workload**:
A named, repeatable mutator scenario with a characteristic allocation pattern (e.g. long-lived cache, short-lived garbage, deep linked structure, bursty allocation).
_Avoid_: Benchmark, test case

**Handle**:
An explicitly registered reference through which the mutator holds a heap object, so the collector knows every root precisely and may move the object.
_Avoid_: Raw pointer, local ref

### Heap and liveness

**Root**:
A reference from outside the heap (a handle or a global) from which tracing starts.
_Avoid_: Anchor, entry point

**Live heap**:
The total size of objects reachable from roots at a given moment.
_Avoid_: Heap size, used memory

**Heap footprint**:
The total memory the collector has reserved, including free space, copy reserve and headroom; always larger than the live heap.
_Avoid_: Heap size, RSS

### Collection

**Pause**:
An interval during which the mutator is stopped so the collector can work; the unit the project budgets and measures.
_Avoid_: Stall, freeze, GC time

**Safepoint**:
A point in mutator execution where it can be stopped with all its roots known to the collector.
_Avoid_: Checkpoint, yield point

**Stage**:
One collector in the project's progression (stop-the-world mark-sweep → generational → concurrent marking), each measured against the same workloads.
_Avoid_: Version, phase (reserved for project phases)

**Mutator assist**:
Collection work an allocating mutator is made to perform in proportion to what it allocates, so allocation cannot outrun reclamation unchecked.
_Avoid_: Throttling, backpressure

**Backstop**:
What happens when assists cannot keep up: a stop-the-world full collection, then out-of-memory if that still frees too little.
_Avoid_: Fallback, emergency GC

### Verification

**Stress mode**:
A run configuration that triggers a collection — moving every movable object — every N allocations, so a missed root fails immediately.
_Avoid_: Torture mode, debug GC

**Heap verifier**:
A post-collection check that every reference points to a valid object and that collector invariants hold.
_Avoid_: Checker, validator, sanity pass
