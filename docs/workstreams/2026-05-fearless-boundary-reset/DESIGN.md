# Fearless Boundary Reset

Status: Closed
Last updated: 2026-05-21

## Closeout

Closed at 2026-05-21 21:12 +08:00. The target seams are implemented and
verified: OpenAI route/provider-family policy, provider transport execution,
provider specification contracts, AI/provider stream vocabulary composition,
AI runtime helper request state, migration docs, and deletion of
`llm_dart_core`.

## Why This Lane Exists

The package graph now resembles `repo-ref/ai`: provider contracts, AI runtime,
transport, chat, Flutter adapters, provider packages, and the root facade are
visible ownership areas. The remaining architecture problem is depth: several
modules still have wide interfaces, duplicated implementation, or transitional
compatibility shells that make the correct seams harder to see.

This lane is intentionally breaking. Compatibility is not a design constraint
when it preserves shallow modules, duplicate ownership, or obsolete import
paths.

## Relevant Authority

- Existing docs:
  - `docs/workstreams/2026-05-provider-ai-runtime-split/01-reference-architecture-map.md`
  - `docs/workstreams/2026-05-provider-ai-runtime-split/02-target-package-graph.md`
  - `docs/workstreams/2026-05-provider-ai-runtime-split/04-data-structure-redesign.md`
  - `docs/workstreams/2026-05-sdk-aligned-fearless-refactor/README.md`
  - `docs/workstreams/2026-05-four-seam-fearless-refactor/README.md`
  - `docs/workstreams/2026-05-runtime-event-tool-loop-boundary/20-primary-runtime-entrypoints.md`
- Reference repository:
  - `repo-ref/ai/packages/provider/src/**`
  - `repo-ref/ai/packages/ai/src/generate-text/**`
  - `repo-ref/ai/packages/openai/src/**`

## Problem

The current architecture has correct package names but still contains shallow
modules and transitional seams:

- OpenAI route selection, OpenAI-compatible family policy, request encoding,
  response decoding, and transport execution still converge through a heavy
  language model adapter.
- Provider transport helpers exist, but provider packages still repeat send,
  stream, cancellation, raw chunk, and error projection choreography.
- Provider stream events and AI runtime text stream events intentionally live
  on separate seams, but their content/tool vocabularies are copied rather than
  composed.
- `llm_dart_core` is a compatibility shell whose interface is nearly as wide
  as the implementation it re-exports.
- Provider object contracts, optional facets, capability profiles, and
  supported input shapes are adjacent conventions rather than one frozen
  provider specification seam.
- Runtime helper entrypoints repeat a wide parameter surface that exposes tool
  loop implementation details across many public helpers.

## Target State

When this lane closes:

- OpenAI route/capability adapters are deep modules with local route policy:
  Responses, Chat Completions, OpenAI-compatible family behavior, and native
  product helpers no longer share one orchestration-heavy adapter.
- Provider call execution is concentrated behind a reusable provider transport
  module whose interface matches the repeated provider adapter needs.
- Runtime stream events compose model-call event vocabulary instead of copying
  provider event classes and JSON codec logic.
- `llm_dart_core` is removed from the main architecture graph or reduced to a
  clearly deprecated migration stub that owns no implementation.
- `llm_dart_provider` exposes an explicit provider specification version and
  optional facets without weakening Dart-native typed provider options.
- Public AI runtime helpers are thin facades over a deep runtime execution
  module; the tool loop, stop policy, output projection, callbacks, and prompt
  normalization have one primary implementation locality.
- Guard tooling rejects the old couplings and obsolete package choices.

## In Scope

- Breaking removal or relocation of compatibility surfaces that obscure the
  target seams.
- OpenAI route adapter decomposition.
- Provider transport helper deepening and naming cleanup.
- Stream event vocabulary composition across provider and runtime layers.
- Provider specification seam hardening.
- Runtime helper option surface consolidation.
- Migration docs, changelog notes, guard updates, and focused tests.

## Out Of Scope

- Copying the Vercel AI SDK package count or TypeScript helper types.
- Removing provider-native product features.
- Flattening provider-specific options into lowest-common-denominator shared
  options.
- Adding framework packages beyond existing chat and Flutter adapters.
- Reintroducing root-owned implementation code.
- Keeping obsolete compatibility solely to avoid a breaking release.

## Starting Assumptions

| Assumption | Confidence | Evidence | Consequence if wrong |
| --- | --- | --- | --- |
| The user accepts breaking changes and deletion of obsolete code. | High | User explicitly requested fearless refactor and no redundant legacy code. | Re-scope deletion tasks into migration stubs. |
| OpenAI is the best first proof because it has the largest adapter mass and strongest reference analogue. | High | `llm_dart_openai` has the most lib files; `repo-ref/ai/packages/openai` is route-adapter based. | Start with provider transport kit first. |
| `llm_dart_core` no longer earns its place after package split. | Medium | Its files are mostly re-export facades over `llm_dart_ai` and `llm_dart_provider`. | Keep a deprecated stub but remove it from runtime dependencies. |
| Provider stream/runtime stream split remains architecturally correct. | High | Existing docs deliberately assign model-call events to provider and lifecycle events to runtime. | Do not merge seams; only reduce duplicated implementation. |
| Provider utilities are now justified as a real seam. | Medium | Multiple providers already share transport/error/cancellation/SSE helper patterns. | Keep helpers internal but still deepen the module shape. |

## Architecture Direction

Use `repo-ref/ai` as a reference for ownership, not as a literal port.

- `llm_dart_provider` owns provider-facing model contracts, provider prompt
  data, model-call events, options, metadata, usage, tools, and provider
  specification versioning.
- `llm_dart_ai` owns user-facing runtime orchestration: generate, stream,
  structured output, tool execution, stop policy, runtime lifecycle events,
  and UI projection.
- `llm_dart_transport` owns HTTP primitives and adapters.
- Provider packages own concrete adapters, provider wire codecs, typed
  provider options, provider-native tools, product helper clients, and
  model-family policy.
- `llm_dart_chat` and `llm_dart_flutter` adapt runtime surfaces without
  owning provider contracts.
- Root `llm_dart` is only a convenience facade.

The first implementation proof should split OpenAI routing into deeper route
adapters. That proof will make the transport kit and provider specification
shape concrete instead of speculative.

## Closeout Condition

This lane can close when:

- the target state is implemented or explicitly split into narrower follow-on
  workstreams,
- focused tests and guard gates pass with fresh evidence,
- migration documentation describes the breaking changes,
- `WORKSTREAM.json`, `TODO.md`, `MILESTONES.md`, `EVIDENCE_AND_GATES.md`, and
  `HANDOFF.md` reflect the shipped state,
- and no compatibility shell remains as an unstated architecture owner.
