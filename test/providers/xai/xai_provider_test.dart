import 'package:test/test.dart';
import 'package:llm_dart/llm_dart.dart';

void main() {
  group('XAIProvider Tests', () {
    late XAIProvider provider;
    late XAIConfig config;

    setUp(() {
      config = const XAIConfig(
        apiKey: 'test-api-key',
        baseUrl: 'https://api.x.ai/v1/',
        model: 'grok-3',
        maxTokens: 1000,
        temperature: 0.7,
        liveSearch: true,
      );
      provider = XAIProvider(config);
    });

    group('Provider Initialization', () {
      test('should initialize with valid config', () {
        expect(provider, isNotNull);
        expect(provider.config, equals(config));
        expect(provider.providerName, equals('xAI'));
      });

      test('should initialize client', () {
        expect(provider.client, isNotNull);
      });
    });

    group('Capability Support', () {
      test('should support core capabilities', () {
        expect(provider.supports(LLMCapability.chat), isTrue);
        expect(provider.supports(LLMCapability.streaming), isTrue);
        expect(provider.supports(LLMCapability.toolCalling), isTrue);
        expect(provider.supports(LLMCapability.reasoning), isTrue);
        expect(provider.supports(LLMCapability.embedding), isTrue);
      });

      test('should support web search for Grok models', () {
        expect(provider.supports(LLMCapability.liveSearch), isTrue);
      });

      test('should report vision optimistically', () {
        expect(provider.supports(LLMCapability.vision), isTrue);
      });

      test('should not support unsupported capabilities', () {
        expect(provider.supports(LLMCapability.imageGeneration), isFalse);
        expect(provider.supports(LLMCapability.textToSpeech), isFalse);
        expect(provider.supports(LLMCapability.speechToText), isFalse);
      });

      test('should return correct supported capabilities set', () {
        final capabilities = provider.supportedCapabilities;

        expect(capabilities, contains(LLMCapability.chat));
        expect(capabilities, contains(LLMCapability.streaming));
        expect(capabilities, contains(LLMCapability.toolCalling));
        expect(capabilities, contains(LLMCapability.reasoning));
        expect(capabilities, contains(LLMCapability.embedding));
        expect(capabilities, contains(LLMCapability.liveSearch));
      });
    });

    group('Interface Implementation', () {
      test('should implement ChatCapability', () {
        expect(provider, isA<ChatCapability>());
      });

      test('should implement EmbeddingCapability', () {
        expect(provider, isA<EmbeddingCapability>());
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

    group('Embedding Methods', () {
      test('should have embed method', () {
        expect(provider.embed, isA<Function>());
      });
    });

    group('Provider Properties', () {
      test('should return correct model family', () {
        expect(provider.config.modelFamily, equals('xAI'));
      });

      test('should return correct model family for embedding models', () {
        final embedConfig = config.copyWith(model: 'text-embedding-ada-002');
        final embedProvider = XAIProvider(embedConfig);

        expect(embedProvider.config.modelFamily, equals('xAI'));
      });

      test('should support search for Grok models', () {
        expect(provider.config.supportsSearch, isTrue);
      });

      test('should support reasoning for Grok models', () {
        expect(provider.config.supportsReasoning, isTrue);
      });

      test('should detect live search when enabled', () {
        expect(provider.config.isLiveSearchEnabled, isTrue);
      });

      test('should not detect live search when disabled', () {
        final noSearchConfig = config.copyWith(liveSearch: false);
        final noSearchProvider = XAIProvider(noSearchConfig);

        expect(noSearchProvider.config.isLiveSearchEnabled, isFalse);
      });
    });

    group('Model-Specific Behavior', () {
      test('should handle Grok models correctly', () {
        expect(provider.config.supportsReasoning, isTrue);
        expect(provider.config.supportsSearch, isTrue);
        expect(provider.config.supportsToolCalling, isTrue);
        expect(provider.config.modelFamily, equals('xAI'));
      });

      test('should handle vision models correctly', () {
        final visionConfig = config.copyWith(model: 'grok-vision-beta');
        final visionProvider = XAIProvider(visionConfig);

        expect(visionProvider.config.supportsVision, isTrue);
        expect(visionProvider.supports(LLMCapability.vision), isTrue);
        expect(visionProvider.config.modelFamily, equals('xAI'));
      });

      test('should handle embedding models correctly', () {
        final embedConfig = config.copyWith(model: 'text-embedding-ada-002');
        final embedProvider = XAIProvider(embedConfig);

        expect(embedProvider.config.supportsEmbeddings, isTrue);
        expect(embedProvider.supports(LLMCapability.embedding), isTrue);
        expect(embedProvider.config.modelFamily, equals('xAI'));
      });
    });

    group('Search Configuration', () {
      test('should handle search parameters', () {
        final searchParams = SearchParameters.webSearch(maxResults: 5);
        final searchConfig = config.copyWith(searchParameters: searchParams);
        final searchProvider = XAIProvider(searchConfig);

        expect(searchProvider.config.searchParameters, equals(searchParams));
        expect(searchProvider.config.isLiveSearchEnabled, isTrue);
      });

      test('should handle web search configuration', () {
        final searchParams = SearchParameters.webSearch(
          maxResults: 10,
          excludedWebsites: ['example.com'],
        );
        final searchConfig = config.copyWith(searchParameters: searchParams);
        final searchProvider = XAIProvider(searchConfig);

        expect(searchProvider.config.searchParameters, isNotNull);
        expect(searchProvider.supports(LLMCapability.liveSearch), isTrue);
      });

      test('should handle news search configuration', () {
        final searchParams = SearchParameters.newsSearch(
          maxResults: 5,
          fromDate: '2024-01-01',
        );
        final searchConfig = config.copyWith(searchParameters: searchParams);
        final searchProvider = XAIProvider(searchConfig);

        expect(searchProvider.config.searchParameters, isNotNull);
        expect(searchProvider.supports(LLMCapability.liveSearch), isTrue);
      });
    });

    group('Configuration Integration', () {
      test('should use config properties correctly', () {
        expect(provider.config.apiKey, equals('test-api-key'));
        expect(provider.config.model, equals('grok-3'));
        expect(provider.config.maxTokens, equals(1000));
        expect(provider.config.temperature, equals(0.7));
        expect(provider.config.liveSearch, isTrue);
      });

      test('should handle embedding configuration', () {
        final embedConfig = config.copyWith(
          embeddingEncodingFormat: 'float',
          embeddingDimensions: 1536,
        );
        final embedProvider = XAIProvider(embedConfig);

        expect(embedProvider.config.embeddingEncodingFormat, equals('float'));
        expect(embedProvider.config.embeddingDimensions, equals(1536));
      });

      test('should handle tool calling configuration', () {
        final toolConfig = config.copyWith(
          tools: [],
          toolChoice: const AutoToolChoice(),
        );
        final toolProvider = XAIProvider(toolConfig);

        expect(toolProvider.config.tools, equals([]));
        expect(toolProvider.config.toolChoice, isA<ToolChoice>());
      });
    });

    group('Error Handling', () {
      test('should handle invalid model gracefully during initialization', () {
        final invalidConfig = config.copyWith(model: 'invalid-model');

        // Should not throw during initialization
        expect(() => XAIProvider(invalidConfig), returnsNormally);
      });

      test('should handle empty model gracefully', () {
        final emptyModelConfig = config.copyWith(model: '');

        // Should not throw during initialization
        expect(() => XAIProvider(emptyModelConfig), returnsNormally);
      });

      test('should handle missing search parameters gracefully', () {
        final noSearchConfig = config.copyWith(
          liveSearch: true,
          searchParameters: null,
        );

        // Should not throw during initialization
        expect(() => XAIProvider(noSearchConfig), returnsNormally);
      });
    });
  });
}
