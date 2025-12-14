import 'package:test/test.dart';
import 'package:llm_dart/llm_dart.dart';

void main() {
  group('ElevenLabsProvider Tests', () {
    late ElevenLabsProvider provider;
    late ElevenLabsConfig config;

    setUp(() {
      config = const ElevenLabsConfig(
        apiKey: 'test-api-key',
        baseUrl: 'https://api.elevenlabs.io/v1/',
        voiceId: 'test-voice-id',
        model: 'eleven_multilingual_v2',
        stability: 0.5,
        similarityBoost: 0.8,
      );
      provider = ElevenLabsProvider(config);
    });

    group('Provider Initialization', () {
      test('should initialize with valid config', () {
        expect(provider, isNotNull);
        expect(provider.config, equals(config));
        expect(provider.providerName, equals('ElevenLabs'));
      });

      test('should initialize audio module', () {
        expect(provider.audio, isNotNull);
      });

      test('should initialize models module', () {
        expect(provider.models, isNotNull);
      });

      test('should initialize client', () {
        expect(provider.client, isNotNull);
      });
    });

    group('Capability Support', () {
      test('should support audio capabilities', () {
        expect(provider.supportsCapability(AudioCapability), isTrue);
      });

      test('should not support chat capabilities', () {
        expect(provider.supportsCapability(ChatCapability), isFalse);
      });

      test('should have supported audio features', () {
        final features = provider.supportedFeatures;
        expect(features, isNotEmpty);
        expect(features, isA<Set<AudioFeature>>());
      });

      test('should support text-to-speech', () {
        expect(provider.config.supportsTextToSpeech, isTrue);
      });

      test('should support speech-to-text', () {
        expect(provider.config.supportsSpeechToText, isTrue);
      });

      test('should support voice cloning', () {
        expect(provider.config.supportsVoiceCloning, isTrue);
      });

      test('should support real-time streaming', () {
        expect(provider.config.supportsRealTimeStreaming, isTrue);
      });
    });

    group('Interface Implementation', () {
      test('should implement AudioCapability', () {
        expect(provider, isA<AudioCapability>());
      });

      test('should not implement ChatCapability', () {
        expect(provider, isNot(isA<ChatCapability>()));
      });
    });

    group('Audio Methods', () {
      test('should have textToSpeech method', () {
        expect(provider.textToSpeech, isA<Function>());
      });

      test('should have textToSpeechStream method', () {
        expect(provider.textToSpeechStream, isA<Function>());
      });

      test('should have speechToText method', () {
        expect(provider.speechToText, isA<Function>());
      });

      test('should have translateAudio method', () {
        expect(provider.translateAudio, isA<Function>());
      });

      test('should have getVoices method', () {
        expect(provider.getVoices, isA<Function>());
      });

      test('should have getSupportedLanguages method', () {
        expect(provider.getSupportedLanguages, isA<Function>());
      });

      test('should have startRealtimeSession method', () {
        expect(provider.startRealtimeSession, isA<Function>());
      });

      test('should have getSupportedAudioFormats method', () {
        expect(provider.getSupportedAudioFormats, isA<Function>());
      });
    });

    group('Convenience Audio Methods', () {
      test('should have speech method', () {
        expect(provider.speech, isA<Function>());
      });

      test('should have speechStream method', () {
        expect(provider.speechStream, isA<Function>());
      });

      test('should have transcribe method', () {
        expect(provider.transcribe, isA<Function>());
      });

      test('should have transcribeFile method', () {
        expect(provider.transcribeFile, isA<Function>());
      });

      test('should have translate method', () {
        expect(provider.translate, isA<Function>());
      });

      test('should have translateFile method', () {
        expect(provider.translateFile, isA<Function>());
      });
    });

    group('Model and User Info Methods', () {
      test('should have getModels method', () {
        expect(provider.getModels, isA<Function>());
      });

      test('should have getUserInfo method', () {
        expect(provider.getUserInfo, isA<Function>());
      });
    });

    group('Provider Information', () {
      test('should provide correct provider info', () {
        final info = provider.info;

        expect(info['provider'], equals('ElevenLabs'));
        expect(info['baseUrl'], equals(config.baseUrl));
        expect(info['supportsChat'], isFalse);
        expect(info['supportsTextToSpeech'], isTrue);
        expect(info['supportsSpeechToText'], isTrue);
        expect(info['supportsVoiceCloning'], isTrue);
        expect(info['supportsRealTimeStreaming'], isTrue);
        expect(info['defaultVoiceId'], isNotNull);
        expect(info['defaultTTSModel'], isNotNull);
        expect(info['defaultSTTModel'], isNotNull);
        expect(info['supportedAudioFormats'], isA<List<String>>());
      });

      test('should have meaningful toString representation', () {
        final stringRep = provider.toString();
        expect(stringRep, contains('ElevenLabsProvider'));
        expect(stringRep, contains(config.defaultVoiceId));
      });
    });

    group('Configuration Copying', () {
      test('should copy provider with new config values', () {
        final newProvider = provider.copyWith(
          apiKey: 'new-api-key',
          voiceId: 'new-voice-id',
          stability: 0.7,
        );

        expect(newProvider, isA<ElevenLabsProvider>());
        expect(newProvider.config.apiKey, equals('new-api-key'));
        expect(newProvider.config.voiceId, equals('new-voice-id'));
        expect(newProvider.config.stability, equals(0.7));
        // Unchanged values should remain the same
        expect(newProvider.config.baseUrl, equals(config.baseUrl));
        expect(newProvider.config.model, equals(config.model));
        expect(
            newProvider.config.similarityBoost, equals(config.similarityBoost));
      });

      test('should preserve original values when not specified in copyWith',
          () {
        final newProvider = provider.copyWith(stability: 0.9);

        expect(newProvider.config.apiKey, equals(config.apiKey));
        expect(newProvider.config.voiceId, equals(config.voiceId));
        expect(newProvider.config.model, equals(config.model));
        expect(
            newProvider.config.similarityBoost, equals(config.similarityBoost));
        expect(newProvider.config.stability, equals(0.9));
      });
    });
  });
}
