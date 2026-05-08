# Milestones

## M1 - Breaking Architecture Contract

Goals:

- freeze the target package graph
- freeze which current `llm_dart_core` responsibilities move to each package
- define the migration posture for root legacy code

Acceptance criteria:

- target package graph is documented
- dependency guard changes are planned
- non-goals are explicit
- root compatibility posture is documented

Current status:

- workstream scaffold created
- target direction documented for provider spec, provider utils, AI runtime,
  transport, chat runtime, Flutter adapter, provider packages, and root facade

## M2 - Provider Spec Package

Goals:

- introduce `llm_dart_provider`
- move stable provider-facing model contracts out of `llm_dart_core`
- keep provider spec independent from transport, chat, Flutter, and root

Acceptance criteria:

- provider packages compile against `llm_dart_provider`
- provider spec does not depend on `llm_dart_transport`
- no provider package imports root `llm_dart`
- guard tooling enforces the new dependency direction

Current status:

- `llm_dart_provider` now exists as the first provider-spec package scaffold.
- the first migrated foundation contracts now live in `llm_dart_provider`:
  `JsonSchema`, `ModelWarning`, `UsageStats`, `ProviderModelOptions`, and
  `ProviderInvocationOptions`
- the second migrated contract slice now also lives in `llm_dart_provider`:
  `ProviderMetadata`, `ModelError`, prompt messages, content parts, tool
  choices, and tool definitions
- provider-facing response and stream contracts now also live in
  `llm_dart_provider`: `FinishReason`, response formats, and
  `TextStreamEvent`
- provider-level call options and cancellation now live in
  `llm_dart_provider`; old `TransportCancellation` names remain compatibility
  aliases in core and transport
- provider-facing model interfaces and request/result contracts now live in
  `llm_dart_provider`: language, embedding, image, speech, transcription, model
  response metadata, and capability profiles
- `llm_dart_core` re-exports those contracts from their old paths as a
  compatibility layer
- shared UI message and message-mapping contracts now live in
  `llm_dart_provider` for the first breaking preview; old `llm_dart_core` UI
  paths re-export them as compatibility shims
- runtime helpers such as `generateText`, `embed`, `generateImage`,
  `generateSpeech`, `transcribe`, runners, and structured output now live in
  `llm_dart_ai`; `llm_dart_core` keeps old-path compatibility re-exports
- workspace bootstrap, dependency guards, root boundary guards, focused package
  analysis, and workspace publish dry-run all understand the new provider
  package

## M3 - AI Runtime Package

Goals:

- introduce `llm_dart_ai`
- move high-level generation functions, runners, structured output, and tool
  orchestration out of the provider spec layer

Acceptance criteria:

- apps can call AI runtime helpers with any `LanguageModel`
- provider packages do not depend on `llm_dart_ai`
- runtime tests cover single-step and multi-step text generation

Current status:

- `llm_dart_ai` exists as a focused runtime package depending only on
  `llm_dart_provider`
- one-shot helpers, multi-step runners, stream result accumulation, partial JSON
  repair, replay stream support, and structured output helpers moved to
  `llm_dart_ai`
- `llm_dart_core` keeps compatibility re-exports for the old runtime paths
- the root `package:llm_dart/ai.dart` entrypoint explicitly exports the new
  runtime package while preserving the modern facade surface
- core no longer owns the duplicate JSON codec helper implementations; those
  helpers now live only in `llm_dart_provider`
- workspace bootstrap, dependency guards, root boundary guards, package
  analysis, and focused runtime/core tests understand the new AI package

## M4 - Data Structure Upgrade

Goals:

- introduce shared `ProviderReference`
- redesign shared file data as a sealed data union
- redesign tool output as explicit common output variants
- clarify provider options versus provider metadata

Acceptance criteria:

- OpenAI, Anthropic, and Google codecs support the new file data shape where
  applicable
- provider references produce clear errors when used with unsupported providers
- tool output replay remains explicit and tested
- compatibility shims or migration recipes exist for old file and tool result
  shapes

Current status:

- first data-structure slice is implemented in `llm_dart_provider`
- `ProviderReference`, sealed `FileData`, and explicit `ToolOutput` variants
  are exported from the provider foundation entrypoint
- prompt/content file parts and generated files now store required structured
  `FileData`, while tool-result parts still expose structured `toolOutput`
  accessors
- `llm_dart_core` compatibility exports expose the new shared types through the
  old content, prompt, and tool paths
- OpenAI Responses and Chat Completions resolve OpenAI provider references for
  image/PDF file inputs without falling back to provider metadata file IDs
- Anthropic Messages resolves Anthropic provider references to file sources and
  adds the Files API beta header when needed
- Google GenerateContent and function-response replay resolve Google/Vertex
  provider references to `fileData.fileUri`
- core prompt JSON serialization preserves the new file-data and tool-output
  unions while still reading the legacy JSON shape
- provider contract tests cover provider references, file data projection, and
  tool-output projection
- focused OpenAI, Anthropic, and Google codec tests cover the first provider
  reference slice
- `ToolResultContent` and `ToolResultPromptPart` now store only `ToolOutput`;
  legacy `output` / `isError` inputs are construction-time migration shims, and
  the old `toolOutputFromLegacy` helper has been removed from the provider
  surface
- active provider-reference coverage is closed for the first breaking preview:
  OpenAI, Anthropic, and Google/Vertex have hosted-reference support, while
  current community providers do not expose a hosted input file reference path

## M5 - Provider Package Migration

Goals:

- migrate OpenAI, Anthropic, Google, and community providers to the new spec
  package
- keep provider-native helpers provider-owned
- preserve capability profile support

Acceptance criteria:

- provider package tests pass against new contracts
- provider-native options remain typed
- provider-owned helpers stay outside common abstractions
- OpenAI-family profile routing remains supported

Current status:

- OpenAI, Anthropic, Google, and community provider packages now depend on
  `llm_dart_provider` for runtime contracts instead of `llm_dart_core`
- provider tests and examples that need high-level helpers use
  `llm_dart_ai` as a dev dependency only
- shared workspace test helpers in `llm_dart_test` now depend on
  `llm_dart_provider` instead of `llm_dart_core`
- provider-owned typed options, capability profiles, OpenAI-family profiles,
  and helper clients remain in their owning provider packages
- workspace dependency guards now reject future concrete-provider runtime
  dependencies on `llm_dart_core`

## M6 - Root Slimming And Legacy Boundary

Goals:

- reduce root implementation ownership
- keep the modern facade focused
- keep legacy compatibility explicit and migration-oriented

Acceptance criteria:

- root package does not host new provider implementations
- root dependencies shrink when implementation moves make that truthful
- examples teach focused modern entrypoints
- compatibility examples import `legacy.dart` or its successor explicitly

Current status:

- shared UI stream chunk, accumulator, projection, prompt JSON, text-stream
  JSON, and chat UI JSON implementations now live in `llm_dart_provider`
- `llm_dart_core` preserves old UI and serialization paths as compatibility
  re-exports for migrated contracts
- `llm_dart_core/lib` is now guarded as a compatibility shell: new
  implementation declarations must move to `llm_dart_provider` or
  `llm_dart_ai`, while old cancellation names remain approved aliases
- `llm_dart_transport` now keeps a transport-owned cancellation surface and no
  longer leaks provider legacy aliases through its public barrel
- `llm_dart_transport` now depends on `llm_dart_provider` directly and no
  longer depends on `llm_dart_core`
- `llm_dart_chat` now depends on `llm_dart_provider` plus
  `llm_dart_transport` and no longer depends on `llm_dart_core`
- `llm_dart_flutter` now depends on `llm_dart_chat` plus
  `llm_dart_provider` and no longer depends on `llm_dart_core`
- root no longer has a runtime dependency on `llm_dart_core`; test/dev
  compatibility coverage still exercises the core shell deliberately
- first-preview root policy is now explicit: keep `legacy.dart` in root as the
  compatibility bridge, keep new implementation ownership out of root legacy
  areas, and defer `llm_dart_legacy` until a later release if needed

## M7 - Migration And Release Readiness

Goals:

- prepare the breaking release line
- document migration from existing public surfaces
- prove the package graph with tests and guards

Acceptance criteria:

- migration matrix exists
- changelog and release notes name breaking changes
- workspace guards pass
- package tests pass in the migrated graph
- publish dry-run is updated for new packages

Current status:

- breaking changelog draft and migration matrix now exist
- test-only broad imports remain only as compatibility-shell coverage
- workspace dependency guards, root boundary guards, and the core compatibility
  shell guard now cover the migrated package graph
- transport boundary guards now cover the transport public barrel as well
- foundational test legacy-import guards now keep core/model/builder/utils
  tests on focused entrypoints
- release readiness is documented, including validation commands, publish
  dry-run expectations, manual release checks, and stop conditions
- workspace publish dry-run passed for all 11 publishable packages with zero
  warnings on 2026-05-08
- clean Dart and Flutter consumer smoke validation passed for modern root,
  focused packages, core compatibility, legacy compatibility, and
  `llm_dart_flutter` import/controller construction paths
