library;

// ===== Stable public API surface =====
//
// Keep exports focused on:
// - provider config + registry factory
// - provider implementation (capabilities)
// - public request/response models
// - Vercel AI-style facade (`createElevenLabs`, `elevenlabs`, etc.)
//
// Low-level building blocks (HTTP client, internal capability modules) are
// intentionally not exported. For repository tests and advanced internal use
// cases, import `package:llm_dart_elevenlabs/testing.dart`.
export 'src/config/elevenlabs_config.dart';
export 'src/models/elevenlabs_models.dart';
export 'src/provider/elevenlabs_provider.dart';
export 'src/factory/elevenlabs_provider_factory.dart'
    show ElevenLabsProviderFactory, registerElevenLabsProvider;

// Vercel AI-style facade exports (model-centric API).
export 'src/facade/elevenlabs_facade.dart'
    show ElevenLabsProviderSettings, ElevenLabs, createElevenLabs, elevenlabs;
