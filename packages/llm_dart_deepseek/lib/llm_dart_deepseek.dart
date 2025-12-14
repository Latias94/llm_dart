library;

// ===== Stable public API surface =====
//
// Keep exports focused on:
// - provider config + Dio strategy + registry factory
// - provider implementation (capabilities)
// - Vercel AI-style facade (`createDeepSeek`, `deepseek`, etc.)
//
// Low-level building blocks (HTTP client, request builders, internal models)
// are intentionally not exported. For repository tests and advanced internal
// use cases, import `package:llm_dart_deepseek/testing.dart`.
export 'src/config/deepseek_config.dart';
export 'src/provider/deepseek_provider.dart';
export 'src/factory/deepseek_provider_factory.dart'
    show DeepSeekProviderFactory, registerDeepSeekProvider;

// Vercel AI-style facade exports (model-centric API).
export 'src/facade/deepseek_facade.dart'
    show DeepSeekProviderSettings, DeepSeek, createDeepSeek, deepseek;
