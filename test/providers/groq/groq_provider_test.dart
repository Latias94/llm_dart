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

      test('should report vision optimistically', () {
        expect(provider.supports(LLMCapability.vision), isTrue);
      });

      test('should report reasoning optimistically', () {
        expect(provider.supports(LLMCapability.reasoning), isTrue);
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
        expect(capabilities, contains(LLMCapability.vision));
        expect(capabilities, contains(LLMCapability.reasoning));
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

    group('Provider Properties', () {
      test('should return correct model family', () {
        expect(provider.modelFamily, equals('Groq'));
      });

      test('should be speed optimized', () {
        expect(provider.isSpeedOptimized, isTrue);
      });
    });

    group('Model-Specific Behavior', () {
      test('should not maintain a per-model capability matrix', () {
        final models = [
          'llama-3.1-8b-instant',
          'llama-3.1-8b-base',
          'llama-3.2-11b-vision-preview',
          'unknown-model',
        ];

        for (final model in models) {
          final p = GroqProvider(config.copyWith(model: model));
          expect(p.supports(LLMCapability.toolCalling), isTrue);
          expect(p.supports(LLMCapability.vision), isTrue);
          expect(p.supports(LLMCapability.reasoning), isTrue);
          expect(p.modelFamily, equals('Groq'));
        }
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
