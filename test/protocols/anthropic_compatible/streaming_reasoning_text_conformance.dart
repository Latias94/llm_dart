import 'package:llm_dart_anthropic_compatible/llm_dart_anthropic_compatible.dart';
import 'package:llm_dart_core/core/stream_parts.dart';
import 'package:llm_dart_core/models/chat_models.dart';
import 'package:test/test.dart';

import '_fake_anthropic_compatible_client.dart';

typedef AnthropicCompatibleChatFactory = ChatStreamPartsCapability Function(
  AnthropicClient client,
  AnthropicConfig config,
);

class AnthropicCompatibleStreamingFixture {
  final List<String> chunks;
  final String expectedText;
  final String expectedThinkingSubstring;
  final String expectedMessageId;
  final String expectedModel;

  const AnthropicCompatibleStreamingFixture({
    required this.chunks,
    required this.expectedText,
    required this.expectedThinkingSubstring,
    required this.expectedMessageId,
    required this.expectedModel,
  });

  static const thinkingThenText = AnthropicCompatibleStreamingFixture(
    chunks: [
      'data: {"type":"message_start","message":{"id":"msg_1","model":"MiniMax-M2","usage":{"input_tokens":3,"output_tokens":0}}}\n',
      'data: {"type":"content_block_start","index":0,"content_block":{"type":"thinking","thinking":""}}\n',
      'data: {"type":"content_block_delta","index":0,"delta":{"type":"thinking_delta","thinking":"I will think."}}\n',
      'data: {"type":"content_block_stop","index":0}\n',
      'data: {"type":"content_block_start","index":1,"content_block":{"type":"text","text":""}}\n',
      'data: {"type":"content_block_delta","index":1,"delta":{"type":"text_delta","text":"Hello"}}\n',
      'data: {"type":"content_block_stop","index":1}\n',
      'data: {"type":"message_delta","delta":{"stop_reason":"end_turn"},"usage":{"output_tokens":5}}\n',
      'data: {"type":"message_stop"}\n',
    ],
    expectedText: 'Hello',
    expectedThinkingSubstring: 'I will think.',
    expectedMessageId: 'msg_1',
    expectedModel: 'MiniMax-M2',
  );
}

void registerAnthropicCompatibleReasoningTextStreamingConformanceTests({
  required String groupName,
  required AnthropicConfig config,
  required AnthropicCompatibleChatFactory createChat,
  required String expectedProviderMetadataKey,
  AnthropicCompatibleStreamingFixture fixture =
      AnthropicCompatibleStreamingFixture.thinkingThenText,
}) {
  group(groupName, () {
    test('emits thinking_delta and text_delta parts in order', () async {
      final client = FakeAnthropicCompatibleClient(
        config,
        chunks: fixture.chunks,
      );
      final chat = createChat(client, config);

      final parts =
          await chat.chatStreamParts([ChatMessage.user('hi')]).toList();

      final reasoningStartIndex =
          parts.indexWhere((part) => part is LLMReasoningStartPart);
      final reasoningDeltaIndex =
          parts.indexWhere((part) => part is LLMReasoningDeltaPart);
      final reasoningEndIndex =
          parts.indexWhere((part) => part is LLMReasoningEndPart);

      final textStartIndex =
          parts.indexWhere((part) => part is LLMTextStartPart);
      final textDeltaIndex =
          parts.indexWhere((part) => part is LLMTextDeltaPart);
      final textEndIndex = parts.indexWhere((part) => part is LLMTextEndPart);

      final finishIndex = parts.indexWhere((part) => part is LLMFinishPart);

      expect(reasoningStartIndex, greaterThanOrEqualTo(0));
      expect(reasoningDeltaIndex, greaterThan(reasoningStartIndex));
      expect(reasoningEndIndex, greaterThan(reasoningDeltaIndex));

      expect(textStartIndex, greaterThan(reasoningEndIndex));
      expect(textDeltaIndex, greaterThan(textStartIndex));
      expect(textEndIndex, greaterThan(textDeltaIndex));

      expect(finishIndex, greaterThan(textEndIndex));

      final finish = parts.whereType<LLMFinishPart>().single;
      expect(finish.response.text, equals(fixture.expectedText));
      expect(
        finish.response.thinking,
        contains(fixture.expectedThinkingSubstring),
      );

      final providerMetadata = finish.response.providerMetadata;
      expect(providerMetadata, isNotNull);
      expect(
          providerMetadata!.containsKey(expectedProviderMetadataKey), isTrue);

      final metadata = providerMetadata[expectedProviderMetadataKey];
      expect(metadata, isA<Map<String, dynamic>>());

      final typed = metadata as Map<String, dynamic>;
      expect(typed['id'], equals(fixture.expectedMessageId));
      expect(typed['model'], equals(fixture.expectedModel));
    });
  });
}
