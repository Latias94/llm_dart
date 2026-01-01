import 'package:llm_dart_anthropic_compatible/llm_dart_anthropic_compatible.dart';
import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:test/test.dart';

import '_fake_anthropic_compatible_client.dart';
import 'streaming_reasoning_text_conformance.dart'
    show AnthropicCompatibleChatFactory;

void registerAnthropicCompatibleToolUseStreamingConformanceTests({
  required String groupName,
  required AnthropicConfig config,
  required AnthropicCompatibleChatFactory createChat,
  required String expectedProviderMetadataKey,
}) {
  group(groupName, () {
    test('streams text + tool call parts and finishes with toolCalls',
        () async {
      final client = FakeAnthropicCompatibleClient(
        config,
        chunks: const [
          'data: {"type":"message_start","message":{"id":"msg_tool","model":"test-model","usage":{"input_tokens":10,"output_tokens":0}}}\n',
          'data: {"type":"content_block_start","index":0,"content_block":{"type":"text","text":""}}\n',
          'data: {"type":"content_block_delta","index":0,"delta":{"type":"text_delta","text":"Hello "}}\n',
          'data: {"type":"content_block_delta","index":0,"delta":{"type":"text_delta","text":"world"}}\n',
          'data: {"type":"content_block_stop","index":0}\n',
          'data: {"type":"message_delta","delta":{"stop_reason":"tool_use"},"usage":{"output_tokens":5}}\n',
          'data: {"type":"content_block_start","index":1,"content_block":{"type":"tool_use","id":"toolu_1","name":"getWeather"}}\n',
          'data: {"type":"content_block_delta","index":1,"delta":{"type":"input_json_delta","partial_json":"{\\"city\\":\\"Lon"}}\n',
          'data: {"type":"content_block_delta","index":1,"delta":{"type":"input_json_delta","partial_json":"don\\"}"}}\n',
          'data: {"type":"content_block_stop","index":1}\n',
          'data: {"type":"message_stop"}\n',
        ],
      );

      final chat = createChat(client, config);
      final parts = await chat
          .chatStreamParts([ChatMessage.user('Hi')], tools: const []).toList();

      expect(parts.whereType<LLMTextStartPart>(), hasLength(1));
      expect(
        parts.whereType<LLMTextDeltaPart>().map((p) => p.delta).join(),
        equals('Hello world'),
      );
      expect(
          parts.whereType<LLMTextEndPart>().single.text, equals('Hello world'));

      final toolStarts = parts.whereType<LLMToolCallStartPart>().toList();
      expect(toolStarts, hasLength(1));
      expect(toolStarts.single.toolCall.id, equals('toolu_1'));
      expect(toolStarts.single.toolCall.function.name, equals('getWeather'));

      final toolDeltas = parts.whereType<LLMToolCallDeltaPart>().toList();
      expect(toolDeltas, hasLength(2));
      expect(
        toolDeltas.map((p) => p.toolCall.function.arguments).join(),
        equals('{"city":"London"}'),
      );

      expect(parts.whereType<LLMToolCallEndPart>().single.toolCallId,
          equals('toolu_1'));

      final finish = parts.last as LLMFinishPart;
      expect(finish.response.text, equals('Hello world'));

      final calls = finish.response.toolCalls;
      expect(calls, isNotNull);
      expect(calls!, hasLength(1));
      expect(calls.single.function.name, equals('getWeather'));
      expect(calls.single.function.arguments, equals('{"city":"London"}'));

      final metadata = finish.response.providerMetadata;
      expect(metadata, isNotNull);
      final typed =
          metadata![expectedProviderMetadataKey] as Map<String, dynamic>;
      expect(typed['id'], equals('msg_tool'));
      expect(typed['model'], equals('test-model'));
      expect(typed['stopReason'], equals('tool_use'));
      expect(typed['usage']['inputTokens'], equals(10));
      expect(typed['usage']['outputTokens'], equals(5));
    });

    test('does not surface web_search as a local tool call part', () async {
      final client = FakeAnthropicCompatibleClient(
        config,
        chunks: const [
          'data: {"type":"message_start","message":{"id":"msg_ws","model":"test-model","usage":{"input_tokens":10,"output_tokens":0}}}\n',
          'data: {"type":"content_block_start","index":0,"content_block":{"type":"tool_use","id":"toolu_ws","name":"web_search"}}\n',
          'data: {"type":"content_block_delta","index":0,"delta":{"type":"input_json_delta","partial_json":"{\\"query\\":\\"dart\\"}"}}\n',
          'data: {"type":"content_block_stop","index":0}\n',
          'data: {"type":"message_delta","delta":{"stop_reason":"end_turn"},"usage":{"output_tokens":1,"server_tool_use":{"web_search_requests":1}}}\n',
          'data: {"type":"message_stop"}\n',
        ],
      );

      final chat = createChat(client, config);
      final parts = await chat
          .chatStreamParts([ChatMessage.user('Hi')], tools: const []).toList();

      expect(parts.whereType<LLMToolCallStartPart>(), isEmpty);
      expect(parts.whereType<LLMToolCallDeltaPart>(), isEmpty);
      expect(parts.whereType<LLMToolCallEndPart>(), isEmpty);

      final finish = parts.last as LLMFinishPart;
      expect(finish.response.toolCalls, anyOf(isNull, isEmpty));

      final metadata = finish.response.providerMetadata;
      expect(metadata, isNotNull);
      expect(
        metadata![expectedProviderMetadataKey]['usage']['serverToolUse']
            ['webSearchRequests'],
        equals(1),
      );
    });
  });
}
