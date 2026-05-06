# LLM Dart Examples

Practical examples for the LLM Dart library, organized by learning path and use case.

For modern examples, the default root import is
`package:llm_dart/llm_dart.dart`.

When an example still needs the broad compatibility shell, it should import
`package:llm_dart/legacy.dart` explicitly and be read as
compatibility-oriented material. Builder-oriented examples should still prefer
focused imports such as `builder/llm_builder.dart`, model barrels, and
provider-owned entrypoints when they do not need the whole legacy surface.

For shared chat UI projection, keep `ChatMessageMapper` on
`package:llm_dart/core.dart`. When the UI also needs provider-owned metadata or
custom-part inspection, prefer provider-owned composed helpers such as
`OpenAIMessageMapper().mapComposed(...)` and
`GoogleMessageMapper().mapComposed(...)` instead of stitching two mapper passes
manually.

Recommended default route:

- start in `01_getting_started/` for model-first setup
- spend most new app work in the stable examples under `02_core_features/`
- treat provider directories and older builder examples as explicit appendices
  rather than the default learning path

## Quick Start

| I need to... | Go to |
|--------------|-------|
| **Get started quickly** | [quick_start.dart](01_getting_started/quick_start.dart) |
| **Build a chatbot** | [chatbot.dart](05_use_cases/chatbot.dart) |
| **Compare stable models by provider** | [provider_comparison.dart](01_getting_started/provider_comparison.dart) |
| **Use streaming** | [streaming_chat.dart](02_core_features/streaming_chat.dart) |
| **Gate app UI by capability profiles** | [capability_profile_ui_gating.dart](02_core_features/capability_profile_ui_gating.dart) |
| **Cancel requests** | [cancellation_demo.dart](02_core_features/cancellation_demo.dart) |
| **Call functions** | [tool_calling.dart](02_core_features/tool_calling.dart) |
| **Handle audio** | [audio_processing.dart](02_core_features/audio_processing.dart) |
| **Generate images** | [image_generation.dart](02_core_features/image_generation.dart) |
| **Edit provider images** | [openai/image_generation.dart](04_providers/openai/image_generation.dart) or [google/image_generation.dart](04_providers/google/image_generation.dart) |
| **Process large datasets** | [batch_processor.dart](05_use_cases/batch_processor.dart) |
| **Build multimodal apps** | [multimodal_app.dart](05_use_cases/multimodal_app.dart) |
| **Use the pure chat runtime** | [packages/llm_dart_chat/example/chat_runtime.dart](../packages/llm_dart_chat/example/chat_runtime.dart) |
| **Send backend chat hints** | [packages/llm_dart_chat/example/http_backend_hint_mapping.dart](../packages/llm_dart_chat/example/http_backend_hint_mapping.dart) |
| **Use Flutter + backend hints** | [packages/llm_dart_flutter/example/flutter_http_backend_integration.dart](../packages/llm_dart_flutter/example/flutter_http_backend_integration.dart) |
| **Run a Flutter Material chat demo** | [packages/llm_dart_flutter/example/flutter_material_chat_demo.dart](../packages/llm_dart_flutter/example/flutter_material_chat_demo.dart) |
| **Gate Flutter controls by model capabilities** | [packages/llm_dart_flutter/example/flutter_capability_gated_controls.dart](../packages/llm_dart_flutter/example/flutter_capability_gated_controls.dart) |
| **Recover HTTP chat after disconnect** | [packages/llm_dart_flutter/example/flutter_http_reconnect_demo.dart](../packages/llm_dart_flutter/example/flutter_http_reconnect_demo.dart) |
| **Handle tool approvals in Flutter** | [packages/llm_dart_flutter/example/flutter_tool_approval_demo.dart](../packages/llm_dart_flutter/example/flutter_tool_approval_demo.dart) |
| **Connect external tools** | [mcp_concept_demo.dart](06_mcp_integration/mcp_concept_demo.dart) |

## Directory Structure

Read these directories from top to bottom if you are new to the repository:
`01_getting_started` and most of `02_core_features` are the default path;
provider directories are explicit boundary appendices.

### Getting Started
*First-time users*

- [quick_start.dart](01_getting_started/quick_start.dart) - Basic usage
- [provider_comparison.dart](01_getting_started/provider_comparison.dart) - Compare providers
- [basic_configuration.dart](01_getting_started/basic_configuration.dart) - Configuration
- [environment_setup.dart](01_getting_started/environment_setup.dart) - Environment setup

### Core Features
*Essential functionality*

- [capability_factory_methods.dart](02_core_features/capability_factory_methods.dart) - Compatibility-oriented typed `build*()` helpers through focused builder imports
- [chat_basics.dart](02_core_features/chat_basics.dart) - Basic chat
- [streaming_chat.dart](02_core_features/streaming_chat.dart) - Real-time streaming
- [capability_profile_ui_gating.dart](02_core_features/capability_profile_ui_gating.dart) - Model-centric UI affordance and fallback gating
- [cancellation_demo.dart](02_core_features/cancellation_demo.dart) - Request cancellation
- [tool_calling.dart](02_core_features/tool_calling.dart) - Function calling
- [embeddings_stable.dart](02_core_features/embeddings_stable.dart) - Stable shared embedding helpers
- [enhanced_tool_calling.dart](02_core_features/enhanced_tool_calling.dart) - Stable advanced tool replay and provider-owned controls
- [structured_output.dart](02_core_features/structured_output.dart) - Shared structured output
- [provider_specific_builders.dart](02_core_features/provider_specific_builders.dart) - Compatibility-oriented provider callback builders through focused builder imports
- [assistants.dart](02_core_features/assistants.dart) - Stable assistant-like chat plus the explicit OpenAI compatibility boundary
- [embeddings.dart](02_core_features/embeddings.dart) - Stable multi-provider embeddings
- [audio_processing.dart](02_core_features/audio_processing.dart) - Stable speech and transcription helpers
- [image_generation.dart](02_core_features/image_generation.dart) - Stable multi-provider image generation
- [file_management.dart](02_core_features/file_management.dart) - Stable local file prompts plus provider-owned remote file lifecycle boundaries
- [web_search.dart](02_core_features/web_search.dart) - Web search integration
- [content_moderation.dart](02_core_features/content_moderation.dart) - Provider-owned moderation signals mapped into app policy through the focused OpenAI moderation client
- [model_listing.dart](02_core_features/model_listing.dart) - Stable capability profiles plus provider-owned remote catalog discovery
- [message_builder_cache.dart](02_core_features/message_builder_cache.dart) - Anthropic-specific prompt caching appendix with narrow typed imports
- [capability_detection.dart](02_core_features/capability_detection.dart) - Feature detection
- [error_handling.dart](02_core_features/error_handling.dart) - Stable `ModelError` normalization and resilience patterns

### Advanced Features
*Specialized capabilities*

- [reasoning_models.dart](03_advanced_features/reasoning_models.dart) - AI thinking processes
- [multi_modal.dart](03_advanced_features/multi_modal.dart) - Stable multimodal prompts plus shared image, audio, and file helpers
- [batch_processing.dart](03_advanced_features/batch_processing.dart) - Stable app-owned batch orchestration with concurrency, retry, and progress tracking
- [realtime_audio.dart](03_advanced_features/realtime_audio.dart) - Provider-owned ElevenLabs realtime appendix plus app-owned session/event orchestration
- [semantic_search.dart](03_advanced_features/semantic_search.dart) - Stable semantic retrieval engine built on shared embedding models
- [custom_providers.dart](03_advanced_features/custom_providers.dart) - Stable custom `LanguageModel` implementations and wrapper composition
- [performance_optimization.dart](03_advanced_features/performance_optimization.dart) - Stable app-owned caching, streaming, batching, and memory patterns
- [http_configuration.dart](03_advanced_features/http_configuration.dart) - Stable transport recipes for proxy, SSL, custom headers, and logging
- [layered_http_config.dart](03_advanced_features/layered_http_config.dart) - Stable layered transport presets plus custom Dio injection patterns
- [timeout_configuration.dart](03_advanced_features/timeout_configuration.dart) - Stable timeout layering with transport defaults and per-call overrides

### Provider Examples
*Provider-specific features*

Most provider directories now follow one of two roles:

- stable model examples for providers that already have a root `AI.*(...)` facade
- compatibility or provider-specific residual examples for broader legacy shells

Ollama and ElevenLabs now also have modern shared-capability surfaces in the
workspace `llm_dart_community` package. The directories below focus on the
remaining provider-specific or compatibility-oriented flows rather than the
shared-capability happy path.

| Provider | Features | Directory |
|----------|----------|-----------|
| OpenAI | Stable chat/image/audio plus files, moderation, and image-editing helpers | [openai/](04_providers/openai/) |
| Anthropic | Claude chat, extended thinking, MCP, and files | [anthropic/](04_providers/anthropic/) |
| DeepSeek / OpenRouter / custom OpenAI-family | Stable profile flows plus explicit compatible endpoint wiring | [others/](04_providers/others/) |
| Groq | Fast inference | [groq/](04_providers/groq/) |
| Google | Gemini/Imagen images, embeddings, speech, and image editing/variation | [google/](04_providers/google/) |
| Ollama | Modern community-surface local runtime tuning with provider-owned options | [ollama/](04_providers/ollama/) |
| ElevenLabs | Stable shared speech/transcription plus provider-owned voice and realtime appendices | [elevenlabs/](04_providers/elevenlabs/) |
| xAI | Live search, Grok | [xai/](04_providers/xai/) |

### Use Cases
*Complete applications*

- [chatbot.dart](05_use_cases/chatbot.dart) - Interactive chatbot with personality
- [cli_tool.dart](05_use_cases/cli_tool.dart) - Command-line AI assistant
- [web_service.dart](05_use_cases/web_service.dart) - HTTP API with authentication
- [packages/llm_dart_chat/example/chat_runtime.dart](../packages/llm_dart_chat/example/chat_runtime.dart) - Framework-neutral session runtime patterns
- [packages/llm_dart_chat/example/http_backend_hint_mapping.dart](../packages/llm_dart_chat/example/http_backend_hint_mapping.dart) - HTTP chat transport metadata-to-backend-options pattern
- [packages/llm_dart_flutter/example/flutter_integration.dart](../packages/llm_dart_flutter/example/flutter_integration.dart) - Flutter app patterns
- [packages/llm_dart_flutter/example/flutter_http_backend_integration.dart](../packages/llm_dart_flutter/example/flutter_http_backend_integration.dart) - Flutter `ChatController` + backend-owned provider routing pattern
- [packages/llm_dart_flutter/example/flutter_material_chat_demo.dart](../packages/llm_dart_flutter/example/flutter_material_chat_demo.dart) - Minimal Flutter Material chat screen using backend-owned provider routing
- [packages/llm_dart_flutter/example/flutter_capability_gated_controls.dart](../packages/llm_dart_flutter/example/flutter_capability_gated_controls.dart) - Flutter Material control gating from shared capability profiles plus provider-native badges
- [packages/llm_dart_flutter/example/flutter_http_reconnect_demo.dart](../packages/llm_dart_flutter/example/flutter_http_reconnect_demo.dart) - Flutter Material chat screen for `HttpChatTransport` error recovery through `resume()`
- [packages/llm_dart_flutter/example/flutter_tool_approval_demo.dart](../packages/llm_dart_flutter/example/flutter_tool_approval_demo.dart) - Flutter Material chat screen for manual provider approval, local tool execution, and paused-state snapshot restore
- [batch_processor.dart](05_use_cases/batch_processor.dart) - Large-scale data processing
- [multimodal_app.dart](05_use_cases/multimodal_app.dart) - Text, image, and audio processing

Capability-profile demos now also include the modern `llm_dart_community`
surface. Treat current ElevenLabs capability answers as stronger hosted-API
descriptors, while reading Ollama vision/reasoning affordances as model-family
inference that still needs real request-path validation.

### MCP Integration
*External tool connections*

Run these examples from the standalone package in `example/06_mcp_integration`.

- [mcp_concept_demo.dart](06_mcp_integration/mcp_concept_demo.dart) - Core concepts
- [simple_mcp_demo.dart](06_mcp_integration/simple_mcp_demo.dart) - Basic integration
- [basic_mcp_client.dart](06_mcp_integration/basic_mcp_client.dart) - MCP client
- [custom_mcp_server_stdio.dart](06_mcp_integration/custom_mcp_server_stdio.dart) - Custom server
- [mcp_tool_bridge.dart](06_mcp_integration/mcp_tool_bridge.dart) - Tool bridging
- [mcp_with_llm.dart](06_mcp_integration/mcp_with_llm.dart) - LLM integration
- [test_all_examples.dart](06_mcp_integration/test_all_examples.dart) - Test runner

## Setup

Set API keys for the providers you want to use:

```bash
export OPENAI_API_KEY="your-key"
export ANTHROPIC_API_KEY="your-key"
export GROQ_API_KEY="your-key"
export DEEPSEEK_API_KEY="your-key"
```

Run examples:

```bash
dart run 01_getting_started/quick_start.dart
dart run 02_core_features/chat_basics.dart
dart run 02_core_features/capability_profile_ui_gating.dart
dart run 05_use_cases/chatbot.dart
dart run ../packages/llm_dart_chat/example/chat_runtime.dart
dart run ../packages/llm_dart_chat/example/http_backend_hint_mapping.dart
flutter run ../packages/llm_dart_flutter/example/flutter_material_chat_demo.dart
flutter run ../packages/llm_dart_flutter/example/flutter_capability_gated_controls.dart
dart run 05_use_cases/batch_processor.dart --help
dart run 05_use_cases/multimodal_app.dart --demo
```

## Learning Path

**Beginner**: Start with `quick_start.dart` → `provider_comparison.dart` → `chat_basics.dart`

**Intermediate**: Focus on `tool_calling.dart` → `structured_output.dart` → `error_handling.dart` → `capability_profile_ui_gating.dart`

**Advanced**: Study `chat_runtime.dart` → `http_backend_hint_mapping.dart` → `batch_processor.dart` → `custom_providers.dart`

**Production**: Explore `performance_optimization.dart` → `flutter_material_chat_demo.dart` → `flutter_http_backend_integration.dart` → provider-owned appendices or MCP integration only when product requirements justify them

## Production Example

[Yumcha](https://github.com/Latias94/yumcha) - A production Flutter app built with LLM Dart, showcasing real-world integration patterns and best practices.

## Resources

- [Main Documentation](../README.md)
- [Community Provider Workspace Guide](../packages/llm_dart_community/README.md)
- [API Reference](https://pub.dev/documentation/llm_dart/)
- [GitHub Issues](https://github.com/your-repo/llm_dart/issues)
