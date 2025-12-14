import 'package:test/test.dart';
import 'package:llm_dart/llm_dart.dart';

void main() {
  group('GroqProviderFactory Tests', () {
    late GroqProviderFactory factory;

    setUp(() {
      factory = GroqProviderFactory();
    });

    group('Factory Properties', () {
      test('should have correct provider ID', () {
        expect(factory.providerId, equals('groq'));
      });

      test('should have correct display name', () {
        expect(factory.displayName, equals('Groq'));
      });

      test('should have descriptive description', () {
        expect(factory.description, isNotEmpty);
        expect(factory.description.toLowerCase(), contains('fast'));
      });

      test('should support expected capabilities', () {
        final capabilities = factory.supportedCapabilities;

        expect(capabilities, contains(LLMCapability.chat));
        expect(capabilities, contains(LLMCapability.streaming));
        expect(capabilities, contains(LLMCapability.toolCalling));
      });

      test('should not support unsupported capabilities', () {
        final capabilities = factory.supportedCapabilities;

        expect(capabilities, isNot(contains(LLMCapability.vision)));
        expect(capabilities, isNot(contains(LLMCapability.reasoning)));
        expect(capabilities, isNot(contains(LLMCapability.embedding)));
        expect(capabilities, isNot(contains(LLMCapability.imageGeneration)));
        expect(capabilities, isNot(contains(LLMCapability.textToSpeech)));
      });
    });

    group('Provider Creation', () {
      test('should create provider with basic config', () {
        final config = LLMConfig(
          apiKey: 'test-api-key',
          baseUrl: 'https://api.groq.com/openai/v1/',
          model: 'llama-3.3-70b-versatile',
        );

        final provider = factory.create(config);

        expect(provider, isA<GroqProvider>());
        expect(provider, isA<ChatCapability>());
      });

      test('should create provider with tool calling config', () {
        final config = LLMConfig(
          apiKey: 'test-api-key',
          baseUrl: 'https://api.groq.com/openai/v1/',
          model: 'llama-3.3-70b-versatile',
          tools: [],
          toolChoice: AutoToolChoice(),
        );

        final provider = factory.create(config);

        expect(provider, isA<GroqProvider>());
        expect(provider, isA<ChatCapability>());
      });

      test('should create provider with all supported parameters', () {
        final config = LLMConfig(
          apiKey: 'test-api-key',
          baseUrl: 'https://custom.api.com',
          model: 'llama-3.1-8b-instant',
          maxTokens: 2000,
          temperature: 0.8,
          systemPrompt: 'You are a helpful assistant',
          timeout: const Duration(seconds: 30),
          topP: 0.9,
          topK: 50,
          tools: [],
          toolChoice: AutoToolChoice(),
        );

        final provider = factory.create(config);

        expect(provider, isA<GroqProvider>());
        expect(provider, isA<ChatCapability>());
      });

      test('should handle missing API key gracefully', () {
        final config = LLMConfig(
          baseUrl: 'https://api.groq.com/openai/v1/',
          model: 'llama-3.3-70b-versatile',
        );

        expect(() => factory.create(config), throwsA(isA<LLMError>()));
      });

      test('should handle empty API key gracefully', () {
        final config = LLMConfig(
          apiKey: '',
          baseUrl: 'https://api.groq.com/openai/v1/',
          model: 'llama-3.3-70b-versatile',
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
        expect(model, startsWith('llama'));
      });

      test('should have valid default base URL', () {
        final defaultConfig = factory.getDefaultConfig();
        final baseUrl = defaultConfig.baseUrl;

        expect(baseUrl, isNotNull);
        expect(baseUrl, equals('https://api.groq.com/openai/v1/'));
      });
    });

    group('Configuration Validation', () {
      test('should validate valid config', () {
        final config = LLMConfig(
          apiKey: 'test-api-key',
          baseUrl: 'https://api.groq.com/openai/v1/',
          model: 'llama-3.3-70b-versatile',
        );

        expect(factory.validateConfig(config), isTrue);
      });

      test('should reject config without API key', () {
        final config = LLMConfig(
          baseUrl: 'https://api.groq.com/openai/v1/',
          model: 'llama-3.3-70b-versatile',
        );

        expect(factory.validateConfig(config), isFalse);
      });

      test('should reject config with empty API key', () {
        final config = LLMConfig(
          apiKey: '',
          baseUrl: 'https://api.groq.com/openai/v1/',
          model: 'llama-3.3-70b-versatile',
        );

        expect(factory.validateConfig(config), isFalse);
      });

      test('should accept config with tool calling', () {
        final config = LLMConfig(
          apiKey: 'test-api-key',
          baseUrl: 'https://api.groq.com/openai/v1/',
          model: 'llama-3.3-70b-versatile',
          tools: [],
          toolChoice: AutoToolChoice(),
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
          baseUrl: 'https://api.groq.com/openai/v1/',
          model: 'llama-3.3-70b-versatile',
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
          baseUrl: 'https://api.groq.com/openai/v1/',
          model: 'invalid-model',
        );

        // Should not throw during creation, but provider may validate later
        expect(() => factory.create(config), returnsNormally);
      });

      test('should handle invalid base URL gracefully', () {
        final config = LLMConfig(
          apiKey: 'test-api-key',
          baseUrl: 'invalid-url',
          model: 'llama-3.3-70b-versatile',
        );

        // Should throw during creation due to URL validation
        expect(() => factory.create(config), throwsA(isA<LLMError>()));
      });

      test('should handle vision models correctly', () {
        final config = LLMConfig(
          apiKey: 'test-api-key',
          baseUrl: 'https://api.groq.com/openai/v1/',
          model: 'llama-3.2-11b-vision-preview',
        );

        expect(() => factory.create(config), returnsNormally);
      });

      test('should handle Whisper models correctly', () {
        final config = LLMConfig(
          apiKey: 'test-api-key',
          baseUrl: 'https://api.groq.com/openai/v1/',
          model: 'whisper-large-v3',
        );

        expect(() => factory.create(config), returnsNormally);
      });
    });
  });
}
