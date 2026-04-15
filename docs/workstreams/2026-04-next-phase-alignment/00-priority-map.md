# Next-Phase Priority Map

## What Is Already Good Enough

The following areas are no longer the highest-value structural problem:

- workspace package splitting
- provider package ownership
- shared event completeness
- Flutter chat/runtime separation
- transport-owned reconnect behavior
- provider-owned UI feature projection

Those areas should now move from “active architecture debt” to “frozen
boundaries unless new evidence appears.”

## Priority 1 - Streamed Runner Maturity

### Why It Matters

The remaining most meaningful maturity gap versus `repo-ref/ai` is no longer
raw provider codecs or event types. It is the layer above them:

- multi-step streamed orchestration
- richer step policy
- clearer run-level lifecycle semantics

`llm_dart_core` already has `StreamTextRunner`, but it is intentionally narrow.
The next question is whether applications now need a slightly broader shared
subset.

### Deliverables

- freeze which streamed step-policy features are truly shared
- decide whether a `prepareStep`-style hook belongs in shared core or stays
  app/provider-owned
- decide whether retry, model switching, or richer stop policy belong in the
  next phase or remain deferred

### Risk If Skipped

The repository can have clean provider boundaries while still lacking the next
level of productized orchestration above raw model streaming.

## Priority 2 - `llm_dart_core` Internal Boundary Hardening

### Why It Matters

The package graph is healthy, but `llm_dart_core` now carries several distinct
roles:

- model specifications
- common request/response primitives
- shared output and runner logic
- UI message and projection models
- serialization codecs

That concentration is not automatically a package-split bug, but it is the
main remaining internal boundary pressure.

### Deliverables

- define the intended internal sublayers inside `llm_dart_core`
- freeze which exports are specification-facing, runtime-facing, or UI-facing
- record the trigger conditions that would justify a future published package
  split

### Risk If Skipped

The workspace can keep a healthy package graph while `llm_dart_core` gradually
becomes the new monolith internally.

## Priority 3 - Root Compatibility Slimming

### Why It Matters

The root package is already much healthier, but it is still both:

- the default modern facade
- the compatibility host

That is acceptable during migration, but the next phase should keep making the
boundary easier to understand.

### Deliverables

- re-baseline which root surfaces are still intentionally compatibility-owned
- define the next safe slimming steps without breaking current users blindly
- keep focused entrypoints honest about ownership

## Priority 4 - Package Documentation And Publishability Signals

### Why It Matters

Several leaf packages now carry real architectural weight, but not all of them
are equally self-describing.

If package roles are unclear, contributors tend to route new logic through the
wrong surface even when the code graph is technically correct.

### Deliverables

- improve package-level documentation where the ownership story is still weak
- document dependency direction and usage intent close to package boundaries

## What Should Not Happen Next

The following moves should stay deferred:

- copying `@ai-sdk/provider` and `@ai-sdk/provider-utils` as new Dart packages
  right now
- widening shared event or UI chunk vocabularies for parity alone
- creating framework-specific UI packages beyond Flutter before the shared
  runtime pressure exists
- splitting `llm_dart_community` further without release or ownership pressure
