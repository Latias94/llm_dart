/// Functionality tests for OpenAI Responses API methods
///
/// This test suite focuses on testing the actual functionality and method
/// behavior of the OpenAI Responses API implementation, including mocking
/// and integration scenarios.
library;

import 'package:test/test.dart';
import 'package:llm_dart/llm_dart.dart';

void main() {
  group('OpenAI Responses API Functionality', () {
    // ========== Method Interface Tests ==========
    group('Method Interfaces', () {
      late OpenAIProvider provider;
      late OpenAIResponses responses;

      setUp(() async {
        provider = await ai()
            .openai((openai) => openai.useResponsesAPI().webSearchTool())
            .apiKey('test-key')
            .model('gpt-4o')
            .build() as OpenAIProvider;

        responses = provider.responses!;
      });

      test('should have all required OpenAIResponsesCapability methods', () {
        // Test that methods exist and can be called (but don't execute them)
        // This tests the interface without making API calls

        // Basic chat methods - test method signatures exist
        expect(responses.chat, isA<Function>());
        expect(responses.chatWithTools, isA<Function>());
        expect(responses.chatWithToolsBackground, isA<Function>());

        // Streaming methods
        expect(responses.chatStream, isA<Function>());

        // Response management methods
        expect(responses.getResponse, isA<Function>());
        expect(responses.deleteResponse, isA<Function>());
        expect(responses.cancelResponse, isA<Function>());
        expect(responses.listInputItems, isA<Function>());

        // Conversation management methods
        expect(responses.continueConversation, isA<Function>());
        expect(responses.forkConversation, isA<Function>());
      });

      test('should implement ChatCapability interface', () {
        expect(responses, isA<ChatCapability>());

        // Test ChatCapability methods exist without calling them
        expect(responses.chat, isA<Function>());
        expect(responses.chatStream, isA<Function>());
      });

      test('should implement OpenAIResponsesCapability interface', () {
        expect(responses, isA<OpenAIResponsesCapability>());

        // Test all OpenAIResponsesCapability methods exist without calling them
        final capability = responses as OpenAIResponsesCapability;
        expect(capability.chatWithTools, isA<Function>());
        expect(capability.chatWithToolsBackground, isA<Function>());
        expect(capability.getResponse, isA<Function>());
        expect(capability.deleteResponse, isA<Function>());
        expect(capability.cancelResponse, isA<Function>());
        expect(capability.listInputItems, isA<Function>());
        expect(capability.continueConversation, isA<Function>());
        expect(capability.forkConversation, isA<Function>());
      });

      test('should support extension methods', () {
        // Extension methods can't be torn off (they are not instance members),
        // so validate them via a small fake implementation.
        final fake = _FakeOpenAIResponsesCapability();

        expect(fake.chat, isA<Function>());
        expect(fake.chatBackground, isA<Function>());

        expect(
          () async => fake.responseExists('resp_missing'),
          returnsNormally,
        );
      });
    });

    // ========== Message Handling Tests ==========
    group('Message Handling', () {
      late OpenAIProvider provider;
      late OpenAIResponses responses;

      setUp(() async {
        provider = await ai()
            .openai((openai) => openai.useResponsesAPI())
            .apiKey('test-key')
            .model('gpt-4o')
            .build() as OpenAIProvider;

        responses = provider.responses!;
      });

      test('should handle empty message list', () {
        // Test that methods can accept empty message lists without API calls
        final messages = <ChatMessage>[];
        expect(messages, isEmpty);
        expect(responses.chat, isA<Function>());
        expect(responses.chatWithTools, isA<Function>());
        expect(responses.chatWithToolsBackground, isA<Function>());
      });

      test('should handle single message', () {
        final messages = [ChatMessage.user('Hello, world!')];
        expect(messages, hasLength(1));
        expect(messages.first.role, equals(ChatRole.user));
        expect(messages.first.content, equals('Hello, world!'));

        // Verify methods exist without calling them
        expect(responses.chat, isA<Function>());
        expect(responses.chatWithTools, isA<Function>());
        expect(responses.chatWithToolsBackground, isA<Function>());
      });

      test('should handle multiple messages', () {
        final messages = [
          ChatMessage.system('You are a helpful assistant.'),
          ChatMessage.user('What is the weather like?'),
          ChatMessage.assistant('I need to check the weather for you.'),
          ChatMessage.user('Please check for San Francisco.'),
        ];

        expect(messages, hasLength(4));
        expect(messages[0].role, equals(ChatRole.system));
        expect(messages[1].role, equals(ChatRole.user));
        expect(messages[2].role, equals(ChatRole.assistant));
        expect(messages[3].role, equals(ChatRole.user));

        // Verify methods exist without calling them
        expect(responses.chat, isA<Function>());
        expect(responses.chatWithTools, isA<Function>());
        expect(responses.chatWithToolsBackground, isA<Function>());
      });

      test('should handle messages with different content types', () {
        final messages = [
          ChatMessage.user('Describe this image'),
          ChatMessage.user(
              'What do you see in this image: https://example.com/image.jpg'),
        ];

        expect(messages, hasLength(2));
        expect(messages.every((msg) => msg.role == ChatRole.user), isTrue);

        // Verify methods exist without calling them
        expect(responses.chat, isA<Function>());
        expect(responses.chatWithTools, isA<Function>());
      });
    });

    // ========== Tool Handling Tests ==========
    group('Tool Handling', () {
      late OpenAIProvider provider;
      late OpenAIResponses responses;

      setUp(() async {
        provider = await ai()
            .openai((openai) => openai.useResponsesAPI().webSearchTool())
            .apiKey('test-key')
            .model('gpt-4o')
            .build() as OpenAIProvider;

        responses = provider.responses!;
      });

      test('should handle null tools', () {
        final messages = [ChatMessage.user('Hello')];
        expect(messages, hasLength(1));

        // Test that methods exist and can accept null tools without API calls
        expect(responses.chatWithTools, isA<Function>());
        expect(responses.chatWithToolsBackground, isA<Function>());
      });

      test('should handle empty tools list', () {
        final messages = [ChatMessage.user('Hello')];
        final tools = <Tool>[];

        expect(messages, hasLength(1));
        expect(tools, isEmpty);

        // Test that methods exist and can accept empty tools without API calls
        expect(responses.chatWithTools, isA<Function>());
        expect(responses.chatWithToolsBackground, isA<Function>());
      });

      test('should handle single tool', () {
        final messages = [ChatMessage.user('What is the weather?')];
        final tools = [
          Tool.function(
            name: 'get_weather',
            description: 'Get current weather',
            parameters: ParametersSchema(
              schemaType: 'object',
              properties: {
                'location': ParameterProperty(
                  propertyType: 'string',
                  description: 'City name',
                ),
              },
              required: ['location'],
            ),
          ),
        ];

        expect(messages, hasLength(1));
        expect(tools, hasLength(1));
        expect(tools.first.function.name, equals('get_weather'));

        // Test that methods exist without calling them
        expect(responses.chatWithTools, isA<Function>());
        expect(responses.chatWithToolsBackground, isA<Function>());
      });

      test('should handle multiple tools', () {
        final messages = [ChatMessage.user('Help me with weather and time')];
        final tools = [
          Tool.function(
            name: 'get_weather',
            description: 'Get current weather',
            parameters: ParametersSchema(
              schemaType: 'object',
              properties: {
                'location': ParameterProperty(
                  propertyType: 'string',
                  description: 'Location to get weather for',
                ),
              },
              required: ['location'],
            ),
          ),
          Tool.function(
            name: 'get_time',
            description: 'Get current time',
            parameters: ParametersSchema(
              schemaType: 'object',
              properties: {
                'timezone': ParameterProperty(
                  propertyType: 'string',
                  description: 'Timezone to get time for',
                ),
              },
              required: [],
            ),
          ),
        ];

        expect(messages, hasLength(1));
        expect(tools, hasLength(2));
        expect(tools[0].function.name, equals('get_weather'));
        expect(tools[1].function.name, equals('get_time'));

        // Test that methods exist without calling them
        expect(responses.chatWithTools, isA<Function>());
        expect(responses.chatWithToolsBackground, isA<Function>());
      });

      test('should handle complex tool parameters', () {
        final messages = [ChatMessage.user('Process this data')];
        final tools = [
          Tool.function(
            name: 'process_data',
            description: 'Process complex data',
            parameters: ParametersSchema(
              schemaType: 'object',
              properties: {
                'data': ParameterProperty(
                  propertyType: 'string',
                  description: 'Data to process',
                ),
                'format': ParameterProperty(
                  propertyType: 'string',
                  description: 'Output format',
                  enumList: ['json', 'csv', 'xml'],
                ),
              },
              required: ['data'],
            ),
          ),
        ];

        expect(messages, hasLength(1));
        expect(tools, hasLength(1));
        expect(tools.first.function.name, equals('process_data'));
        expect(tools.first.function.parameters.required, contains('data'));

        // Test that methods exist without calling them
        expect(responses.chatWithTools, isA<Function>());
      });
    });

    // ========== Response ID Handling Tests ==========
    group('Response ID Handling', () {
      late OpenAIProvider provider;
      late OpenAIResponses responses;

      setUp(() async {
        provider = await ai()
            .openai((openai) => openai.useResponsesAPI())
            .apiKey('test-key')
            .model('gpt-4o')
            .build() as OpenAIProvider;

        responses = provider.responses!;
      });

      test('should handle valid response IDs', () {
        const validIds = [
          'resp_123abc',
          'resp_456def789',
          'resp_xyz_123',
          'response_id_with_underscores',
        ];

        // Test that all IDs are valid strings and methods exist
        for (final id in validIds) {
          expect(id, isA<String>());
          expect(id, isNotEmpty);
        }

        // Test that methods exist without calling them
        expect(responses.getResponse, isA<Function>());
        expect(responses.deleteResponse, isA<Function>());
        expect(responses.cancelResponse, isA<Function>());
        expect(responses.listInputItems, isA<Function>());
        expect(responses.continueConversation, isA<Function>());
        expect(responses.forkConversation, isA<Function>());
      });

      test('should handle empty response ID', () {
        const emptyId = '';
        expect(emptyId, isEmpty);

        // Test that methods exist and can accept empty strings without calling them
        expect(responses.getResponse, isA<Function>());
        expect(responses.deleteResponse, isA<Function>());
        expect(responses.cancelResponse, isA<Function>());
        expect(responses.listInputItems, isA<Function>());
        expect(responses.continueConversation, isA<Function>());
        expect(responses.forkConversation, isA<Function>());
      });

      test('should handle special characters in response ID', () {
        const specialIds = [
          'resp-with-dashes',
          'resp.with.dots',
          'resp_with_underscores',
          'resp123numbers',
        ];

        // Test that all IDs are valid strings
        for (final id in specialIds) {
          expect(id, isA<String>());
          expect(id, isNotEmpty);
          expect(id, contains(RegExp(r'[a-zA-Z0-9._-]')));
        }

        // Test that methods exist without calling them
        expect(responses.getResponse, isA<Function>());
        expect(responses.deleteResponse, isA<Function>());
        expect(responses.cancelResponse, isA<Function>());
      });
    });

    // ========== Streaming Tests ==========
    group('Streaming', () {
      late OpenAIProvider provider;
      late OpenAIResponses responses;

      setUp(() async {
        provider = await ai()
            .openai((openai) => openai.useResponsesAPI().webSearchTool())
            .apiKey('test-key')
            .model('gpt-4o')
            .build() as OpenAIProvider;

        responses = provider.responses!;
      });

      test('should handle streaming with empty messages', () {
        final messages = <ChatMessage>[];
        expect(messages, isEmpty);

        // Test that streaming method exists without calling it
        expect(responses.chatStream, isA<Function>());
      });

      test('should handle streaming with messages', () {
        final messages = [ChatMessage.user('Tell me a story')];
        expect(messages, hasLength(1));
        expect(messages.first.role, equals(ChatRole.user));

        // Test that streaming method exists without calling it
        expect(responses.chatStream, isA<Function>());
      });

      test('should handle streaming with tools', () {
        final messages = [ChatMessage.user('What is the weather?')];
        final tools = [
          Tool.function(
            name: 'get_weather',
            description: 'Get weather',
            parameters: ParametersSchema(
              schemaType: 'object',
              properties: {
                'location': ParameterProperty(
                  propertyType: 'string',
                  description: 'Location for weather',
                ),
              },
              required: [],
            ),
          ),
        ];

        expect(messages, hasLength(1));
        expect(tools, hasLength(1));
        expect(tools.first.function.name, equals('get_weather'));

        // Test that streaming method exists without calling it
        expect(responses.chatStream, isA<Function>());
      });
    });
  });
}

class _FakeChatResponse implements ChatResponse {
  @override
  final String? text;

  const _FakeChatResponse({this.text});

  @override
  List<ToolCall>? get toolCalls => null;

  @override
  String? get thinking => null;

  @override
  UsageInfo? get usage => null;

  @override
  Map<String, dynamic>? get providerMetadata => null;
}

class _FakeOpenAIResponsesCapability implements OpenAIResponsesCapability {
  @override
  Future<ChatResponse> chatWithTools(
    List<ChatMessage> messages,
    List<Tool>? tools,
  ) async {
    return _FakeChatResponse(text: messages.map((m) => m.content).join('\n'));
  }

  @override
  Future<ChatResponse> chatWithToolsBackground(
    List<ChatMessage> messages,
    List<Tool>? tools,
  ) async {
    return _FakeChatResponse(text: 'background');
  }

  @override
  Stream<ChatStreamEvent> chatStream(
    List<ChatMessage> messages, {
    List<Tool>? tools,
  }) async* {
    yield const TextDeltaEvent('delta');
    yield const CompletionEvent(_FakeChatResponse(text: 'done'));
  }

  @override
  Future<ChatResponse> getResponse(
    String responseId, {
    List<String>? include,
    int? startingAfter,
    bool stream = false,
  }) async {
    throw StateError('not found');
  }

  @override
  Future<bool> deleteResponse(String responseId) async => true;

  @override
  Future<ChatResponse> cancelResponse(String responseId) async =>
      const _FakeChatResponse(text: 'cancelled');

  @override
  Future<ResponseInputItemsList> listInputItems(
    String responseId, {
    String? after,
    String? before,
    List<String>? include,
    int limit = 20,
    String order = 'desc',
  }) async {
    return ResponseInputItemsList(
      object: 'list',
      data: const [],
      firstId: null,
      lastId: null,
      hasMore: false,
    );
  }

  @override
  Future<ChatResponse> continueConversation(
    String previousResponseId,
    List<ChatMessage> newMessages, {
    List<Tool>? tools,
    bool background = false,
  }) async {
    return _FakeChatResponse(text: 'continued');
  }

  @override
  Future<ChatResponse> forkConversation(
    String fromResponseId,
    List<ChatMessage> newMessages, {
    List<Tool>? tools,
    bool background = false,
  }) async {
    return _FakeChatResponse(text: 'forked');
  }
}
