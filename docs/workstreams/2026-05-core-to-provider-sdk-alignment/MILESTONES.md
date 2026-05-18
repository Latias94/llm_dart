# Milestones

## M0 - Alignment Blueprint

Goals:

- create the top-level alignment workstream
- link the existing AI SDK-inspired and SDK-aligned refactor evidence
- define the audit surfaces and non-goals

Acceptance criteria:

- target package ownership is documented
- audit documents exist for core, runtime, providers, helper utilities, and
  compatibility
- the workstream clearly states that it does not restart completed adapter
  splits

Exit gate:

- maintainers can choose the next implementation slice from this workstream
  instead of relying on opportunistic module splitting.

## M1 - Core Contract Reconciliation

Goals:

- audit `llm_dart_provider` model contracts against the reference provider
  contracts
- settle request metadata, response metadata, usage, warnings, provider object,
  and registry posture

Acceptance criteria:

- each model kind has an explicit keep/change/defer decision
- any breaking contract changes have migration notes
- provider contract tests cover the accepted interface semantics

Exit gate:

- provider contracts are stable enough for provider package parity work.

## M2 - Runtime Semantics Reconciliation

Goals:

- audit `llm_dart_ai` runtime helpers against the reference runtime seams
- settle tool-loop, stream event, output parsing, UI projection, and runtime
  error semantics

Acceptance criteria:

- runtime-only behavior remains out of provider contracts
- stream event conversion between provider and runtime remains explicit
- focused runtime tests cover newly documented invariants

Exit gate:

- provider packages can rely on stable provider-facing stream contracts while
  AI runtime owns user-facing orchestration.

## M3 - Provider Implementation Kit Decision

Goals:

- inventory repeated provider implementation helpers after adapter splits
- decide local/internal/public ownership for helper seams

Acceptance criteria:

- helper categories are documented
- any new shared helper boundary has at least two real provider consumers
- no public utility package is created without a stable public contract

Exit gate:

- future provider work has clear rules for duplication versus extraction.

## M4 - Provider Parity Matrix

Goals:

- document current parity for OpenAI, Google, Anthropic, Ollama, ElevenLabs,
  and OpenAI-compatible providers
- identify shared option gaps and provider-owned gaps

Acceptance criteria:

- each provider row records language, embedding, image, speech,
  transcription, stream, metadata, capability, and native helper status where
  applicable
- provider-owned features are not promoted to shared contracts without a real
  cross-provider seam
- shared option gaps have explicit owners

Exit gate:

- provider parity work can be scheduled as independent implementation slices.

## M5 - Compatibility Exit Plan

Goals:

- settle root facade and `llm_dart_core` compatibility posture
- document registry migration and legacy API exit path

Acceptance criteria:

- root exports are classified as modern facade, migration bridge, or removal
  candidate
- `llm_dart_core` exports are classified by owner package and exit policy
- migration examples exist for changed imports and registry usage
- guards enforce the compatibility policy

Exit gate:

- compatibility surfaces no longer influence new architecture decisions.

## M6 - Release Readiness

Goals:

- prove the final alignment with repeatable validation
- make the breaking line publishable

Acceptance criteria:

- workspace dependency guards pass
- root and core boundary guards pass
- provider replay metadata guard passes
- provider metadata namespace guard passes
- transport boundary guard passes
- package-local analysis and focused tests pass for touched packages
- consumer smoke and release readiness gates pass

Exit gate:

- the aligned core-to-provider architecture is ready for maintainer release
  decision.
