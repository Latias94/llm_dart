/// Error handling and edge cases tests for OpenAI Responses API
///
/// This test suite focuses on error scenarios, edge cases, and robustness
/// testing for the OpenAI Responses API implementation.
library;

import 'package:test/test.dart';
import 'package:llm_dart/llm_dart.dart';
import 'package:llm_dart_openai/llm_dart_openai.dart' as openai;

void main() {
  group('OpenAI Responses API Error Handling', () {
    // ========== Error Types Tests ==========
    group('Error Types', () {
      test('should create OpenAIResponsesError with all fields', () {
        const error = OpenAIResponsesError(
          'Test error message',
          responseId: 'resp_error_123',
          errorType: 'validation_error',
        );

        expect(error.message, equals('Test error message'));
        expect(error.responseId, equals('resp_error_123'));
        expect(error.errorType, equals('validation_error'));
        expect(error, isA<LLMError>());
      });

      test('should create OpenAIResponsesError with minimal fields', () {
        const error = OpenAIResponsesError('Minimal error');

        expect(error.message, equals('Minimal error'));
        expect(error.responseId, isNull);
        expect(error.errorType, isNull);
      });

      test('should format OpenAIResponsesError toString correctly', () {
        const error1 = OpenAIResponsesError('Basic error');
        expect(error1.toString(),
            equals('OpenAI Responses API error: Basic error'));

        const error2 = OpenAIResponsesError(
          'Complex error',
          responseId: 'resp_123',
          errorType: 'timeout',
        );
        expect(error2.toString(),
            contains('OpenAI Responses API error: Complex error'));
        expect(error2.toString(), contains('Response ID: resp_123'));
        expect(error2.toString(), contains('Error type: timeout'));
      });

      test('should handle OpenAIResponsesError equality', () {
        const error1 = OpenAIResponsesError(
          'Same error',
          responseId: 'resp_123',
          errorType: 'timeout',
        );
        const error2 = OpenAIResponsesError(
          'Same error',
          responseId: 'resp_123',
          errorType: 'timeout',
        );
        const error3 = OpenAIResponsesError('Different error');

        expect(error1, equals(error2));
        expect(error1.hashCode, equals(error2.hashCode));
        expect(error1, isNot(equals(error3)));
      });
    });

    // ========== Configuration Validation Tests ==========
    group('Configuration Validation', () {
      test('should handle invalid API key gracefully', () async {
        expect(() async {
          await ai()
              .openai((openai) => openai.useResponsesAPI())
              .apiKey('') // Empty API key
              .model('gpt-4o')
              .build();
        }, throwsA(isA<InvalidRequestError>()));
      });

      test('should handle missing model gracefully', () async {
        expect(() async {
          await ai()
              .openai((openai) => openai.useResponsesAPI())
              .apiKey('test-key')
              .model('') // Empty model
              .build();
        }, throwsA(isA<InvalidRequestError>()));
      });

      test('should validate built-in tool parameters', () {
        // Test file search with empty vector store IDs
        expect(() {
          OpenAIBuiltInTools.fileSearch(vectorStoreIds: []);
        }, returnsNormally);

        // Test computer use with invalid dimensions
        expect(() {
          OpenAIBuiltInTools.computerUse(
            displayWidth: -1,
            displayHeight: 0,
            environment: 'test',
          );
        }, returnsNormally); // Should not throw, validation happens at API level
      });

      test('should handle null and empty parameters in tools', () {
        final webTool = OpenAIBuiltInTools.webSearch();
        final json = webTool.toJson();
        expect(json, isA<Map<String, dynamic>>());

        final fileTool = OpenAIBuiltInTools.fileSearch(parameters: {});
        final fileJson = fileTool.toJson();
        expect(fileJson, isA<Map<String, dynamic>>());

        final computerTool = OpenAIBuiltInTools.computerUse(
          displayWidth: 1024,
          displayHeight: 768,
          environment: 'test',
          parameters: null,
        );
        final computerJson = computerTool.toJson();
        expect(computerJson, isA<Map<String, dynamic>>());
      });
    });

    // ========== Response Model Edge Cases ==========
    group('Response Model Edge Cases', () {
      test('should handle ResponseInputItem with null content', () {
        final inputItem = ResponseInputItem(
          id: 'item_null_content',
          type: 'message',
          role: 'user',
          content: null,
        );

        final json = inputItem.toJson();
        expect(json['content'], isNull);

        final reconstructed = ResponseInputItem.fromJson(json);
        expect(reconstructed.content, isNull);
      });

      test('should handle ResponseInputItem with empty content', () {
        final inputItem = ResponseInputItem(
          id: 'item_empty_content',
          type: 'message',
          role: 'user',
          content: [],
        );

        final json = inputItem.toJson();
        expect(json['content'], isEmpty);

        final reconstructed = ResponseInputItem.fromJson(json);
        expect(reconstructed.content, isEmpty);
      });

      test('should handle ResponseInputItemsList with empty data', () {
        final inputItemsList = ResponseInputItemsList(
          object: 'list',
          data: [],
          hasMore: false,
        );

        final json = inputItemsList.toJson();
        expect(json['data'], isEmpty);

        final reconstructed = ResponseInputItemsList.fromJson(json);
        expect(reconstructed.data, isEmpty);
      });

      test('should handle ResponseInputItemsList with null pagination fields',
          () {
        final inputItemsList = ResponseInputItemsList(
          object: 'list',
          data: [
            ResponseInputItem(id: 'item_1', type: 'message'),
          ],
          firstId: null,
          lastId: null,
          hasMore: false,
        );

        final json = inputItemsList.toJson();
        expect(json['first_id'], isNull);
        expect(json['last_id'], isNull);

        final reconstructed = ResponseInputItemsList.fromJson(json);
        expect(reconstructed.firstId, isNull);
        expect(reconstructed.lastId, isNull);
      });

      test('should handle malformed JSON gracefully', () {
        // Test with missing required fields
        expect(() {
          ResponseInputItem.fromJson({'type': 'message'}); // Missing id
        }, throwsA(isA<TypeError>()));

        expect(() {
          ResponseInputItem.fromJson({'id': 'item_1'}); // Missing type
        }, throwsA(isA<TypeError>()));

        expect(() {
          ResponseInputItemsList.fromJson(
              {'data': []}); // Missing object and hasMore
        }, throwsA(isA<TypeError>()));
      });

      test('should handle complex content structures', () {
        final complexContent = [
          {
            'type': 'text',
            'text': 'Hello world',
          },
          {
            'type': 'image_url',
            'image_url': {
              'url': 'https://example.com/image.jpg',
              'detail': 'high',
            },
          },
          {
            'type': 'tool_call',
            'tool_call': {
              'id': 'call_123',
              'type': 'function',
              'function': {
                'name': 'get_weather',
                'arguments': '{"location": "San Francisco"}',
              },
            },
          },
        ];

        final inputItem = ResponseInputItem(
          id: 'item_complex',
          type: 'message',
          role: 'assistant',
          content: complexContent,
        );

        final json = inputItem.toJson();
        expect(json['content'], hasLength(3));
        expect(json['content'][0]['type'], equals('text'));
        expect(json['content'][1]['type'], equals('image_url'));
        expect(json['content'][2]['type'], equals('tool_call'));

        final reconstructed = ResponseInputItem.fromJson(json);
        expect(reconstructed.content, hasLength(3));
        expect(reconstructed.content![0]['type'], equals('text'));
        expect(
            reconstructed.content![1]['image_url']['detail'], equals('high'));
        expect(reconstructed.content![2]['tool_call']['function']['name'],
            equals('get_weather'));
      });
    });

    // ========== Builder Edge Cases ==========
    group('Builder Edge Cases', () {
      test('should handle multiple calls to same builder method', () async {
        final provider = await ai()
            .openai((openai) => openai
                .useResponsesAPI()
                .useResponsesAPI(false) // Override
                .useResponsesAPI(true)) // Override again
            .apiKey('test-key')
            .model('gpt-4o')
            .build();

        final openaiProvider = provider as openai.OpenAIProvider;
        expect(openaiProvider.config.useResponsesAPI, isTrue);
      });

      test('should handle duplicate tool additions', () async {
        final provider = await ai()
            .openai((openai) => openai
                .useResponsesAPI()
                .webSearchTool()
                .webSearchTool() // Duplicate
                .fileSearchTool(vectorStoreIds: ['vs_123']).fileSearchTool(
                    vectorStoreIds: ['vs_123'])) // Duplicate
            .apiKey('test-key')
            .model('gpt-4o')
            .build();

        final openaiProvider = provider as openai.OpenAIProvider;
        // Should accumulate all tools, even duplicates
        expect(openaiProvider.config.builtInTools, hasLength(4));
      });

      test('should handle previousResponseId override', () async {
        final provider = await ai()
            .openai((openai) => openai
                .useResponsesAPI()
                .previousResponseId('resp_first')
                .previousResponseId('resp_second')) // Override
            .apiKey('test-key')
            .model('gpt-4o')
            .build();

        final openaiProvider = provider as openai.OpenAIProvider;
        expect(openaiProvider.config.previousResponseId, equals('resp_second'));
      });

      test('should handle buildOpenAIResponses with non-OpenAI provider',
          () async {
        expect(() async {
          await ai()
              .anthropic()
              .apiKey('test-key')
              .model('claude-3-sonnet-20240229')
              .buildOpenAIResponses();
        }, throwsA(isA<UnsupportedCapabilityError>()));
      });
    });

    // ========== Capability Edge Cases ==========
    group('Capability Edge Cases', () {
      test('should handle capability detection with mixed configurations',
          () async {
        // Provider with Responses API but no tools
        final provider1 = await ai()
            .openai((openai) => openai.useResponsesAPI())
            .apiKey('test-key')
            .model('gpt-4o')
            .build();

        expect(
            (provider1 as ProviderCapabilities)
                .supports(LLMCapability.openaiResponses),
            isTrue);

        // Provider with tools but no explicit Responses API
        final provider2 =
            await ai().openai().apiKey('test-key').model('gpt-4o').build();

        expect(
            (provider2 as ProviderCapabilities)
                .supports(LLMCapability.openaiResponses),
            isFalse);
      });

      test('should handle responses getter consistency', () async {
        final provider = await ai()
            .openai((openai) => openai.useResponsesAPI())
            .apiKey('test-key')
            .model('gpt-4o')
            .build();

        final openaiProvider = provider as openai.OpenAIProvider;
        final responses1 = openaiProvider.responses;
        final responses2 = openaiProvider.responses;

        // Should return the same instance
        expect(identical(responses1, responses2), isTrue);
        expect(responses1, isNotNull);
      });
    });
  });
}
