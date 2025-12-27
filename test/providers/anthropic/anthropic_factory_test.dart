import 'package:test/test.dart';
import 'package:llm_dart/llm_dart.dart';
import 'package:llm_dart_provider_utils/llm_dart_provider_utils.dart';

void main() {
  group('AnthropicProviderFactory Tests', () {
    late AnthropicProviderFactory factory;

    setUp(() {
      factory = AnthropicProviderFactory();
    });

    group('Factory Properties', () {
      test('should have correct provider ID', () {
        expect(factory.providerId, equals('anthropic'));
      });

      test('should have correct display name', () {
        expect(factory.displayName, equals('Anthropic'));
      });

      test('should have descriptive description', () {
        expect(factory.description, isNotEmpty);
        expect(factory.description, contains('Claude'));
      });

      test('should support expected capabilities', () {
        final capabilities = factory.supportedCapabilities;

        expect(capabilities, contains(LLMCapability.chat));
        expect(capabilities, contains(LLMCapability.streaming));
        expect(capabilities, contains(LLMCapability.toolCalling));
        expect(capabilities, contains(LLMCapability.reasoning));
        expect(capabilities, contains(LLMCapability.vision));
      });

      test('should not support unsupported capabilities', () {
        final capabilities = factory.supportedCapabilities;

        expect(capabilities, isNot(contains(LLMCapability.embedding)));
        expect(capabilities, isNot(contains(LLMCapability.imageGeneration)));
        expect(capabilities, isNot(contains(LLMCapability.textToSpeech)));
      });
    });

    group('Provider Creation', () {
      test('should create provider with basic config', () {
        final config = LLMConfig(
          apiKey: 'test-api-key',
          baseUrl: 'https://api.anthropic.com/v1/',
          model: 'claude-3-5-sonnet-20241022',
        );

        final provider = factory.create(config);

        expect(provider, isA<AnthropicProvider>());
        expect(provider, isA<ChatCapability>());
      });

      test('should create provider with reasoning config', () {
        final config = LLMConfig(
          apiKey: 'test-api-key',
          baseUrl: 'https://api.anthropic.com',
          model: 'claude-sonnet-4-20250514',
          providerOptions: const {
            'anthropic': {
              'reasoning': true,
              'thinkingBudgetTokens': 5000,
              'interleavedThinking': false,
            },
          },
        );

        final provider = factory.create(config);

        expect(provider, isA<AnthropicProvider>());
        expect(provider, isA<ChatCapability>());
      });

      test('should create provider with all supported parameters', () {
        final config = LLMConfig(
          apiKey: 'test-api-key',
          baseUrl: 'https://custom.api.com',
          model: 'claude-sonnet-4-20250514',
          maxTokens: 2000,
          temperature: 0.8,
          systemPrompt: 'You are a helpful assistant',
          timeout: const Duration(seconds: 30),
          topP: 0.9,
          topK: 50,
          stopSequences: ['STOP'],
          user: 'test-user',
          providerOptions: const {
            'anthropic': {
              'reasoning': true,
              'thinkingBudgetTokens': 3000,
              'interleavedThinking': true,
            },
          },
        );

        final provider = factory.create(config);

        expect(provider, isA<AnthropicProvider>());
        expect(provider, isA<ChatCapability>());
      });

      test('should handle missing API key gracefully', () {
        final config = LLMConfig(
          baseUrl: 'https://api.anthropic.com',
          model: 'claude-3-5-sonnet-20241022',
        );

        expect(() => factory.create(config), throwsA(isA<LLMError>()));
      });

      test('should handle empty API key gracefully', () {
        final config = LLMConfig(
          apiKey: '',
          baseUrl: 'https://api.anthropic.com',
          model: 'claude-3-5-sonnet-20241022',
        );

        expect(() => factory.create(config), throwsA(isA<LLMError>()));
      });
    });

    group('Default Configuration', () {
      test('should provide default configuration', () {
        final defaultConfig = factory.getProviderDefaults();

        expect(defaultConfig, isNotEmpty);
        expect(defaultConfig['model'], isNotNull);
        expect(defaultConfig['baseUrl'], isNotNull);
      });

      test('should have valid default model', () {
        final defaultConfig = factory.getProviderDefaults();
        final model = defaultConfig['model'] as String?;

        expect(model, isNotNull);
        expect(model, isNotEmpty);
        expect(model, startsWith('claude'));
      });

      test('should have valid default base URL', () {
        final defaultConfig = factory.getProviderDefaults();
        final baseUrl = defaultConfig['baseUrl'] as String?;

        expect(baseUrl, isNotNull);
        expect(baseUrl, equals('https://api.anthropic.com/v1/'));
      });
    });

    group('Configuration Validation', () {
      test('should validate valid config', () {
        final config = LLMConfig(
          apiKey: 'test-api-key',
          baseUrl: 'https://api.anthropic.com',
          model: 'claude-3-5-sonnet-20241022',
        );

        expect(factory.validateConfig(config), isTrue);
      });

      test('should reject config without API key', () {
        final config = LLMConfig(
          baseUrl: 'https://api.anthropic.com',
          model: 'claude-3-5-sonnet-20241022',
        );

        expect(factory.validateConfig(config), isFalse);
      });

      test('should reject config with empty API key', () {
        final config = LLMConfig(
          apiKey: '',
          baseUrl: 'https://api.anthropic.com',
          model: 'claude-3-5-sonnet-20241022',
        );

        expect(factory.validateConfig(config), isFalse);
      });

      test('should accept config with reasoning providerOptions', () {
        final config = LLMConfig(
          apiKey: 'test-api-key',
          baseUrl: 'https://api.anthropic.com',
          model: 'claude-sonnet-4-20250514',
          providerOptions: const {
            'anthropic': {
              'reasoning': true,
              'thinkingBudgetTokens': 5000,
            },
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
          baseUrl: 'https://api.anthropic.com',
          model: 'claude-3-5-sonnet-20241022',
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
          baseUrl: 'https://api.anthropic.com',
          model: 'invalid-model',
        );

        // Should not throw during creation, but provider may validate later
        expect(() => factory.create(config), returnsNormally);
      });

      test('should handle invalid base URL gracefully', () {
        final config = LLMConfig(
          apiKey: 'test-api-key',
          baseUrl: 'invalid-url',
          model: 'claude-3-5-sonnet-20241022',
        );

        // Should throw during creation due to URL validation
        expect(() => factory.create(config), throwsA(isA<LLMError>()));
      });
    });
  });
}
