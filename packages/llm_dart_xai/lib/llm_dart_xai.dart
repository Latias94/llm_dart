library;

// ===== Stable public API surface =====
//
// Keep exports focused on:
// - provider config + Dio strategy + registry factory
// - provider implementation (capabilities)
// - provider-defined tools and search parameter models
// - Vercel AI-style facade (`createXAI`, `xai`, etc.)
//
// Low-level building blocks (HTTP client, chat mapping, internal response
// models) are intentionally not exported. For repository tests and advanced
// internal use cases, import `package:llm_dart_xai/testing.dart`.
export 'src/config/xai_config.dart';
export 'src/config/search_parameters.dart';
export 'src/http/xai_dio_strategy.dart';
export 'src/provider/xai_provider.dart';
export 'src/factory/xai_provider_factory.dart'
    show XAIProviderFactory, registerXAIProvider;
export 'src/facade/xai_facade.dart'
    show
        XAIProviderSettings,
        XAI,
        XAITools,
        XAIProviderDefinedTools,
        createXAI,
        xai;
