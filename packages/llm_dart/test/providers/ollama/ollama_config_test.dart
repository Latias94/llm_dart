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
      test('should detect vision support for vision models', () {
        const config = OllamaConfig(model: 'llava:7b');
        expect(config.supportsVision, isTrue);
      });

      test('should detect vision support for minicpm models', () {
        const config = OllamaConfig(model: 'minicpm-v:8b');
        expect(config.supportsVision, isTrue);
      });

      test('should detect vision support for moondream models', () {
        const config = OllamaConfig(model: 'moondream:1.8b');
        expect(config.supportsVision, isTrue);
      });

      test('should not support vision for regular models', () {
        const config = OllamaConfig(model: 'llama3.2:3b');
        expect(config.supportsVision, isFalse);
      });

      test('should detect reasoning support for reasoning models', () {
        const config = OllamaConfig(model: 'qwen2.5:7b');
        expect(config.supportsReasoning, isTrue);
      });

      test('should detect reasoning support for thinking models', () {
        const config = OllamaConfig(model: 'llama3-think:8b');
        expect(config.supportsReasoning, isTrue);
      });

      test('should not support reasoning for regular models', () {
        const config = OllamaConfig(model: 'llama3.2:3b');
        expect(config.supportsReasoning, isFalse);
      });

      test('should detect tool calling support for llama3 models', () {
        const config = OllamaConfig(model: 'llama3.1:8b');
        expect(config.supportsToolCalling, isTrue);
      });

      test('should detect tool calling support for mistral models', () {
        const config = OllamaConfig(model: 'mistral:7b');
        expect(config.supportsToolCalling, isTrue);
      });

      test('should detect tool calling support for qwen models', () {
        const config = OllamaConfig(model: 'qwen2:7b');
        expect(config.supportsToolCalling, isTrue);
      });

      test('should detect tool calling support for phi3 models', () {
        const config = OllamaConfig(model: 'phi3:3.8b');
        expect(config.supportsToolCalling, isTrue);
      });

      test('should detect embeddings support for embedding models', () {
        const config = OllamaConfig(model: 'nomic-embed-text:v1.5');
        expect(config.supportsEmbeddings, isTrue);
      });

      test('should detect embeddings support for mxbai models', () {
        const config = OllamaConfig(model: 'mxbai-embed-large:v1');
        expect(config.supportsEmbeddings, isTrue);
      });

      test('should detect code generation support for codellama models', () {
        const config = OllamaConfig(model: 'codellama:7b');
        expect(config.supportsCodeGeneration, isTrue);
      });

      test('should detect code generation support for codegemma models', () {
        const config = OllamaConfig(model: 'codegemma:7b');
        expect(config.supportsCodeGeneration, isTrue);
      });

      test('should detect code generation support for starcoder models', () {
        const config = OllamaConfig(model: 'starcoder2:3b');
        expect(config.supportsCodeGeneration, isTrue);
      });

      test('should detect code generation support for deepseek-coder models',
          () {
        const config = OllamaConfig(model: 'deepseek-coder:6.7b');
        expect(config.supportsCodeGeneration, isTrue);
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
      test('should detect Llama family', () {
        const config = OllamaConfig(model: 'llama3.2:3b');
        expect(config.modelFamily, equals('Llama'));
      });

      test('should detect Mistral family', () {
        const config = OllamaConfig(model: 'mistral:7b');
        expect(config.modelFamily, equals('Mistral'));
      });

      test('should detect Qwen family', () {
        const config = OllamaConfig(model: 'qwen2:7b');
        expect(config.modelFamily, equals('Qwen'));
      });

      test('should detect Phi family', () {
        const config = OllamaConfig(model: 'phi3:3.8b');
        expect(config.modelFamily, equals('Phi'));
      });

      test('should detect Gemma family', () {
        const config = OllamaConfig(model: 'gemma2:9b');
        expect(config.modelFamily, equals('Gemma'));
      });

      test('should detect Code Llama family', () {
        const config = OllamaConfig(model: 'codellama:7b');
        expect(config.modelFamily, equals('Code Llama'));
      });

      test('should detect LLaVA family', () {
        const config = OllamaConfig(model: 'llava:7b');
        expect(config.modelFamily, equals('LLaVA'));
      });

      test('should return Unknown for unrecognized models', () {
        const config = OllamaConfig(model: 'unknown-model:1b');
        expect(config.modelFamily, equals('Unknown'));
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
          extensions: {
            'numCtx': 4096,
            'numGpu': 2,
            'numThread': 8,
            'numa': true,
            'numBatch': 512,
            'keepAlive': '10m',
            'raw': false,
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

      test('should access extensions from original config', () {
        final llmConfig = LLMConfig(
          baseUrl: 'http://localhost:11434',
          model: 'llama3.2:3b',
          extensions: {'customParam': 'customValue'},
        );

        final ollamaConfig = OllamaConfig.fromLLMConfig(llmConfig);

        expect(ollamaConfig.getExtension<String>('customParam'),
            equals('customValue'));
      });
    });
  });
}
