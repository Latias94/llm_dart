# Fearless Boundary Reset — Handoff

Status: Closed
Last updated: 2026-05-21

## Current State

FBR-010 through FBR-110 are implemented, verified, and closed. OpenAI language
model route behavior now flows
through route-specific adapters:

- `OpenAIResponsesLanguageModelRouteAdapter`
- `OpenAIChatCompletionsLanguageModelRouteAdapter`

The old route switch helper files for request, response, stream, and transport
URI selection were removed. `OpenAILanguageModel` now depends on
`OpenAILanguageModelRouteAdapters` rather than directly carrying Responses and
Chat Completions codecs.

Provider transport call execution now flows through:

- `sendProviderModelRequest`
- `sendProviderLanguageModelStreamRequest`

The shared seam owns transport send/stream, cancellation normalization,
`StartEvent` emission, and transport-to-model-error projection. OpenAI, Google,
Anthropic, Ollama, and ElevenLabs wrappers have been moved onto the shared
provider-utils helper where applicable.

`tool/check_workspace_dependency_guards.dart` now prevents provider
implementation packages from reintroducing direct `transport.send` or
`transport.sendStream` choreography.

Fresh evidence is recorded in `EVIDENCE_AND_GATES.md`.

`packages/llm_dart_core/**` has been deleted from the workspace instead of
kept as a deprecated compatibility stub. Root, release, bootstrap, consumer
smoke, package-test, and migration-doc orchestration now point at the owning
packages (`llm_dart`, `llm_dart_ai`, and `llm_dart_provider`) rather than the
historical core package.

`llm_dart_provider` now freezes provider-object discovery behind
`ProviderSpecification`. Every `Provider` must expose `specification`, and
`ProviderModelFacetSupportResolver` now requires both the matching model
provider interface and a declared specification facet. OpenAI-family, Google,
Anthropic, Ollama, and ElevenLabs facades expose conservative provider specs
with facets, shared capabilities, and supported input shapes.

AI full-stream JSON serialization now composes provider model-call event JSON
through `LanguageModelStreamEventJsonCodec` and the explicit provider/runtime
bridge. AI still owns runtime-only lifecycle events (`run-*`, `step-*`,
`tool-output-denied`, `abort`); provider owns model-call content/tool/start/
finish/error event JSON.

AI text-generation runtime helper plumbing now flows through
`TextGenerationRuntimeRequest`. The internal seam owns prompt normalization,
immutable tools and stop conditions, planner/continuation setup, cancellation
helpers, and structured-output option derivation for `GenerateTextRunner`,
`StreamTextRunner`, output helpers, and text-call helpers while preserving the
existing public helper ergonomics.

Migration docs and examples now describe the breaking architecture line:
`llm_dart_core` is removed, root remains provider-neutral, concrete providers
come from direct provider packages, and root legacy/provider/model/builder
paths are removal warnings rather than recommended usage.

OpenAI-family routing and provider-specific policy is now profile-owned:
`OpenAIFamilyProfile` owns route policy, option resolver, capability policy,
Chat Completions request policy, and OpenAI tool-option acceptance.
`OpenAICompatibleProfile` is the explicit profile for custom compatible
endpoints that use the OpenAI-family Chat Completions contract but should not
inherit OpenAI Responses behavior.

## Active Task

None. The lane is closed.

## Decisions Since Last Update

- The lane is intentionally breaking.
- Compatibility shims should be removed when they obscure ownership.
- OpenAI route adapters are the first proof because they provide the highest
  leverage and strongest reference analogue in `repo-ref/ai`.
- FBR-020 completed the first proof without preserving the shallow switch
  helper modules.
- FBR-040 completed the provider transport kit proof and kept provider-utils as
  the shared provider implementation seam.
- FBR-050 codified the provider transport seam in the workspace dependency
  guard.
- The shared provider transport call module is intentionally provider-facing,
  not a transport primitive; `llm_dart_transport` still owns HTTP mechanics.
- `llm_dart_core` is a candidate for deletion or reduction to a deprecated
  non-owning stub.
- FBR-060 chose full deletion of `llm_dart_core` from the package graph; any
  remaining mention should be either migration documentation or a negative
  guard fixture that prevents reintroduction.
- FBR-070 added explicit provider specifications and intentionally broke
  third-party provider implementations that do not declare their version,
  facets, and supported input shapes.
- FBR-080 removed duplicated AI content/tool stream JSON codecs and composes
  provider model-call stream vocabulary from the provider codec. Runtime-only
  AI lifecycle events remain in AI.
- Provider/runtime stream seams should remain separate, but duplicated event
  vocabulary implementation should be reduced through composition.
- FBR-090 introduced `TextGenerationRuntimeRequest` as an internal deep module
  for shared runtime helper options and kept public helper signatures stable.
- FBR-100 updated migration docs, README, CHANGELOG, AI README, and examples so
  removed compatibility paths are warnings/history rather than recommended
  targets.
- FBR-030 was completed before closeout after audit found it still open:
  route selection, option resolution, capability policy, Chat Completions
  request policy, and tool-option acceptance now hang off
  `OpenAIFamilyProfile`.
- FBR-110 closed the lane after analyzer, OpenAI package tests, workspace/root/
  transport guards, and `git diff --check` passed.

## Blockers

None.

## Next Recommended Action

Suggested follow-ons, not blockers:

1. Decide whether to remove thin historical OpenAI-family wrapper helpers
   after downstream API audits.
2. Consider a public object-style text generation request API after the alpha
   migration surface stabilizes.
3. Continue release hardening/dry-run work before publishing the breaking
   architecture line.
