import 'package:test/test.dart';
import 'package:llm_dart/llm_dart.dart';
import 'package:llm_dart_ollama/testing.dart';

void main() {
  group('OllamaThinking', () {
    test('OllamaConfig should support thinking configuration', () {
      final config = OllamaConfig(
        model: 'gpt-oss:latest',
        reasoning: true,
      );

      expect(config.reasoning, isTrue);
      expect(config.supportsReasoning, isTrue);
    });

    test('OllamaConfig copyWith should preserve thinking setting', () {
      final originalConfig = OllamaConfig(
        model: 'gpt-oss:latest',
        reasoning: true,
      );

      final copiedConfig = originalConfig.copyWith(temperature: 0.8);

      expect(copiedConfig.reasoning, isTrue);
      expect(copiedConfig.temperature, equals(0.8));
    });

    test('OllamaConfig should recognize reasoning models', () {
      final configs = [
        OllamaConfig(model: 'gpt-oss:latest'),
        OllamaConfig(model: 'deepseek-r1:latest'),
        OllamaConfig(model: 'qwen2.5-reasoning'),
        OllamaConfig(model: 'thinking-model'),
      ];

      for (final config in configs) {
        expect(config.supportsReasoning, isTrue,
            reason: 'Model ${config.model} should support reasoning');
      }
    });

    test('OllamaConfig should not recognize non-reasoning models', () {
      final configs = [
        OllamaConfig(model: 'llama3.2'),
        OllamaConfig(model: 'mistral'),
        OllamaConfig(model: 'phi3'),
      ];

      for (final config in configs) {
        expect(config.supportsReasoning, isFalse,
            reason: 'Model ${config.model} should not support reasoning');
      }
    });

    // Provider-level convenience constructors were removed during the
    // multi-package refactor. Use `OllamaProvider(OllamaConfig(...))`
    // or the `ai().ollama()` builder shortcuts instead.

    test('OllamaConfig.fromLLMConfig should handle reasoning extension', () {
      final llmConfig = LLMConfig(
        apiKey: 'test',
        baseUrl: 'http://localhost:11434',
        model: 'gpt-oss:latest',
        extensions: {LLMConfigKeys.reasoning: true},
      );

      final ollamaConfig = OllamaConfig.fromLLMConfig(llmConfig);

      expect(ollamaConfig.reasoning, isTrue);
    });

    test('OllamaConfig default thinking should be null', () {
      final config = OllamaConfig(
        model: 'test-model',
      );

      expect(config.reasoning, isNull);
    });

    test('Builder reasoning method should work end-to-end', () async {
      final provider = await ai()
          .ollama()
          .baseUrl('http://localhost:11434')
          .model('gpt-oss:latest')
          .reasoning(true)
          .build();

      expect(provider, isA<OllamaProvider>());

      final ollamaProvider = provider as OllamaProvider;
      final config = ollamaProvider.config;
      expect(config.reasoning, isTrue);
    });

    test('OllamaBuilder reasoning method should work end-to-end', () async {
      final provider = await ai()
          .ollama((builder) => builder.reasoning(true).keepAlive('5m'))
          .baseUrl('http://localhost:11434')
          .model('gpt-oss:latest')
          .build();

      expect(provider, isA<OllamaProvider>());

      final ollamaProvider = provider as OllamaProvider;
      final config = ollamaProvider.config;
      expect(config.reasoning, isTrue);
    });

    test('OllamaChatResponse should handle thinking content in message', () {
      final mockResponse = {
        'message': {
          'role': 'assistant',
          'content': 'The answer is 42.',
          'thinking': 'Let me think about this step by step...',
        },
        'done': true,
      };

      final response = OllamaChatResponse(mockResponse);

      expect(
          response.thinking, equals('Let me think about this step by step...'));
      expect(response.text, equals('The answer is 42.'));
    });

    test('OllamaChatResponse should handle thinking content in root', () {
      final mockResponse = {
        'thinking': 'This is my thinking process...',
        'response': 'The final answer.',
        'done': true,
      };

      final response = OllamaChatResponse(mockResponse);

      expect(response.thinking, equals('This is my thinking process...'));
    });

    test('OllamaChatResponse should return null when no thinking content', () {
      final mockResponse = {
        'message': {
          'role': 'assistant',
          'content': 'Just a regular response.',
        },
        'done': true,
      };

      final response = OllamaChatResponse(mockResponse);

      expect(response.thinking, isNull);
      expect(response.text, equals('Just a regular response.'));
    });

    test('OllamaChatResponse toString should include thinking content', () {
      final mockResponse = {
        'message': {
          'role': 'assistant',
          'content': 'The answer is 42.',
          'thinking': 'Let me calculate...',
        },
        'done': true,
      };

      final response = OllamaChatResponse(mockResponse);
      final stringOutput = response.toString();

      expect(stringOutput, contains('Thinking: Let me calculate...'));
      expect(stringOutput, contains('The answer is 42.'));
    });

    test('OllamaChatResponse toString should work without thinking', () {
      final mockResponse = {
        'message': {
          'role': 'assistant',
          'content': 'Just a response.',
        },
        'done': true,
      };

      final response = OllamaChatResponse(mockResponse);
      final stringOutput = response.toString();

      expect(stringOutput, equals('Just a response.'));
      expect(stringOutput, isNot(contains('Thinking:')));
    });

    test('OllamaChatResponse toString should handle empty response', () {
      final mockResponse = <String, dynamic>{
        'done': true,
      };

      final response = OllamaChatResponse(mockResponse);
      final stringOutput = response.toString();

      expect(stringOutput, equals(''));
    });

    test('OllamaChatResponse should map usage and metadata from native fields',
        () {
      final mockResponse = <String, dynamic>{
        'model': 'llama3.2',
        'response': 'Answer',
        'prompt_eval_count': 10,
        'eval_count': 20,
        'total_duration': 1000000000,
        'load_duration': 1000000,
        'context': [1, 2, 3],
        'done_reason': 'stop',
      };

      final response = OllamaChatResponse(mockResponse);

      final usage = response.usage;
      expect(usage, isNotNull);
      expect(usage!.promptTokens, equals(10));
      expect(usage.completionTokens, equals(20));
      expect(usage.totalTokens, equals(30));

      final metadata = response.metadata;
      expect(metadata, isNotNull);
      expect(metadata!['provider'], equals('ollama'));
      expect(metadata['model'], equals('llama3.2'));
      expect(metadata['doneReason'], equals('stop'));
      expect(metadata['hasContext'], isTrue);
      expect(metadata['totalDuration'], equals(1000000000));
      expect(metadata['loadDuration'], equals(1000000));
      expect(metadata['promptEvalCount'], equals(10));
      expect(metadata['evalCount'], equals(20));
    });
  });
}
