library;

// ===== Stable public API surface =====
//
// Keep exports focused on:
// - provider config + Dio strategy + registry factory
// - provider implementation (capabilities)
// - high-level admin helper
// - Vercel AI-style facade (`createOllama`, etc.)
//
// Low-level building blocks (HTTP client, chat/completion modules, internal
// models) are intentionally not exported. For repository tests and advanced
// internal use cases, import `package:llm_dart_ollama/testing.dart`.
export 'src/config/ollama_config.dart';
export 'src/http/ollama_dio_strategy.dart';
export 'src/admin/ollama_admin.dart';
export 'src/provider/ollama_provider.dart';
export 'src/factory/ollama_provider_factory.dart'
    show OllamaProviderFactory, registerOllamaProvider;

// Vercel AI-style facade exports (model-centric API).
export 'src/facade/ollama_facade.dart'
    show OllamaProviderSettings, Ollama, createOllama;
