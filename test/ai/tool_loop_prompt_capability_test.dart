import 'package:test/test.dart';

import 'package:llm_dart_ai/llm_dart_ai.dart';
import 'package:llm_dart_core/core/capability.dart';
import 'package:llm_dart_core/core/cancellation.dart';
import 'package:llm_dart_core/models/chat_models.dart';
import 'package:llm_dart_core/models/tool_models.dart';

class _FakePromptToolModel extends ChatCapability
    implements PromptChatCapability {
  int chatWithToolsCalls = 0;
  int chatPromptCalls = 0;
  int _step = 0;

  @override
  Future<ChatResponse> chatWithTools(
    List<ChatMessage> messages,
    List<Tool>? tools, {
    CancelToken? cancelToken,
  }) async {
    chatWithToolsCalls++;
    throw StateError(
        'chatWithTools should not be called for PromptChatCapability');
  }

  @override
  Stream<ChatStreamEvent> chatStream(
    List<ChatMessage> messages, {
    List<Tool>? tools,
    CancelToken? cancelToken,
  }) async* {
    throw UnimplementedError();
  }

  @override
  Future<ChatResponse> chatPrompt(
    Prompt prompt, {
    List<Tool>? tools,
    CancelToken? cancelToken,
  }) async {
    chatPromptCalls++;
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
  Stream<ChatStreamEvent> chatPromptStream(
    Prompt prompt, {
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
  group('Tool loop PromptChatCapability', () {
    test('runToolLoop(promptIr) prefers chatPrompt()', () async {
      final model = _FakePromptToolModel();

      final result = await runToolLoop(
        model: model,
        promptIr: Prompt(
          messages: [
            PromptMessage.user('hi'),
          ],
        ),
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
      expect(model.chatWithToolsCalls, equals(0));
      expect(model.chatPromptCalls, greaterThanOrEqualTo(1));
    });

    test('runToolLoopUntilBlocked(promptIr) prefers chatPrompt()', () async {
      final model = _FakePromptToolModel();

      final outcome = await runToolLoopUntilBlocked(
        model: model,
        promptIr: Prompt(messages: [PromptMessage.user('hi')]),
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
      expect(model.chatWithToolsCalls, equals(0));
      expect(model.chatPromptCalls, greaterThanOrEqualTo(1));
    });
  });
}
