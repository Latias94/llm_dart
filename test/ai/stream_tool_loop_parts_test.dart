library;

import 'dart:convert';

import 'package:llm_dart_ai/llm_dart_ai.dart';
import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:test/test.dart';

class _FakeChatResponse implements ChatResponse {
  @override
  final String? text;

  @override
  final String? thinking;

  @override
  final List<ToolCall>? toolCalls;

  @override
  final UsageInfo? usage;

  final Map<String, dynamic>? _providerMetadata;

  const _FakeChatResponse({
    Map<String, dynamic>? providerMetadata,
  })  : text = null,
        thinking = null,
        toolCalls = null,
        usage = null,
        _providerMetadata = providerMetadata;

  @override
  Map<String, dynamic>? get providerMetadata => _providerMetadata;
}

class _SequencedStreamChatModel extends ChatCapability {
  final List<List<ChatStreamEvent>> steps;

  _SequencedStreamChatModel(this.steps);

  var _index = 0;

  @override
  Future<ChatResponse> chatWithTools(
    List<ChatMessage> messages,
    List<Tool>? tools, {
    CancelToken? cancelToken,
  }) {
    throw UnsupportedError('chatWithTools not used in this test');
  }

  @override
  Stream<ChatStreamEvent> chatStream(
    List<ChatMessage> messages, {
    List<Tool>? tools,
    CancelToken? cancelToken,
  }) async* {
    if (_index >= steps.length) {
      throw StateError('No more stream steps configured for fake model');
    }
    final events = steps[_index++];
    for (final event in events) {
      yield event;
    }
  }
}

void main() {
  group('streamToolLoopParts', () {
    test('should emit tool results and a single finish part', () async {
      final model = _SequencedStreamChatModel([
        [
          const TextDeltaEvent('Need '),
          ToolCallDeltaEvent(
            ToolCall(
              id: 'call_1',
              callType: 'function',
              function: FunctionCall(name: 'get_weather', arguments: '{'),
            ),
          ),
          ToolCallDeltaEvent(
            ToolCall(
              id: 'call_1',
              callType: 'function',
              function: FunctionCall(name: '', arguments: '"city":"SF"}'),
            ),
          ),
          const CompletionEvent(
            _FakeChatResponse(
              providerMetadata: {
                'openai': {'id': 'resp_step_1'}
              },
            ),
          ),
        ],
        [
          const TextDeltaEvent('Done'),
          const CompletionEvent(
            _FakeChatResponse(
              providerMetadata: {
                'openai': {'id': 'resp_step_2'}
              },
            ),
          ),
        ],
      ]);

      final parts = await streamToolLoopParts(
        model: model,
        messages: [ChatMessage.user('hi')],
        toolHandlers: {
          'get_weather': (toolCall, {cancelToken}) => {'temp': 70},
        },
        maxSteps: 3,
      ).toList();

      // Step 1
      expect(parts[0], isA<LLMTextStartPart>());
      expect(parts[1], isA<LLMTextDeltaPart>());
      expect((parts[1] as LLMTextDeltaPart).delta, equals('Need '));

      expect(parts[2], isA<LLMToolCallStartPart>());
      expect((parts[2] as LLMToolCallStartPart).toolCall.id, equals('call_1'));
      expect(parts[3], isA<LLMToolCallDeltaPart>());

      expect(parts[4], isA<LLMTextEndPart>());
      expect((parts[4] as LLMTextEndPart).text, equals('Need '));
      expect(parts[5], isA<LLMToolCallEndPart>());

      expect(parts[6], isA<LLMProviderMetadataPart>());
      expect(
        (parts[6] as LLMProviderMetadataPart).providerMetadata,
        containsPair('openai', {'id': 'resp_step_1'}),
      );

      expect(parts[7], isA<LLMToolResultPart>());
      final toolResult = (parts[7] as LLMToolResultPart).result;
      expect(toolResult.toolCallId, equals('call_1'));
      expect(toolResult.isError, isFalse);
      expect(jsonDecode(toolResult.content), equals({'temp': 70}));

      // Step 2 (final)
      expect(parts[8], isA<LLMTextStartPart>());
      expect(parts[9], isA<LLMTextDeltaPart>());
      expect((parts[9] as LLMTextDeltaPart).delta, equals('Done'));
      expect(parts[10], isA<LLMTextEndPart>());
      expect((parts[10] as LLMTextEndPart).text, equals('Done'));
      expect(parts[11], isA<LLMProviderMetadataPart>());
      expect(
        (parts[11] as LLMProviderMetadataPart).providerMetadata,
        containsPair('openai', {'id': 'resp_step_2'}),
      );

      expect(parts[12], isA<LLMFinishPart>());
      expect((parts[12] as LLMFinishPart).response.text, equals('Done'));
    });
  });
}
