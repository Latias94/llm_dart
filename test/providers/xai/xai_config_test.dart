import 'package:test/test.dart';
import 'package:llm_dart/llm_dart.dart';

void main() {
  group('XAIConfig Tests', () {
    group('Basic Configuration', () {
      test('should create config with required parameters', () {
        const config = XAIConfig(
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
        final searchParams = SearchParameters.webSearch(maxResults: 5);
        final config = XAIConfig(
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
      test('should not maintain a model capability matrix (reasoning)', () {
        const config = XAIConfig(
          apiKey: 'test-key',
          model: 'grok-3',
        );

        expect(config.supportsReasoning, isTrue);
      });

      test('should not maintain a model capability matrix (vision)', () {
        const config = XAIConfig(
          apiKey: 'test-key',
          model: 'grok-vision-beta',
        );

        expect(config.supportsVision, isTrue);
      });

      test('should report vision optimistically for regular models', () {
        const config = XAIConfig(
          apiKey: 'test-key',
          model: 'grok-3',
        );

        expect(config.supportsVision, isTrue);
      });

      test('should not maintain a model capability matrix (tool calling)', () {
        const config = XAIConfig(
          apiKey: 'test-key',
          model: 'grok-3',
        );

        expect(config.supportsToolCalling, isTrue);
      });

      test('should not maintain a model capability matrix (search)', () {
        const config = XAIConfig(
          apiKey: 'test-key',
          model: 'grok-3',
        );

        expect(config.supportsSearch, isTrue);
      });

      test('should report embeddings optimistically for embedding models', () {
        const config = XAIConfig(
          apiKey: 'test-key',
          model: 'text-embedding-ada-002',
        );

        expect(config.supportsEmbeddings, isTrue);
      });

      test('should report embeddings optimistically for chat models', () {
        const config = XAIConfig(
          apiKey: 'test-key',
          model: 'grok-3',
        );

        expect(config.supportsEmbeddings, isTrue);
      });
    });

    group('Live Search Configuration', () {
      test('should detect live search when explicitly enabled', () {
        const config = XAIConfig(
          apiKey: 'test-key',
          liveSearch: true,
        );

        expect(config.isLiveSearchEnabled, isTrue);
      });

      test('should detect live search when search parameters are provided', () {
        final searchParams = SearchParameters.webSearch();
        final config = XAIConfig(
          apiKey: 'test-key',
          searchParameters: searchParams,
        );

        expect(config.isLiveSearchEnabled, isTrue);
      });

      test('should not detect live search when disabled', () {
        const config = XAIConfig(
          apiKey: 'test-key',
          liveSearch: false,
        );

        expect(config.isLiveSearchEnabled, isFalse);
      });
    });

    group('Model Family Detection', () {
      test('should not maintain a model family matrix', () {
        const config = XAIConfig(
          apiKey: 'test-key',
          model: 'grok-3',
        );

        expect(config.modelFamily, equals('xAI'));
      });

      test('should not maintain a model family matrix (embedding model)', () {
        const config = XAIConfig(
          apiKey: 'test-key',
          model: 'text-embedding-ada-002',
        );

        expect(config.modelFamily, equals('xAI'));
      });

      test('should not maintain a model family matrix (unknown model)', () {
        const config = XAIConfig(
          apiKey: 'test-key',
          model: 'unknown-model',
        );

        expect(config.modelFamily, equals('xAI'));
      });
    });

    group('Configuration Copying', () {
      test('should copy config with new values', () {
        const original = XAIConfig(
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
        final searchParams = SearchParameters.webSearch();
        final original = XAIConfig(
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
          providerOptions: const {
            'xai': {
              'liveSearch': true,
              'embeddingEncodingFormat': 'float',
              'embeddingDimensions': 1536,
            },
          },
        );

        final xaiConfig = XAIConfig.fromLLMConfig(llmConfig);

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

      test('should preserve transportOptions via original config', () {
        final llmConfig = LLMConfig(
          apiKey: 'test-key',
          baseUrl: 'https://api.x.ai/v1/',
          model: 'grok-3',
          transportOptions: const {
            'customHeaders': {'X-Test': 'customValue'},
          },
        );

        final xaiConfig = XAIConfig.fromLLMConfig(llmConfig);

        expect(xaiConfig.originalConfig, isNotNull);
        expect(
          xaiConfig.originalConfig!
              .getTransportOption<Map<String, String>>('customHeaders'),
          equals({'X-Test': 'customValue'}),
        );
      });

      test('should enable live search from providerOptions.webSearchEnabled',
          () {
        final llmConfig = LLMConfig(
          apiKey: 'test-key',
          baseUrl: 'https://api.x.ai/v1/',
          model: 'grok-3',
          providerOptions: const {
            'xai': {
              'webSearchEnabled': true,
            },
          },
        );

        final xaiConfig = XAIConfig.fromLLMConfig(llmConfig);

        expect(xaiConfig.liveSearch, isTrue);
        expect(xaiConfig.searchParameters, isNotNull);
        expect(xaiConfig.isLiveSearchEnabled, isTrue);
      });

      test('should convert providerOptions.webSearch to searchParameters', () {
        final llmConfig = LLMConfig(
          apiKey: 'test-key',
          baseUrl: 'https://api.x.ai/v1/',
          model: 'grok-3',
          providerOptions: const {
            'xai': {
              'webSearch': {
                'enabled': true,
                'mode': 'always',
                'max_results': 7,
                'blocked_domains': ['spam.com'],
                'search_type': 'news',
              },
            },
          },
        );

        final xaiConfig = XAIConfig.fromLLMConfig(llmConfig);

        expect(xaiConfig.liveSearch, isTrue);
        expect(xaiConfig.searchParameters, isNotNull);
        expect(xaiConfig.searchParameters!.mode, equals('always'));
        expect(xaiConfig.searchParameters!.maxSearchResults, equals(7));
        expect(xaiConfig.searchParameters!.sources, isNotNull);
        expect(xaiConfig.searchParameters!.sources, hasLength(1));
        expect(xaiConfig.searchParameters!.sources!.single.sourceType,
            equals('news'));
        expect(
          xaiConfig.searchParameters!.sources!.single.excludedWebsites,
          contains('spam.com'),
        );
      });

      test('should parse providerOptions.searchParameters JSON', () {
        final llmConfig = LLMConfig(
          apiKey: 'test-key',
          baseUrl: 'https://api.x.ai/v1/',
          model: 'grok-3',
          providerOptions: const {
            'xai': {
              'liveSearch': true,
              'searchParameters': {
                'mode': 'auto',
                'max_search_results': 5,
                'sources': [
                  {
                    'type': 'web',
                    'excluded_websites': ['example.com']
                  }
                ],
              },
            },
          },
        );

        final xaiConfig = XAIConfig.fromLLMConfig(llmConfig);

        expect(xaiConfig.liveSearch, isTrue);
        expect(xaiConfig.searchParameters, isNotNull);
        expect(xaiConfig.searchParameters!.mode, equals('auto'));
        expect(xaiConfig.searchParameters!.maxSearchResults, equals(5));
        expect(xaiConfig.searchParameters!.sources, isNotNull);
        expect(xaiConfig.searchParameters!.sources, hasLength(1));
        expect(
          xaiConfig.searchParameters!.sources!.single.sourceType,
          equals('web'),
        );
        expect(
          xaiConfig.searchParameters!.sources!.single.excludedWebsites,
          contains('example.com'),
        );
      });
    });
  });
}
