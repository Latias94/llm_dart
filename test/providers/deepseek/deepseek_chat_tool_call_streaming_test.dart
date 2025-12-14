/// Streaming tool call tests for DeepSeekChat.
///
/// This test verifies that the DeepSeekChat streaming implementation:
/// - Preserves a stable tool call ID across all chunks
/// - Emits ToolCallDeltaEvent instances in order with incremental arguments
library;

import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_deepseek/testing.dart' as deepseek;
import 'package:test/test.dart';
import 'deepseek_test_utils.dart';

void main() {
  group('DeepSeekChat streaming tool calls', () {
    test('should preserve tool call id across incremental tool_calls',
        () async {
      final config = deepseek.DeepSeekConfig(
        apiKey: 'test-key',
        baseUrl: 'https://api.deepseek.com/v1/',
        model: 'deepseek-chat',
      );

      final client = FakeDeepSeekStreamClient(
        config,
        chunks: const <String>[
          'data: {"choices":[{"delta":{"tool_calls":[{"index":0,"id":"call_1","type":"function","function":{"name":"get_weather","arguments":""}}]},"finish_reason":null}]}\n',
          'data: {"choices":[{"delta":{"tool_calls":[{"index":0,"type":"function","function":{"arguments":"{\\"location\\": \\""}}]},"finish_reason":null}]}\n',
          'data: {"choices":[{"delta":{"tool_calls":[{"index":0,"type":"function","function":{"arguments":"New York\\"}"}}]},"finish_reason":"tool_calls"}],"usage":{"prompt_tokens":1,"completion_tokens":2,"total_tokens":3}}\n',
          'data: [DONE]\n',
        ],
      );
      final chat = deepseek.DeepSeekChat(client, config);

      final events =
          await chat.chatStream([ModelMessage.userText('test')]).toList();

      final toolEvents = events.whereType<ToolCallDeltaEvent>().toList();
      expect(toolEvents, hasLength(3));

      // All chunks should share the same id, proving index → id tracking works.
      final ids = toolEvents.map((e) => e.toolCall.id).toSet();
      expect(ids.length, equals(1));
      expect(ids.single, equals('call_1'));

      // Arguments should reflect incremental updates in order:
      // '', '{"location": "', 'New York"}'.
      expect(
        toolEvents.map((e) => e.toolCall.function.arguments).toList(),
        equals([
          '',
          '{"location": "',
          'New York"}',
        ]),
      );
    });
  });
}
