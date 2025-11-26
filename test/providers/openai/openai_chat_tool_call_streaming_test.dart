/// Streaming tool call tests for OpenAI Chat (llm_dart_openai).
///
/// This test verifies that the OpenAIChat streaming implementation:
/// - Preserves a stable tool call ID across all chunks
/// - Emits ToolCallDeltaEvent instances in order with incremental arguments
library;

import 'dart:async';

import 'package:dio/dio.dart';
import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_openai/llm_dart_openai.dart' as openai;
import 'package:test/test.dart';

void main() {
  group('OpenAIChat streaming tool calls', () {
    test('should preserve tool call id across incremental tool_calls',
        () async {
      final config = openai.OpenAIConfig(
        apiKey: 'test-key',
        baseUrl: 'https://api.openai.com/v1/',
        model: 'gpt-4o',
      );

      final client = _FakeOpenAIClient(config);
      final chat = openai.OpenAIChat(client, config);

      final events = await chat.chatStream([ChatMessage.user('test')]).toList();

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

/// Fake OpenAIClient that returns a synthetic SSE stream for testing.
class _FakeOpenAIClient extends openai.OpenAIClient {
  _FakeOpenAIClient(openai.OpenAIConfig config) : super(config);

  @override
  Stream<String> postStreamRaw(
    String endpoint,
    Map<String, dynamic> body, {
    CancelToken? cancelToken,
  }) async* {
    // Simulate an OpenAI Chat SSE stream with three incremental tool_calls
    // chunks and a final [DONE] marker.
    const chunks = <String>[
      'data: {"choices":[{"delta":{"tool_calls":[{"index":0,"id":"call_1","type":"function","function":{"name":"get_weather","arguments":""}}]},"finish_reason":null}]}\n',
      'data: {"choices":[{"delta":{"tool_calls":[{"index":0,"type":"function","function":{"arguments":"{\\"location\\": \\""}}]},"finish_reason":null}]}\n',
      'data: {"choices":[{"delta":{"tool_calls":[{"index":0,"type":"function","function":{"arguments":"New York\\"}"}}]},"finish_reason":"tool_calls"}],"usage":{"prompt_tokens":1,"completion_tokens":2,"total_tokens":3}}\n',
      'data: [DONE]\n',
    ];

    // Yield each chunk separately to simulate real SSE framing.
    for (final chunk in chunks) {
      yield chunk;
    }
  }
}
