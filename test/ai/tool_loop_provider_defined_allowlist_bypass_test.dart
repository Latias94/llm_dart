import 'package:test/test.dart';

import 'package:llm_dart_ai/llm_dart_ai.dart';
import 'package:llm_dart_core/llm_dart_core.dart';

class _FakeProviderToolCallStreamModel extends ChatCapability
    implements ChatStreamPartsCapability {
  int _step = 0;

  @override
  Stream<LLMStreamPart> chatStreamParts(
    List<ChatMessage> messages, {
    List<ProviderTool>? providerTools,
    List<Tool>? tools,
    CancelToken? cancelToken,
  }) async* {
    if (_step == 0) {
      _step++;
      yield const LLMProviderToolCallPart(
        toolCallId: 'call_1',
        toolName: 'shell',
        input: {
          'action': {
            'commands': ['echo hi']
          }
        },
        providerExecuted: false,
      );
      yield LLMFinishPart(_FakeStreamResponse());
      return;
    }

    yield const LLMTextStartPart();
    yield const LLMTextDeltaPart('done');
    yield const LLMTextEndPart('done');
    yield LLMFinishPart(_FakeStreamResponse());
  }

  @override
  Future<ChatResponse> chatWithTools(
    List<ChatMessage> messages,
    List<Tool>? tools, {
    List<ProviderTool>? providerTools,
    CancelToken? cancelToken,
  }) {
    throw StateError('Should not be called for ChatStreamPartsCapability.');
  }
}

class _FakeStreamResponse extends ChatResponse {
  @override
  String? get text => null;

  @override
  List<ToolCall>? get toolCalls => null;
}

void main() {
  group('Tool loop provider-defined tool allowlist bypass', () {
    test(
        'executes providerExecuted=false tool calls even when tools allowlist is empty',
        () async {
      final model = _FakeProviderToolCallStreamModel();
      var handlerCalls = 0;

      final parts = await streamToolLoopParts(
        model: model,
        messages: [ChatMessage.user('hi')],
        tools: const [],
        toolHandlers: {
          'shell': (input, options) async {
            handlerCalls++;
            expect(options.toolCallId, equals('call_1'));
            expect(options.toolName, equals('shell'));
            expect(options.rawArguments, contains('commands'));
            return {
              'output': [
                {
                  'stdout': 'hi\n',
                  'stderr': '',
                  'outcome': {'type': 'exit', 'exitCode': 0},
                }
              ],
            };
          },
        },
      ).toList();

      expect(handlerCalls, equals(1));

      final toolResult = parts.whereType<LLMToolResultPart>().single.result;
      expect(toolResult.toolCallId, equals('call_1'));
      expect(toolResult.isError, isFalse);

      final finish = parts.whereType<LLMFinishPart>().single;
      expect(finish.response.text, equals('done'));
    });
  });
}
