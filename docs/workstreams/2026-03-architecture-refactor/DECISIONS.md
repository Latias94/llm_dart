# Decisions

## 2026-03-26

The following decisions are considered frozen for this workstream. Any future change should be treated as an explicit architecture change, not a return to open discussion.

## D1. Dual Top-Level Entry Strategy

- Keep `ai()` as a compatibility entry point.
- The new primary architecture should use `AI.*` style model factories.
- During migration, `ai()` becomes a facade only and stops defining the core design.

## D2. Unify Around Model Types and Use-Case Functions

The following objects belong in the shared spec:

- `LanguageModel`
- `EmbeddingModel`
- `ImageModel`
- `SpeechModel`
- `TranscriptionModel`
- `generateText`
- `streamText`
- `embed`
- `generateImage`
- `generateSpeech`
- `transcribe`

The following objects do not belong in the phase-1 shared spec:

- OpenAI Responses CRUD
- provider file, assistant, moderation, or admin APIs
- Anthropic MCP connector

## D3. Provider-Specific Options Use Two Typed Layers

- model-level typed options carry stable provider features
- invocation-level typed options carry per-call provider features
- `extensions` is no longer the main design path and remains compatibility or escape-hatch only

## D4. Message Models Must Stay Layered

Freeze the following three message boundaries:

- Prompt layer
- Result / Stream layer
- UI Chat layer

One message model must no longer attempt to serve all three roles.

## D5. Flutter Integration Lives in Its Own Package

- `llm_dart_core` does not depend on Flutter
- the Flutter chat-session layer lives in `llm_dart_flutter`
- phase 1 freezes interfaces first; widget-level implementation is not a first-phase goal

## D6. Use a Medium-Grained Workspace Split

Recommended first-phase package boundaries:

- `llm_dart_core`
- `llm_dart_transport`
- `llm_dart_openai`
- `llm_dart_anthropic`
- `llm_dart_google`
- `llm_dart_community`
- `llm_dart_flutter`
- `llm_dart`

## D7. OpenAI-Compatible Providers Share an OpenAI-Family Core

The following providers should no longer keep fully repeated long-term implementations:

- OpenRouter
- DeepSeek OpenAI-compatible
- Groq OpenAI-compatible
- xAI OpenAI-compatible
- Phind OpenAI-compatible

They should migrate toward an OpenAI-family profile model.

## D8. Dependency Direction Must Be One-Way

Freeze the dependency direction as:

- `llm_dart_core`
- `llm_dart_transport -> llm_dart_core`
- `llm_dart_openai / anthropic / google / community -> core + transport`
- `llm_dart -> core + transport + provider packages`
- `llm_dart_flutter -> core`, and optionally `transport` when needed

Explicitly disallow:

- core depending back on providers
- provider-package dependency cycles
- Flutter packages depending on concrete provider packages

## D9. Third-Party Dependencies Must Stay in the Right Layer

- keep `dio`, but only inside `transport` and provider implementation layers
- keep `logging` as an internal implementation dependency only
- `http_parser` should stop being a long-term root-package runtime dependency and should be localized after migration
- `mcp_dart` stays out of the main library dependency chain and remains example or integration-package only

## D10. Provider-Specific Features Must Use Five Fixed Channels

Provider-specific features should be represented through:

- typed model settings
- typed invocation options
- provider metadata
- custom content or UI parts
- provider-native extension APIs

`extensions` remains compatibility or escape-hatch only and is no longer a first-class design path.

## D11. Provider Metadata Must Stay Namespaced And JSON-Safe

- `ProviderMetadata` is provider-owned detail, not a substitute for common core fields
- top-level keys must be namespace keys such as `openai`, `anthropic`, or `google`
- metadata values must stay JSON-safe so prompt, UI, and session persistence remain possible
- common concepts that already have stable fields or common UI metadata keys must not be pushed back into provider metadata

## D12. Serialization Must Use Explicit Versioned Codecs

- do not add ad hoc `toJson()` methods across all domain models as the primary design
- prompt history, UI messages, and session snapshots should use explicit codecs
- serialized top-level artifacts must carry a schema version and artifact kind
- session restore must serialize both prompt history and rendered UI messages, not only `ChatState.messages`

## D13. Result And Stream Layers Must Preserve Approval And Common Response Metadata

- `ContentPart` must include a first-class tool approval request part
- provider-executed approval flows must be representable in both `generate()` results and `stream()` events
- `GenerateTextResult` must expose common response metadata fields such as response ID, response timestamp, response model ID, and raw finish reason directly
- `FinishEvent` should carry `rawFinishReason` when the provider exposes one
- provider metadata should keep provider-owned detail and should not be the primary home for those common response fields
