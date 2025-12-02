/// Comprehensive tests for OpenAI Responses API
///
/// This test suite covers all aspects of the OpenAI Responses API including:
/// - Configuration and builder methods
/// - Built-in tools (web search, file search, computer use)
/// - Response models and serialization
/// - Error handling and edge cases
/// - Capability detection and type safety
/// - Stateful conversation management
/// - Background processing
/// - Response lifecycle management
library;

import 'package:test/test.dart';
import 'package:llm_dart/llm_dart.dart';
import 'package:llm_dart/providers/openai/responses_capability.dart';
import 'package:llm_dart_openai/llm_dart_openai.dart' as openai;

void main() {
  group('OpenAI Responses API Comprehensive Tests', () {
    // ========== Configuration Tests ==========
    group('Configuration', () {
      test('should create config with Responses API enabled', () {
        final config = openai.OpenAIConfig(
          apiKey: 'test-key',
          model: 'gpt-4o',
          useResponsesAPI: true,
        );

        expect(config.useResponsesAPI, isTrue);
        expect(config.previousResponseId, isNull);
        expect(config.builtInTools, isNull);
      });

      test('should create config with previous response ID', () {
        final config = openai.OpenAIConfig(
          apiKey: 'test-key',
          model: 'gpt-4o',
          useResponsesAPI: true,
          previousResponseId: 'resp_123abc',
        );

        expect(config.useResponsesAPI, isTrue);
        expect(config.previousResponseId, equals('resp_123abc'));
      });

      test('should handle config copyWith for Responses API fields', () {
        final originalConfig = openai.OpenAIConfig(
          apiKey: 'test-key',
          model: 'gpt-4o',
          useResponsesAPI: false,
        );

        final updatedConfig = originalConfig.copyWith(
          useResponsesAPI: true,
          previousResponseId: 'resp_456def',
          builtInTools: [OpenAIBuiltInTools.webSearch()],
        );

        expect(updatedConfig.useResponsesAPI, isTrue);
        expect(updatedConfig.previousResponseId, equals('resp_456def'));
        expect(updatedConfig.builtInTools, hasLength(1));

        // Original should remain unchanged
        expect(originalConfig.useResponsesAPI, isFalse);
        expect(originalConfig.previousResponseId, isNull);
        expect(originalConfig.builtInTools, isNull);
      });

      test('should handle config equality with Responses API fields', () {
        final config1 = openai.OpenAIConfig(
          apiKey: 'test-key',
          model: 'gpt-4o',
          useResponsesAPI: true,
          previousResponseId: 'resp_123',
        );

        final config2 = openai.OpenAIConfig(
          apiKey: 'test-key',
          model: 'gpt-4o',
          useResponsesAPI: true,
          previousResponseId: 'resp_123',
        );

        final config3 = openai.OpenAIConfig(
          apiKey: 'test-key',
          model: 'gpt-4o',
          useResponsesAPI: false,
        );

        expect(config1, equals(config2));
        expect(config1, isNot(equals(config3)));
        expect(config1.hashCode, equals(config2.hashCode));
      });
    });

    // ========== Built-in Tools Tests ==========
    group('Built-in Tools', () {
      test('should create web search tool correctly', () {
        final tool = OpenAIBuiltInTools.webSearch();
        final json = tool.toJson();

        expect(json['type'], equals('web_search'));
        expect(tool.type, equals(OpenAIBuiltInToolType.webSearch));
        expect(tool, isA<OpenAIWebSearchTool>());
      });

      test('should create file search tool with vector stores', () {
        final tool = OpenAIBuiltInTools.fileSearch(
          vectorStoreIds: ['vs_123', 'vs_456'],
          parameters: {
            'max_num_results': 20,
            'ranking_options': {'score_threshold': 0.8}
          },
        );
        final json = tool.toJson();

        expect(json['type'], equals('file_search'));
        expect(json['vector_store_ids'], equals(['vs_123', 'vs_456']));
        expect(json['max_num_results'], equals(20));
        expect(json['ranking_options'], isA<Map>());
        expect(tool.type, equals(OpenAIBuiltInToolType.fileSearch));
        expect(tool, isA<OpenAIFileSearchTool>());
      });

      test('should create file search tool without parameters', () {
        final tool = OpenAIBuiltInTools.fileSearch();
        final json = tool.toJson();

        expect(json['type'], equals('file_search'));
        expect(json.containsKey('vector_store_ids'), isFalse);
        expect(json.containsKey('max_num_results'), isFalse);
      });

      test('should create computer use tool correctly', () {
        final tool = OpenAIBuiltInTools.computerUse(
          displayWidth: 1920,
          displayHeight: 1080,
          environment: 'desktop',
          parameters: {'timeout': 60, 'screenshot_quality': 'high'},
        );
        final json = tool.toJson();

        expect(json['type'], equals('computer_use_preview'));
        expect(json['display_width'], equals(1920));
        expect(json['display_height'], equals(1080));
        expect(json['environment'], equals('desktop'));
        expect(json['timeout'], equals(60));
        expect(json['screenshot_quality'], equals('high'));
        expect(tool.type, equals(OpenAIBuiltInToolType.computerUse));
        expect(tool, isA<OpenAIComputerUseTool>());
      });

      test('should handle tool equality and hashCode correctly', () {
        final tool1 = OpenAIBuiltInTools.webSearch();
        final tool2 = OpenAIBuiltInTools.webSearch();
        final tool3 = OpenAIBuiltInTools.fileSearch();

        expect(tool1, equals(tool2));
        expect(tool1.hashCode, equals(tool2.hashCode));
        expect(tool1, isNot(equals(tool3)));

        // Test that tools are instances of correct types
        expect(tool1, isA<OpenAIWebSearchTool>());
        expect(tool3, isA<OpenAIFileSearchTool>());
      });

      test('should handle complex file search parameters', () {
        final tool = OpenAIBuiltInTools.fileSearch(
          vectorStoreIds: ['vs_primary', 'vs_secondary'],
          parameters: {
            'max_num_results': 50,
            'ranking_options': {
              'score_threshold': 0.75,
              'ranker': 'auto',
            },
            'include_file_names': true,
          },
        );
        final json = tool.toJson();

        expect(json['vector_store_ids'], hasLength(2));
        expect(json['max_num_results'], equals(50));
        expect(json['ranking_options']['score_threshold'], equals(0.75));
        expect(json['include_file_names'], isTrue);
      });
    });

    // ========== Builder Methods Tests ==========
    group('Builder Methods', () {
      test('should build provider with Responses API using builder', () async {
        final provider = await ai()
            .openai((openai) => openai
                .useResponsesAPI()
                .webSearchTool()
                .fileSearchTool(vectorStoreIds: ['vs_123']))
            .apiKey('test-key')
            .model('gpt-4o')
            .build();

        expect(provider, isA<openai.OpenAIProvider>());

        final openaiProvider = provider as openai.OpenAIProvider;
        expect(openaiProvider.config.useResponsesAPI, isTrue);
        expect(openaiProvider.config.builtInTools, hasLength(2));
        expect(openaiProvider.responses, isNotNull);
      });

      test('should accumulate multiple built-in tools', () async {
        final provider = await ai()
            .openai((openai) => openai
                    .useResponsesAPI()
                    .webSearchTool()
                    .fileSearchTool(vectorStoreIds: ['vs_123']).computerUseTool(
                  displayWidth: 1024,
                  displayHeight: 768,
                  environment: 'browser',
                ))
            .apiKey('test-key')
            .model('gpt-4o')
            .build();

        final openaiProvider = provider as openai.OpenAIProvider;
        expect(openaiProvider.config.builtInTools, hasLength(3));

        final tools = openaiProvider.config.builtInTools!;
        expect(tools[0], isA<OpenAIWebSearchTool>());
        expect(tools[1], isA<OpenAIFileSearchTool>());
        expect(tools[2], isA<OpenAIComputerUseTool>());
      });

      test('should set previous response ID correctly', () async {
        final provider = await ai()
            .openai((openai) =>
                openai.useResponsesAPI().previousResponseId('resp_chain_123'))
            .apiKey('test-key')
            .model('gpt-4o')
            .build();

        final openaiProvider = provider as openai.OpenAIProvider;
        expect(
            openaiProvider.config.previousResponseId, equals('resp_chain_123'));
      });

      test('should support buildOpenAIResponses convenience method', () async {
        final provider = await ai()
            .openai((openai) => openai
                .webSearchTool()
                .fileSearchTool(vectorStoreIds: ['vs_auto']))
            .apiKey('test-key')
            .model('gpt-4o')
            .buildOpenAIResponses();

        expect(provider, isA<openai.OpenAIProvider>());
        expect(provider.responses, isNotNull);
        expect(provider.config.useResponsesAPI, isTrue);
        expect(provider.supports(LLMCapability.openaiResponses), isTrue);
      });
    });

    // ========== Response Models Tests ==========
    group('Response Models', () {
      test('should create and serialize ResponseInputItem correctly', () {
        final inputItem = ResponseInputItem(
          id: 'item_test_123',
          type: 'message',
          role: 'user',
          content: [
            {'type': 'text', 'text': 'Hello, world!'},
            {
              'type': 'image_url',
              'image_url': {'url': 'https://example.com/image.jpg'}
            },
          ],
        );

        final json = inputItem.toJson();
        expect(json['id'], equals('item_test_123'));
        expect(json['type'], equals('message'));
        expect(json['role'], equals('user'));
        expect(json['content'], isA<List>());
        expect(json['content'], hasLength(2));

        final reconstructed = ResponseInputItem.fromJson(json);
        expect(reconstructed.id, equals(inputItem.id));
        expect(reconstructed.type, equals(inputItem.type));
        expect(reconstructed.role, equals(inputItem.role));
        expect(
            reconstructed.content?.length, equals(inputItem.content?.length));
      });

      test('should create ResponseInputItem with minimal data', () {
        final inputItem = ResponseInputItem(
          id: 'item_minimal',
          type: 'system',
        );

        final json = inputItem.toJson();
        expect(json['id'], equals('item_minimal'));
        expect(json['type'], equals('system'));
        expect(json.containsKey('role'), isFalse);
        expect(json.containsKey('content'), isFalse);

        final reconstructed = ResponseInputItem.fromJson(json);
        expect(reconstructed.id, equals('item_minimal'));
        expect(reconstructed.type, equals('system'));
        expect(reconstructed.role, isNull);
        expect(reconstructed.content, isNull);
      });

      test('should create and serialize ResponseInputItemsList correctly', () {
        final inputItems = [
          ResponseInputItem(
            id: 'item_1',
            type: 'message',
            role: 'user',
            content: [
              {'type': 'text', 'text': 'First message'}
            ],
          ),
          ResponseInputItem(
            id: 'item_2',
            type: 'message',
            role: 'assistant',
            content: [
              {'type': 'text', 'text': 'Second message'}
            ],
          ),
        ];

        final inputItemsList = ResponseInputItemsList(
          object: 'list',
          data: inputItems,
          firstId: 'item_1',
          lastId: 'item_2',
          hasMore: false,
        );

        final json = inputItemsList.toJson();
        expect(json['object'], equals('list'));
        expect(json['data'], isA<List>());
        expect(json['data'], hasLength(2));
        expect(json['first_id'], equals('item_1'));
        expect(json['last_id'], equals('item_2'));
        expect(json['has_more'], equals(false));

        final reconstructed = ResponseInputItemsList.fromJson(json);
        expect(reconstructed.object, equals(inputItemsList.object));
        expect(reconstructed.data.length, equals(inputItemsList.data.length));
        expect(reconstructed.firstId, equals(inputItemsList.firstId));
        expect(reconstructed.lastId, equals(inputItemsList.lastId));
        expect(reconstructed.hasMore, equals(inputItemsList.hasMore));
      });

      test('should handle ResponseInputItemsList with pagination', () {
        final inputItemsList = ResponseInputItemsList(
          object: 'list',
          data: [],
          firstId: 'item_start',
          lastId: 'item_end',
          hasMore: true,
        );

        final json = inputItemsList.toJson();
        expect(json['has_more'], isTrue);
        expect(json['first_id'], equals('item_start'));
        expect(json['last_id'], equals('item_end'));

        final reconstructed = ResponseInputItemsList.fromJson(json);
        expect(reconstructed.hasMore, isTrue);
        expect(reconstructed.firstId, equals('item_start'));
        expect(reconstructed.lastId, equals('item_end'));
      });

      test('should handle ResponseInputItemsList properties', () {
        final item1 = ResponseInputItem(id: 'item_1', type: 'message');
        final item2 = ResponseInputItem(id: 'item_2', type: 'message');

        final list1 = ResponseInputItemsList(
          object: 'list',
          data: [item1, item2],
          hasMore: false,
        );

        final list2 = ResponseInputItemsList(
          object: 'list',
          data: [item1],
          hasMore: true,
        );

        expect(list1.object, equals('list'));
        expect(list1.data, hasLength(2));
        expect(list1.hasMore, isFalse);

        expect(list2.object, equals('list'));
        expect(list2.data, hasLength(1));
        expect(list2.hasMore, isTrue);
      });
    });

    // ========== Capability Detection Tests ==========
    group('Capability Detection', () {
      test('should detect OpenAI Responses capability when enabled', () async {
        final provider = await ai()
            .openai((openai) => openai.useResponsesAPI())
            .apiKey('test-key')
            .model('gpt-4o')
            .build();

        expect(provider, isA<ProviderCapabilities>());
        final capabilities = provider as ProviderCapabilities;
        expect(capabilities.supports(LLMCapability.openaiResponses), isTrue);
        expect(
            capabilities.supportedCapabilities
                .contains(LLMCapability.openaiResponses),
            isTrue);
      });

      test('should not detect OpenAI Responses capability when disabled',
          () async {
        final provider =
            await ai().openai().apiKey('test-key').model('gpt-4o').build();

        expect(provider, isA<ProviderCapabilities>());
        final capabilities = provider as ProviderCapabilities;
        expect(capabilities.supports(LLMCapability.openaiResponses), isFalse);
        expect(
            capabilities.supportedCapabilities
                .contains(LLMCapability.openaiResponses),
            isFalse);
      });

      test('should provide responses getter when capability is enabled',
          () async {
        final provider = await ai()
            .openai((openai) => openai.useResponsesAPI())
            .apiKey('test-key')
            .model('gpt-4o')
            .build();

        final openaiProvider = provider as openai.OpenAIProvider;
        expect(openaiProvider.responses, isNotNull);
        expect(openaiProvider.responses, isA<OpenAIResponses>());
        expect(openaiProvider.responses, isA<OpenAIResponsesCapability>());
        expect(openaiProvider.responses, isA<ChatCapability>());
      });

      test('should not provide responses getter when capability is disabled',
          () async {
        final provider =
            await ai().openai().apiKey('test-key').model('gpt-4o').build();

        final openaiProvider = provider as openai.OpenAIProvider;
        expect(openaiProvider.responses, isNull);
      });

      test('should support type-safe capability checking', () async {
        final provider = await ai()
            .openai((openai) => openai.useResponsesAPI().webSearchTool())
            .apiKey('test-key')
            .model('gpt-4o')
            .build();

        // Type-safe capability detection
        if (provider is ProviderCapabilities &&
            (provider as ProviderCapabilities)
                .supports(LLMCapability.openaiResponses) &&
            provider is openai.OpenAIProvider) {
          final openaiProvider = provider;
          final responses = openaiProvider.responses;

          expect(responses, isNotNull);
          expect(responses, isA<OpenAIResponsesCapability>());

          // Verify all required methods exist (without calling them to avoid API key requirements)
          final responsesInstance = responses!;
          expect(responsesInstance.chatWithTools, isA<Function>());
          expect(responsesInstance.chatWithToolsBackground, isA<Function>());
          expect(responsesInstance.getResponse, isA<Function>());
          expect(responsesInstance.deleteResponse, isA<Function>());
          expect(responsesInstance.cancelResponse, isA<Function>());
          expect(responsesInstance.listInputItems, isA<Function>());
          expect(responsesInstance.continueConversation, isA<Function>());
          expect(responsesInstance.forkConversation, isA<Function>());
        } else {
          fail('Provider should support OpenAI Responses capability');
        }
      });
    });
  });
}
