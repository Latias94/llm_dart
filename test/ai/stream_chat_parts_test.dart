library;

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
    this.text,
    this.thinking,
    Map<String, dynamic>? providerMetadata,
  })  : toolCalls = null,
        usage = null,
        _providerMetadata = providerMetadata;

  @override
  Map<String, dynamic>? get providerMetadata => _providerMetadata;
}

class _FakeChatModel extends ChatCapability
    implements ChatStreamPartsCapability {
  final List<LLMStreamPart> parts;

  _FakeChatModel(this.parts);

  @override
  Future<ChatResponse> chatWithTools(
    List<ChatMessage> messages,
    List<Tool>? tools, {
    CancelToken? cancelToken,
  }) async {
    throw UnsupportedError('chatWithTools not used in this test');
  }

  @override
  Stream<LLMStreamPart> chatStreamParts(
    List<ChatMessage> messages, {
    List<ProviderTool>? providerTools,
    List<Tool>? tools,
    CancelToken? cancelToken,
  }) async* {
    for (final part in parts) {
      yield part;
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
        const LLMTextStartPart(),
        const LLMTextDeltaPart('Hel'),
        const LLMTextDeltaPart('lo'),
        const LLMTextEndPart('Hello'),
        const LLMReasoningStartPart(),
        const LLMReasoningDeltaPart('Th'),
        const LLMReasoningDeltaPart('ink'),
        const LLMReasoningEndPart('Think'),
        LLMToolCallStartPart(toolCall),
        const LLMToolCallEndPart('call_1'),
        const LLMProviderMetadataPart({
          'openai': {'id': 'resp_1'},
        }),
        const LLMFinishPart(
          _FakeChatResponse(
            text: 'Hello',
            thinking: 'Think',
            providerMetadata: {
              'openai': {'id': 'resp_1'}
            },
          ),
        ),
      ]);

      final parts = await streamChatParts(
        model: model,
        messages: [ChatMessage.user('hi')],
      ).toList();

      expect(parts[0], isA<LLMStreamStartPart>());
      expect(parts.whereType<LLMStreamStartPart>(), hasLength(1));

      expect(parts[1], isA<LLMTextStartPart>());
      expect(parts[2], isA<LLMTextDeltaPart>());
      expect((parts[2] as LLMTextDeltaPart).delta, equals('Hel'));
      expect(parts[3], isA<LLMTextDeltaPart>());
      expect((parts[3] as LLMTextDeltaPart).delta, equals('lo'));

      expect(parts[4], isA<LLMTextEndPart>());
      expect((parts[4] as LLMTextEndPart).text, equals('Hello'));

      expect(parts[5], isA<LLMReasoningStartPart>());
      expect(parts[6], isA<LLMReasoningDeltaPart>());
      expect((parts[6] as LLMReasoningDeltaPart).delta, equals('Th'));
      expect(parts[7], isA<LLMReasoningDeltaPart>());
      expect((parts[7] as LLMReasoningDeltaPart).delta, equals('ink'));

      expect(parts[8], isA<LLMReasoningEndPart>());
      expect((parts[8] as LLMReasoningEndPart).thinking, equals('Think'));

      final toolInputStart = parts.whereType<LLMToolInputStartPart>().single;
      expect(toolInputStart.id, equals('call_1'));
      expect(toolInputStart.toolName, equals('getWeather'));

      final toolInputDelta = parts.whereType<LLMToolInputDeltaPart>().single;
      expect(toolInputDelta.id, equals('call_1'));
      expect(toolInputDelta.delta, equals('{"q":"a"}'));

      expect(parts.whereType<LLMToolCallStartPart>(), hasLength(1));
      expect(parts.whereType<LLMToolCallEndPart>(), hasLength(1));
      expect(parts.whereType<LLMToolInputEndPart>(), hasLength(1));

      final toolCallStartIndex =
          parts.indexWhere((p) => p is LLMToolCallStartPart);
      final toolInputStartIndex =
          parts.indexWhere((p) => p is LLMToolInputStartPart);
      final toolInputEndIndex =
          parts.indexWhere((p) => p is LLMToolInputEndPart);
      final toolCallEndIndex = parts.indexWhere((p) => p is LLMToolCallEndPart);
      expect(toolInputStartIndex, lessThan(toolCallStartIndex));
      expect(toolCallStartIndex, lessThan(toolInputEndIndex));
      expect(toolInputEndIndex, lessThan(toolCallEndIndex));

      final providerMetadataIndex =
          parts.indexWhere((p) => p is LLMProviderMetadataPart);
      expect(providerMetadataIndex, isNonNegative);

      expect(parts[providerMetadataIndex], isA<LLMProviderMetadataPart>());
      expect(
        (parts[providerMetadataIndex] as LLMProviderMetadataPart)
            .providerMetadata,
        containsPair('openai', {'id': 'resp_1'}),
      );

      expect(parts.last, isA<LLMFinishPart>());
      expect((parts.last as LLMFinishPart).response.text, equals('Hello'));
    });

    test('deduplicates finish and ensures it is last', () async {
      final model = _FakeChatModel([
        const LLMTextDeltaPart('A'),
        const LLMFinishPart(_FakeChatResponse(text: 'first')),
        const LLMProviderMetadataPart({
          'openai': {'id': 'resp_early'},
        }),
        const LLMFinishPart(_FakeChatResponse(text: 'last')),
      ]);

      final parts = await streamChatParts(
        model: model,
        messages: [ChatMessage.user('hi')],
      ).toList();

      expect(parts.whereType<LLMStreamStartPart>(), hasLength(1));
      expect(parts.whereType<LLMFinishPart>(), hasLength(1));
      expect(parts.last, isA<LLMFinishPart>());
      expect((parts.last as LLMFinishPart).response.text, equals('last'));

      final providerMetadataIndex =
          parts.indexWhere((p) => p is LLMProviderMetadataPart);
      expect(providerMetadataIndex, isNonNegative);
      expect(providerMetadataIndex, lessThan(parts.length - 1));
    });
  });
}
