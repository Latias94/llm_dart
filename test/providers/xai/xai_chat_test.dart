import 'package:dio/dio.dart';
import 'package:llm_dart/llm_dart.dart';
import 'package:test/test.dart';

class FakeXAIClient extends XAIClient {
  Map<String, dynamic>? lastRequestBody;
  String? lastEndpoint;

  FakeXAIClient(XAIConfig config) : super(config);

  @override
  Future<Map<String, dynamic>> postJson(
    String endpoint,
    Map<String, dynamic> data, {
    CancelToken? cancelToken,
  }) async {
    lastEndpoint = endpoint;
    lastRequestBody = data;

    // Minimal valid xAI-style response.
    return {
      'id': 'chatcmpl-1',
      'model': 'grok-3',
      'object': 'chat.completion',
      'choices': [
        {
          'index': 0,
          'finish_reason': 'stop',
          'message': {
            'role': 'assistant',
            'content': 'ok',
            'reasoning_content': null,
            'tool_calls': null,
          },
        },
      ],
      'usage': {
        'prompt_tokens': 3,
        'completion_tokens': 5,
        'total_tokens': 8,
        'completion_tokens_details': {'reasoning_tokens': 2},
      },
      'citations': ['https://example.com'],
    };
  }
}

void main() {
  group('XAIChat request body mapping', () {
    test('includes system prompt and user message', () async {
      const config = XAIConfig(
        apiKey: 'test-key',
        model: 'grok-3',
        systemPrompt: 'You are a helpful assistant.',
      );

      final client = FakeXAIClient(config);
      final chat = XAIChat(client, config);

      final messages = [ChatMessage.user('Hello')];

      await chat.chat(messages);

      final body = client.lastRequestBody;
      expect(body, isNotNull);
      expect(body!['model'], equals('grok-3'));
      expect(body['stream'], isFalse);

      final apiMessages = body['messages'] as List<dynamic>;
      expect(apiMessages.length, equals(2));

      final systemMessage = apiMessages[0] as Map<String, dynamic>;
      expect(systemMessage['role'], equals('system'));
      expect(systemMessage['content'], equals(config.systemPrompt));

      final userMessage = apiMessages[1] as Map<String, dynamic>;
      expect(userMessage['role'], equals('user'));
      expect(userMessage['content'], equals('Hello'));

      expect(body.containsKey('tools'), isFalse);
      expect(body.containsKey('tool_choice'), isFalse);
      expect(body.containsKey('search_parameters'), isFalse);
      expect(body.containsKey('response_format'), isFalse);
    });

    test('builds multi-modal user message and tool result messages', () async {
      const config = XAIConfig(
        apiKey: 'test-key',
        model: 'grok-3',
      );

      final client = FakeXAIClient(config);
      final chat = XAIChat(client, config);

      final imageMessage = ChatMessage.imageUrl(
        role: ChatRole.user,
        url: 'https://example.com/image.jpg',
        content: 'Look at this image',
      );

      final toolCall = ToolCall(
        id: 'tool-1',
        callType: 'function',
        function: const FunctionCall(
          name: 'get_weather',
          arguments: '{}',
        ),
      );

      final toolResultMessage = ChatMessage.toolResult(
        results: [toolCall],
        content: '',
      );

      await chat.chat([imageMessage, toolResultMessage]);

      final body = client.lastRequestBody;
      expect(body, isNotNull);

      final apiMessages = body!['messages'] as List<dynamic>;
      expect(apiMessages.length, equals(2));

      final userMessage = apiMessages
              .firstWhere((m) => (m as Map<String, dynamic>)['role'] == 'user')
          as Map<String, dynamic>;
      final userContent = userMessage['content'] as List<dynamic>;

      // Should contain both text and image_url parts.
      final hasTextPart = userContent.any((part) =>
          (part as Map<String, dynamic>)['type'] == 'text' &&
          part['text'] == 'Look at this image');
      final hasImagePart = userContent.any((part) {
        final map = part as Map<String, dynamic>;
        if (map['type'] != 'image_url') return false;
        final imageUrl = map['image_url'] as Map<String, dynamic>;
        return imageUrl['url'] == 'https://example.com/image.jpg';
      });

      expect(hasTextPart, isTrue);
      expect(hasImagePart, isTrue);

      final toolMessage = apiMessages
              .firstWhere((m) => (m as Map<String, dynamic>)['role'] == 'tool')
          as Map<String, dynamic>;
      expect(toolMessage['tool_call_id'], equals('tool-1'));
      expect(toolMessage['content'], equals('{}'));
    });

    test('maps tools and tool_choice correctly', () async {
      final tool = Tool.function(
        name: 'get_weather',
        description: 'Get the current weather',
        parameters: ParametersSchema(
          schemaType: 'object',
          properties: {
            'location': ParameterProperty(
              propertyType: 'string',
              description: 'City name',
            ),
          },
          required: const ['location'],
        ),
      );

      final config = XAIConfig(
        apiKey: 'test-key',
        model: 'grok-3',
        tools: [tool],
        toolChoice: const SpecificToolChoice('get_weather'),
      );

      final client = FakeXAIClient(config);
      final chat = XAIChat(client, config);

      await chat.chatWithTools([ChatMessage.user('Hello')], null);

      final body = client.lastRequestBody;
      expect(body, isNotNull);

      final toolsJson = body!['tools'] as List<dynamic>;
      expect(toolsJson.length, equals(1));

      final toolJson = toolsJson.first as Map<String, dynamic>;
      expect(toolJson['type'], equals('function'));

      final functionJson = toolJson['function'] as Map<String, dynamic>;
      expect(functionJson['name'], equals('get_weather'));
      expect(functionJson['description'], equals('Get the current weather'));
      expect(functionJson['parameters'], isA<Map<String, dynamic>>());

      final toolChoice = body['tool_choice'] as Map<String, dynamic>;
      expect(toolChoice['type'], equals('function'));
      final toolChoiceFunction = toolChoice['function'] as Map<String, dynamic>;
      expect(toolChoiceFunction['name'], equals('get_weather'));
    });

    test('maps searchParameters to search_parameters', () async {
      final searchParams = SearchParameters.webSearch(
        maxResults: 5,
        excludedWebsites: ['example.com'],
      );

      final config = XAIConfig(
        apiKey: 'test-key',
        model: 'grok-3',
        searchParameters: searchParams,
      );

      final client = FakeXAIClient(config);
      final chat = XAIChat(client, config);

      await chat.chat([ChatMessage.user('Hello')]);

      final body = client.lastRequestBody;
      expect(body, isNotNull);

      expect(body!.containsKey('search_parameters'), isTrue);
      expect(body.containsKey('search'), isFalse);

      final searchJson = body['search_parameters'] as Map<String, dynamic>;
      expect(searchJson['mode'], equals(searchParams.mode));
      expect(
        searchJson['max_search_results'],
        equals(searchParams.maxSearchResults),
      );
    });
  });

  group('XAIChatResponse parsing', () {
    test('parses text, thinking, toolCalls, usage and metadata', () {
      final rawResponse = {
        'id': 'chatcmpl-1',
        'model': 'grok-3',
        'object': 'chat.completion',
        'choices': [
          {
            'index': 0,
            'finish_reason': 'stop',
            'message': {
              'role': 'assistant',
              'content': 'Hello',
              'reasoning_content': 'Chain-of-thought reasoning',
              'tool_calls': [
                {
                  'id': 'call_1',
                  'type': 'function',
                  'function': {
                    'name': 'get_weather',
                    'arguments': '{"location":"Tokyo"}',
                  },
                },
              ],
            },
          },
        ],
        'usage': {
          'prompt_tokens': 10,
          'completion_tokens': 20,
          'total_tokens': 30,
          'completion_tokens_details': {'reasoning_tokens': 5},
        },
        'citations': ['https://example.com'],
      };

      final response = XAIChatResponse(rawResponse);

      expect(response.text, equals('Hello'));
      expect(response.thinking, equals('Chain-of-thought reasoning'));

      final toolCalls = response.toolCalls;
      expect(toolCalls, isNotNull);
      expect(toolCalls!.length, equals(1));
      expect(toolCalls.first.function.name, equals('get_weather'));
      expect(
        toolCalls.first.function.arguments,
        equals('{"location":"Tokyo"}'),
      );

      final usage = response.usage;
      expect(usage, isNotNull);
      expect(usage!.promptTokens, equals(10));
      expect(usage.completionTokens, equals(20));
      expect(usage.totalTokens, equals(30));
      expect(usage.reasoningTokens, equals(5));

      final metadata = response.metadata;
      expect(metadata, isNotNull);
      expect(metadata!['provider'], equals('xai'));
      expect(metadata['id'], equals('chatcmpl-1'));
      expect(metadata['model'], equals('grok-3'));
      expect(metadata['hasThinking'], isTrue);
      expect(metadata['hasCitations'], isTrue);
      expect(metadata['citations'], isA<List<dynamic>>());
    });
  });
}
