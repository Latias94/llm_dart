import 'package:test/test.dart';
import 'package:llm_dart/llm_dart.dart';
import 'package:llm_dart/providers/factories/elevenlabs_factory.dart';

void main() {
  group('ElevenLabsProviderFactory Tests', () {
    late ElevenLabsProviderFactory factory;

    setUp(() {
      factory = ElevenLabsProviderFactory();
    });

    group('Factory Properties', () {
      test('should have correct provider ID', () {
        expect(factory.providerId, equals('elevenlabs'));
      });

      test('should have correct display name', () {
        expect(factory.displayName, equals('ElevenLabs'));
      });

      test('should have descriptive description', () {
        expect(factory.description, isNotEmpty);
        expect(factory.description.toLowerCase(), contains('text-to-speech'));
      });

      test('should support expected capabilities', () {
        final capabilities = factory.supportedCapabilities;

        expect(capabilities, contains(LLMCapability.textToSpeech));
        expect(capabilities, contains(LLMCapability.speechToText));
      });

      test('should not support unsupported capabilities', () {
        final capabilities = factory.supportedCapabilities;

        expect(capabilities, isNot(contains(LLMCapability.chat)));
        expect(capabilities, isNot(contains(LLMCapability.embedding)));
        expect(capabilities, isNot(contains(LLMCapability.imageGeneration)));
        expect(capabilities, isNot(contains(LLMCapability.reasoning)));
        expect(capabilities, isNot(contains(LLMCapability.streaming)));
      });
    });

    group('Provider Creation', () {
      test('should create provider with basic config', () {
        final config = LLMConfig(
          apiKey: 'test-api-key',
          baseUrl: 'https://api.elevenlabs.io/v1/',
          model: 'eleven_multilingual_v2',
        );

        final provider = factory.create(config);

        expect(provider, isA<ElevenLabsProvider>());
        expect(provider, isA<AudioCapability>());
      });

      test('should create provider with voice settings', () {
        final config = LLMConfig(
          apiKey: 'test-api-key',
          baseUrl: 'https://api.elevenlabs.io/v1/',
          model: 'eleven_multilingual_v2',
          extensions: {
            'voiceId': 'test-voice-id',
            'stability': 0.5,
            'similarityBoost': 0.8,
            'style': 0.3,
            'useSpeakerBoost': true,
          },
        );

        final provider = factory.create(config);

        expect(provider, isA<ElevenLabsProvider>());
        expect(provider, isA<AudioCapability>());
      });

      test('should create provider with all supported parameters', () {
        final config = LLMConfig(
          apiKey: 'test-api-key',
          baseUrl: 'https://custom.api.com',
          model: 'eleven_multilingual_v2',
          timeout: const Duration(seconds: 30),
          extensions: {
            'voiceId': 'custom-voice',
            'stability': 0.6,
            'similarityBoost': 0.9,
            'style': 0.4,
            'useSpeakerBoost': false,
          },
        );

        final provider = factory.create(config);

        expect(provider, isA<ElevenLabsProvider>());
        expect(provider, isA<AudioCapability>());
      });

      test('should handle missing API key gracefully', () {
        final config = LLMConfig(
          baseUrl: 'https://api.elevenlabs.io/v1/',
          model: 'eleven_multilingual_v2',
        );

        expect(() => factory.create(config), throwsA(isA<LLMError>()));
      });

      test('should handle empty API key gracefully', () {
        final config = LLMConfig(
          apiKey: '',
          baseUrl: 'https://api.elevenlabs.io/v1/',
          model: 'eleven_multilingual_v2',
        );

        expect(() => factory.create(config), throwsA(isA<LLMError>()));
      });
    });

    group('Default Configuration', () {
      test('should provide default configuration', () {
        final defaultConfig = factory.getDefaultConfig();

        expect(defaultConfig.baseUrl, isNotNull);
      });

      test('should have valid default base URL', () {
        final defaultConfig = factory.getDefaultConfig();
        final baseUrl = defaultConfig.baseUrl;

        expect(baseUrl, isNotNull);
        expect(baseUrl, equals('https://api.elevenlabs.io/v1/'));
      });

      test('should have default voice settings', () {
        final defaultConfig = factory.getDefaultConfig();
        expect(defaultConfig.model, isNotEmpty);
      });
    });

    group('Configuration Validation', () {
      test('should validate valid config', () {
        final config = LLMConfig(
          apiKey: 'test-api-key',
          baseUrl: 'https://api.elevenlabs.io/v1/',
          model: 'eleven_multilingual_v2',
        );

        expect(factory.validateConfig(config), isTrue);
      });

      test('should reject config without API key', () {
        final config = LLMConfig(
          baseUrl: 'https://api.elevenlabs.io/v1/',
          model: 'eleven_multilingual_v2',
        );

        expect(factory.validateConfig(config), isFalse);
      });

      test('should reject config with empty API key', () {
        final config = LLMConfig(
          apiKey: '',
          baseUrl: 'https://api.elevenlabs.io/v1/',
          model: 'eleven_multilingual_v2',
        );

        expect(factory.validateConfig(config), isFalse);
      });

      test('should accept config with voice extensions', () {
        final config = LLMConfig(
          apiKey: 'test-api-key',
          baseUrl: 'https://api.elevenlabs.io/v1/',
          model: 'eleven_multilingual_v2',
          extensions: {
            'voiceId': 'test-voice',
            'stability': 0.5,
            'similarityBoost': 0.8,
          },
        );

        expect(factory.validateConfig(config), isTrue);
      });
    });

    group('Provider Interface Compliance', () {
      test('should implement BaseProviderFactory', () {
        expect(factory, isA<BaseProviderFactory<ChatCapability>>());
      });

      test('should implement LLMProviderFactory', () {
        expect(factory, isA<LLMProviderFactory<ChatCapability>>());
      });

      test('should create providers that implement required interfaces', () {
        final config = LLMConfig(
          apiKey: 'test-api-key',
          baseUrl: 'https://api.elevenlabs.io/v1/',
          model: 'eleven_multilingual_v2',
        );

        final provider = factory.create(config);

        expect(provider, isA<ChatCapability>());
        expect(provider, isA<AudioCapability>());
      });
    });

    group('Error Handling', () {
      test('should handle invalid model gracefully', () {
        final config = LLMConfig(
          apiKey: 'test-api-key',
          baseUrl: 'https://api.elevenlabs.io/v1/',
          model: 'invalid-model',
        );

        // Should not throw during creation, but provider may validate later
        expect(() => factory.create(config), returnsNormally);
      });

      test('should handle invalid base URL gracefully', () {
        final config = LLMConfig(
          apiKey: 'test-api-key',
          baseUrl: 'invalid-url',
          model: 'eleven_multilingual_v2',
        );

        // Should throw during creation due to URL validation
        expect(() => factory.create(config), throwsA(isA<LLMError>()));
      });

      test('should handle invalid voice settings gracefully', () {
        final config = LLMConfig(
          apiKey: 'test-api-key',
          baseUrl: 'https://api.elevenlabs.io/v1/',
          model: 'eleven_multilingual_v2',
          extensions: {
            'stability': 2.0, // Invalid value (should be 0-1)
            'similarityBoost': -0.5, // Invalid value (should be 0-1)
          },
        );

        // Should not throw during creation, validation happens at runtime
        expect(() => factory.create(config), returnsNormally);
      });
    });
  });
}
