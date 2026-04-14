import 'package:llm_dart/core/capability.dart';
import 'package:llm_dart/models/chat_models.dart';
import 'package:llm_dart/models/tool_models.dart';
import 'package:llm_dart/providers/ollama/client.dart';
import 'package:llm_dart/providers/ollama/config.dart';
import 'package:llm_dart/src/compatibility/providers/ollama/ollama_chat_compat.dart';
import 'package:test/test.dart';

void main() {
  group('OllamaChat compatibility shell', () {
    test('chatWithTools keeps legacy request shaping and response wrapper',
        () async {
      final client = _FakeOllamaClient(
        const OllamaConfig(
          baseUrl: 'http://localhost:11434/',
          model: 'llama3.2',
          systemPrompt: 'You are helpful.',
          temperature: 0.3,
          topP: 0.8,
          topK: 32,
          maxTokens: 256,
          numCtx: 2048,
          numGpu: 1,
          numThread: 4,
          numBatch: 8,
          keepAlive: '10m',
          raw: true,
          reasoning: true,
        ),
      )..jsonResponse = {
          'message': {
            'content': 'Done',
            'thinking': 'Thinking...',
            'tool_calls': [
              {
                'function': {
                  'name': 'weather',
                  'arguments': {'city': 'Shanghai'},
                },
              },
            ],
          },
        };
      final chat = OllamaChat(client, client.config);
      final tools = [
        Tool.function(
          name: 'weather',
          description: 'Get weather',
          parameters: ParametersSchema(
            schemaType: 'object',
            properties: {
              'city': ParameterProperty(
                propertyType: 'string',
                description: 'City name',
              ),
            },
            required: ['city'],
          ),
        ),
      ];

      final response = await chat.chatWithTools(
        [
          ChatMessage.user('Hello'),
          ChatMessage.toolUse(
            toolCalls: const [
              ToolCall(
                id: 'tool-1',
                callType: 'function',
                function: FunctionCall(
                  name: 'weather',
                  arguments: '{"city":"Shanghai"}',
                ),
              ),
            ],
          ),
        ],
        tools,
      );

      expect(client.lastJsonEndpoint, '/api/chat');
      expect(client.lastJsonBody, {
        'model': 'llama3.2',
        'messages': [
          {
            'role': 'system',
            'content': 'You are helpful.',
          },
          {
            'role': 'user',
            'content': 'Hello',
          },
          {
            'role': 'assistant',
            'content': '',
            'tool_calls': [
              {
                'function': {
                  'name': 'weather',
                  'arguments': {'city': 'Shanghai'},
                },
              },
            ],
          },
        ],
        'stream': false,
        'keep_alive': '10m',
        'options': {
          'temperature': 0.3,
          'top_p': 0.8,
          'top_k': 32,
          'num_predict': 256,
          'num_ctx': 2048,
          'num_gpu': 1,
          'num_thread': 4,
          'num_batch': 8,
        },
        'raw': true,
        'tools': [
          {
            'type': 'function',
            'function': {
              'name': 'weather',
              'description': 'Get weather',
              'parameters': {
                'type': 'object',
                'properties': {
                  'city': {
                    'type': 'string',
                    'description': 'City name',
                  },
                },
                'required': ['city'],
              },
            },
          },
        ],
        'think': true,
      });
      expect(response.text, 'Done');
      expect(response.thinking, 'Thinking...');
      expect(response.toolCalls, hasLength(1));
      expect(response.toolCalls!.single.function.name, 'weather');
      expect(
          response.toolCalls!.single.function.arguments, '{"city":"Shanghai"}');
    });

    test('chatStream parses thinking, text, and completion events', () async {
      final client = _FakeOllamaClient(
        const OllamaConfig(
          baseUrl: 'http://localhost:11434/',
          model: 'llama3.2',
        ),
      )..streamChunks = [
          '{"message":{"thinking":"plan"}}\n{"message":{"content":"hello"}}\n',
          '{"message":{"content":"done"}}\n',
          '{"done":true}\n',
        ];
      final chat = OllamaChat(client, client.config);

      final events = await chat.chatStream(
        [ChatMessage.user('hi')],
        cancelToken: TransportCancellation(),
      ).toList();

      expect(events, hasLength(4));
      expect(events[0], isA<ThinkingDeltaEvent>());
      expect((events[0] as ThinkingDeltaEvent).delta, 'plan');
      expect(events[1], isA<TextDeltaEvent>());
      expect((events[1] as TextDeltaEvent).delta, 'hello');
      expect(events[2], isA<TextDeltaEvent>());
      expect((events[2] as TextDeltaEvent).delta, 'done');
      expect(events[3], isA<CompletionEvent>());
      expect(
        (events[3] as CompletionEvent).response.text,
        isNull,
      );
      expect(client.lastStreamEndpoint, '/api/chat');
      expect(client.lastStreamBody?['stream'], isTrue);
    });
  });
}

final class _FakeOllamaClient extends OllamaClient {
  Map<String, dynamic> jsonResponse = const {};
  List<String> streamChunks = const [];
  String? lastJsonEndpoint;
  Map<String, dynamic>? lastJsonBody;
  String? lastStreamEndpoint;
  Map<String, dynamic>? lastStreamBody;

  _FakeOllamaClient(super.config);

  @override
  Future<Map<String, dynamic>> postJson(
    String endpoint,
    Map<String, dynamic> data, {
    TransportCancellation? cancelToken,
  }) async {
    lastJsonEndpoint = endpoint;
    lastJsonBody = data;
    return jsonResponse;
  }

  @override
  Stream<String> postStreamRaw(
    String endpoint,
    Map<String, dynamic> data, {
    TransportCancellation? cancelToken,
  }) async* {
    lastStreamEndpoint = endpoint;
    lastStreamBody = data;
    yield* Stream<String>.fromIterable(streamChunks);
  }
}
