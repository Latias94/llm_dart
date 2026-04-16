# Milestones

## M1 - Legacy Surface Inventory

Goals:

- identify the remaining public legacy surface groups
- separate true migration rails from removable convenience aliases

Acceptance criteria:

- a repository-level inventory exists
- each main public legacy group has a current posture
- modern stable surfaces are explicitly excluded from the cleanup target

Current status:

- the initial inventory is now written down in
  `00-legacy-surface-inventory.md`
- the main surface groups are now classified as keep, freeze, or
  soft-deprecate

## M2 - Deprecation Policy Freeze

Goals:

- define the public status vocabulary for legacy cleanup
- freeze the release rules for annotation versus removal

Acceptance criteria:

- the status vocabulary is explicit
- no-removal patch policy is written down
- breaking-window prerequisites are documented

Current status:

- the initial deprecation policy is now written down in
  `01-deprecation-policy.md`
- the default rule is now clear: remove leaves before trunks

## M3 - Migration Sequence Decision

Goals:

- define the practical order for docs, deprecation, and removal
- avoid a sequence that strands users without a coherent migration rail

Acceptance criteria:

- the repository has a staged migration sequence
- builder posture is explicitly deferred until recipes are ready
- the first breaking window stays conservative

Current status:

- the initial sequence is now written down in `02-migration-sequence.md`
- the workstream now explicitly treats modern docs-first cleanup as the first
  real step

## M4 - Removal Readiness Freeze

Goals:

- map the main legacy surface groups to concrete next actions
- prevent future cleanup from becoming vague or ad hoc

Acceptance criteria:

- the main public symbols have a readiness posture
- blockers are named explicitly
- "keep", "deprecate", and "remove" are not conflated

Current status:

- the first readiness table is now written down in
  `03-removal-readiness-matrix.md`
- the repository now has a default answer for which symbols are first-breaking
  candidates and which are not

## M5 - Implementation Preparation

Goals:

- turn the planning phase into a concrete implementation queue
- decide what should happen in the next docs/code round

Acceptance criteria:

- examples and README usage audits are complete
- the first deprecation wave is scoped
- breaking-window candidates are backed by migration notes

Current status:

- the README and example audit is now complete in
  `04-readme-and-example-audit.md`
- the first stable-helper rewrite pass is now complete in
  `example/02_core_features` for embeddings, audio, and image generation
- the second stable-helper rewrite pass is now complete in
  `example/02_core_features` for enhanced tool calling and error handling
- the third rewrite pass is now complete in `example/02_core_features` for
  assistants and file management, reframing them as explicit provider
  boundaries instead of stable shared capability examples
- the fourth rewrite pass is now complete in `example/02_core_features` for
  content moderation and model discovery, separating provider-owned endpoints
  from app-owned policy and capability-profile usage
- the Anthropic prompt-caching appendix no longer depends on the broad
  `legacy.dart` barrel and now uses focused typed imports instead
- `example/02_core_features` is now effectively down to two explicit
  compatibility appendix files:
  `capability_factory_methods.dart` and `provider_specific_builders.dart`
- the next honest implementation slice is now clear: keep rewriting the
  highest-traffic example paths before expanding deprecation annotations
  further
