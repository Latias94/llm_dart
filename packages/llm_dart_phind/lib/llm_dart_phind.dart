library;

// ===== Stable public API surface =====
//
// Keep exports focused on:
// - provider config + registry factory
// - provider implementation (capabilities)
// - Vercel AI-style facade (`createPhind`, `phind`, etc.)
//
// Low-level building blocks (HTTP client, chat prompt mapping, internal
// response models) are intentionally not exported. For repository tests and
// advanced internal use cases, import `package:llm_dart_phind/testing.dart`.
export 'src/config/phind_config.dart';
export 'src/provider/phind_provider.dart';
export 'src/factory/phind_provider_factory.dart'
    show PhindProviderFactory, registerPhindProvider;

// Vercel AI-style facade exports (model-centric API).
export 'src/facade/phind_facade.dart'
    show PhindProviderSettings, Phind, createPhind, phind;
