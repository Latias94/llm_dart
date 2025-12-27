import 'package:test/test.dart';

import 'package:llm_dart_ai/llm_dart_ai.dart';
import 'package:llm_dart_core/core/capability.dart';
import 'package:llm_dart_core/core/cancellation.dart';
import 'package:llm_dart_core/models/chat_models.dart';
import 'package:llm_dart_core/models/tool_models.dart';

class _FakePromptToolStreamPartsModel extends ChatCapability
    implements PromptChatStreamPartsCapability {
  int chatWithToolsCalls = 0;
  int chatStreamCalls = 0;
  int chatPromptStreamPartsCalls = 0;
  int _step = 0;

  @override
  Future<ChatResponse> chatWithTools(
    List<ChatMessage> messages,
    List<Tool>? tools, {
    CancelToken? cancelToken,
  }) async {
    chatWithToolsCalls++;
    throw StateError(
      'chatWithTools should not be called for PromptChatStreamPartsCapability',
    );
  }

  @override
  Stream<ChatStreamEvent> chatStream(
    List<ChatMessage> messages, {
    List<Tool>? tools,
    CancelToken? cancelToken,
  }) async* {
    chatStreamCalls++;
    throw StateError(
      'chatStream should not be called for PromptChatStreamPartsCapability',
    );
  }

  @override
  Stream<LLMStreamPart> chatPromptStreamParts(
    Prompt prompt, {
    List<Tool>? tools,
    CancelToken? cancelToken,
  }) async* {
    chatPromptStreamPartsCalls++;

    if (_step == 0) {
      _step++;
      yield const LLMToolCallStartPart(
        ToolCall(
          id: 'toolu_1',
          callType: 'function',
          function: FunctionCall(
            name: 'get_weather',
            arguments: '{"location":"SF"}',
          ),
        ),
      );
      yield const LLMToolCallEndPart('toolu_1');

      yield LLMFinishPart(_FakeStreamResponse());
      return;
    }

    yield const LLMTextStartPart();
    yield const LLMTextDeltaPart('done');
    yield const LLMTextEndPart('done');
    yield LLMFinishPart(_FakeStreamResponse());
  }
}

class _FakeStreamResponse extends ChatResponse {
  _FakeStreamResponse();

  @override
  String? get text => null;

  @override
  List<ToolCall>? get toolCalls => null;
}

void main() {
  group('Tool loop PromptChatStreamPartsCapability', () {
    test('streamToolLoopParts(promptIr) prefers chatPromptStreamParts()',
        () async {
      final model = _FakePromptToolStreamPartsModel();

      final parts = await streamToolLoopParts(
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
        toolHandlers: {
          'get_weather': (call, {cancelToken}) async => {'ok': true},
        },
      ).toList();

      expect(parts.whereType<LLMToolCallStartPart>(), isNotEmpty);
      expect(parts.whereType<LLMToolResultPart>(), isNotEmpty);

      final finish = parts.whereType<LLMFinishPart>().single;
      expect(finish.response.text, equals('done'));

      expect(model.chatWithToolsCalls, equals(0));
      expect(model.chatStreamCalls, equals(0));
      expect(model.chatPromptStreamPartsCalls, greaterThanOrEqualTo(1));
    });
  });
}
