import 'package:test/test.dart';
import 'package:llm_dart/llm_dart.dart';

void main() {
  group('GroqConfig Tests', () {
    group('Basic Configuration', () {
      test('should create config with required parameters', () {
        const config = GroqConfig(
          apiKey: 'test-api-key',
        );

        expect(config.apiKey, equals('test-api-key'));
        expect(config.baseUrl, equals('https://api.groq.com/openai/v1/'));
        expect(config.model, equals('llama-3.3-70b-versatile'));
        expect(config.maxTokens, isNull);
        expect(config.temperature, isNull);
        expect(config.systemPrompt, isNull);
        expect(config.timeout, isNull);
        expect(config.topP, isNull);
        expect(config.topK, isNull);
        expect(config.tools, isNull);
        expect(config.toolChoice, isNull);
      });

      test('should create config with all parameters', () {
        const config = GroqConfig(
          apiKey: 'test-api-key',
          baseUrl: 'https://custom.api.com',
          model: 'llama-3.1-8b-instant',
          maxTokens: 2000,
          temperature: 0.8,
          systemPrompt: 'You are a helpful assistant',
          timeout: Duration(seconds: 30),
          topP: 0.9,
          topK: 50,
          tools: [],
          toolChoice: AutoToolChoice(),
        );

        expect(config.apiKey, equals('test-api-key'));
        expect(config.baseUrl, equals('https://custom.api.com'));
        expect(config.model, equals('llama-3.1-8b-instant'));
        expect(config.maxTokens, equals(2000));
        expect(config.temperature, equals(0.8));
        expect(config.systemPrompt, equals('You are a helpful assistant'));
        expect(config.timeout, equals(const Duration(seconds: 30)));
        expect(config.topP, equals(0.9));
        expect(config.topK, equals(50));
        expect(config.tools, equals([]));
        expect(config.toolChoice, isA<ToolChoice>());
      });
    });

    group('Model Support Detection', () {
      test('should detect vision support for vision models', () {
        const config = GroqConfig(
          apiKey: 'test-key',
          model: 'llama-3.2-11b-vision-preview',
        );

        expect(config.supportsVision, isTrue);
      });

      test('should detect vision support for llava models', () {
        const config = GroqConfig(
          apiKey: 'test-key',
          model: 'llava-v1.5-7b-4096-preview',
        );

        expect(config.supportsVision, isTrue);
      });

      test('should not support vision for regular models', () {
        const config = GroqConfig(
          apiKey: 'test-key',
          model: 'llama-3.3-70b-versatile',
        );

        expect(config.supportsVision, isFalse);
      });

      test('should support tool calling for most models', () {
        const config = GroqConfig(
          apiKey: 'test-key',
          model: 'llama-3.3-70b-versatile',
        );

        expect(config.supportsToolCalling, isTrue);
      });

      test('should not support tool calling for base models', () {
        const config = GroqConfig(
          apiKey: 'test-key',
          model: 'llama-3.1-8b-base',
        );

        expect(config.supportsToolCalling, isFalse);
      });

      test('should not support reasoning', () {
        const config = GroqConfig(
          apiKey: 'test-key',
          model: 'llama-3.3-70b-versatile',
        );

        expect(config.supportsReasoning, isFalse);
      });

      test('should be speed optimized', () {
        const config = GroqConfig(
          apiKey: 'test-key',
          model: 'llama-3.3-70b-versatile',
        );

        expect(config.isSpeedOptimized, isTrue);
      });
    });

    group('Model Family Detection', () {
      test('should detect Llama family', () {
        const config = GroqConfig(
          apiKey: 'test-key',
          model: 'llama-3.3-70b-versatile',
        );

        expect(config.modelFamily, equals('Llama'));
      });

      test('should detect Mixtral family', () {
        const config = GroqConfig(
          apiKey: 'test-key',
          model: 'mixtral-8x7b-32768',
        );

        expect(config.modelFamily, equals('Mixtral'));
      });

      test('should detect Gemma family', () {
        const config = GroqConfig(
          apiKey: 'test-key',
          model: 'gemma-7b-it',
        );

        expect(config.modelFamily, equals('Gemma'));
      });

      test('should detect Whisper family', () {
        const config = GroqConfig(
          apiKey: 'test-key',
          model: 'whisper-large-v3',
        );

        expect(config.modelFamily, equals('Whisper'));
      });

      test('should return Unknown for unrecognized models', () {
        const config = GroqConfig(
          apiKey: 'test-key',
          model: 'unknown-model',
        );

        expect(config.modelFamily, equals('Unknown'));
      });
    });

    group('Configuration Copying', () {
      test('should copy config with new values', () {
        const original = GroqConfig(
          apiKey: 'original-key',
          model: 'llama-3.1-8b-instant',
          temperature: 0.5,
        );

        final copied = original.copyWith(
          apiKey: 'new-key',
          temperature: 0.8,
        );

        expect(copied.apiKey, equals('new-key'));
        expect(copied.model, equals('llama-3.1-8b-instant')); // Unchanged
        expect(copied.temperature, equals(0.8));
      });

      test('should preserve original values when not specified', () {
        const original = GroqConfig(
          apiKey: 'test-key',
          model: 'llama-3.3-70b-versatile',
          maxTokens: 1000,
          temperature: 0.7,
          topP: 0.9,
        );

        final copied = original.copyWith(temperature: 0.9);

        expect(copied.apiKey, equals('test-key'));
        expect(copied.model, equals('llama-3.3-70b-versatile'));
        expect(copied.maxTokens, equals(1000));
        expect(copied.topP, equals(0.9));
        expect(copied.temperature, equals(0.9));
      });
    });

    group('LLMConfig Integration', () {
      test('should create from LLMConfig', () {
        final llmConfig = LLMConfig(
          apiKey: 'test-key',
          baseUrl: 'https://api.groq.com/openai/v1/',
          model: 'llama-3.3-70b-versatile',
          maxTokens: 2000,
          temperature: 0.7,
          systemPrompt: 'You are helpful',
          timeout: const Duration(seconds: 30),
          topP: 0.9,
          topK: 50,
          tools: [],
          toolChoice: AutoToolChoice(),
        );

        final groqConfig = GroqConfig.fromLLMConfig(llmConfig);

        expect(groqConfig.apiKey, equals('test-key'));
        expect(groqConfig.baseUrl, equals('https://api.groq.com/openai/v1/'));
        expect(groqConfig.model, equals('llama-3.3-70b-versatile'));
        expect(groqConfig.maxTokens, equals(2000));
        expect(groqConfig.temperature, equals(0.7));
        expect(groqConfig.systemPrompt, equals('You are helpful'));
        expect(groqConfig.timeout, equals(const Duration(seconds: 30)));
        expect(groqConfig.topP, equals(0.9));
        expect(groqConfig.topK, equals(50));
        expect(groqConfig.tools, equals([]));
        expect(groqConfig.toolChoice, isA<ToolChoice>());
      });

      test('should access extensions from original config', () {
        final llmConfig = LLMConfig(
          apiKey: 'test-key',
          baseUrl: 'https://api.groq.com/openai/v1/',
          model: 'llama-3.3-70b-versatile',
          extensions: {'customParam': 'customValue'},
        );

        final groqConfig = GroqConfig.fromLLMConfig(llmConfig);

        expect(groqConfig.getExtension<String>('customParam'),
            equals('customValue'));
      });
    });
  });
}
