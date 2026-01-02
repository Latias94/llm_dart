import 'package:test/test.dart';
import 'package:llm_dart/llm_dart.dart';

void main() {
  group('DeepSeekProviderFactory Tests', () {
    late DeepSeekProviderFactory factory;

    setUp(() {
      factory = DeepSeekProviderFactory();
    });

    group('Factory Properties', () {
      test('should have correct provider ID', () {
        expect(factory.providerId, equals('deepseek'));
      });

      test('should have correct display name', () {
        expect(factory.displayName, equals('DeepSeek'));
      });

      test('should have descriptive description', () {
        expect(factory.description, isNotEmpty);
        expect(factory.description, contains('DeepSeek'));
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
        expect(capabilities, isNot(contains(LLMCapability.fileManagement)));
      });
    });

    group('Provider Creation', () {
      test('should create provider with basic config', () {
        final config = LLMConfig(
          apiKey: 'test-api-key',
          baseUrl: 'https://api.deepseek.com/v1/',
          model: 'deepseek-chat',
        );

        final provider = factory.create(config);

        expect(provider, isA<DeepSeekProvider>());
        expect(provider, isA<ChatCapability>());
      });

      test('should create provider with reasoning config', () {
        final config = LLMConfig(
          apiKey: 'test-api-key',
          baseUrl: 'https://api.deepseek.com/v1/',
          model: 'deepseek-reasoner',
          providerOptions: const {
            'deepseek': {
              'logprobs': true,
              'topLogprobs': 5,
            },
          },
        );

        final provider = factory.create(config);

        expect(provider, isA<DeepSeekProvider>());
        expect(provider, isA<ChatCapability>());
      });

      test('should create provider with all supported parameters', () {
        final config = LLMConfig(
          apiKey: 'test-api-key',
          baseUrl: 'https://custom.api.com',
          model: 'deepseek-reasoner',
          maxTokens: 2000,
          temperature: 0.8,
          systemPrompt: 'You are a helpful assistant',
          timeout: const Duration(seconds: 30),
          topP: 0.9,
          topK: 50,
          providerOptions: const {
            'deepseek': {
              'logprobs': true,
              'topLogprobs': 3,
              'frequencyPenalty': 0.1,
              'presencePenalty': 0.2,
              'responseFormat': {'type': 'json_object'},
            },
          },
        );

        final provider = factory.create(config);

        expect(provider, isA<DeepSeekProvider>());
        expect(provider, isA<ChatCapability>());
      });

      test('should handle missing API key gracefully', () {
        final config = LLMConfig(
          baseUrl: 'https://api.deepseek.com/v1/',
          model: 'deepseek-chat',
        );

        expect(() => factory.create(config), throwsA(isA<LLMError>()));
      });

      test('should handle empty API key gracefully', () {
        final config = LLMConfig(
          apiKey: '',
          baseUrl: 'https://api.deepseek.com/v1/',
          model: 'deepseek-chat',
        );

        expect(() => factory.create(config), throwsA(isA<LLMError>()));
      });
    });

    group('Default Configuration', () {
      test('should provide default configuration', () {
        final defaultConfig = factory.getDefaultConfig();

        expect(defaultConfig, isNotNull);
        expect(defaultConfig.baseUrl, isNotNull);
        expect(defaultConfig.model, isNotNull);
      });

      test('should have valid default model', () {
        final defaultConfig = factory.getDefaultConfig();

        expect(defaultConfig.model, isNotNull);
        expect(defaultConfig.model, isNotEmpty);
        expect(defaultConfig.model, startsWith('deepseek'));
      });

      test('should have valid default base URL', () {
        final defaultConfig = factory.getDefaultConfig();

        expect(defaultConfig.baseUrl, isNotNull);
        expect(defaultConfig.baseUrl, equals('https://api.deepseek.com/v1/'));
      });
    });

    group('Configuration Validation', () {
      test('should validate valid config', () {
        final config = LLMConfig(
          apiKey: 'test-api-key',
          baseUrl: 'https://api.deepseek.com/v1/',
          model: 'deepseek-chat',
        );

        expect(factory.validateConfig(config), isTrue);
      });

      test('should reject config without API key', () {
        final config = LLMConfig(
          baseUrl: 'https://api.deepseek.com/v1/',
          model: 'deepseek-chat',
        );

        expect(factory.validateConfig(config), isFalse);
      });

      test('should reject config with empty API key', () {
        final config = LLMConfig(
          apiKey: '',
          baseUrl: 'https://api.deepseek.com/v1/',
          model: 'deepseek-chat',
        );

        expect(factory.validateConfig(config), isFalse);
      });

      test('should accept config with reasoning model', () {
        final config = LLMConfig(
          apiKey: 'test-api-key',
          baseUrl: 'https://api.deepseek.com/v1/',
          model: 'deepseek-reasoner',
        );

        expect(factory.validateConfig(config), isTrue);
      });

      test('should accept config with provider options', () {
        final config = LLMConfig(
          apiKey: 'test-api-key',
          baseUrl: 'https://api.deepseek.com/v1/',
          model: 'deepseek-chat',
          providerOptions: const {
            'deepseek': {
              'logprobs': true,
              'frequencyPenalty': 0.1,
            },
          },
        );

        expect(factory.validateConfig(config), isTrue);
      });
    });

    group('Provider Interface Compliance', () {
      test('should implement LLMProviderFactory', () {
        expect(factory, isA<LLMProviderFactory<ChatCapability>>());
      });

      test('should create providers that implement required interfaces', () {
        final config = LLMConfig(
          apiKey: 'test-api-key',
          baseUrl: 'https://api.deepseek.com/v1/',
          model: 'deepseek-chat',
        );

        final provider = factory.create(config);

        expect(provider, isA<ChatCapability>());
        expect(provider, isA<ProviderCapabilities>());
      });
    });

    group('Configuration Transformation', () {
      test('should transform LLMConfig to DeepSeekConfig correctly', () {
        final llmConfig = LLMConfig(
          apiKey: 'test-key',
          baseUrl: 'https://custom.api.com',
          model: 'deepseek-reasoner',
          maxTokens: 1500,
          temperature: 0.8,
          systemPrompt: 'Custom prompt',
          timeout: const Duration(seconds: 45),
          topP: 0.95,
          topK: 40,
          providerOptions: const {
            'deepseek': {
              'logprobs': true,
              'topLogprobs': 5,
              'frequencyPenalty': 0.2,
              'presencePenalty': 0.3,
            },
          },
        );

        final provider = factory.create(llmConfig) as DeepSeekProvider;
        final config = provider.config;

        expect(config.apiKey, equals('test-key'));
        expect(config.baseUrl, equals('https://custom.api.com'));
        expect(config.model, equals('deepseek-reasoner'));
        expect(config.maxTokens, equals(1500));
        expect(config.temperature, equals(0.8));
        expect(config.systemPrompt, equals('Custom prompt'));
        expect(config.timeout, equals(const Duration(seconds: 45)));
        expect(config.topP, equals(0.95));
        expect(config.topK, equals(40));
        expect(config.logprobs, isTrue);
        expect(config.topLogprobs, equals(5));
        expect(config.frequencyPenalty, equals(0.2));
        expect(config.presencePenalty, equals(0.3));
      });

      test('should preserve original config reference', () {
        final llmConfig = LLMConfig(
          apiKey: 'test-key',
          baseUrl: 'https://api.deepseek.com/v1/',
          model: 'deepseek-chat',
          transportOptions: const {
            'customHeaders': {'X-Test': 'customValue'},
          },
        );

        final provider = factory.create(llmConfig) as DeepSeekProvider;
        final config = provider.config;

        expect(config.originalConfig, isNotNull);
        expect(
          config.originalConfig!.getTransportOption<Map<String, String>>(
            'customHeaders',
          ),
          equals({'X-Test': 'customValue'}),
        );
      });
    });

    group('Error Handling', () {
      test('should handle invalid model gracefully', () {
        final config = LLMConfig(
          apiKey: 'test-api-key',
          baseUrl: 'https://api.deepseek.com/v1/',
          model: 'invalid-model',
        );

        // Should not throw during creation, but provider may validate later
        expect(() => factory.create(config), returnsNormally);
      });

      test('should handle invalid base URL gracefully', () {
        final config = LLMConfig(
          apiKey: 'test-api-key',
          baseUrl: 'invalid-url',
          model: 'deepseek-chat',
        );

        // Should throw during creation due to URL validation
        expect(() => factory.create(config), throwsA(isA<LLMError>()));
      });
    });
  });
}
