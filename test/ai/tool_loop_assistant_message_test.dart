import 'package:test/test.dart';

import 'package:llm_dart_ai/llm_dart_ai.dart';
import 'package:llm_dart_core/core/capability.dart';
import 'package:llm_dart_core/core/cancellation.dart';
import 'package:llm_dart_core/models/chat_models.dart';
import 'package:llm_dart_core/models/tool_models.dart';

class _FakeToolModel extends ChatCapability {
  int _step = 0;

  @override
  Future<ChatResponse> chatWithTools(
    List<ChatMessage> messages,
    List<Tool>? tools, {
    CancelToken? cancelToken,
  }) async {
    if (_step == 0) {
      _step++;
      final toolCalls = [
        const ToolCall(
          id: 'toolu_1',
          callType: 'function',
          function: FunctionCall(
            name: 'get_weather',
            arguments: '{"location":"SF"}',
          ),
        ),
      ];

      return _FakeResponseWithAssistantMessage(
        toolCalls: toolCalls,
        assistantMessage: ChatMessage(
          role: ChatRole.assistant,
          messageType: const TextMessage(),
          content: '',
          extensions: const {
            'anthropic': {
              'contentBlocks': [
                {
                  'type': 'thinking',
                  'thinking': 'I should call the weather tool.',
                  'signature': 'sig_1',
                },
                {
                  'type': 'tool_use',
                  'id': 'toolu_1',
                  'name': 'get_weather',
                  'input': {'location': 'SF'},
                },
              ],
            },
          },
        ),
      );
    }

    return _FakeTextResponse('done');
  }

  @override
  Stream<ChatStreamEvent> chatStream(
    List<ChatMessage> messages, {
    List<Tool>? tools,
    CancelToken? cancelToken,
  }) async* {
    throw UnimplementedError();
  }
}

class _FakeTextResponse extends ChatResponse {
  final String _text;
  _FakeTextResponse(this._text);

  @override
  String? get text => _text;

  @override
  List<ToolCall>? get toolCalls => null;
}

class _FakeResponseWithAssistantMessage
    extends ChatResponseWithAssistantMessage {
  final List<ToolCall> _toolCalls;
  final ChatMessage _assistantMessage;

  _FakeResponseWithAssistantMessage({
    required List<ToolCall> toolCalls,
    required ChatMessage assistantMessage,
  })  : _toolCalls = toolCalls,
        _assistantMessage = assistantMessage;

  @override
  String? get text => null;

  @override
  List<ToolCall>? get toolCalls => _toolCalls;

  @override
  ChatMessage get assistantMessage => _assistantMessage;
}

void main() {
  group('Tool loop assistant message persistence', () {
    test('persists ChatResponseWithAssistantMessage instead of toolUse()',
        () async {
      final model = _FakeToolModel();

      final result = await runToolLoop(
        model: model,
        messages: [ChatMessage.user('hi')],
        tools: [
          Tool.function(
            name: 'get_weather',
            description: 'Get weather for a location',
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
        ],
        toolHandlers: {
          'get_weather': (call, {cancelToken}) async => {'ok': true},
        },
      );

      expect(result.finalResult.text, equals('done'));

      final persistedAssistant = result.messages.firstWhere(
        (m) => m.role == ChatRole.assistant,
        orElse: () => throw StateError('no assistant message persisted'),
      );
      // ignore: deprecated_member_use
      expect(persistedAssistant.extensions, contains('anthropic'));
      // ignore: deprecated_member_use
      final anthropic = persistedAssistant.getExtension('anthropic');
      expect(anthropic, isA<Map>());
      expect((anthropic as Map)['contentBlocks'], isA<List>());

      // Ensure we didn't fall back to a generic ToolUseMessage for the tool call.
      expect(
        result.messages.where((m) => m.messageType is ToolUseMessage),
        isEmpty,
      );
    });

    test('blocked state includes assistant message when approval is required',
        () async {
      final model = _FakeToolModel();

      final outcome = await runToolLoopUntilBlocked(
        model: model,
        messages: [ChatMessage.user('hi')],
        tools: [
          Tool.function(
            name: 'get_weather',
            description: 'Get weather for a location',
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
        ],
        toolHandlers: const {},
        needsApproval: (
          call, {
          required messages,
          required stepIndex,
          cancelToken,
        }) async =>
            true,
      );

      expect(outcome, isA<ToolLoopBlocked>());
      final blocked = outcome as ToolLoopBlocked;
      final messages = blocked.state.messages;
      expect(messages.any((m) => m.role == ChatRole.assistant), isTrue);
    });
  });
}
