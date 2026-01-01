import 'package:llm_dart_anthropic_compatible/llm_dart_anthropic_compatible.dart';
import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:test/test.dart';

import '_fake_anthropic_compatible_client.dart';

void main() {
  group('AnthropicChat chatStream legacy conformance (Anthropic-compatible)',
      () {
    test('aggregates tool_use deltas into a single ToolCallDeltaEvent',
        () async {
      const config = AnthropicConfig(
        apiKey: 'k',
        providerId: 'anthropic',
        stream: true,
      );

      final client = FakeAnthropicCompatibleClient(
        config,
        chunks: const [
          // Include an event line to ensure the parser ignores it.
          'event: message_start\n'
              'data: {"type":"message_start","message":{"id":"msg_legacy","model":"test-model","usage":{"input_tokens":10,"output_tokens":0}}}\n'
              '\n',
          'data: {"type":"content_block_start","index":0,"content_block":{"type":"tool_use","id":"toolu_1","name":"getWeather"}}\n',
          // Split a data line across chunks to assert buffering works.
          'data: {"type":"content_block_delta","index":0,"delta":{"type":"input_json_delta","partial_json":"{\\"city\\":\\"Lon"}}',
          '\n',
          'data: {"type":"content_block_delta","index":0,"delta":{"type":"input_json_delta","partial_json":"don\\"}"}}\n',
          'data: {"type":"content_block_stop","index":0}\n',
          'data: {"type":"message_delta","delta":{"stop_reason":"tool_use"},"usage":{"output_tokens":5}}\n',
          'data: {"type":"message_stop"}\n',
        ],
      );

      final chat = AnthropicChat(client, config);

      final events = await chat
          .chatStream([ChatMessage.user('Hi')], tools: const []).toList();

      final toolEvents = events.whereType<ToolCallDeltaEvent>().toList();
      expect(toolEvents, hasLength(1));
      expect(toolEvents.single.toolCall.id, equals('toolu_1'));
      expect(toolEvents.single.toolCall.function.name, equals('getWeather'));
      expect(
        toolEvents.single.toolCall.function.arguments,
        equals('{"city":"London"}'),
      );
    });

    test('does not surface provider-native web_search as ToolCallDeltaEvent',
        () async {
      const config = AnthropicConfig(
        apiKey: 'k',
        providerId: 'anthropic',
        stream: true,
      );

      final client = FakeAnthropicCompatibleClient(
        config,
        chunks: const [
          'data: {"type":"message_start","message":{"id":"msg_ws","model":"test-model","usage":{"input_tokens":10,"output_tokens":0}}}\n',
          'data: {"type":"content_block_start","index":0,"content_block":{"type":"tool_use","id":"toolu_ws","name":"web_search"}}\n',
          'data: {"type":"content_block_delta","index":0,"delta":{"type":"input_json_delta","partial_json":"{\\"query\\":\\"dart\\"}"}}\n',
          'data: {"type":"content_block_stop","index":0}\n',
          'data: {"type":"message_stop"}\n',
        ],
      );

      final chat = AnthropicChat(client, config);

      final events = await chat
          .chatStream([ChatMessage.user('Hi')], tools: const []).toList();

      expect(events.whereType<ToolCallDeltaEvent>(), isEmpty);
    });
  });
}
