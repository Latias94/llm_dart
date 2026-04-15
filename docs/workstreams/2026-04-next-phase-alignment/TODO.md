# TODO

## Workstream Setup

- [x] Create the next-phase alignment workstream scaffold
- [x] Re-baseline the remaining useful gaps versus `repo-ref/ai`

## Streamed Runner Maturity

- [ ] Audit the current `StreamTextRunner` surface against real app needs and
  freeze which missing behaviors are truly shared
- [ ] Decide whether a `prepareStep`-style hook belongs in shared core or
  should remain app/provider-owned
- [ ] Decide whether retry, model fallback, or richer stop policy belong in
  the shared runner or should stay explicitly deferred

## `llm_dart_core` Internal Boundary Hardening

- [ ] Write a frozen internal sublayer map for `llm_dart_core`
- [ ] Classify current `llm_dart_core` exports into specification, runtime,
  UI, and serialization ownership groups
- [ ] Define the trigger conditions for any future published package split out
  of `llm_dart_core`

## Root And Package Ownership

- [ ] Re-audit the root package role after the latest community/package moves
- [ ] Improve package-level documentation where the ownership story is still
  thin or implicit
