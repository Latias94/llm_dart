# LLM Dart Examples

Practical examples for the LLM Dart library, organized by learning path and use case.

## Quick Start

| I need to... | Go to |
|--------------|-------|
| **Get started quickly** | [quick_start.dart](01_getting_started/quick_start.dart) |
| **Build a chatbot** | [chatbot.dart](05_use_cases/chatbot.dart) |
| **Compare providers** | [provider_comparison.dart](01_getting_started/provider_comparison.dart) |
| **Use streaming** | [streaming_chat.dart](02_core_features/streaming_chat.dart) |
| **Cancel requests** | [cancellation_demo.dart](02_core_features/cancellation_demo.dart) |
| **Call functions** | [tool_calling.dart](02_core_features/tool_calling.dart) |
| **Handle audio** | [audio_processing.dart](02_core_features/audio_processing.dart) |
| **Generate images** | [image_generation.dart](02_core_features/image_generation.dart) |
| **Process large datasets** | [batch_processor.dart](05_use_cases/batch_processor.dart) |
| **Build multimodal apps** | [multimodal_app.dart](05_use_cases/multimodal_app.dart) |
| **Connect external tools** | [MCP examples (repo)](https://github.com/Latias94/llm_dart/tree/main/examples/06_mcp_integration) |

## Directory Structure

### Getting Started
*First-time users*

- [quick_start.dart](01_getting_started/quick_start.dart) - Basic usage
- [provider_comparison.dart](01_getting_started/provider_comparison.dart) - Compare providers
- [basic_configuration.dart](01_getting_started/basic_configuration.dart) - Configuration
- [environment_setup.dart](01_getting_started/environment_setup.dart) - Environment setup

### Core Features
*Essential functionality*

- [capability_factory_methods.dart](02_core_features/capability_factory_methods.dart) - Type-safe provider initialization
- [chat_basics.dart](02_core_features/chat_basics.dart) - Basic chat
- [streaming_chat.dart](02_core_features/streaming_chat.dart) - Real-time streaming
- [cancellation_demo.dart](02_core_features/cancellation_demo.dart) - Request cancellation
- [tool_calling.dart](02_core_features/tool_calling.dart) - Function calling
- [enhanced_tool_calling.dart](02_core_features/enhanced_tool_calling.dart) - Advanced tool usage
- [structured_output.dart](02_core_features/structured_output.dart) - JSON output
- [assistants.dart](02_core_features/assistants.dart) - AI assistants
- [embeddings.dart](02_core_features/embeddings.dart) - Text embeddings
- [audio_processing.dart](02_core_features/audio_processing.dart) - Speech/TTS
- [image_generation.dart](02_core_features/image_generation.dart) - Image generation
- [file_management.dart](02_core_features/file_management.dart) - File operations
- [web_search.dart](02_core_features/web_search.dart) - Web search integration
- [content_moderation.dart](02_core_features/content_moderation.dart) - Content filtering
- [model_listing.dart](02_core_features/model_listing.dart) - Available models
- [capability_detection.dart](02_core_features/capability_detection.dart) - Feature detection
- [error_handling.dart](02_core_features/error_handling.dart) - Error handling

### Advanced Features
*Specialized capabilities*

- [reasoning_models.dart](03_advanced_features/reasoning_models.dart) - AI thinking processes
- [multi_modal.dart](03_advanced_features/multi_modal.dart) - Images/audio processing
- [batch_processing.dart](03_advanced_features/batch_processing.dart) - Concurrent processing
- [realtime_audio.dart](03_advanced_features/realtime_audio.dart) - Real-time audio
- [semantic_search.dart](03_advanced_features/semantic_search.dart) - Vector search
- [custom_providers.dart](03_advanced_features/custom_providers.dart) - Custom providers
- [performance_optimization.dart](03_advanced_features/performance_optimization.dart) - Optimization

### Provider Examples
*Provider-specific features*

| Provider | Features | Directory |
|----------|----------|-----------|
| OpenAI | GPT, DALL-E, assistants | [openai/](04_providers/openai/) |
| Anthropic | Claude, thinking | [anthropic/](04_providers/anthropic/) |
| DeepSeek | Reasoning, cost-effective | [deepseek/](04_providers/deepseek/) |
| Groq | Fast inference | [groq/](04_providers/groq/) |
| Ollama | Local models | [ollama/](04_providers/ollama/) |
| ElevenLabs | Voice synthesis | [elevenlabs/](04_providers/elevenlabs/) |
| xAI | Live search, Grok | [xai/](04_providers/xai/) |
| Others | OpenAI-compatible | [others/](04_providers/others/) |

### Use Cases
*Complete applications*

- [chatbot.dart](05_use_cases/chatbot.dart) - Interactive chatbot with personality
- [cli_tool.dart](05_use_cases/cli_tool.dart) - Command-line AI assistant
- [web_service.dart](05_use_cases/web_service.dart) - HTTP API with authentication
- [flutter_integration.dart](05_use_cases/flutter_integration.dart) - Flutter app patterns
- [batch_processor.dart](05_use_cases/batch_processor.dart) - Large-scale data processing
- [multimodal_app.dart](05_use_cases/multimodal_app.dart) - Text, image, and audio processing

### MCP Integration
*External tool connections*

MCP examples are maintained in the repository (not shipped in the published package):
https://github.com/Latias94/llm_dart/tree/main/examples/06_mcp_integration

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
dart run 05_use_cases/chatbot.dart
dart run 05_use_cases/batch_processor.dart --help
dart run 05_use_cases/multimodal_app.dart --demo
```

## Prompt Patterns in Examples

- For new code, prefer prompt‑first modeling with `ChatPromptBuilder` + `ModelMessage`.
- Multi‑modal or complex prompts (especially in provider‑specific examples such as Gemini audio/video) use:
  - `ChatPromptBuilder` to build a structured `ModelMessage` with multiple parts.
  - Model‑centric helpers such as `generateTextWithModel(model, promptMessages: [...])` to send them through the unified API.
- Low-level examples use `ChatCapability` directly with `ModelMessage` inputs, but the recommended default is the `LanguageModel` helpers.

This mirrors the internal content model (`ModelMessage` + `ChatContentPart`) and keeps advanced examples consistent across providers.

## Learning Path

**Beginner**: Start with `quick_start.dart` → `provider_comparison.dart` → `chat_basics.dart`

**Intermediate**: Focus on `tool_calling.dart` → `structured_output.dart` → `chatbot.dart`

**Advanced**: Study `batch_processor.dart` → `multimodal_app.dart` → `custom_providers.dart`

**Production**: Explore `performance_optimization.dart` → provider-specific features → MCP integration (repo examples)

## Production Example

[Yumcha](https://github.com/Latias94/yumcha) - A production Flutter app built with LLM Dart, showcasing real-world integration patterns and best practices.

## Resources

- [Main Documentation](../README.md)
- [API Reference](https://pub.dev/documentation/llm_dart/)
- [GitHub Issues](https://github.com/Latias94/llm_dart/issues)
