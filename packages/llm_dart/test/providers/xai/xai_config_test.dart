import 'package:test/test.dart';
import 'package:llm_dart/llm_dart.dart';
import 'package:llm_dart_xai/llm_dart_xai.dart' as xai;

void main() {
  group('XAIConfig Tests', () {
    group('Basic Configuration', () {
      test('should create config with required parameters', () {
        const config = xai.XAIConfig(
          apiKey: 'test-api-key',
        );

        expect(config.apiKey, equals('test-api-key'));
        expect(config.baseUrl, equals('https://api.x.ai/v1/'));
        expect(config.model, equals('grok-3'));
        expect(config.maxTokens, isNull);
        expect(config.temperature, isNull);
        expect(config.systemPrompt, isNull);
        expect(config.timeout, isNull);
        expect(config.topP, isNull);
        expect(config.topK, isNull);
        expect(config.tools, isNull);
        expect(config.toolChoice, isNull);
        expect(config.jsonSchema, isNull);
        expect(config.embeddingEncodingFormat, isNull);
        expect(config.embeddingDimensions, isNull);
        expect(config.searchParameters, isNull);
        expect(config.liveSearch, isNull);
      });

      test('should create config with all parameters', () {
        final searchParams = xai.SearchParameters.webSearch(maxResults: 5);
        final config = xai.XAIConfig(
          apiKey: 'test-api-key',
          baseUrl: 'https://custom.api.com',
          model: 'grok-vision-beta',
          maxTokens: 2000,
          temperature: 0.8,
          systemPrompt: 'You are a helpful assistant',
          timeout: Duration(seconds: 30),
          topP: 0.9,
          topK: 50,
          tools: [],
          toolChoice: AutoToolChoice(),
          embeddingEncodingFormat: 'float',
          embeddingDimensions: 1536,
          searchParameters: searchParams,
          liveSearch: true,
        );

        expect(config.apiKey, equals('test-api-key'));
        expect(config.baseUrl, equals('https://custom.api.com'));
        expect(config.model, equals('grok-vision-beta'));
        expect(config.maxTokens, equals(2000));
        expect(config.temperature, equals(0.8));
        expect(config.systemPrompt, equals('You are a helpful assistant'));
        expect(config.timeout, equals(const Duration(seconds: 30)));
        expect(config.topP, equals(0.9));
        expect(config.topK, equals(50));
        expect(config.tools, equals([]));
        expect(config.toolChoice, isA<ToolChoice>());
        expect(config.embeddingEncodingFormat, equals('float'));
        expect(config.embeddingDimensions, equals(1536));
        expect(config.searchParameters, equals(searchParams));
        expect(config.liveSearch, isTrue);
      });
    });

    group('Model Support Detection', () {
      test('should detect reasoning support for Grok models', () {
        const config = xai.XAIConfig(
          apiKey: 'test-key',
          model: 'grok-3',
        );

        expect(config.supportsReasoning, isTrue);
      });

      test('should detect vision support for vision models', () {
        const config = xai.XAIConfig(
          apiKey: 'test-key',
          model: 'grok-vision-beta',
        );

        expect(config.supportsVision, isTrue);
      });

      test('should not support vision for regular models', () {
        const config = xai.XAIConfig(
          apiKey: 'test-key',
          model: 'grok-3',
        );

        expect(config.supportsVision, isFalse);
      });

      test('should support tool calling', () {
        const config = xai.XAIConfig(
          apiKey: 'test-key',
          model: 'grok-3',
        );

        expect(config.supportsToolCalling, isTrue);
      });

      test('should detect search support for Grok models', () {
        const config = xai.XAIConfig(
          apiKey: 'test-key',
          model: 'grok-3',
        );

        expect(config.supportsSearch, isTrue);
      });

      test('should detect embeddings support for embedding models', () {
        const config = xai.XAIConfig(
          apiKey: 'test-key',
          model: 'text-embedding-ada-002',
        );

        expect(config.supportsEmbeddings, isTrue);
      });

      test('should not support embeddings for chat models', () {
        const config = xai.XAIConfig(
          apiKey: 'test-key',
          model: 'grok-3',
        );

        expect(config.supportsEmbeddings, isFalse);
      });
    });

    group('Live Search Configuration', () {
      test('should detect live search when explicitly enabled', () {
        const config = xai.XAIConfig(
          apiKey: 'test-key',
          liveSearch: true,
        );

        expect(config.isLiveSearchEnabled, isTrue);
      });

      test('should detect live search when search parameters are provided', () {
        final searchParams = xai.SearchParameters.webSearch();
        final config = xai.XAIConfig(
          apiKey: 'test-key',
          searchParameters: searchParams,
        );

        expect(config.isLiveSearchEnabled, isTrue);
      });

      test('should not detect live search when disabled', () {
        const config = xai.XAIConfig(
          apiKey: 'test-key',
          liveSearch: false,
        );

        expect(config.isLiveSearchEnabled, isFalse);
      });
    });

    group('Model Family Detection', () {
      test('should detect Grok family', () {
        const config = xai.XAIConfig(
          apiKey: 'test-key',
          model: 'grok-3',
        );

        expect(config.modelFamily, equals('Grok'));
      });

      test('should detect Embedding family', () {
        const config = xai.XAIConfig(
          apiKey: 'test-key',
          model: 'text-embedding-ada-002',
        );

        expect(config.modelFamily, equals('Embedding'));
      });

      test('should return Unknown for unrecognized models', () {
        const config = xai.XAIConfig(
          apiKey: 'test-key',
          model: 'unknown-model',
        );

        expect(config.modelFamily, equals('Unknown'));
      });
    });

    group('Configuration Copying', () {
      test('should copy config with new values', () {
        const original = xai.XAIConfig(
          apiKey: 'original-key',
          model: 'grok-3',
          temperature: 0.5,
          liveSearch: false,
        );

        final copied = original.copyWith(
          apiKey: 'new-key',
          temperature: 0.8,
          liveSearch: true,
        );

        expect(copied.apiKey, equals('new-key'));
        expect(copied.model, equals('grok-3')); // Unchanged
        expect(copied.temperature, equals(0.8));
        expect(copied.liveSearch, isTrue);
      });

      test('should preserve original values when not specified', () {
        final searchParams = xai.SearchParameters.webSearch();
        final original = xai.XAIConfig(
          apiKey: 'test-key',
          model: 'grok-vision-beta',
          maxTokens: 1000,
          temperature: 0.7,
          embeddingDimensions: 1536,
          searchParameters: searchParams,
          liveSearch: true,
        );

        final copied = original.copyWith(temperature: 0.9);

        expect(copied.apiKey, equals('test-key'));
        expect(copied.model, equals('grok-vision-beta'));
        expect(copied.maxTokens, equals(1000));
        expect(copied.embeddingDimensions, equals(1536));
        expect(copied.searchParameters, equals(searchParams));
        expect(copied.liveSearch, isTrue);
        expect(copied.temperature, equals(0.9));
      });
    });

    group('LLMConfig Integration', () {
      test('should create from LLMConfig', () {
        final llmConfig = LLMConfig(
          apiKey: 'test-key',
          baseUrl: 'https://api.x.ai/v1/',
          model: 'grok-3',
          maxTokens: 2000,
          temperature: 0.7,
          systemPrompt: 'You are helpful',
          timeout: const Duration(seconds: 30),
          topP: 0.9,
          topK: 50,
          tools: [],
          toolChoice: AutoToolChoice(),
          extensions: {
            LLMConfigKeys.embeddingEncodingFormat: 'float',
            LLMConfigKeys.embeddingDimensions: 1536,
            LLMConfigKeys.liveSearch: true,
          },
        );

        final xaiConfig = xai.XAIConfig.fromLLMConfig(llmConfig);

        expect(xaiConfig.apiKey, equals('test-key'));
        expect(xaiConfig.baseUrl, equals('https://api.x.ai/v1/'));
        expect(xaiConfig.model, equals('grok-3'));
        expect(xaiConfig.maxTokens, equals(2000));
        expect(xaiConfig.temperature, equals(0.7));
        expect(xaiConfig.systemPrompt, equals('You are helpful'));
        expect(xaiConfig.timeout, equals(const Duration(seconds: 30)));
        expect(xaiConfig.topP, equals(0.9));
        expect(xaiConfig.topK, equals(50));
        expect(xaiConfig.tools, equals([]));
        expect(xaiConfig.toolChoice, isA<ToolChoice>());
        expect(xaiConfig.embeddingEncodingFormat, equals('float'));
        expect(xaiConfig.embeddingDimensions, equals(1536));
        expect(xaiConfig.liveSearch, isTrue);
      });

      test('should access extensions from original config', () {
        final llmConfig = LLMConfig(
          apiKey: 'test-key',
          baseUrl: 'https://api.x.ai/v1/',
          model: 'grok-3',
          extensions: {'customParam': 'customValue'},
        );

        final xaiConfig = xai.XAIConfig.fromLLMConfig(llmConfig);

        expect(xaiConfig.getExtension<String>('customParam'),
            equals('customValue'));
      });

      test('should enable live search from webSearchEnabled flag', () {
        final llmConfig = LLMConfig(
          apiKey: 'test-key',
          baseUrl: 'https://api.x.ai/v1/',
          model: 'grok-3',
          extensions: {
            LLMConfigKeys.webSearchEnabled: true,
          },
        );

        final xaiConfig = xai.XAIConfig.fromLLMConfig(llmConfig);

        expect(xaiConfig.liveSearch, isTrue);
        expect(xaiConfig.searchParameters, isNotNull);
        expect(xaiConfig.isLiveSearchEnabled, isTrue);
      });
    });
  });
}
