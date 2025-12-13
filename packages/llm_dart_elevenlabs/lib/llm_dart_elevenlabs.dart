library;

export 'src/config/elevenlabs_config.dart';
export 'src/http/elevenlabs_dio_strategy.dart';
export 'src/client/elevenlabs_client.dart';
export 'src/audio/elevenlabs_audio.dart';
export 'src/models/elevenlabs_models.dart';
export 'src/provider/elevenlabs_provider.dart';
export 'src/factory/elevenlabs_provider_factory.dart'
    show ElevenLabsProviderFactory, registerElevenLabsProvider;

// Vercel AI-style facade exports (model-centric API).
export 'src/facade/elevenlabs_facade.dart'
    show
        ElevenLabsProviderSettings,
        ElevenLabs,
        createElevenLabs,
        elevenlabs;
