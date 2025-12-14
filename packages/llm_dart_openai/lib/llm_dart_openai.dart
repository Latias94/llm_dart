/// OpenAI provider package for llm_dart
///
/// This package contains the OpenAI-specific configuration, client,
/// and provider implementation that build on top of the core
/// abstractions defined in `llm_dart_core`.
library;

// ===== Stable public API surface =====
//
// Keep exports focused on:
// - provider config + registry factory
// - provider implementation (capabilities)
// - Vercel AI-style facade (`createOpenAI`, `openai`, etc.)
// - Responses built-in tools + Responses capability interface
//
// Low-level building blocks (HTTP client, request builders, internal models)
// are intentionally not exported. For repository tests and advanced internal
// use cases, import `package:llm_dart_openai/testing.dart`.
export 'src/config/openai_config.dart';
export 'src/config/openai_config_keys.dart';
export 'src/tools/openai_builtin_tools.dart';
export 'src/provider/openai_provider.dart';
export 'src/responses/openai_responses_capability.dart';
export 'src/factory/openai_provider_factory.dart'
    show OpenAIProviderFactory, registerOpenAIProvider;

// Vercel AI-style facade exports (model-centric API).
export 'src/facade/openai_facade.dart'
    show
        OpenAIProviderSettings,
        OpenAI,
        OpenAIResponsesModel,
        OpenAITools,
        OpenAIProviderDefinedTools,
        createOpenAI,
        openai;
