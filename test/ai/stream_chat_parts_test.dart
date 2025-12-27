library;

import 'package:llm_dart_ai/llm_dart_ai.dart';
import 'package:llm_dart_core/core/capability.dart';
import 'package:llm_dart_core/core/cancellation.dart';
import 'package:llm_dart_core/models/chat_models.dart';
import 'package:llm_dart_core/models/tool_models.dart';
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
    this.text,
    this.thinking,
    Map<String, dynamic>? providerMetadata,
  })  : toolCalls = null,
        usage = null,
        _providerMetadata = providerMetadata;

  @override
  Map<String, dynamic>? get providerMetadata => _providerMetadata;
}

class _FakeChatModel extends ChatCapability {
  final List<ChatStreamEvent> streamEvents;

  _FakeChatModel(this.streamEvents);

  @override
  Future<ChatResponse> chatWithTools(
    List<ChatMessage> messages,
    List<Tool>? tools, {
    CancelToken? cancelToken,
  }) async {
    throw UnsupportedError('chatWithTools not used in this test');
  }

  @override
  Stream<ChatStreamEvent> chatStream(
    List<ChatMessage> messages, {
    List<Tool>? tools,
    CancelToken? cancelToken,
  }) async* {
    for (final event in streamEvents) {
      yield event;
    }
  }
}

void main() {
  group('streamChatParts', () {
    test('should emit block boundaries and finish metadata', () async {
      final toolCall = ToolCall(
        id: 'call_1',
        callType: 'function',
        function: FunctionCall(name: 'getWeather', arguments: '{"q":"a"}'),
      );

      final model = _FakeChatModel([
        const TextDeltaEvent('Hel'),
        const TextDeltaEvent('lo'),
        const ThinkingDeltaEvent('Th'),
        const ThinkingDeltaEvent('ink'),
        ToolCallDeltaEvent(toolCall),
        CompletionEvent(
          _FakeChatResponse(
            text: 'Hello',
            thinking: 'Think',
            providerMetadata: const {
              'openai': {'id': 'resp_1'}
            },
          ),
        ),
      ]);

      final parts = await streamChatParts(
        model: model,
        messages: [ChatMessage.user('hi')],
      ).toList();

      expect(parts[0], isA<LLMTextStartPart>());
      expect(parts[1], isA<LLMTextDeltaPart>());
      expect((parts[1] as LLMTextDeltaPart).delta, equals('Hel'));
      expect(parts[2], isA<LLMTextDeltaPart>());
      expect((parts[2] as LLMTextDeltaPart).delta, equals('lo'));

      expect(parts[3], isA<LLMReasoningStartPart>());
      expect(parts[4], isA<LLMReasoningDeltaPart>());
      expect((parts[4] as LLMReasoningDeltaPart).delta, equals('Th'));
      expect(parts[5], isA<LLMReasoningDeltaPart>());
      expect((parts[5] as LLMReasoningDeltaPart).delta, equals('ink'));

      expect(parts[6], isA<LLMToolCallStartPart>());
      expect((parts[6] as LLMToolCallStartPart).toolCall.id, equals('call_1'));

      // Completion emits end parts, provider metadata, then finish.
      expect(parts[7], isA<LLMTextEndPart>());
      expect((parts[7] as LLMTextEndPart).text, equals('Hello'));

      expect(parts[8], isA<LLMReasoningEndPart>());
      expect((parts[8] as LLMReasoningEndPart).thinking, equals('Think'));

      expect(parts[9], isA<LLMToolCallEndPart>());
      expect((parts[9] as LLMToolCallEndPart).toolCallId, equals('call_1'));

      expect(parts[10], isA<LLMProviderMetadataPart>());
      expect(
        (parts[10] as LLMProviderMetadataPart).providerMetadata,
        containsPair('openai', {'id': 'resp_1'}),
      );

      expect(parts[11], isA<LLMFinishPart>());
      expect((parts[11] as LLMFinishPart).response.text, equals('Hello'));
    });
  });
}
