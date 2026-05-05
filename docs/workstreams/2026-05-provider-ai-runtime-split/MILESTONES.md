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
- `llm_dart_core` currently re-exports those contracts from their old paths as
  a compatibility layer while the rest of the provider-facing spec moves over
- `llm_dart_core` still owns runtime helpers such as `generateText`, `embed`,
  `generateImage`, `generateSpeech`, `transcribe`, runners, and structured
  output until `llm_dart_ai` exists
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

- workspace publish dry-run tooling now stages every package, including the
  root facade package, so dirty development worktrees do not produce false
  publish warnings during refactor validation
- transport cancellation now consumes provider-level cancellation contracts
  through compatibility aliases, reducing direct conceptual coupling between
  provider/model APIs and transport naming

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

- not started

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

- not started

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

- not started

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

- not started
