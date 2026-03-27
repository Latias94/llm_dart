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
- [x] Run static analysis for `llm_dart_core` and `llm_dart_transport`
- [x] Run static analysis for `llm_dart_openai`
- [ ] Create the facade compatibility entry
- [ ] Establish the new shared test foundation
- [ ] Establish the new export strategy and `src/` structure

## Core

- [ ] Rewrite the error model
- [ ] Rewrite usage, warning, and provider metadata models
- [x] Define provider model-options and invocation-options marker interfaces
- [x] Strengthen `SourceReference` with an explicit source kind
- [x] Define malformed tool-input semantics in the core stream and UI models
- [ ] Rewrite the tool schema and tool-result model
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
- [ ] Migrate OpenAI chat
- [x] Migrate OpenAI responses
- [ ] Migrate OpenAI embeddings
- [ ] Migrate OpenAI image
- [ ] Migrate OpenAI speech and transcription
- [ ] Turn OpenRouter into a profile
- [ ] Turn DeepSeek OpenAI-compatible into a profile
- [ ] Turn Groq OpenAI-compatible into a profile
- [ ] Turn xAI OpenAI-compatible into a profile
- [ ] Turn Phind OpenAI-compatible into a profile

## Anthropic

- [ ] Migrate the Anthropic language model
- [ ] Migrate the Anthropic tool codec
- [ ] Migrate the Anthropic reasoning codec
- [ ] Migrate the Anthropic web-search adapter
- [ ] Migrate the Anthropic MCP connector
- [ ] Move cache-related structures into provider metadata or custom parts

## Google

- [ ] Migrate the Gemini language model
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
- [ ] Define how UI-only data parts enter `ChatSession` and `HttpChatTransport` without expanding `TextStreamEvent`
- [ ] Implement `ChatController`
- [x] Define a serialized chat chunk protocol for `HttpChatTransport`
- [x] Design the message serialization protocol
- [x] Implement prompt and UI JSON codecs
- [x] Implement `ChatSessionSnapshot` export and import
- [x] Design and implement the baseline tool approval and output injection API
- [ ] Rewrite the Flutter integration examples

## Compatibility Layer

- [ ] Implement adaptation from old `ai()` to the new architecture
- [ ] Implement the old `ChatCapability` adapter
- [ ] Implement migration adaptation from old `ChatMessage` to new `PromptMessage`
- [ ] Mark old extension entry points as deprecated
- [ ] Define the old API removal window

## Testing

- [ ] prompt normalization tests
- [x] stream event accumulation tests
- [x] UI message projection tests
- [x] transport reconnection tests
- [ ] provider profile tests
- [ ] compatibility adapter tests
- [x] transport SSE decoder tests
- [x] OpenAI text mainline smoke tests

## Documentation And Examples

- [ ] Rewrite the README minimal example
- [ ] Rewrite the streaming example
- [ ] Rewrite the tool-calling example
- [ ] Rewrite the reasoning example
- [ ] Rewrite the Flutter integration example
- [ ] Add a migration guide

## Dependency Cleanup

- [ ] Remove `dio` from the core public API surface
- [ ] Move `http_parser` out of the root package or remove it
- [ ] Move `mcp_dart` under an example or dedicated integration-package strategy
- [ ] Remove unused `mockito`

## Provider Feature Representation

- [x] Add payload support to `CustomContentPart`
- [x] Add payload support to `CustomUiPart`
- [x] Define provider metadata namespace rules
- [x] Define custom-part `kind` namespace rules
