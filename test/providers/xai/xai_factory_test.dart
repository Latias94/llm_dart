import 'package:test/test.dart';
import 'package:llm_dart/llm_dart.dart';
import 'package:llm_dart_xai/llm_dart_xai.dart' as xai;

void main() {
  group('XAIProviderFactory Tests', () {
    late XAIProviderFactory factory;

    setUp(() {
      factory = XAIProviderFactory();
    });

    group('Factory Properties', () {
      test('should have correct provider ID', () {
        expect(factory.providerId, equals('xai'));
      });

      test('should have correct display name', () {
        expect(factory.displayName, equals('xAI (Grok)'));
      });

      test('should have descriptive description', () {
        expect(factory.description, isNotEmpty);
        expect(factory.description.toLowerCase(), contains('grok'));
      });

      test('should support expected capabilities', () {
        final capabilities = factory.supportedCapabilities;

        expect(capabilities, contains(LLMCapability.chat));
        expect(capabilities, contains(LLMCapability.streaming));
        expect(capabilities, contains(LLMCapability.toolCalling));
        expect(capabilities, contains(LLMCapability.reasoning));
        expect(capabilities, contains(LLMCapability.vision));
        expect(capabilities, contains(LLMCapability.embedding));
        expect(capabilities, contains(LLMCapability.liveSearch));
      });

      test('should not support unsupported capabilities', () {
        final capabilities = factory.supportedCapabilities;

        expect(capabilities, isNot(contains(LLMCapability.imageGeneration)));
        expect(capabilities, isNot(contains(LLMCapability.textToSpeech)));
        expect(capabilities, isNot(contains(LLMCapability.speechToText)));
      });
    });

    group('Provider Creation', () {
      test('should create provider with basic config', () {
        final config = LLMConfig(
          apiKey: 'test-api-key',
          baseUrl: 'https://api.x.ai/v1/',
          model: 'grok-3',
        );

        final provider = factory.create(config);

        expect(provider, isA<xai.XAIProvider>());
        expect(provider, isA<ChatCapability>());
      });

      test('should create provider with live search enabled', () {
        final config = LLMConfig(
          apiKey: 'test-api-key',
          baseUrl: 'https://api.x.ai/v1/',
          model: 'grok-3',
          extensions: {
            LLMConfigKeys.liveSearch: true,
          },
        );

        final provider = factory.create(config);

        expect(provider, isA<xai.XAIProvider>());
        expect(provider, isA<ChatCapability>());
      });

      test('should create provider with all supported parameters', () {
        final config = LLMConfig(
          apiKey: 'test-api-key',
          baseUrl: 'https://custom.api.com',
          model: 'grok-vision-beta',
          maxTokens: 2000,
          temperature: 0.8,
          systemPrompt: 'You are a helpful assistant',
          timeout: const Duration(seconds: 30),
          topP: 0.9,
          topK: 50,
          tools: [],
          toolChoice: const AutoToolChoice(),
          extensions: {
            LLMConfigKeys.embeddingEncodingFormat: 'float',
            LLMConfigKeys.embeddingDimensions: 1536,
            LLMConfigKeys.liveSearch: true,
          },
        );

        final provider = factory.create(config);

        expect(provider, isA<xai.XAIProvider>());
        expect(provider, isA<ChatCapability>());
      });

      test('should handle missing API key gracefully', () {
        final config = LLMConfig(
          baseUrl: 'https://api.x.ai/v1/',
          model: 'grok-3',
        );

        expect(() => factory.create(config), throwsA(isA<LLMError>()));
      });

      test('should handle empty API key gracefully', () {
        final config = LLMConfig(
          apiKey: '',
          baseUrl: 'https://api.x.ai/v1/',
          model: 'grok-3',
        );

        expect(() => factory.create(config), throwsA(isA<LLMError>()));
      });
    });

    group('Default Configuration', () {
      test('should provide default configuration', () {
        final defaultConfig = factory.getDefaultConfig();

        expect(defaultConfig.model, isNotNull);
        expect(defaultConfig.baseUrl, isNotNull);
      });

      test('should have valid default model', () {
        final defaultConfig = factory.getDefaultConfig();
        final model = defaultConfig.model;

        expect(model, isNotNull);
        expect(model, isNotEmpty);
        expect(model, startsWith('grok'));
      });

      test('should have valid default base URL', () {
        final defaultConfig = factory.getDefaultConfig();
        final baseUrl = defaultConfig.baseUrl;

        expect(baseUrl, isNotNull);
        expect(baseUrl, equals('https://api.x.ai/v1/'));
      });
    });

    group('Configuration Validation', () {
      test('should validate valid config', () {
        final config = LLMConfig(
          apiKey: 'test-api-key',
          baseUrl: 'https://api.x.ai/v1/',
          model: 'grok-3',
        );

        expect(factory.validateConfig(config), isTrue);
      });

      test('should reject config without API key', () {
        final config = LLMConfig(
          baseUrl: 'https://api.x.ai/v1/',
          model: 'grok-3',
        );

        expect(factory.validateConfig(config), isFalse);
      });

      test('should reject config with empty API key', () {
        final config = LLMConfig(
          apiKey: '',
          baseUrl: 'https://api.x.ai/v1/',
          model: 'grok-3',
        );

        expect(factory.validateConfig(config), isFalse);
      });

      test('should accept config with search extensions', () {
        final config = LLMConfig(
          apiKey: 'test-api-key',
          baseUrl: 'https://api.x.ai/v1/',
          model: 'grok-3',
          extensions: {
            'liveSearch': true,
            'webSearchEnabled': true,
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
          baseUrl: 'https://api.x.ai/v1/',
          model: 'grok-3',
        );

        final provider = factory.create(config);

        expect(provider, isA<ChatCapability>());
        expect(provider, isA<ProviderCapabilities>());
      });
    });

    group('Error Handling', () {
      test('should handle invalid model gracefully', () {
        final config = LLMConfig(
          apiKey: 'test-api-key',
          baseUrl: 'https://api.x.ai/v1/',
          model: 'invalid-model',
        );

        // Should not throw during creation, but provider may validate later
        expect(() => factory.create(config), returnsNormally);
      });

      test('should handle invalid base URL gracefully', () {
        final config = LLMConfig(
          apiKey: 'test-api-key',
          baseUrl: 'invalid-url',
          model: 'grok-3',
        );

        // Should throw during creation due to URL validation
        expect(() => factory.create(config), throwsA(isA<LLMError>()));
      });

      test('should handle vision models correctly', () {
        final config = LLMConfig(
          apiKey: 'test-api-key',
          baseUrl: 'https://api.x.ai/v1/',
          model: 'grok-vision-beta',
        );

        expect(() => factory.create(config), returnsNormally);
      });

      test('should handle embedding models correctly', () {
        final config = LLMConfig(
          apiKey: 'test-api-key',
          baseUrl: 'https://api.x.ai/v1/',
          model: 'text-embedding-ada-002',
        );

        expect(() => factory.create(config), returnsNormally);
      });
    });
  });
}
