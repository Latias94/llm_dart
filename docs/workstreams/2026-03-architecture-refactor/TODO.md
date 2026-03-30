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
- [x] Create `llm_dart_openai` skeleton
- [x] Create `llm_dart_anthropic` skeleton
- [x] Create `llm_dart_google` skeleton
- [x] Create `llm_dart_community` skeleton
- [x] Run static analysis for `llm_dart_core` and `llm_dart_transport`
- [x] Run static analysis for `llm_dart_openai`
- [x] Create the facade compatibility entry
- [ ] Establish the new shared test foundation
- [x] Establish the new export strategy and `src/` structure

## Core

- [ ] Rewrite the error model
- [ ] Rewrite usage, warning, and provider metadata models
- [x] Add common `reasoning-file` support across prompt, result, stream, and UI layers
- [x] Add part-level provider metadata to replayable prompt parts and codecs
- [x] Define provider model-options and invocation-options marker interfaces
- [x] Strengthen `SourceReference` with an explicit source kind
- [x] Define malformed tool-input semantics in the core stream and UI models
- [x] Rewrite the function-tool schema and tool-choice model
- [ ] Freeze provider-native tool declaration APIs and the remaining tool-result orchestration work
- [x] Define unified `CallOptions`
- [x] Define `LanguageModel`
- [x] Define `EmbeddingModel`
- [x] Define `ImageModel`
- [x] Define `SpeechModel`
- [x] Define `TranscriptionModel`
- [x] Implement `generateText`
- [x] Implement `streamText`
- [ ] Implement `embed` / `embedMany`
- [ ] Implement `generateImage`
- [ ] Implement `generateSpeech`
- [ ] Implement `transcribe`

## Transport

- [x] Extract the HTTP request executor
- [x] Extract the SSE decoder
- [ ] Extract the stream chunk parser helper
- [ ] Extract retry, timeout, and cancellation
- [x] Replace public `CancelToken` with a transport cancellation abstraction
- [x] Extract provider-independent error mapping
- [ ] Define the transport diagnostics interface
- [x] Define `HttpChatTransport` request and chunk codecs
- [x] Implement `TextStreamEvent` JSON codec

## OpenAI Family

- [x] Design the OpenAI-family profile structure
- [x] Expose OpenAI-family convenience constructors on the root `AI` facade
- [ ] Complete OpenAI chat migration
- [x] Add the initial OpenAI-family chat-completions mainline
- [x] Migrate OpenAI responses
- [x] Preserve OpenAI replay-critical item metadata, reasoning state, and compaction replay
- [ ] Migrate OpenAI embeddings
- [ ] Migrate OpenAI image
- [ ] Migrate OpenAI speech and transcription
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
- [ ] Migrate the Anthropic tool codec
- [ ] Migrate the Anthropic reasoning codec
- [ ] Migrate the Anthropic web-search adapter
- [ ] Migrate the Anthropic MCP connector
- [ ] Move cache-related structures into provider metadata or custom parts

## Google

- [x] Migrate the Gemini language model
- [x] Add the initial Google native tool entry API
- [x] Preserve Google thought signatures and thought files through prompt replay
- [ ] Migrate the Gemini image model
- [ ] Migrate the Gemini embedding model
- [ ] Migrate Gemini speech and TTS
- [ ] Migrate Gemini safety and modality options

## Community Providers

- [ ] Migrate Ollama
- [ ] Migrate ElevenLabs
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
- [x] Define a serialized chat chunk protocol for `HttpChatTransport`
- [x] Design the message serialization protocol
- [x] Implement prompt and UI JSON codecs
- [x] Implement `ChatSessionSnapshot` export and import
- [x] Design and implement the baseline tool approval and output injection API
- [x] Rewrite the Flutter integration examples

## Compatibility Layer

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
- [ ] Expand Google bridge coverage for additional modality coverage beyond the text structured-output path
- [ ] Expand Anthropic bridge coverage for provider-native result replay beyond `tool_result` / `mcp_tool_result`
- [x] Design and implement the Anthropic-owned custom prompt/content/UI path for replayable `web_search_tool_result`
- [x] Design and implement the Anthropic-owned custom prompt/content/UI path for replayable `web_fetch_tool_result`
- [x] Decide whether the legacy raw Anthropic compatibility bridge should allow `web_search_tool_result` directly or keep routing it to fallback
- [x] Decide whether the legacy raw Anthropic compatibility bridge should allow `web_fetch_tool_result` directly or keep routing it to fallback
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

## Dependency Cleanup

- [x] Remove `dio` from the core public API surface
- [x] Remove or isolate deprecated `HttpConfig.dioClient(Dio)` from the stable builder surface
- [x] Move provider-owned default catalogs and OpenAI-compatible profile catalogs out of `core/` implementation files
- [x] Move Google OpenAI-compatible transformers out of `core/`
- [x] Move Dio-specific error mapping helpers out of `core/` implementation files
- [x] Move legacy `BaseHttpProvider` implementation out of `core/`
- [ ] Move `http_parser` out of the root package or remove it
- [ ] Move `mcp_dart` under an example or dedicated integration-package strategy
- [x] Remove unused `mockito`

## Provider Feature Representation

- [x] Add payload support to `CustomContentPart`
- [x] Add payload support to `CustomUiPart`
- [x] Define provider metadata namespace rules
- [x] Define custom-part `kind` namespace rules
- [x] Freeze provider-native tool entry placement in provider packages
