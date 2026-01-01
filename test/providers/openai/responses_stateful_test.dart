import 'package:test/test.dart';
import 'package:llm_dart/llm_dart.dart';
import 'package:llm_dart_openai/responses.dart';

void main() {
  group('OpenAI Responses API Stateful Features', () {
    test('should have responses getter when useResponsesAPI is enabled',
        () async {
      final provider = await ai()
          .openai((openai) => openai.useResponsesAPI())
          .apiKey('test-key')
          .model('gpt-4o')
          .build();

      final openaiProvider = provider as OpenAIProvider;
      expect(openaiProvider.responses, isNotNull);
      expect(openaiProvider.responses, isA<OpenAIResponses>());
    });

    test('should not have responses getter when useResponsesAPI is disabled',
        () async {
      final provider =
          await ai().openai().apiKey('test-key').model('gpt-4o').build();

      final openaiProvider = provider as OpenAIProvider;
      expect(openaiProvider.responses, isNull);
    });

    test('should implement OpenAIResponsesCapability interface', () async {
      final provider = await ai()
          .openai((openai) => openai.useResponsesAPI())
          .apiKey('test-key')
          .model('gpt-4o')
          .build();

      final openaiProvider = provider as OpenAIProvider;
      final responses = openaiProvider.responses!;

      expect(responses, isA<OpenAIResponsesCapability>());
      expect(responses, isA<ChatCapability>());
    });

    test('should have all required OpenAIResponsesCapability methods',
        () async {
      final provider = await ai()
          .openai((openai) => openai.useResponsesAPI())
          .apiKey('test-key')
          .model('gpt-4o')
          .build();

      final openaiProvider = provider as OpenAIProvider;
      final responses = openaiProvider.responses!;

      // Check that all methods exist (without calling them to avoid API key requirements)
      expect(responses.chatWithTools, isA<Function>());
      expect(responses.chatWithToolsBackground, isA<Function>());
      expect(responses.getResponse, isA<Function>());
      expect(responses.deleteResponse, isA<Function>());
      expect(responses.cancelResponse, isA<Function>());
      expect(responses.listInputItems, isA<Function>());
      expect(responses.continueConversation, isA<Function>());
      expect(responses.forkConversation, isA<Function>());
    });

    test('should support basic OpenAIResponsesCapability methods', () async {
      final provider = await ai()
          .openai((openai) => openai.useResponsesAPI())
          .apiKey('test-key')
          .model('gpt-4o')
          .build();

      final openaiProvider = provider as OpenAIProvider;
      final responses = openaiProvider.responses!;

      // Check that basic methods exist (without calling them to avoid API key requirements)
      expect(responses.chat, isA<Function>());
    });

    test('ResponseInputItemsList should serialize correctly', () {
      final inputItem = ResponseInputItem(
        id: 'item_123',
        type: 'message',
        role: 'user',
        content: [
          {'type': 'text', 'text': 'Hello'}
        ],
      );

      final inputItemsList = ResponseInputItemsList(
        object: 'list',
        data: [inputItem],
        firstId: 'item_123',
        lastId: 'item_123',
        hasMore: false,
      );

      final json = inputItemsList.toJson();
      expect(json['object'], equals('list'));
      expect(json['data'], isA<List>());
      expect(json['first_id'], equals('item_123'));
      expect(json['last_id'], equals('item_123'));
      expect(json['has_more'], equals(false));

      final reconstructed = ResponseInputItemsList.fromJson(json);
      expect(reconstructed.object, equals(inputItemsList.object));
      expect(reconstructed.data.length, equals(inputItemsList.data.length));
      expect(reconstructed.firstId, equals(inputItemsList.firstId));
      expect(reconstructed.lastId, equals(inputItemsList.lastId));
      expect(reconstructed.hasMore, equals(inputItemsList.hasMore));
    });

    test('ResponseInputItem should serialize correctly', () {
      final inputItem = ResponseInputItem(
        id: 'item_123',
        type: 'message',
        role: 'user',
        content: [
          {'type': 'text', 'text': 'Hello world'}
        ],
      );

      final json = inputItem.toJson();
      expect(json['id'], equals('item_123'));
      expect(json['type'], equals('message'));
      expect(json['role'], equals('user'));
      expect(json['content'], isA<List>());

      final reconstructed = ResponseInputItem.fromJson(json);
      expect(reconstructed.id, equals(inputItem.id));
      expect(reconstructed.type, equals(inputItem.type));
      expect(reconstructed.role, equals(inputItem.role));
      expect(reconstructed.content?.length, equals(inputItem.content?.length));
    });
  });
}
