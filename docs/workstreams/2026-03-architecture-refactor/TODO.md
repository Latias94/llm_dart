# TODO

## Architecture Freeze

- [x] Complete the current repository audit and target-architecture mapping
- [x] Freeze third-party dependency policy and inter-package dependency direction
- [x] Freeze `PromptMessage` / `PromptPart`
- [x] Freeze `ContentPart` / `GenerateTextResult`
- [x] Freeze `TextStreamEvent`
- [x] Freeze `ChatUiMessage` / `ChatUiPart`
- [x] Freeze provider typed options design
- [x] Freeze workspace package boundaries

## Workspace And Infrastructure

- [x] Introduce workspace management
- [x] Create `llm_dart_core`
- [x] Create `llm_dart_transport`
- [x] Create `llm_dart_chat`
- [x] Create `llm_dart_openai` skeleton
- [x] Create `llm_dart_anthropic` skeleton
- [x] Create `llm_dart_google` skeleton
- [x] Create `llm_dart_community` skeleton
- [x] Run static analysis for `llm_dart_core` and `llm_dart_transport`
- [x] Run static analysis for `llm_dart_openai`
- [x] Create the facade compatibility entry
- [x] Establish the new shared test foundation
- [x] Establish the new export strategy and `src/` structure

## Core

- [x] Rewrite the error model
- [x] Rewrite usage, warning, and provider metadata models
- [x] Add common `reasoning-file` support across prompt, result, stream, and UI layers
- [x] Add explicit shared abort semantics across `TextStreamEvent`, chat-UI projection, and Flutter chat transport/session
- [x] Add part-level provider metadata to replayable prompt parts and codecs
- [x] Define provider model-options and invocation-options marker interfaces
- [x] Strengthen `SourceReference` with an explicit source kind
- [x] Define malformed tool-input semantics in the core stream and UI models
- [x] Rewrite the function-tool schema and tool-choice model
- [x] Freeze provider-native tool declaration APIs and the remaining tool-result orchestration work
- [x] Define unified `CallOptions`
- [x] Define `LanguageModel`
- [x] Define `EmbeddingModel`
- [x] Define `ImageModel`
- [x] Define `SpeechModel`
- [x] Define `TranscriptionModel`
- [x] Implement `generateText`
- [x] Implement `streamText`
- [x] Add a first non-streaming shared structured-output helper with `OutputSpec`, `generateOutput`, and built-in `text` / `json` / `object` / `array` / `choice` modes
- [x] Add `GenerateTextStepResult` as the shared single-step snapshot wrapper above existing request/result models
- [x] Add initial runner-facing shared model primitives: `GenerateTextRunResult` and `GenerateTextStepStartEvent`
- [x] Implement a minimal non-streaming single-step `GenerateTextRunner` with `onStepStart`, `onStepFinish`, and `onFinish`
- [x] Design and implement a narrow non-streaming multi-step text generation runner with lifecycle callbacks, synthesized `StepResult` snapshots, and app-supplied common function-tool continuation above the single-step `generateText` / `streamText` helpers
- [x] Decide whether the shared runner should later add streaming orchestration, `prepareStep`-style mutation hooks, or broader retry/model-switch policies
- [x] Decide whether approval-gated continuation and provider-native built-in tool continuation should stay provider/session-owned or ever gain a shared runner path
- [x] Decide whether the additive `generateTextCall(...)` / `streamTextCall(...)` layer should later fold into `generateText(...)` / `streamText(...)` directly or remain the explicit higher-level result surface
- [x] Design and implement an additive streamed multi-step runner above raw `streamText(...)` with a stitched run stream, `stepStream`, and final run result
- [ ] Re-evaluate shared runner expansion only after a replay-safe approval or provider-executed continuation contract is proven across at least two provider families
- [ ] Re-evaluate whether the new streamed runner needs a constrained pre-step hook after the layered API is used by at least two concrete shared call paths
- [ ] Decide whether streamed multi-step orchestration really needs richer step-start/step-finish metadata in the shared core, or whether that detail should stay in a future UI/transport chunk layer
- [x] Decide that the initial streamed runner keeps its stitched `eventStream` provider-step-only instead of synthesizing local tool-result or other inter-step projection events in the narrow phase
- [ ] Evaluate a lightweight `llm_dart_chat` UI-stream helper above `ChatUiStreamChunk` for non-session consumers, instead of widening chunk vocabulary or adding more core events
- [x] Implement `embed` / `embedMany`
- [x] Implement `generateImage`
- [x] Implement `generateSpeech`
- [x] Implement `transcribe`

## Transport

- [x] Extract the HTTP request executor
- [x] Extract the SSE decoder
- [x] Extract the stream chunk parser helper
- [x] Complete retry and timeout helpers
- [x] Replace public `CancelToken` with a transport cancellation abstraction
- [x] Extract provider-independent error mapping
- [x] Define the transport diagnostics interface
- [x] Define `HttpChatTransport` request and chunk codecs
- [x] Move the HTTP chat transport protocol codecs into `llm_dart_transport` and add a pure-Dart backend SSE/reference adapter
- [x] Implement `TextStreamEvent` JSON codec

## OpenAI Family

- [x] Design the OpenAI-family profile structure
- [x] Expose OpenAI-family convenience constructors on the root `AI` facade
- [ ] Complete OpenAI chat migration (see `58-openai-chat-migration-status.md`, `60-openai-assistant-replay-alignment.md`, and `61-openai-responses-persistence-policy.md` for the narrowed remaining replay and provider-owned persistence-policy gaps)
- [x] Add the initial OpenAI-family chat-completions mainline
- [x] Migrate OpenAI responses
- [x] Preserve OpenAI replay-critical item metadata, reasoning state, and compaction replay
- [x] Freeze OpenAI Responses persistence policy for `store`, `conversation`, and `item_reference`
- [x] Migrate OpenAI embeddings
- [x] Migrate OpenAI image
- [x] Migrate OpenAI speech and transcription
- [x] Align provider-owned OpenAI `logprobs` request encoding and provider-metadata decode without widening the shared core
- [x] Align OpenAI chat-completions provider-owned `systemMessageMode` shaping and default reasoning-model `developer` role without widening the shared prompt model
- [x] Align OpenAI chat-completions provider-owned reasoning-model compatibility and `serviceTier` gating without widening the shared text-generation spec
- [x] Align OpenAI Responses provider-owned system-message and reasoning-model compatibility without widening the shared text-generation spec
- [x] Implement provider-owned OpenAI Responses persistence options for `store` / `conversation` plus `item_reference` replay branching without widening the shared core
- [x] Add provider-owned OpenAI `image_generation` and `mcp` native-tool declaration surfaces without widening the shared core
- [x] Add provider-owned OpenAI custom output helpers for `image_generation_call`, partial-image stream chunks, and `mcp_list_tools` without widening the shared core
- [x] Add provider-owned OpenAI `code_interpreter` declaration support without widening the shared core
- [x] Add a provider-owned OpenAI image edit helper without widening the shared image contract
- [x] Decide that OpenAI image variation should remain compatibility-only for now instead of gaining an automatic provider-owned helper
- [x] Freeze the remaining root OpenAI public compatibility API policy and deprecate preset helpers that only prefill `baseUrl` or `model`
- [x] Layer OpenAI compatibility config reads behind internal grouped views while keeping the public `OpenAIConfig` constructor flat
- [x] Align the modern OpenAI Responses stream codec on `content_part.done`, annotation dedupe, and final text-part metadata
- [x] Decide that the public root `OpenAIProvider` chat path should narrow to an internal adapter over modern `llm_dart_openai` for the already-audited bridge-safe subset
- [x] Decide that deprecated root OpenAI-compatible preset helpers remain fallback-only while migration keeps moving toward provider-owned packages
- [ ] Re-evaluate richer OpenAI Responses hosted-tool or custom item-family replay only if a concrete OpenAI-native use case requires it beyond the current common function-tool and MCP continuation subset
- [ ] Decide whether OpenAI should keep the remaining advanced hosted-tool families deferred, or add only narrowly-scoped provider-owned helpers if a concrete product need appears
- [x] Turn OpenRouter into a profile
- [x] Turn DeepSeek OpenAI-compatible into a profile
- [x] Turn Groq OpenAI-compatible into a profile
- [x] Turn xAI OpenAI-compatible into a profile
- [x] Turn Phind OpenAI-compatible into a profile

## Anthropic

- [x] Establish the Anthropic messages request codec
- [x] Migrate the Anthropic language model
- [x] Add the initial Anthropic native tool entry API
- [x] Add warning-based downgrade rules for unsupported assistant replay parts
- [x] Migrate the Anthropic tool codec
- [x] Migrate the Anthropic reasoning codec
- [x] Migrate the Anthropic web-search adapter
- [x] Migrate the Anthropic MCP connector
- [x] Move cache-related structures into provider metadata or typed provider options, while keeping `anthropic.contentBlocks` as compatibility-only input

## Google

- [x] Migrate the Gemini language model
- [x] Add the initial Google native tool entry API
- [x] Preserve Google thought signatures and thought files through prompt replay
- [x] Re-audit Gemini 3 mixed-tool request support and tool-context circulation before exposing any public Google native-tool selection API
- [x] Introduce a provider-owned Google `includeServerSideToolInvocations` option surface
- [x] Preserve Google provider-originated Gemini 3 `functionCall.id` values through result decode, runner continuation, and request replay for common function-tool history
- [x] Add a provider-owned Google `functionResponse` replay helper for multimodal Gemini 3 follow-up turns without widening the shared tool-result model
- [x] Add provider-owned Google custom replay helpers for assistant-side `toolCall` / `toolResponse` circulation history
- [x] Decode Google server-side `toolCall` / `toolResponse` parts into provider-owned custom content and stream events
- [x] Enable the provider-owned Google mixed-tool circulation option for Gemini 3
- [x] Migrate Google mixed built-in + function-tool request encoding for Gemini 3
- [x] Preserve Google mixed-tool replay IDs and server-side tool context through follow-up prompt encoding
- [x] Add provider-owned Google custom-part parser helpers for Flutter or other UI renderers
- [x] Add provider-owned Google custom-part summary helpers for Flutter or other UI renderers
- [x] Add a provider-owned Google message mapper for Flutter or other UI renderers
- [ ] Decide whether any Google `toolCall` / `toolResponse` families should later gain richer shared projection or dedicated Flutter renderers beyond provider-owned custom replay
- [x] Migrate the Gemini image model
- [x] Migrate the Gemini embedding model
- [x] Migrate Gemini speech and TTS
- [x] Decide whether Google image editing and variation should later gain a provider-owned modern helper instead of remaining on compatibility-only `ImageEditRequest` / `ImageVariationRequest`
- [ ] Decide whether Google streamed TTS should later return as a provider-owned package surface outside the shared `SpeechModel`
- [x] Migrate Gemini safety and modality options
- [ ] Decide whether Google file-upload/cache helpers should remain compatibility-only or gain a provider-owned utility surface

## Structural Cleanup

- [x] Break the current `llm_dart_core <-> llm_dart_transport` package cycle without introducing a finer-grained public utility package
- [x] Move the shared Dio cancellation adapter into `llm_dart_transport` and switch root/provider code away from a root-local adapter implementation
- [x] Extract transport-owned configurable Dio setup primitives so reusable HTTP client setup no longer lives only under root `HttpConfigUtils`
- [x] Move provider-facing Dio strategy/factory abstractions into `llm_dart_transport` and reduce root `DioClientFactory` to a compatibility wrapper
- [x] Move Ollama and ElevenLabs default values out of root `provider_defaults.dart` imports and into provider-owned local defaults
- [x] Move the shared UTF-8 streaming decoder into `llm_dart_transport` and reduce the root utility path to a compatibility re-export
- [x] Move shared log sanitization and JSON-object response decoding into `llm_dart_transport` and narrow root `HttpResponseHandler` to a compatibility wrapper
- [x] Move Ollama and ElevenLabs provider-side Dio override data out of the root `LegacyDioClientOverrides` mixin and into transport-owned override values
- [x] Move Ollama and ElevenLabs legacy `fromLLMConfig` / `originalConfig` shaping out of provider config types and into explicit compatibility adapters
- [x] Remove Ollama's direct dependency on root `HttpResponseHandler` by using transport-owned JSON decode/logging primitives plus provider-local error mapping
- [x] Move Ollama and ElevenLabs builder DSL implementations out of provider directories and into the root compatibility layer, leaving thin compatibility exports behind
- [x] Make `llm_dart_community` a real migration target instead of an empty landing-zone package
- [ ] Decouple Ollama and ElevenLabs from root-local compatibility imports before moving real implementation weight into `llm_dart_community` (see `101-community-root-shell-thinning-plan.md` and `105-community-provider-decoupling-blocker-inventory.md`)
- [x] Extract Ollama root-shell compatibility config shaping and bridge setup out of `lib/providers/ollama/provider.dart` into the root compatibility layer
- [x] Extract ElevenLabs root-shell speech/transcription bridge setup out of `lib/providers/elevenlabs/provider.dart` into the root compatibility layer
- [x] Relocate the remaining root OpenAI provider shell under `src/compatibility`, leaving the public provider entry file as a compatibility re-export
- [x] Relocate the remaining root-hosted OpenAI legacy implementation modules under `src/compatibility`, leaving the public provider paths as compatibility re-exports
- [x] Narrow the provider-focused OpenAI barrel so broad compatibility exports move to `legacy.dart`
- [x] Freeze that the remaining root builder/factory adaptation path survives only as a compatibility shell, while provider-owned modern config constructors remain the long-term API direction
- [x] Decide that `HttpResponseHandler` and `DioErrorHandler` stay root compatibility-owned for now, while transport keeps lower-level primitives and provider packages keep owning their modern model-path error handling
- [x] Audit and narrow provider-focused root entrypoints so `openai.dart`, `google.dart`, and `anthropic.dart` stop re-exporting `AI`, `core.dart`, and `transport.dart`
- [x] Remove the direct root `logging` runtime dependency by routing compatibility, provider, test, and example imports through `llm_dart_transport` re-exports
- [x] Remove the direct root `dio` runtime dependency by routing raw Dio imports through explicit `llm_dart_transport` sub-entrypoints instead of the root facade
- [x] Split legacy `LLMConfig -> DioHttpClientConfig` shaping into the config layer and stop routing compat transport creation through `BaseHttpProvider`
- [x] Extract repeated Dio streaming-response byte/text decoding into `llm_dart_transport` and switch root compatibility/provider clients to the shared helper
- [x] Extract raw Dio error-response text collection into `llm_dart_transport` and share parsed-error extraction between root `DioErrorHandler` and the OpenAI compatibility client
- [x] Introduce a thin compatibility-owned Dio request executor and migrate Anthropic/Google compatibility clients off repeated dispatch/cancellation/catch shells
- [x] Remove the dead root `BaseHttpProvider` legacy shell after all in-repo provider implementations stop inheriting from it
- [x] Narrow `HttpResponseHandler` to shared JSON parsing and success-status validation, and remove its dead `getJson(...)` helper
- [x] Let shared `HttpResponseHandler.postJson(...)` accept provider-specific Dio error mappers so DeepSeek-style compatibility semantics survive the shared helper path
- [x] Add shared `HttpResponseHandler.postTextStream(...)` mechanics and migrate the repeated DeepSeek/Groq/xAI/Ollama stream-request shells onto it
- [x] Move the remaining Phind and ElevenLabs outlier request shells onto the shared compatibility request executor while keeping their provider-local response projections
- [x] Collapse the remaining repeated OpenAI compatibility request shells behind a provider-local helper without widening the shared compatibility HTTP layer
- [x] Extract shared OpenAI-family compatibility request-body field encoding so chat-completions and Responses stop duplicating the same common parameter shaping
- [x] Extract shared OpenAI-family streamed reasoning and tool-call delta parsing state so chat-completions and Responses stop duplicating the same incremental parsing mechanics
- [x] Move the remaining root OpenAI chat bridge and fallback routing out of `OpenAIProvider` into a local chat facade so the public provider shell keeps shrinking toward composition-only code
- [x] Freeze that the legacy compatibility layer stays as an explicit migration shell while real implementation weight keeps moving downward into provider-owned packages and shared helpers
- [x] Audit the remaining compatibility provider-shell heavy files after the recent OpenAI shell thinning rounds and freeze the next decomposition order
- [x] Split `openai_family_compat_provider.dart` into provider/profile-specific builder slices so the remaining OpenAI-family compatibility builder stops mixing six providers in one file
- [x] Re-evaluate whether `anthropic_compat_provider.dart` now deserves the same shell/support split, or whether it should stay provider-local because most of its remaining weight is real replay conversion logic
- [ ] Revisit the Anthropic compatibility adapter only if a new provider-local subdomain becomes large enough to deserve its own helper file without inventing a generic compatibility framework

## Community Providers

- [x] Freeze the split between root legacy community-provider shells and package-owned modern community model APIs
- [x] Freeze the policy for provider-specific community-provider extras versus shared modern model surfaces
- [x] Freeze Ollama `/api/generate` completion as compatibility-only unless a concrete provider-owned modern helper is justified
- [x] Freeze Ollama model listing as provider-owned or compatibility-only instead of widening the shared modern package surface
- [x] Thin the root Ollama shell for chat and embeddings by delegating replay-safe shared-capability paths into `llm_dart_community` while preserving fallback for named-message and duplicate-system-prompt legacy cases
- [x] Thin the root ElevenLabs shell for text-to-speech and direct-audio transcription by delegating shared-capability paths into `llm_dart_community` while preserving legacy fallback for file input and provider-only audio/admin features
- [x] Thin the root Ollama and ElevenLabs providers into explicit legacy delegation shells above package-owned modern community models
- [x] Add the first package-owned Ollama `EmbeddingModel` slice in `llm_dart_community`
- [x] Expand the package-owned Ollama modern slice with `LanguageModel`
- [ ] Close the remaining Ollama modern fidelity gaps after the first replay re-audit, especially explicit `toolChoice` forcing, non-inline multimodal inputs, and the lack of a native replay-time tool error flag
- [x] Add the first package-owned ElevenLabs `SpeechModel` / `TranscriptionModel` slice in `llm_dart_community`
- [ ] Migrate Ollama
- [ ] Migrate ElevenLabs
- [x] Audit whether any remaining community-provider event or metadata gaps still block moving more provider logic out of the root compatibility shells
- [x] Design richer shared speech/transcription result surfaces so common segments, language, duration, warnings, and response metadata no longer depend only on provider-specific metadata maps
- [x] Implement the shared non-text result enrichment in `llm_dart_core` and migrate ElevenLabs modern models to populate the new shared fields before treating community-provider audio migration as structurally mature
- [x] Decide whether OpenAI- and Google-owned speech/transcription models should also populate the new shared response metadata and transcript-structure fields in the same round
- [x] Decide that Google should continue leaving dedicated transcription outside the current Google modern package surface, and that transcript-oriented audio handling should stay on multimodal prompting for now instead of a misleading shared `TranscriptionModel`
- [ ] Decide whether Google should later gain a provider-owned audio-understanding helper above multimodal prompting instead of a fake shared transcription model
- [ ] Decide whether file-based ElevenLabs transcription should remain legacy-only or gain a provider-owned modern helper outside the shared `TranscriptionModel`
- [ ] Decide which remaining ElevenLabs voice/realtime/admin capabilities should stay provider-owned outside the shared audio model surfaces
- [ ] Evaluate whether community providers should later split into dedicated packages

## Flutter

- [x] Create `llm_dart_flutter`
- [x] Define `ChatSession`
- [x] Define `ChatTransport`
- [x] Define `ChatState`
- [x] Implement pure Dart `ChatUiAccumulator` / stream-to-UI-message projection
- [x] Implement `DirectChatTransport`
- [x] Implement baseline `DefaultChatSession`
- [x] Implement baseline client-side tool output continuation in `DefaultChatSession`
- [x] Implement baseline `HttpChatTransport`
- [x] Add approval-response reason support to session, prompt, and UI state
- [x] Define how UI-only data parts enter `ChatSession` and `HttpChatTransport` without expanding `TextStreamEvent`
- [x] Make assistant prompt reconstruction preserve reasoning, reasoning-file, custom parts, and prompt-part provider metadata
- [x] Audit current event completeness against `repo-ref/ai` and freeze the boundary between shared stream events and UI transport chunks
- [x] Implement `ChatController`
- [x] Implement `ChatPersistenceAdapter`
- [x] Implement `ChatMessageMapper`
- [x] Extract the framework-neutral chat runtime into `llm_dart_chat`
- [x] Keep `llm_dart_flutter` as a thin Flutter adapter above `llm_dart_chat`
- [x] Expose a focused root `chat.dart` entrypoint for the pure Dart chat runtime while keeping Flutter adapters out of the root package
- [x] Split session persistence from Flutter controller persistence convenience
- [x] Audit the remaining `llm_dart_chat` runtime surface against `repo-ref/ai` and adopt only transport request customization plus request metadata, not React-style local message-store mutation APIs
- [x] Define a serialized chat chunk protocol for `HttpChatTransport`
- [x] Design the message serialization protocol
- [x] Implement prompt and UI JSON codecs
- [x] Implement `ChatSessionSnapshot` export and import
- [x] Design and implement the baseline tool approval and output injection API
- [x] Rewrite the Flutter integration examples
- [x] Decide that richer remote chat streaming should come through a dedicated UI/session chunk layer above `TextStreamEvent`, not by widening the shared model event surface
- [x] Design a dedicated UI chunk layer above `TextStreamEvent` instead of continuing to overload transport/session responsibilities into the model-layer stream
- [x] Add a shared `ChatUiStreamChunk` runtime model above `TextStreamEvent` and below `ChatUiMessage`
- [x] Add a UI-stream accumulator/projector that merges message-start, message-metadata, event, data-part, and message-finish chunks into `ChatUiMessage`
- [x] Refactor `DefaultChatSession` to consume the dedicated UI/session chunk layer instead of transport-owned runtime chunks
- [x] Replace `ChatTransportChunk` outright with the dedicated `ChatUiStreamChunk` runtime chunk family in the breaking round
- [x] Design and implement protocol negotiation plus additive HTTP transport v2 chunk families that separate `transport-start` from `message-start`
- [x] Audit the remaining `repo-ref/ai` chat-runtime event gap and freeze transient `data-*` delivery as a transport/session concern rather than a new core event family
- [x] Add non-persistent transient UI-data chunks plus a framework-neutral delivery hook above persisted `ChatUiMessage` state

## Compatibility Layer

- [x] Audit the remaining root-package bus files and freeze the next decomposition order
- [x] Decompose `compat_providers.dart` into provider-family compatibility slices and shared routing helpers without changing the current compatibility surface
- [x] Decompose `LLMBuilder` into provider selection, common config, and capability-build implementation modules without widening the stable builder API
- [x] Decompose root `chat_models.dart` into barrel-managed compatibility modules without changing current public exports
- [x] Decompose root `capability.dart` into barrel-managed compatibility modules without changing current public exports
- [x] Decompose compatibility route gating and the legacy chat adapter into focused compatibility modules without changing current bridge decisions
- [x] Decompose `anthropic_legacy_extensions.dart` into focused provider-owned compatibility parser modules without changing the audited raw-block contract
- [x] Decompose `audio_models.dart` into focused shared model modules without changing current public exports
- [x] Decompose `tool_models.dart` into focused shared model modules without changing current public exports
- [x] Decompose `assistant_models.dart` into focused shared/legacy model modules without changing current public exports
- [x] Decompose `core/config.dart` into focused configuration modules without changing current public exports
- [x] Centralize legacy config extension keys and typed accessors before any deeper migration away from flat compatibility extensions
- [x] Introduce namespaced OpenAI-family `providerOptions` reads/writes with flat-key fallback during the compatibility migration
- [x] Freeze the root shared web-search helpers and `createProvider(..., extensions: ...)` as compatibility-only migration surfaces
- [x] Route `LLMBuilder.build()` through compat provider subclasses for OpenAI / Google / Anthropic chat
- [x] Implement the old `ChatCapability` adapter
- [x] Implement migration adaptation from old `ChatMessage` / `Tool` to new prompt and tool models
- [x] Add conservative runtime bridge gating and automatic fallback to legacy providers
- [x] Design the OpenAI-family legacy routing matrix for OpenRouter / DeepSeek / Groq / xAI / Phind
- [x] Freeze and implement the initial DeepSeek bridge-safe subset on top of the new chat-completions mainline
- [x] Freeze and implement the initial OpenRouter bridge-safe subset on top of the new chat-completions mainline
- [x] Freeze and implement the initial Groq bridge-safe subset on top of the new chat-completions mainline
- [x] Freeze and implement the initial xAI bridge-safe subset on top of the new chat-completions mainline
- [x] Audit the Phind legacy request and response protocol and freeze the current facade-only fallback policy
- [x] Freeze the provider-owned search request/options and shared-source/result boundary
- [ ] Decide whether Phind should ever gain a dedicated migrated provider path or any bridge-safe subset later
- [x] Design provider-owned typed search option surfaces for OpenRouter and xAI without widening shared OpenAI options
- [x] Implement OpenRouter provider-owned online-model search settings without reviving legacy `searchPrompt` or `maxSearchResults` as stable API
- [x] Implement xAI provider-owned chat live-search options and exact `search_parameters` encoding in `llm_dart_openai`
- [x] Expand xAI compatibility routing for the audited legacy live-search migration inputs after the typed option codecs land
- [ ] Re-audit any broader OpenRouter search mapping and any xAI compatibility expansion beyond the audited live-search subset
- [x] Expand OpenAI bridge coverage for common tools, built-in tools, and structured output
- [x] Expand Anthropic bridge coverage for legacy prompt caching and `MessageBuilder` tools blocks
- [x] Expand Anthropic bridge coverage for lossless legacy raw text `contentBlocks`
- [x] Expand Anthropic bridge coverage for lossless legacy user image and document `contentBlocks`
- [x] Expand Anthropic bridge coverage for lossless raw assistant tool-use and user tool-result replay inside `anthropic.contentBlocks`
- [x] Expand Google bridge coverage for additional modality coverage beyond the text structured-output path
- [x] Add Anthropic tool-search native tools and provider-owned deferred-loading controls for common function tools
- [ ] Decide whether Anthropic should add provider-owned custom tool-reference helpers for user-defined tool-search flows beyond the native tool-search subset
- [x] Design and implement the Anthropic-owned custom prompt/content/UI path for replayable `web_search_tool_result`
- [x] Design and implement the Anthropic-owned custom prompt/content/UI path for replayable `web_fetch_tool_result`
- [x] Design and implement the Anthropic-owned custom prompt/content/UI path for replayable `tool_search_tool_result`
- [x] Decide whether the legacy raw Anthropic compatibility bridge should allow `web_search_tool_result` directly or keep routing it to fallback
- [x] Decide whether the legacy raw Anthropic compatibility bridge should allow `web_fetch_tool_result` directly or keep routing it to fallback
- [x] Decide whether the legacy raw Anthropic compatibility bridge should allow `tool_search_tool_result` directly or keep routing it to fallback
- [x] Write a design note for execution-oriented provider-native result replay before expanding the Anthropic bridge further
- [x] Freeze the canonical payload contract for `anthropic.result.code_execution`
- [x] Decide whether Anthropic code-execution result families need replay support at all before compatibility cleanup
- [x] Add typed `llm_dart_anthropic` helpers for parsing and rendering `anthropic.result.code_execution`
- [x] Decide whether Anthropic file-download handles need a dedicated typed provider-native model before implementation
- [x] Implement Anthropic execution replay through `CustomContentPart` / `CustomEvent` / `CustomUiPart` / `CustomPromptPart`
- [x] Add session replay and request re-encoding tests for Anthropic execution replay
- [x] Implement the provider-native Anthropic files API for execution file handles
- [x] Decide how provider-native tool results that stay bridge-incompatible should surface in migration guidance and deprecation messaging
- [x] Mark old extension entry points as deprecated
- [x] Define the old API removal window

## Testing

- [x] prompt normalization tests
- [x] stream event accumulation tests
- [x] UI message projection tests
- [x] transport reconnection tests
- [x] Expand provider stream-coverage tests for the existing shared event families instead of adding new core event types
- [x] provider profile tests
- [x] compatibility adapter tests
- [x] chat route compatibility tests
- [x] transport SSE decoder tests
- [x] OpenAI text mainline smoke tests

## Documentation And Examples

- [x] Rewrite the README minimal example
- [x] Rewrite the streaming example
- [x] Rewrite the tool-calling example
- [x] Rewrite the reasoning example
- [x] Rewrite the Flutter integration example
- [x] Add a migration guide
- [x] Repoint high-visibility README and core example entrypoints at the stable `AI` facade and provider-owned search APIs
- [x] Add an explicit root `legacy.dart` compatibility shell before further broad-root surface slimming
- [x] Repoint the remaining builder-era and compatibility examples from `llm_dart.dart` to `legacy.dart`
- [x] Decouple `legacy.dart` exports from `llm_dart.dart` before the next broad-root slimming round
- [x] Shrink `llm_dart.dart` to the modern stable surface and move remaining compatibility expectations behind `legacy.dart`
- [x] Freeze the default-root versus explicit-`ai.dart` alias boundary and align public docs with that import guidance
- [x] Align public README and provider example guidance with `llm_dart_community` as the modern Ollama/ElevenLabs shared-capability entrypoint
- [x] Add runnable `llm_dart_community` package examples for the current Ollama and ElevenLabs modern shared-capability surfaces

## Dependency Cleanup

- [x] Remove `dio` from the core public API surface
- [x] Move raw Dio cancellation inspection out of the root `CancellationHelper`
- [x] Move root registry/bootstrap diagnostics off `package:logging`
- [x] Remove or isolate deprecated `HttpConfig.dioClient(Dio)` from the stable builder surface
- [x] Move provider-owned default catalogs and OpenAI-compatible profile catalogs out of `core/` implementation files
- [x] Move Google OpenAI-compatible transformers out of `core/`
- [x] Move Dio-specific error mapping helpers out of `core/` implementation files
- [x] Move legacy `BaseHttpProvider` implementation out of `core/`
- [x] Move `http_parser` out of the root package or remove it
- [x] Move `mcp_dart` under an example or dedicated integration-package strategy
- [x] Remove unused `mockito`

## Provider Feature Representation

- [x] Add payload support to `CustomContentPart`
- [x] Add payload support to `CustomUiPart`
- [x] Define provider metadata namespace rules
- [x] Define custom-part `kind` namespace rules
- [x] Freeze provider-native tool entry placement in provider packages
- [x] Design provider-owned native-tool forcing or selection APIs without widening shared `ToolChoice`
- [ ] Implement Anthropic provider-owned tool-selection options only if a real native-tool forcing use case appears beyond the current shared subset
- [ ] Expose any public Google native-tool selection or forcing API only after the Gemini 3 mixed-tool wire contract is implemented
