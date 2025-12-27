import 'package:test/test.dart';
import 'package:llm_dart/llm_dart.dart';

void main() {
  group('OllamaConfig Tests', () {
    group('Basic Configuration', () {
      test('should create config with default parameters', () {
        const config = OllamaConfig();

        expect(config.baseUrl, equals('http://localhost:11434/'));
        expect(config.apiKey, isNull);
        expect(config.model, equals('llama3.2'));
        expect(config.maxTokens, isNull);
        expect(config.temperature, isNull);
        expect(config.systemPrompt, isNull);
        expect(config.timeout, isNull);
        expect(config.topP, isNull);
        expect(config.topK, isNull);
        expect(config.tools, isNull);
        expect(config.jsonSchema, isNull);
        expect(config.numCtx, isNull);
        expect(config.numGpu, isNull);
        expect(config.numThread, isNull);
        expect(config.numa, isNull);
        expect(config.numBatch, isNull);
        expect(config.keepAlive, isNull);
        expect(config.raw, isNull);
      });

      test('should create config with all parameters', () {
        const config = OllamaConfig(
          baseUrl: 'https://custom.ollama.com',
          apiKey: 'test-api-key',
          model: 'llama3.1:8b',
          maxTokens: 2000,
          temperature: 0.8,
          systemPrompt: 'You are a helpful assistant',
          timeout: Duration(seconds: 30),
          topP: 0.9,
          topK: 50,
          tools: [],
          numCtx: 4096,
          numGpu: 2,
          numThread: 8,
          numa: true,
          numBatch: 512,
          keepAlive: '5m',
          raw: false,
        );

        expect(config.baseUrl, equals('https://custom.ollama.com'));
        expect(config.apiKey, equals('test-api-key'));
        expect(config.model, equals('llama3.1:8b'));
        expect(config.maxTokens, equals(2000));
        expect(config.temperature, equals(0.8));
        expect(config.systemPrompt, equals('You are a helpful assistant'));
        expect(config.timeout, equals(const Duration(seconds: 30)));
        expect(config.topP, equals(0.9));
        expect(config.topK, equals(50));
        expect(config.tools, equals([]));
        expect(config.numCtx, equals(4096));
        expect(config.numGpu, equals(2));
        expect(config.numThread, equals(8));
        expect(config.numa, isTrue);
        expect(config.numBatch, equals(512));
        expect(config.keepAlive, equals('5m'));
        expect(config.raw, isFalse);
      });
    });

    group('Model Support Detection', () {
      test('should not maintain a model capability matrix', () {
        final configs = [
          const OllamaConfig(model: 'llava:7b'),
          const OllamaConfig(model: 'minicpm-v:8b'),
          const OllamaConfig(model: 'moondream:1.8b'),
          const OllamaConfig(model: 'llama3.2:3b'),
          const OllamaConfig(model: 'qwen2.5:7b'),
          const OllamaConfig(model: 'llama3-think:8b'),
          const OllamaConfig(model: 'mistral:7b'),
          const OllamaConfig(model: 'phi3:3.8b'),
          const OllamaConfig(model: 'nomic-embed-text:v1.5'),
          const OllamaConfig(model: 'codellama:7b'),
          const OllamaConfig(model: 'unknown-model:1b'),
        ];

        for (final config in configs) {
          expect(config.supportsVision, isTrue);
          expect(config.supportsReasoning, isTrue);
          expect(config.supportsToolCalling, isTrue);
          expect(config.supportsEmbeddings, isTrue);
          expect(config.supportsCodeGeneration, isTrue);
        }
      });
    });

    group('Local Deployment Detection', () {
      test('should detect localhost as local', () {
        const config = OllamaConfig(baseUrl: 'http://localhost:11434');
        expect(config.isLocal, isTrue);
      });

      test('should detect 127.0.0.1 as local', () {
        const config = OllamaConfig(baseUrl: 'http://127.0.0.1:11434');
        expect(config.isLocal, isTrue);
      });

      test('should detect 0.0.0.0 as local', () {
        const config = OllamaConfig(baseUrl: 'http://0.0.0.0:11434');
        expect(config.isLocal, isTrue);
      });

      test('should not detect remote URLs as local', () {
        const config = OllamaConfig(baseUrl: 'https://api.ollama.com');
        expect(config.isLocal, isFalse);
      });
    });

    group('Model Family Detection', () {
      test('should not maintain a model family matrix', () {
        final models = [
          'llama3.2:3b',
          'mistral:7b',
          'qwen2:7b',
          'phi3:3.8b',
          'gemma2:9b',
          'codellama:7b',
          'llava:7b',
          'unknown-model:1b',
        ];

        for (final model in models) {
          final config = OllamaConfig(model: model);
          expect(config.modelFamily, equals('Ollama'));
        }
      });
    });

    group('Configuration Copying', () {
      test('should copy config with new values', () {
        const original = OllamaConfig(
          model: 'llama3.2:3b',
          temperature: 0.5,
          numCtx: 2048,
        );

        final copied = original.copyWith(
          model: 'llama3.1:8b',
          temperature: 0.8,
        );

        expect(copied.model, equals('llama3.1:8b'));
        expect(copied.temperature, equals(0.8));
        expect(copied.numCtx, equals(2048)); // Unchanged
      });

      test('should preserve original values when not specified', () {
        const original = OllamaConfig(
          baseUrl: 'http://localhost:11434',
          model: 'llama3.2:3b',
          maxTokens: 1000,
          temperature: 0.7,
          numCtx: 4096,
          numGpu: 1,
          keepAlive: '5m',
        );

        final copied = original.copyWith(temperature: 0.9);

        expect(copied.baseUrl, equals('http://localhost:11434'));
        expect(copied.model, equals('llama3.2:3b'));
        expect(copied.maxTokens, equals(1000));
        expect(copied.numCtx, equals(4096));
        expect(copied.numGpu, equals(1));
        expect(copied.keepAlive, equals('5m'));
        expect(copied.temperature, equals(0.9));
      });
    });

    group('LLMConfig Integration', () {
      test('should create from LLMConfig', () {
        final llmConfig = LLMConfig(
          apiKey: 'test-key',
          baseUrl: 'http://localhost:11434',
          model: 'llama3.1:8b',
          maxTokens: 2000,
          temperature: 0.7,
          systemPrompt: 'You are helpful',
          timeout: const Duration(seconds: 30),
          topP: 0.9,
          topK: 50,
          tools: [],
          providerOptions: const {
            'ollama': {
              'numCtx': 4096,
              'numGpu': 2,
              'numThread': 8,
              'numa': true,
              'numBatch': 512,
              'keepAlive': '10m',
              'raw': false,
            },
          },
        );

        final ollamaConfig = OllamaConfig.fromLLMConfig(llmConfig);

        expect(ollamaConfig.apiKey, equals('test-key'));
        expect(ollamaConfig.baseUrl, equals('http://localhost:11434'));
        expect(ollamaConfig.model, equals('llama3.1:8b'));
        expect(ollamaConfig.maxTokens, equals(2000));
        expect(ollamaConfig.temperature, equals(0.7));
        expect(ollamaConfig.systemPrompt, equals('You are helpful'));
        expect(ollamaConfig.timeout, equals(const Duration(seconds: 30)));
        expect(ollamaConfig.topP, equals(0.9));
        expect(ollamaConfig.topK, equals(50));
        expect(ollamaConfig.tools, equals([]));
        expect(ollamaConfig.numCtx, equals(4096));
        expect(ollamaConfig.numGpu, equals(2));
        expect(ollamaConfig.numThread, equals(8));
        expect(ollamaConfig.numa, isTrue);
        expect(ollamaConfig.numBatch, equals(512));
        expect(ollamaConfig.keepAlive, equals('10m'));
        expect(ollamaConfig.raw, isFalse);
      });

      test('should preserve transportOptions via original config', () {
        final llmConfig = LLMConfig(
          baseUrl: 'http://localhost:11434',
          model: 'llama3.2:3b',
          transportOptions: const {
            'customHeaders': {'X-Test': 'customValue'},
          },
        );

        final ollamaConfig = OllamaConfig.fromLLMConfig(llmConfig);

        expect(ollamaConfig.originalConfig, isNotNull);
        expect(
          ollamaConfig.originalConfig!
              .getTransportOption<Map<String, String>>('customHeaders'),
          equals({'X-Test': 'customValue'}),
        );
      });
    });
  });
}
