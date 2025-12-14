import 'package:test/test.dart';
import 'package:llm_dart/llm_dart.dart';

void main() {
  group('PhindConfig Tests', () {
    group('Basic Configuration', () {
      test('should create config with required parameters', () {
        const config = PhindConfig(
          apiKey: 'test-api-key',
        );

        expect(config.apiKey, equals('test-api-key'));
        expect(config.baseUrl, equals('https://api.phind.com/v1/'));
        expect(config.model, equals('Phind-70B'));
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
        const config = PhindConfig(
          apiKey: 'test-api-key',
          baseUrl: 'https://custom.api.com',
          model: 'Phind-34B',
          maxTokens: 2000,
          temperature: 0.8,
          systemPrompt: 'You are a coding assistant',
          timeout: Duration(seconds: 30),
          topP: 0.9,
          topK: 50,
          tools: [],
          toolChoice: AutoToolChoice(),
        );

        expect(config.apiKey, equals('test-api-key'));
        expect(config.baseUrl, equals('https://custom.api.com'));
        expect(config.model, equals('Phind-34B'));
        expect(config.maxTokens, equals(2000));
        expect(config.temperature, equals(0.8));
        expect(config.systemPrompt, equals('You are a coding assistant'));
        expect(config.timeout, equals(const Duration(seconds: 30)));
        expect(config.topP, equals(0.9));
        expect(config.topK, equals(50));
        expect(config.tools, equals([]));
        expect(config.toolChoice, isA<ToolChoice>());
      });
    });

    group('Capability Support', () {
      test('should support reasoning', () {
        const config = PhindConfig(apiKey: 'test-key');
        expect(config.supportsReasoning, isTrue);
      });

      test('should support code generation', () {
        const config = PhindConfig(apiKey: 'test-key');
        expect(config.supportsCodeGeneration, isTrue);
      });

      test('should not support tool calling', () {
        const config = PhindConfig(apiKey: 'test-key');
        expect(config.supportsToolCalling, isFalse);
      });

      test('should not support vision', () {
        const config = PhindConfig(apiKey: 'test-key');
        expect(config.supportsVision, isFalse);
      });
    });

    group('Model Family Detection', () {
      test('should detect Phind family', () {
        const config = PhindConfig(
          apiKey: 'test-key',
          model: 'Phind-70B',
        );

        expect(config.modelFamily, equals('Phind'));
      });

      test('should detect Phind family for different models', () {
        const config = PhindConfig(
          apiKey: 'test-key',
          model: 'Phind-34B-v2',
        );

        expect(config.modelFamily, equals('Phind'));
      });

      test('should return Unknown for unrecognized models', () {
        const config = PhindConfig(
          apiKey: 'test-key',
          model: 'unknown-model',
        );

        expect(config.modelFamily, equals('Unknown'));
      });
    });

    group('Configuration Copying', () {
      test('should copy config with new values', () {
        const original = PhindConfig(
          apiKey: 'original-key',
          model: 'Phind-70B',
          temperature: 0.5,
        );

        final copied = original.copyWith(
          apiKey: 'new-key',
          temperature: 0.8,
        );

        expect(copied.apiKey, equals('new-key'));
        expect(copied.model, equals('Phind-70B')); // Unchanged
        expect(copied.temperature, equals(0.8));
      });

      test('should preserve original values when not specified', () {
        const original = PhindConfig(
          apiKey: 'test-key',
          model: 'Phind-34B',
          maxTokens: 1000,
          temperature: 0.7,
          topP: 0.9,
        );

        final copied = original.copyWith(temperature: 0.9);

        expect(copied.apiKey, equals('test-key'));
        expect(copied.model, equals('Phind-34B'));
        expect(copied.maxTokens, equals(1000));
        expect(copied.topP, equals(0.9));
        expect(copied.temperature, equals(0.9));
      });
    });

    group('LLMConfig Integration', () {
      test('should create from LLMConfig', () {
        final llmConfig = LLMConfig(
          apiKey: 'test-key',
          baseUrl: 'https://api.phind.com/v1/',
          model: 'Phind-70B',
          maxTokens: 2000,
          temperature: 0.7,
          systemPrompt: 'You are a coding assistant',
          timeout: const Duration(seconds: 30),
          topP: 0.9,
          topK: 50,
          tools: [],
          toolChoice: AutoToolChoice(),
        );

        final phindConfig = PhindConfig.fromLLMConfig(llmConfig);

        expect(phindConfig.apiKey, equals('test-key'));
        expect(phindConfig.baseUrl, equals('https://api.phind.com/v1/'));
        expect(phindConfig.model, equals('Phind-70B'));
        expect(phindConfig.maxTokens, equals(2000));
        expect(phindConfig.temperature, equals(0.7));
        expect(phindConfig.systemPrompt, equals('You are a coding assistant'));
        expect(phindConfig.timeout, equals(const Duration(seconds: 30)));
        expect(phindConfig.topP, equals(0.9));
        expect(phindConfig.topK, equals(50));
        expect(phindConfig.tools, equals([]));
        expect(phindConfig.toolChoice, isA<ToolChoice>());
      });

      test('should access extensions from original config', () {
        final llmConfig = LLMConfig(
          apiKey: 'test-key',
          baseUrl: 'https://api.phind.com/v1/',
          model: 'Phind-70B',
          extensions: {'customParam': 'customValue'},
        );

        final phindConfig = PhindConfig.fromLLMConfig(llmConfig);

        expect(phindConfig.getExtension<String>('customParam'),
            equals('customValue'));
      });
    });

    group('Coding-Specific Features', () {
      test('should be optimized for coding tasks', () {
        const config = PhindConfig(apiKey: 'test-key');

        expect(config.supportsCodeGeneration, isTrue);
        expect(config.supportsReasoning, isTrue);
        expect(config.modelFamily, equals('Phind'));
      });

      test('should work with coding-focused system prompts', () {
        const config = PhindConfig(
          apiKey: 'test-key',
          systemPrompt: 'You are an expert programmer. Help with coding tasks.',
        );

        expect(config.systemPrompt, contains('programmer'));
        expect(config.supportsCodeGeneration, isTrue);
      });
    });
  });
}
