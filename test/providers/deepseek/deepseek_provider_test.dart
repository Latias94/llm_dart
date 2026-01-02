import 'package:test/test.dart';
import 'package:llm_dart/llm_dart.dart';

void main() {
  group('DeepSeekProvider Tests', () {
    late DeepSeekProvider provider;
    late DeepSeekConfig config;

    setUp(() {
      config = const DeepSeekConfig(
        apiKey: 'test-api-key',
        model: 'deepseek-chat',
        baseUrl: 'https://api.deepseek.com/v1/',
        maxTokens: 1000,
        temperature: 0.7,
      );
      provider = DeepSeekProvider(config);
    });

    group('Provider Initialization', () {
      test('should initialize with valid config', () {
        expect(provider, isNotNull);
        expect(provider.config, equals(config));
        expect(provider.providerName, equals('DeepSeek'));
      });

      test('should initialize with reasoning model', () {
        final reasoningConfig = const DeepSeekConfig(
          apiKey: 'test-api-key',
          model: 'deepseek-reasoner',
        );

        final reasoningProvider = DeepSeekProvider(reasoningConfig);
        expect(reasoningProvider, isNotNull);
        expect(reasoningProvider.config.model, equals('deepseek-reasoner'));
      });
    });

    group('Capability Support', () {
      test('should support core capabilities', () {
        expect(provider.supports(LLMCapability.chat), isTrue);
        expect(provider.supports(LLMCapability.streaming), isTrue);
        expect(provider.supports(LLMCapability.toolCalling), isTrue);
      });

      test('should report reasoning optimistically', () {
        expect(provider.supports(LLMCapability.reasoning), isTrue);
      });

      test('should report vision optimistically', () {
        expect(provider.supports(LLMCapability.vision), isTrue);
      });

      test('should not support unsupported capabilities', () {
        expect(provider.supports(LLMCapability.embedding), isFalse);
        expect(provider.supports(LLMCapability.imageGeneration), isFalse);
        expect(provider.supports(LLMCapability.textToSpeech), isFalse);
        expect(provider.supports(LLMCapability.fileManagement), isFalse);
      });

      test('should return correct supported capabilities set', () {
        final capabilities = provider.supportedCapabilities;

        expect(capabilities, contains(LLMCapability.chat));
        expect(capabilities, contains(LLMCapability.streaming));
        expect(capabilities, contains(LLMCapability.toolCalling));
        expect(capabilities, contains(LLMCapability.reasoning));
        expect(capabilities, contains(LLMCapability.vision));
      });

      test('should not maintain a per-model capability matrix', () {
        final configs = [
          config.copyWith(model: 'deepseek-chat'),
          config.copyWith(model: 'deepseek-reasoner'),
          config.copyWith(model: 'unknown-model'),
        ];

        for (final cfg in configs) {
          final p = DeepSeekProvider(cfg);
          expect(p.supports(LLMCapability.reasoning), isTrue);
          expect(p.supports(LLMCapability.vision), isTrue);
        }
      });
    });

    group('Interface Implementation', () {
      test('should implement ChatCapability', () {
        expect(provider, isA<ChatCapability>());
      });

      test('should implement ProviderCapabilities', () {
        expect(provider, isA<ProviderCapabilities>());
      });

      test('should not implement unsupported capabilities', () {
        expect(provider, isNot(isA<EmbeddingCapability>()));
        expect(provider, isNot(isA<ImageGenerationCapability>()));
      });
    });

    group('Chat Methods', () {
      test('should have chat method', () {
        expect(provider.chat, isA<Function>());
      });

      test('should have chatWithTools method', () {
        expect(provider.chatWithTools, isA<Function>());
      });

      test('should have chatStream method', () {
        expect(provider.chatStream, isA<Function>());
      });

      test('should have memoryContents method', () {
        expect(provider.memoryContents, isA<Function>());
      });

      test('should have summarizeHistory method', () {
        expect(provider.summarizeHistory, isA<Function>());
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
        final customConfig = const DeepSeekConfig(
          apiKey: 'custom-key',
          model: 'deepseek-reasoner',
          baseUrl: 'https://custom.api.com',
          temperature: 0.9,
          maxTokens: 2000,
          topP: 0.8,
          topK: 40,
        );

        final customProvider = DeepSeekProvider(customConfig);

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

        final deepseekConfig = DeepSeekConfig.fromLLMConfig(llmConfig);
        final factoryProvider = DeepSeekProvider(deepseekConfig);

        expect(factoryProvider, isA<DeepSeekProvider>());
        expect(factoryProvider.config.apiKey, equals('test-key'));
        expect(factoryProvider.config.model, equals('deepseek-chat'));
        expect(factoryProvider.config.temperature, equals(0.7));
      });

      test('should handle provider options from LLMConfig', () {
        final llmConfig = LLMConfig(
          apiKey: 'test-key',
          baseUrl: 'https://api.deepseek.com/v1/',
          model: 'deepseek-chat',
          providerOptions: const {
            'deepseek': {
              'logprobs': true,
              'topLogprobs': 5,
              'frequencyPenalty': 0.1,
              'presencePenalty': 0.2,
            },
          },
        );

        final deepseekConfig = DeepSeekConfig.fromLLMConfig(llmConfig);

        expect(deepseekConfig.logprobs, isTrue);
        expect(deepseekConfig.topLogprobs, equals(5));
        expect(deepseekConfig.frequencyPenalty, equals(0.1));
        expect(deepseekConfig.presencePenalty, equals(0.2));
      });
    });

    group('Helper Functions', () {
      test('createDeepSeekProvider should work', () {
        final helperProvider = createDeepSeekProvider(
          apiKey: 'helper-key',
          model: 'deepseek-chat',
          temperature: 0.8,
        );

        expect(helperProvider, isA<DeepSeekProvider>());
        expect(helperProvider.config.apiKey, equals('helper-key'));
        expect(helperProvider.config.model, equals('deepseek-chat'));
        expect(helperProvider.config.temperature, equals(0.8));
      });

      test('createDeepSeekProvider should support reasoning model', () {
        final reasoningProvider = createDeepSeekProvider(
          apiKey: 'reasoning-key',
          model: 'deepseek-reasoner',
          systemPrompt: 'Think step by step',
        );

        expect(reasoningProvider, isA<DeepSeekProvider>());
        expect(reasoningProvider.config.apiKey, equals('reasoning-key'));
        expect(reasoningProvider.config.model, equals('deepseek-reasoner'));
        expect(reasoningProvider.config.systemPrompt,
            equals('Think step by step'));
        expect(reasoningProvider.supports(LLMCapability.reasoning), isTrue);
      });
    });
  });
}
