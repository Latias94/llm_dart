# Milestones

## M1 - Gap Rebaseline

Goals:

- restate the current architecture using present-day code rather than older
  migration assumptions
- freeze which remaining differences versus `repo-ref/ai` are still real

Acceptance criteria:

- the current package graph is written down accurately
- deliberate differences are explicitly named
- the next priorities are feature-driven rather than symmetry-driven

Current status:

- the package graph is now re-baselined after the post-closure priority phase
- the next meaningful gap is now identified as streamed runner maturity rather
  than provider package or event-surface expansion
- `llm_dart_core` concentration is now explicitly tracked as an internal
  boundary-hardening topic, not an automatic package-splitting mandate

## M2 - Streamed Runner Productization Decision

Goals:

- decide which higher-level streamed orchestration features belong in shared
  core
- keep provider-specific continuation and approval semantics out of the shared
  runner unless a real cross-provider subset appears

Acceptance criteria:

- the next shared streamed-runner subset is frozen
- deferred features are named explicitly rather than left ambiguous
- any implementation work has a documented boundary before code changes begin

Current status:

- `StreamTextRunner` already provides narrow multi-step stitched streaming plus
  `stepStream` and final `result`
- the current-phase audit now also confirms that the next truthful shared
  subset still stops at the current boundary: no shared `prepareStep`, no
  shared retry/model fallback, and no richer shared stop policy yet

## M3 - `llm_dart_core` Internal Boundary Hardening

Goals:

- keep `llm_dart_core` from becoming the new internal monolith
- clarify internal ownership without premature package fragmentation

Acceptance criteria:

- internal sublayers are documented
- export ownership is classified
- future split triggers are explicit

Current status:

- the internal `llm_dart_core` sublayers are now documented as foundation,
  model/capability, runner, stream/UI, and serialization ownership groups
- future split triggers are now explicit instead of implied by file count alone
- `llm_dart_core` now also exposes additive focused entrypoints for foundation,
  model, UI, and serialization imports without splitting the package
- the focused entrypoints are now proven by real adopters in both
  `llm_dart_transport` and `llm_dart_chat`, not only by isolated compile tests
- package-level README guidance now exists for `llm_dart_core`,
  `llm_dart_transport`, and `llm_dart_community`
- `ChatUiAccumulator` is now internally split across tool, text/reasoning,
  metadata, output, hydration, and data-part support while keeping the same
  public API and shared event surface

## M4 - Root And Package Ownership Clarity

Goals:

- keep the root package understandable as both modern facade and compatibility
  host
- make leaf package ownership easier to follow

Acceptance criteria:

- package-level documentation is improved where needed
- the next root-slimming steps are documented without speculative breakage

Current status:

- the current root role is now re-audited after the latest package moves
- focused provider root shells are now explicitly recognized as narrow and
  honest again
- the root package is now classified as clear enough for the current stage: a
  modern convenience facade plus an explicit compatibility host
