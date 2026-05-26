# Core Seam Fearless Refactor

Status: Closed
Last updated: 2026-05-27

## Why This Lane Exists

The package graph is already close to the mature shape in `repo-ref/ai`:
provider contracts, AI runtime, transport, chat, Flutter adapters, provider
packages, and root facade are separate ownership areas. The remaining problem
is that several important modules still expose shallow interfaces. Callers and
tests can still see too much option plumbing, error taxonomy, provider/runtime
event mirroring, provider facade construction policy, and app/provider-author
entrypoint overlap.

This lane is intentionally breaking. Compatibility is not a design constraint
when it preserves shallow modules or ambiguous seams.

## Relevant Authority

- Existing docs:
  - `docs/workstreams/2026-05-fearless-boundary-reset/DESIGN.md`
  - `docs/workstreams/2026-05-fearless-boundary-reset/EVIDENCE_AND_GATES.md`
  - `docs/workstreams/2026-05-runtime-event-tool-loop-boundary/README.md`
  - `docs/workstreams/2026-05-sdk-aligned-fearless-refactor/README.md`
  - `docs/workstreams/2026-05-provider-options-seam-deepening/README.md`
  - `docs/workstreams/2026-05-fearless-refactor-wave-3/DESIGN.md`
- Reference repository:
  - `repo-ref/ai/architecture/provider-abstraction.md`
  - `repo-ref/ai/architecture/message-layers.md`
  - `repo-ref/ai/architecture/stream-text-loop-control.md`
  - `repo-ref/ai/packages/ai/src/error/**`
  - `repo-ref/ai/packages/provider/src/errors/**`
  - `repo-ref/ai/packages/provider-utils/src/response-handler.ts`

## Problem

The current architecture has good packages but several shallow module
interfaces:

- public text generation helpers repeat a broad parameter surface even though
  internal execution now flows through `TextGenerationRuntimeRequest`;
- runtime, provider, and transport error modes are split across raw Dart
  exceptions and `ModelError` data values without one clear error module;
- provider and AI stream events are separate by design, but model-call
  vocabulary still appears in two class families;
- provider facades own provider specifications, facet policy, model factories,
  native product clients, and profile policy in one broad module;
- `llm_dart_provider_utils` is now a real shared seam, but its public interface
  still reads like helper functions rather than a durable provider call kit;
- app-facing convenience exports still make provider-authoring structures easy
  to reach from ordinary application code.

## Target State

When this lane closes:

- app-facing text generation accepts one deep request object, while named
  helper functions remain thin adapters for common use;
- runtime/provider/transport failures share a coherent error module with typed
  thrown errors, stream error projection, and JSON support;
- model-call stream vocabulary has one tested locality that provider and AI
  runtime compose without collapsing their separate seams;
- provider facade modules delegate specification and facet/policy description
  to provider-owned descriptor modules;
- provider call execution is a named provider call kit with explicit request,
  response, stream, cancellation, and error policy ownership;
- app-facing and provider-authoring entrypoints are explicit enough that
  ordinary users do not learn provider-facing prompt and metadata contracts by
  accident;
- guards, tests, README, migration docs, and workstream evidence prevent old
  couplings from returning.

## In Scope

- Breaking public API changes in `llm_dart_ai`, root facade, and package
  entrypoints when they deepen core seams.
- Internal module reshaping in `llm_dart_provider`, `llm_dart_provider_utils`,
  and primary provider packages.
- Focused migration docs and examples for changed app-facing entrypoints.
- Guard updates for direct use of obsolete or shallow seams.
- Tests that hit module interfaces rather than private helper implementation.

## Out Of Scope

- Copying the Vercel AI SDK package count or TypeScript type machinery.
- Removing provider-native product APIs such as files, assistants, catalogs,
  voices, moderation, lifecycle helpers, or provider-native tools.
- Flattening provider-specific typed options into weak shared maps.
- Reintroducing `llm_dart_core` or root-owned implementation code.
- Publishing side effects. Local publish dry-runs are allowed; actual
  `pub publish` is not.

## Starting Assumptions

| Assumption | Confidence | Evidence | Consequence if wrong |
| --- | --- | --- | --- |
| Breaking changes are allowed. | High | User explicitly requested break and fearless refactor. | Keep compatibility adapters longer and record migration cost. |
| Public text-generation request shape is the best first proof. | High | `TextGenerationRuntimeRequest` already exists internally and repeated public signatures remain visible. | Start with error module if public API churn is too risky. |
| Error taxonomy should be deepened before stream vocabulary changes. | Medium | Error modes are part of the interface and currently cross runtime/provider/transport. | Keep stream work independent if error work proves larger. |
| Provider/runtime event seams should remain separate. | High | Existing runtime-event workstream deliberately split ownership. | Do not merge ownership; compose shared value vocabulary only. |
| `llm_dart_provider_utils` is now a real seam. | High | Current packages depend on it and guards require provider transport calls to go through it. | If it becomes unstable, keep helper names but narrow public export. |

## Architecture Direction

Use `repo-ref/ai` as a reference for ownership, not literal structure:

- `llm_dart_ai` owns app-facing generation request objects, orchestration,
  tool-loop policy, structured output, result facades, runtime errors, and UI
  projection.
- `llm_dart_provider` owns provider-facing model contracts, prompt/data
  contracts, provider metadata, provider options, model-call event vocabulary,
  model warnings, provider specifications, and provider-visible errors.
- `llm_dart_provider_utils` owns provider implementation call execution: how a
  provider adapter sends requests through transport, maps cancellation, projects
  transport errors, and decodes provider streams.
- Provider packages own provider-specific descriptors, route/profile policy,
  wire codecs, typed options, native tools, and product clients.
- Root `llm_dart` stays a convenience facade and never regains implementation
  ownership.

## Closeout Condition

This lane can close when:

- all six seam candidates are implemented, explicitly deferred with evidence,
  or split into narrower follow-on lanes;
- affected packages pass focused tests and analysis;
- workspace guards pass;
- migration docs and examples describe the breaking surfaces;
- `WORKSTREAM.json`, `TODO.md`, `MILESTONES.md`, `EVIDENCE_AND_GATES.md`, and
  `HANDOFF.md` reflect the shipped state;
- and no newly introduced public interface is a pass-through over the old
  shallow implementation.
