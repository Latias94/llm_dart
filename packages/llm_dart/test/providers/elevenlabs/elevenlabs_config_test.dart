import 'package:test/test.dart';
import 'package:llm_dart/llm_dart.dart';

void main() {
  group('ElevenLabsConfig Tests', () {
    group('Basic Configuration', () {
      test('should create config with required parameters', () {
        const config = ElevenLabsConfig(
          apiKey: 'test-api-key',
        );

        expect(config.apiKey, equals('test-api-key'));
        expect(config.baseUrl, equals('https://api.elevenlabs.io/v1/'));
        expect(config.voiceId, isNull);
        expect(config.model, isNull);
        expect(config.timeout, isNull);
        expect(config.stability, isNull);
        expect(config.similarityBoost, isNull);
        expect(config.style, isNull);
        expect(config.useSpeakerBoost, isNull);
      });

      test('should create config with all parameters', () {
        const config = ElevenLabsConfig(
          apiKey: 'test-api-key',
          baseUrl: 'https://custom.api.com',
          voiceId: 'test-voice-id',
          model: 'eleven_multilingual_v2',
          timeout: Duration(seconds: 30),
          stability: 0.5,
          similarityBoost: 0.8,
          style: 0.3,
          useSpeakerBoost: true,
        );

        expect(config.apiKey, equals('test-api-key'));
        expect(config.baseUrl, equals('https://custom.api.com'));
        expect(config.voiceId, equals('test-voice-id'));
        expect(config.model, equals('eleven_multilingual_v2'));
        expect(config.timeout, equals(const Duration(seconds: 30)));
        expect(config.stability, equals(0.5));
        expect(config.similarityBoost, equals(0.8));
        expect(config.style, equals(0.3));
        expect(config.useSpeakerBoost, isTrue);
      });
    });

    group('Capability Support', () {
      test('should support text-to-speech', () {
        const config = ElevenLabsConfig(apiKey: 'test-key');
        expect(config.supportsTextToSpeech, isTrue);
      });

      test('should support speech-to-text', () {
        const config = ElevenLabsConfig(apiKey: 'test-key');
        expect(config.supportsSpeechToText, isTrue);
      });

      test('should support voice cloning', () {
        const config = ElevenLabsConfig(apiKey: 'test-key');
        expect(config.supportsVoiceCloning, isTrue);
      });

      test('should support real-time streaming', () {
        const config = ElevenLabsConfig(apiKey: 'test-key');
        expect(config.supportsRealTimeStreaming, isTrue);
      });
    });

    group('Default Values', () {
      test('should return default voice ID when not specified', () {
        const config = ElevenLabsConfig(apiKey: 'test-key');
        expect(config.defaultVoiceId, isNotEmpty);
      });

      test('should return custom voice ID when specified', () {
        const config = ElevenLabsConfig(
          apiKey: 'test-key',
          voiceId: 'custom-voice',
        );
        expect(config.defaultVoiceId, equals('custom-voice'));
      });

      test('should return default TTS model when not specified', () {
        const config = ElevenLabsConfig(apiKey: 'test-key');
        expect(config.defaultTTSModel, isNotEmpty);
      });

      test('should return custom model when specified', () {
        const config = ElevenLabsConfig(
          apiKey: 'test-key',
          model: 'custom-model',
        );
        expect(config.defaultTTSModel, equals('custom-model'));
      });

      test('should return default STT model', () {
        const config = ElevenLabsConfig(apiKey: 'test-key');
        expect(config.defaultSTTModel, isNotEmpty);
      });

      test('should return supported audio formats', () {
        const config = ElevenLabsConfig(apiKey: 'test-key');
        final formats = config.supportedAudioFormats;
        expect(formats, isNotEmpty);
        expect(formats, isA<List<String>>());
      });
    });

    group('Voice Settings', () {
      test('should return empty voice settings when none specified', () {
        const config = ElevenLabsConfig(apiKey: 'test-key');
        final settings = config.voiceSettings;
        expect(settings, isEmpty);
      });

      test('should return voice settings when specified', () {
        const config = ElevenLabsConfig(
          apiKey: 'test-key',
          stability: 0.5,
          similarityBoost: 0.8,
          style: 0.3,
          useSpeakerBoost: true,
        );

        final settings = config.voiceSettings;
        expect(settings['stability'], equals(0.5));
        expect(settings['similarity_boost'], equals(0.8));
        expect(settings['style'], equals(0.3));
        expect(settings['use_speaker_boost'], isTrue);
      });

      test('should only include non-null voice settings', () {
        const config = ElevenLabsConfig(
          apiKey: 'test-key',
          stability: 0.5,
          // Other settings are null
        );

        final settings = config.voiceSettings;
        expect(settings.length, equals(1));
        expect(settings['stability'], equals(0.5));
        expect(settings.containsKey('similarity_boost'), isFalse);
      });
    });

    group('Configuration Copying', () {
      test('should copy config with new values', () {
        const original = ElevenLabsConfig(
          apiKey: 'original-key',
          voiceId: 'original-voice',
          stability: 0.5,
        );

        final copied = original.copyWith(
          apiKey: 'new-key',
          stability: 0.8,
        );

        expect(copied.apiKey, equals('new-key'));
        expect(copied.voiceId, equals('original-voice')); // Unchanged
        expect(copied.stability, equals(0.8));
      });

      test('should preserve original values when not specified', () {
        const original = ElevenLabsConfig(
          apiKey: 'test-key',
          voiceId: 'test-voice',
          model: 'test-model',
          stability: 0.5,
          similarityBoost: 0.8,
        );

        final copied = original.copyWith(style: 0.3);

        expect(copied.apiKey, equals('test-key'));
        expect(copied.voiceId, equals('test-voice'));
        expect(copied.model, equals('test-model'));
        expect(copied.stability, equals(0.5));
        expect(copied.similarityBoost, equals(0.8));
        expect(copied.style, equals(0.3));
      });
    });

    group('LLMConfig Integration', () {
      test('should create from LLMConfig', () {
        final llmConfig = LLMConfig(
          apiKey: 'test-key',
          baseUrl: 'https://api.elevenlabs.io/v1/',
          model: 'eleven_multilingual_v2',
          timeout: const Duration(seconds: 30),
          extensions: {
            'voiceId': 'test-voice',
            'stability': 0.5,
            'similarityBoost': 0.8,
            'style': 0.3,
            'useSpeakerBoost': true,
          },
        );

        final elevenLabsConfig = ElevenLabsConfig.fromLLMConfig(llmConfig);

        expect(elevenLabsConfig.apiKey, equals('test-key'));
        expect(
            elevenLabsConfig.baseUrl, equals('https://api.elevenlabs.io/v1/'));
        expect(elevenLabsConfig.model, equals('eleven_multilingual_v2'));
        expect(elevenLabsConfig.timeout, equals(const Duration(seconds: 30)));
        expect(elevenLabsConfig.voiceId, equals('test-voice'));
        expect(elevenLabsConfig.stability, equals(0.5));
        expect(elevenLabsConfig.similarityBoost, equals(0.8));
        expect(elevenLabsConfig.style, equals(0.3));
        expect(elevenLabsConfig.useSpeakerBoost, isTrue);
      });

      test('should access extensions from original config', () {
        final llmConfig = LLMConfig(
          apiKey: 'test-key',
          baseUrl: 'https://api.elevenlabs.io/v1/',
          model: 'eleven_multilingual_v2',
          extensions: {'customParam': 'customValue'},
        );

        final elevenLabsConfig = ElevenLabsConfig.fromLLMConfig(llmConfig);

        expect(elevenLabsConfig.getExtension<String>('customParam'),
            equals('customValue'));
      });
    });
  });
}
