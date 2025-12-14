import 'package:test/test.dart';
import 'package:llm_dart/llm_dart.dart';

void main() {
  group('GroqProvider Tests', () {
    late GroqProvider provider;
    late GroqConfig config;

    setUp(() {
      config = const GroqConfig(
        apiKey: 'test-api-key',
        baseUrl: 'https://api.groq.com/openai/v1/',
        model: 'llama-3.3-70b-versatile',
        maxTokens: 1000,
        temperature: 0.7,
      );
      provider = GroqProvider(config);
    });

    group('Provider Initialization', () {
      test('should initialize with valid config', () {
        expect(provider, isNotNull);
        expect(provider.config, equals(config));
        expect(provider.providerName, equals('Groq'));
      });

      test('should have provider name', () {
        expect(provider.providerName, equals('Groq'));
      });
    });

    group('Capability Support', () {
      test('should support core capabilities', () {
        expect(provider.supports(LLMCapability.chat), isTrue);
        expect(provider.supports(LLMCapability.streaming), isTrue);
        expect(provider.supports(LLMCapability.toolCalling), isTrue);
      });

      test('should support vision for vision models', () {
        final visionConfig =
            config.copyWith(model: 'llama-3.2-11b-vision-preview');
        final visionProvider = GroqProvider(visionConfig);

        expect(visionProvider.supports(LLMCapability.vision), isTrue);
      });

      test('should not support reasoning', () {
        expect(provider.supports(LLMCapability.reasoning), isFalse);
      });

      test('should not support unsupported capabilities', () {
        expect(provider.supports(LLMCapability.embedding), isFalse);
        expect(provider.supports(LLMCapability.imageGeneration), isFalse);
        expect(provider.supports(LLMCapability.textToSpeech), isFalse);
        expect(provider.supports(LLMCapability.speechToText), isFalse);
      });

      test('should return correct supported capabilities set', () {
        final capabilities = provider.supportedCapabilities;

        expect(capabilities, contains(LLMCapability.chat));
        expect(capabilities, contains(LLMCapability.streaming));
        expect(capabilities, contains(LLMCapability.toolCalling));
        expect(capabilities,
            isNot(contains(LLMCapability.vision))); // Regular model
        expect(capabilities, isNot(contains(LLMCapability.reasoning)));
      });

      test('should include vision capability for vision models', () {
        final visionConfig =
            config.copyWith(model: 'llava-v1.5-7b-4096-preview');
        final visionProvider = GroqProvider(visionConfig);
        final capabilities = visionProvider.supportedCapabilities;

        expect(capabilities, contains(LLMCapability.vision));
      });
    });

    group('Interface Implementation', () {
      test('should implement ChatCapability', () {
        expect(provider, isA<ChatCapability>());
      });

      test('should implement ProviderCapabilities', () {
        expect(provider, isA<ProviderCapabilities>());
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

    group('Provider Properties', () {
      test('should return correct model family', () {
        expect(provider.modelFamily, equals('Llama'));
      });

      test('should return correct model family for Mixtral', () {
        final mixtralConfig = config.copyWith(model: 'mixtral-8x7b-32768');
        final mixtralProvider = GroqProvider(mixtralConfig);

        expect(mixtralProvider.modelFamily, equals('Mixtral'));
      });

      test('should return correct model family for Gemma', () {
        final gemmaConfig = config.copyWith(model: 'gemma-7b-it');
        final gemmaProvider = GroqProvider(gemmaConfig);

        expect(gemmaProvider.modelFamily, equals('Gemma'));
      });

      test('should return correct model family for Whisper', () {
        final whisperConfig = config.copyWith(model: 'whisper-large-v3');
        final whisperProvider = GroqProvider(whisperConfig);

        expect(whisperProvider.modelFamily, equals('Whisper'));
      });

      test('should be speed optimized', () {
        expect(provider.isSpeedOptimized, isTrue);
      });
    });

    group('Model-Specific Behavior', () {
      test('should handle Llama models correctly', () {
        final llamaConfig = config.copyWith(model: 'llama-3.1-8b-instant');
        final llamaProvider = GroqProvider(llamaConfig);

        expect(llamaProvider.modelFamily, equals('Llama'));
        expect(llamaProvider.supports(LLMCapability.chat), isTrue);
        expect(llamaProvider.supports(LLMCapability.toolCalling), isTrue);
      });

      test('should handle base models correctly', () {
        final baseConfig = config.copyWith(model: 'llama-3.1-8b-base');
        final baseProvider = GroqProvider(baseConfig);

        expect(baseProvider.config.supportsToolCalling, isFalse);
      });

      test('should handle vision models correctly', () {
        final visionConfig =
            config.copyWith(model: 'llama-3.2-11b-vision-preview');
        final visionProvider = GroqProvider(visionConfig);

        expect(visionProvider.config.supportsVision, isTrue);
        expect(visionProvider.supports(LLMCapability.vision), isTrue);
      });
    });

    group('Configuration Integration', () {
      test('should use config properties correctly', () {
        expect(provider.config.apiKey, equals('test-api-key'));
        expect(provider.config.model, equals('llama-3.3-70b-versatile'));
        expect(provider.config.maxTokens, equals(1000));
        expect(provider.config.temperature, equals(0.7));
      });

      test('should handle tool calling configuration', () {
        final toolConfig = config.copyWith(
          tools: [],
          toolChoice: AutoToolChoice(),
        );
        final toolProvider = GroqProvider(toolConfig);

        expect(toolProvider.config.tools, equals([]));
        expect(toolProvider.config.toolChoice, isA<ToolChoice>());
      });
    });

    group('Error Handling', () {
      test('should handle invalid model gracefully during initialization', () {
        final invalidConfig = config.copyWith(model: 'invalid-model');

        // Should not throw during initialization
        expect(() => GroqProvider(invalidConfig), returnsNormally);
      });

      test('should handle empty model gracefully', () {
        final emptyModelConfig = config.copyWith(model: '');

        // Should not throw during initialization
        expect(() => GroqProvider(emptyModelConfig), returnsNormally);
      });
    });
  });
}
