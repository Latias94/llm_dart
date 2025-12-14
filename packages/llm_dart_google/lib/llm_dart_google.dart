library;

// ===== Stable public API surface =====
//
// Keep exports focused on:
// - provider config + Dio strategy + registry factory
// - provider implementation (capabilities)
// - provider-specific high-level helper types (TTS + Files API helpers)
// - Vercel AI-style facade (`createGoogleGenerativeAI`, `google`, etc.)
//
// Low-level building blocks (HTTP client, chat request builders, internal
// capability modules) are intentionally not exported. For repository tests and
// advanced internal use cases, import `package:llm_dart_google/testing.dart`.
export 'src/config/google_config.dart';
export 'src/provider/google_provider.dart';
export 'src/http/google_dio_strategy.dart';
export 'src/tts/google_tts.dart'
    show
        GoogleTTSCapability,
        GoogleTTSRequest,
        GoogleTTSResponse,
        GoogleTTSStreamEvent,
        GoogleTTSAudioDataEvent,
        GoogleTTSMetadataEvent,
        GoogleTTSCompletionEvent,
        GoogleTTSErrorEvent,
        GoogleVoiceInfo,
        GoogleVoiceConfig,
        GooglePrebuiltVoiceConfig,
        GoogleMultiSpeakerVoiceConfig,
        GoogleSpeakerVoiceConfig;
export 'src/files/google_files.dart' show GoogleFile, GoogleFilesClient;
export 'src/factory/google_provider_factory.dart'
    show GoogleProviderFactory, registerGoogleProvider;

// Vercel AI-style facade exports (model-centric API).
export 'src/facade/google_facade.dart'
    show
        GoogleGenerativeAIProviderSettings,
        GoogleGenerativeAI,
        GoogleProviderDefinedTools,
        GoogleTools,
        createGoogleGenerativeAI,
        google;
