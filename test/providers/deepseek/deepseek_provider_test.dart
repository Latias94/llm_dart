import 'package:test/test.dart';
import 'package:llm_dart/llm_dart.dart';
import 'package:llm_dart_deepseek/llm_dart_deepseek.dart' as deepseek;

void main() {
  group('DeepSeekProvider Tests', () {
    late deepseek.DeepSeekProvider provider;
    late deepseek.DeepSeekConfig config;

    setUp(() {
      config = const deepseek.DeepSeekConfig(
        apiKey: 'test-api-key',
        model: 'deepseek-chat',
        baseUrl: 'https://api.deepseek.com/v1/',
        maxTokens: 1000,
        temperature: 0.7,
      );
      provider = deepseek.DeepSeekProvider(config);
    });

    group('Provider Initialization', () {
      test('should initialize with valid config', () {
        expect(provider, isNotNull);
        expect(provider.config, equals(config));
        expect(provider.providerName, equals('DeepSeek'));
      });

      test('should initialize with reasoning model', () {
        final reasoningConfig = const deepseek.DeepSeekConfig(
          apiKey: 'test-api-key',
          model: 'deepseek-reasoner',
        );

        final reasoningProvider = deepseek.DeepSeekProvider(reasoningConfig);
        expect(reasoningProvider, isNotNull);
        expect(reasoningProvider.config.model, equals('deepseek-reasoner'));
      });
    });

    group('Capability Support', () {
      test('should support core capabilities', () {
        expect(provider.supports(LLMCapability.chat), isTrue);
        expect(provider.supports(LLMCapability.streaming), isTrue);
        expect(provider.supports(LLMCapability.toolCalling), isTrue);
        expect(provider.supports(LLMCapability.modelListing), isTrue);
      });

      test('should support reasoning for reasoning models', () {
        final reasoningConfig = config.copyWith(model: 'deepseek-reasoner');
        final reasoningProvider = deepseek.DeepSeekProvider(reasoningConfig);

        expect(reasoningProvider.supports(LLMCapability.reasoning), isTrue);
      });

      test('should not support reasoning for non-reasoning models', () {
        expect(provider.supports(LLMCapability.reasoning), isFalse);
      });

      test('should not support unsupported capabilities', () {
        expect(provider.supports(LLMCapability.embedding), isFalse);
        expect(provider.supports(LLMCapability.imageGeneration), isFalse);
        expect(provider.supports(LLMCapability.textToSpeech), isFalse);
        expect(provider.supports(LLMCapability.fileManagement), isFalse);
        expect(provider.supports(LLMCapability.vision), isFalse);
      });

      test('should return correct supported capabilities set', () {
        final capabilities = provider.supportedCapabilities;

        expect(capabilities, contains(LLMCapability.chat));
        expect(capabilities, contains(LLMCapability.streaming));
        expect(capabilities, contains(LLMCapability.toolCalling));
        expect(capabilities, contains(LLMCapability.modelListing));
        expect(capabilities, isNot(contains(LLMCapability.reasoning)));
      });

      test('should include reasoning in capabilities for reasoning models', () {
        final reasoningConfig = config.copyWith(model: 'deepseek-reasoner');
        final reasoningProvider = deepseek.DeepSeekProvider(reasoningConfig);

        final capabilities = reasoningProvider.supportedCapabilities;
        expect(capabilities, contains(LLMCapability.reasoning));
      });
    });

    group('Interface Implementation', () {
      test('should implement ChatCapability', () {
        expect(provider, isA<ChatCapability>());
      });

      test('should implement ModelListingCapability', () {
        expect(provider, isA<ModelListingCapability>());
      });

      test('should implement ProviderCapabilities', () {
        expect(provider, isA<ProviderCapabilities>());
      });

      test('should not implement unsupported capabilities', () {
        expect(provider, isNot(isA<FileManagementCapability>()));
        expect(provider, isNot(isA<EmbeddingCapability>()));
        expect(provider, isNot(isA<ImageGenerationCapability>()));
      });
    });

    group('Chat Methods', () {
      test('should have chat method', () {
        expect(provider.chat, isA<Function>());
      });

      test('should have chatStream method', () {
        expect(provider.chatStream, isA<Function>());
      });
    });

    group('Model Listing Methods', () {
      test('should have models method', () {
        expect(provider.models, isA<Function>());
      });
    });

    group('Configuration Properties', () {
      test('should expose configuration', () {
        expect(provider.config, isNotNull);
        expect(provider.config.apiKey, equals('test-api-key'));
        expect(provider.config.model, equals('deepseek-chat'));
        expect(provider.config.baseUrl, equals('https://api.deepseek.com/v1/'));
      });

      test('should handle custom configuration', () {
        final customConfig = const deepseek.DeepSeekConfig(
          apiKey: 'custom-key',
          model: 'deepseek-reasoner',
          baseUrl: 'https://custom.api.com',
          temperature: 0.9,
          maxTokens: 2000,
          topP: 0.8,
          topK: 40,
        );

        final customProvider = deepseek.DeepSeekProvider(customConfig);

        expect(customProvider.config.apiKey, equals('custom-key'));
        expect(customProvider.config.model, equals('deepseek-reasoner'));
        expect(customProvider.config.baseUrl, equals('https://custom.api.com'));
        expect(customProvider.config.temperature, equals(0.9));
        expect(customProvider.config.maxTokens, equals(2000));
        expect(customProvider.config.topP, equals(0.8));
        expect(customProvider.config.topK, equals(40));
      });
    });

    group('Provider Factory Integration', () {
      test('should work with factory pattern', () {
        final llmConfig = LLMConfig(
          apiKey: 'test-key',
          baseUrl: 'https://api.deepseek.com/v1/',
          model: 'deepseek-chat',
          temperature: 0.7,
        );

        final deepseekConfig = deepseek.DeepSeekConfig.fromLLMConfig(llmConfig);
        final factoryProvider = deepseek.DeepSeekProvider(deepseekConfig);

        expect(factoryProvider, isA<deepseek.DeepSeekProvider>());
        expect(factoryProvider.config.apiKey, equals('test-key'));
        expect(factoryProvider.config.model, equals('deepseek-chat'));
        expect(factoryProvider.config.temperature, equals(0.7));
      });

      test('should handle extensions from LLMConfig', () {
        final llmConfig = LLMConfig(
          apiKey: 'test-key',
          baseUrl: 'https://api.deepseek.com/v1/',
          model: 'deepseek-chat',
          extensions: {
            'logprobs': true,
            'top_logprobs': 5,
            'frequency_penalty': 0.1,
            'presence_penalty': 0.2,
          },
        );

        final deepseekConfig = deepseek.DeepSeekConfig.fromLLMConfig(llmConfig);

        expect(deepseekConfig.logprobs, isTrue);
        expect(deepseekConfig.topLogprobs, equals(5));
        expect(deepseekConfig.frequencyPenalty, equals(0.1));
        expect(deepseekConfig.presencePenalty, equals(0.2));
      });
    });

    // Provider-level convenience constructors were intentionally removed
    // during the multi-package refactor. Prefer:
    // - `DeepSeekProvider(DeepSeekConfig(...))` for low-level provider access, or
    // - `createDeepSeek(...).chat(modelId)` for model-centric usage.
  });
}
