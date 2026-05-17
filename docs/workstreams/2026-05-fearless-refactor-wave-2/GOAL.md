# Goal

## Canonical Goal Text

Prepare the second fearless refactor wave by using alpha feedback, source
evidence, and the completed provider/runtime boundary as the foundation for the
next intentional breaking line.

The goal is not to continue broad restructuring. The goal is to identify and
execute the smallest high-value modernization step that improves the public
surface, migration story, provider maintainability, or compatibility exit path
without reopening completed architecture work.

## Why This Goal Exists

The provider/runtime/chat split is already complete enough to serve as the
foundation. The remaining risks are now around public API clarity,
compatibility gravity, provider helper duplication, provider package
organization, and documentation drift.

This goal exists to prevent the second wave from becoming an unbounded rewrite.

## Completion Definition

This goal is complete when:

- alpha publish or explicit non-publish decision is recorded
- post-publish or equivalent consumer smoke evidence is recorded
- modern API docs and examples are audited for provider-facing or legacy-first
  usage
- root and `llm_dart_core` compatibility surfaces are classified with removal
  blockers or review windows
- provider helper duplication is inventoried across focused providers
- any proposed `llm_dart_provider_utils` extraction has evidence from at least
  two provider packages
- the next implementation milestone is selected as one bounded workstream
- no task reopens the completed provider/runtime stream boundary without a
  concrete defect

## Non-Goals

This goal does not:

- remove `legacy.dart`
- remove `LLMBuilder`
- delete `llm_dart_core`
- publish `llm_dart_provider_utils`
- rewrite provider package layouts only for symmetry
- widen shared model contracts for one provider-specific feature
- change provider/runtime stream ownership

## Decision Rules

- Prefer documentation and migration clarity before compatibility removal.
- Prefer typed provider options over shared raw option maps.
- Extract shared provider utilities only after repeated stable duplication.
- Keep provider-native product APIs provider-owned.
- Keep root and `llm_dart_core` free of new implementation ownership.
- Treat `repo-ref/ai` as an architecture reference, not a file-layout template.
