library;

// ===== Stable public API surface =====
//
// Keep exports focused on:
// - provider config + Dio strategy + registry factory
// - provider implementation (capabilities)
// - MCP connector models
// - Vercel AI-style facade (`createAnthropic`, `anthropic`, etc.)
// - Provider-specific response types when they surface extra features
//
// Low-level building blocks (HTTP client, request builders, internal models)
// are intentionally not exported. For repository tests and advanced internal
// use cases, import `package:llm_dart_anthropic/testing.dart`.
export 'src/config/anthropic_config.dart';
export 'src/provider/anthropic_provider.dart';
export 'src/mcp/anthropic_mcp_models.dart';
export 'src/http/anthropic_dio_strategy.dart';
export 'src/chat/anthropic_chat.dart' show AnthropicChatResponse;
export 'src/models/anthropic_models.dart'
    show
        AnthropicCacheTtl,
        AnthropicMessageBuilder,
        AnthropicMessageBuilderExtension;
export 'src/factory/anthropic_provider_factory.dart'
    show AnthropicProviderFactory, registerAnthropicProvider;

// Vercel AI-style facade exports (model-centric API).
export 'src/facade/anthropic_facade.dart'
    show
        AnthropicProviderSettings,
        Anthropic,
        AnthropicTools,
        createAnthropic,
        anthropic;
