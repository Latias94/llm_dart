# Stable Boundary Migration Matrix

## Goal

Map common product and app-facing tasks to the smallest honest public boundary:

1. stable shared model path
2. stable shared call path plus provider-owned options
3. provider-owned helper in a focused package
4. explicit compatibility appendix

This keeps the repository aligned with the useful architectural lesson from
`repo-ref/ai` without copying its package granularity mechanically.

## Default Boundary Order

When a feature request arrives, choose the first boundary below that fits the
real product need:

1. shared model + shared helper
2. shared model + provider-owned typed settings or invocation options
3. focused provider package helper or chat/flutter package helper
4. compatibility/provider appendix for residual lifecycle or management APIs

Do not jump straight to compatibility APIs just because a provider exposes a
broader management surface.

## A. Stable Shared Default For New App Code

| Product need | Default path | Main imports | Current examples | Why this is the default |
| --- | --- | --- | --- | --- |
| Basic text generation | `AI.*(...).chatModel(...)` + `generateTextCall(...)` | `package:llm_dart/llm_dart.dart`, `package:llm_dart/core.dart` | `example/01_getting_started/quick_start.dart`, `example/02_core_features/chat_basics.dart` | Shared prompt/result contract is already honest and mature |
| Streaming text UX | `streamTextCall(...)` | `llm_dart`, `core.dart` | `example/02_core_features/streaming_chat.dart` | Shared `TextStreamEvent` is the correct stable stream boundary |
| Structured output | `generateTextCall(...)` or `streamTextCall(...)` with `OutputSpec` | `core.dart` | `example/02_core_features/structured_output.dart` | Output shaping is shared model behavior, not provider-local management API |
| Shared tool calling | `FunctionToolDefinition`, replay parts, shared tool events | `core.dart` | `example/02_core_features/tool_calling.dart`, `example/02_core_features/enhanced_tool_calling.dart` | Common tool declaration and replay are already stable cross-provider semantics |
| Error normalization and retries | `ModelError` plus app-owned retry/fallback policy | `core.dart`, `transport.dart` | `example/01_getting_started/basic_configuration.dart`, `example/02_core_features/error_handling.dart` | Shared error normalization is already the honest boundary |
| Capability-gated app or Flutter UI | concrete model `capabilityProfile` or provider describers | `core.dart`, focused provider packages, `llm_dart_community` | `example/02_core_features/capability_profile_ui_gating.dart`, `packages/llm_dart_flutter/example/flutter_capability_gated_controls.dart` | Capability checks are model-centric, not provider-registry-centric |
| Embeddings | `embeddingModel(...)` + `embed(...)` / `embedMany(...)` | `llm_dart`, `core.dart` | `example/02_core_features/embeddings_stable.dart`, `example/02_core_features/embeddings.dart` | Shared embedding contract is already stable |
| Prompt-based image generation | `imageModel(...)` + `generateImage(...)` | `llm_dart`, `core.dart` | `example/02_core_features/image_generation.dart` | Shared image generation shape is already stable |
| Speech generation | `speechModel(...)` + `generateSpeech(...)` | `llm_dart`, `core.dart` | `example/02_core_features/audio_processing.dart` | One-shot speech generation already fits a stable shared contract |
| Transcription | `transcriptionModel(...)` + `transcribe(...)` | `llm_dart`, `core.dart` | `example/02_core_features/audio_processing.dart` | Byte-oriented transcription already has a truthful shared contract |
| Local prompt attachments | `FilePromptPart` | `core.dart` | `example/02_core_features/file_management.dart` | Local prompt attachments should stay app-owned by default |
| Pure Dart chat runtime | `DefaultChatSession` + `DirectChatTransport` or `HttpChatTransport` | `package:llm_dart/chat.dart` or `llm_dart_chat` | `packages/llm_dart_chat/example/chat_runtime.dart`, `packages/llm_dart_chat/example/http_backend_hint_mapping.dart` | Session/runtime orchestration belongs in `llm_dart_chat`, not provider packages |
| Flutter chat control | `ChatController` above `llm_dart_chat` | `llm_dart_flutter` | `packages/llm_dart_flutter/example/flutter_material_chat_demo.dart`, `packages/llm_dart_flutter/example/flutter_http_backend_integration.dart` | Flutter control ownership belongs in `llm_dart_flutter`, not the root model layer |
| Shared chat UI summaries | `ChatMessageMapper` | `core.dart` | root README and package README guidance | Shared text/reasoning/tool/source/file summaries are already stable UI semantics |

## B. Shared Stable Call Path Plus Provider-Owned Options

Use the shared model and shared helper first, then branch into provider-owned
typed settings or invocation options only for provider-native value.

| Product need | Recommended path | Main imports | Current examples | Why this stays provider-owned |
| --- | --- | --- | --- | --- |
| OpenAI built-in tools, verbosity, reasoning effort, logprobs, system-message routing | `AI.openai(...).chatModel(...)` plus `OpenAIChatModelSettings` / `OpenAIGenerateTextOptions` | `package:llm_dart/openai.dart` | `example/04_providers/openai/gpt5_features.dart`, `example/04_providers/openai/advanced_features.dart`, `example/02_core_features/web_search.dart` | These are OpenAI-family request-shaping and hosted-tool details, not shared text-generation contract |
| Anthropic extended thinking, MCP servers, and native-tool controls | `AI.anthropic(...).chatModel(...)` plus `AnthropicGenerateTextOptions` | `package:llm_dart/anthropic.dart` | `example/04_providers/anthropic/extended_thinking.dart`, `example/04_providers/anthropic/mcp_connector.dart` | Thinking and MCP server declarations are provider-native controls |
| Google image and speech knobs | `AI.google(...).*Model(...)` plus `GoogleImageOptions` / `GoogleSpeechOptions` | `package:llm_dart/google.dart` | `example/04_providers/google/image_generation.dart`, `example/04_providers/google/google_tts_example.dart` | Aspect ratio, safety, multi-speaker routing, and sampling stay Google-owned |
| OpenRouter online-model search or xAI live search | shared text call plus `OpenRouter...` or `XAI...` provider options/settings | `package:llm_dart/openai.dart` | `example/04_providers/others/openai_compatible.dart`, `example/04_providers/xai/README.md`, `example/02_core_features/web_search.dart` | Search semantics remain provider-owned even on the OpenAI-family transport boundary |
| Ollama local runtime tuning | `community.Ollama(...).chatModel(...)` plus `OllamaGenerateTextOptions` | `package:llm_dart_community/llm_dart_community.dart` | `example/04_providers/ollama/advanced_features.dart`, `example/04_providers/ollama/thinking_example.dart` | Local runtime control is a provider-native tuning layer above the shared language-model contract |
| ElevenLabs synthesis/transcription controls | `community.ElevenLabs(...).*Model(...)` plus `ElevenLabsSpeechOptions` / `ElevenLabsTranscriptionOptions` | `llm_dart_community` | `packages/llm_dart_community/example/elevenlabs_speech.dart`, `packages/llm_dart_community/example/elevenlabs_transcription.dart` | Voice defaults, latency, and pronunciation controls are provider-native media knobs |

## C. Focused Provider-Owned Helper Boundary

Use a focused provider package helper when the behavior is real product value
but does not belong in the shared cross-provider contract.

| Product need | Recommended path | Main imports | Current status | Why it should stay provider-owned |
| --- | --- | --- | --- | --- |
| Provider-aware UI mapping for OpenAI metadata and custom parts | `OpenAIMessageMapper().mapComposed(...)` | `package:llm_dart/openai.dart` or `llm_dart_openai` | Landed | Provider message metadata must not widen `ChatMessageMapper` |
| Provider-aware UI mapping for Google thought signatures and custom parts | `GoogleMessageMapper().mapComposed(...)` | `package:llm_dart/google.dart` or `llm_dart_google` | Landed | Google-specific UI metadata should remain package-owned |
| Anthropic file lifecycle | `AI.anthropic(...).files()` | `package:llm_dart/anthropic.dart` | Landed | Upload, list, metadata, download, and delete stay Anthropic-owned without inventing shared file lifecycle semantics |
| OpenAI remote file lifecycle | `AI.openai(...).files()` or `OpenAI(...).files()` | `package:llm_dart/openai.dart` or `llm_dart_openai` | Landed | Remote persistence, purpose fields, and content download are OpenAI-owned and should not widen shared file contracts |
| OpenAI moderation endpoint | `AI.openai(...).moderation()` or `OpenAI(...).moderation()` | `package:llm_dart/openai.dart` or `llm_dart_openai` | Landed | Moderation taxonomy and score semantics stay OpenAI-owned while app policy remains application-owned |
| Ollama installed-model catalog | `community.Ollama(...).catalog().listModels()` | `llm_dart_community` | Landed | Local runtime tags and installed-model metadata are provider-owned and should not become a shared model registry |
| ElevenLabs voice catalog | `community.ElevenLabs(...).voices().listVoices()` | `llm_dart_community` | Landed | Voice IDs, labels, preview URLs, and tier availability are provider-owned voice-picker data |
| OpenAI image editing | `OpenAIImageModel.edit(OpenAIImageEditRequest)` | `llm_dart_openai` or `package:llm_dart/openai.dart` | Landed | Edit inputs are provider-native and should not widen the shared image contract |
| Google image editing and variation | `GoogleImageModel.edit(...)` / `createVariation(...)` | `llm_dart_google` or `package:llm_dart/google.dart` | Landed | This is an additive Google-owned helper above the shared image generation path |
| Modern community-provider models | `community.Ollama(...).*Model(...)`, `community.ElevenLabs(...).*Model(...)` | `llm_dart_community` | Landed | Community providers should stay in `llm_dart_community`, not as broad root compatibility shells |

### Important note

High-visibility provider READMEs and image examples now teach the landed
OpenAI and Google provider-owned image-editing helpers directly. Keep future
edits aligned with this boundary: shared `generateImage(...)` remains prompt
generation, while file-based edit and variation shapes stay provider-owned.

## D. Explicit Compatibility Appendix Or Residual Boundary

Use these surfaces only when the product requirement genuinely needs them.
They are not the default path for new app-facing code.

| Product need | Current path | Why it stays outside the stable default |
| --- | --- | --- |
| OpenAI assistants lifecycle | `package:llm_dart/providers/openai/openai.dart` | Stored assistants, threads, tool resources, and lifecycle IDs remain OpenAI-specific management APIs |
| OpenAI raw Responses CRUD or lifecycle objects | focused OpenAI compatibility surface | Response IDs, raw response objects, and CRUD lifecycle are still provider-native appendix behavior |
| Remote model catalogs and model listing | compatibility or provider-owned catalog surfaces | Remote catalogs are not a truthful shared app contract because metadata and filters differ heavily by provider |
| Google streamed PCM TTS and voice discovery | Google compatibility appendix | One-shot speech is already stable; deeper streaming and discovery remain provider-native appendix behavior |
| Ollama `/api/generate` completion | Ollama compatibility shell | It is not the modern shared chat contract and would only reopen an avoidable second local text path |
| ElevenLabs realtime/session APIs, cloning, and admin endpoints | ElevenLabs compatibility shell | These are provider-owned media management or realtime APIs, not shared speech/transcription semantics |
| Legacy builder, broad root factories, and older builder helpers | `package:llm_dart/legacy.dart` and compatibility shells | Deliberate migration rail, not the target architecture for new code |

## Default Flutter / Chat-App Choices

For new Flutter chat products, the recommended order is:

1. Pick a concrete model and inspect its `capabilityProfile`.
2. Keep message history, attachments, retries, and UI state app-owned.
3. Use `ChatController` only above `llm_dart_chat` session/runtime ownership.
4. Prefer `HttpChatTransport` when provider routing, approvals, audit, or keys
   should stay backend-owned.
5. Add provider-owned options or provider mappers only when a product feature
   truly needs provider-native behavior.
6. Use focused provider helpers such as OpenAI moderation before broad
   compatibility appendices when a narrow modern client exists.
7. Cross into compatibility appendices only for explicit lifecycle or
   management APIs such as assistants, remote file stores, model catalogs,
   realtime/session APIs, or provider-specific moderation surfaces that still
   have no narrow modern package helper.

## What Should Not Be Unified Right Now

- assistants lifecycle
- remote file-management lifecycles
- moderation taxonomy
- remote model listing
- realtime audio/session protocols
- provider admin/account management

Those may deserve provider-owned helpers later, but they still do not justify a
new shared abstraction today.
