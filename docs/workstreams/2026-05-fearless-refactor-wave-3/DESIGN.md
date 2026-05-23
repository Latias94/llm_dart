# Fearless Refactor Wave 3

Status: Active
Last updated: 2026-05-23

## Why This Lane Exists

The package graph and alpha release-hardening lane are locally stable. The next
architecture work should deepen the remaining shallow modules that still spread
state, compatibility, codec, fixture, and legacy decisions across broad
surfaces.

## Relevant Authority

- Existing docs:
  - `docs/workstreams/2026-05-provider-options-seam-deepening/`
  - `docs/workstreams/2026-05-alpha-release-hardening/`
  - `docs/workstreams/2026-05-provider-fixture-contracts/`
  - `docs/workstreams/2026-05-anthropic-fixture-contracts/`
  - `docs/workstreams/2026-05-provider-implementation-kit-and-codec-boundaries/`
  - `docs/workstreams/2026-04-legacy-deprecation-planning/`
  - `docs/workstreams/2026-05-root-legacy-prompt-options-breaking-line/`
- Architecture report:
  - `C:\Users\Frankorz\AppData\Local\Temp\architecture-review-llm-dart-20260523-201704.html`
- ADRs:
  - none present in this repository at lane creation time

## Problem

Five refactor candidates remain after provider options and release-hardening
work: chat session turn lifecycle is still a broad orchestrator, OpenAI-family
compatibility options still have high mass, provider fixture parity is uneven,
serialization support is broad across protocol families, and root legacy
classification still needs a post-alpha closeout path.

## Target State

When this lane closes:

- `DefaultChatSession` is a stable public adapter over a deeper turn lifecycle
  implementation.
- OpenAI-family typed option resolution remains the primary implementation
  path, while compatibility bag transport is narrower and clearly localized.
- Provider fixture coverage is even enough to support more codec refactors
  without provider-specific test blind spots.
- `SerializationJsonSupport` remains source-compatible while its protocol
  families have clearer locality.
- Root legacy classification is recorded as a post-alpha decision path with
  guards or docs that encode the chosen behavior.
- The current root legacy classification is anchored in
  `06-root-legacy-classification.md` and mirrored by
  `tool/root_legacy_classification.dart`.
- Public exports and existing behavior remain stable unless a task explicitly
  records a maintainer-approved breaking change.

## In Scope

- Internal module extraction and relocation in `llm_dart_chat`,
  `llm_dart_openai`, `llm_dart_provider`, and related tests.
- Provider-local fixture contracts where they improve refactor safety.
- Guard updates when source ownership moves.
- Workstream documentation and evidence updates for each vertical slice.
- Targeted `dart analyze`, package tests, workspace guards, release-readiness
  smoke, and `git diff --check` evidence.

## Out Of Scope

- Running `pub publish` or any external release side effect.
- Reintroducing `llm_dart_core`, `legacy.dart`, or a broad compatibility
  bucket.
- Adding new provider features unrelated to the refactor slices.
- Changing public exports without explicit task evidence and maintainer
  approval.
- Opening shared fixture packages before repeated provider-local contracts prove
  a stable shared module is worth the seam.

## Starting Assumptions

| Assumption | Confidence | Evidence | Consequence if wrong |
| --- | --- | --- | --- |
| Public behavior must remain stable through this wave. | High | Alpha release-hardening and provider options closeout. | Split breaking changes into a separate lane. |
| Chat session turn lifecycle has the highest immediate depth gap. | High | Architecture report and `DefaultChatSession` command/state concentration. | Reorder tasks if first slice proves too risky. |
| OpenAI compatibility bag transport still needs to exist for alpha migration. | Medium | Existing option resolver tests and compatibility comments. | Remove rather than localize only if tests prove no supported callers remain. |
| Provider-local fixtures should stay provider-owned for now. | High | Provider fixture contracts and Anthropic repetition audit. | Create a shared fixture helper only after a repeated implementation proves the seam. |
| Root legacy classification is partly product/release timing. | High | Alpha hardening closeout and legacy workstream history. | Defer final removal decisions until alpha feedback exists. |

## Architecture Direction

This lane deepens modules without widening public surfaces. Each slice should
put a narrow interface at the seam already used by callers, then move the
implementation details behind that seam. The main design pressure is locality:
bugs and tests should concentrate around one module instead of requiring edits
across callers.

The first slice targets `DefaultChatSession` because its public interface is
small, but the implementation still coordinates state transitions, transcript
edits, transport calls, active turn consumption, and tool continuation policy.
The desired shape is a stable public adapter with internal turn lifecycle
implementation behind it.

## Closeout Condition

This lane can close when:

- all five vertical slices are either complete or explicitly split with a new
  scope boundary,
- evidence gates pass for touched packages and guards,
- docs reflect the shipped behavior,
- `WORKSTREAM.json` status is updated,
- and any remaining release or product decisions are recorded as follow-ons.
