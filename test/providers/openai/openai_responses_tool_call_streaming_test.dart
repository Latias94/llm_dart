import 'dart:async';

import 'package:dio/dio.dart';
import 'package:llm_dart/llm_dart.dart';
import 'package:llm_dart/providers/openai/client.dart' as openai_client;
import 'package:llm_dart/providers/openai/config.dart' as openai_config;
import 'package:llm_dart/providers/openai/responses.dart' as openai_responses;
import 'package:test/test.dart';

void main() {
  group('OpenAIResponses streaming tool calls', () {
    test('should preserve tool call id across incremental tool_calls',
        () async {
      final config = openai_config.OpenAIConfig(
        apiKey: 'test-key',
        baseUrl: 'https://api.openai.com/v1/',
        model: 'gpt-4.1-mini',
        // Ensure Responses API is used
        useResponsesAPI: true,
      );

      final client = _FakeOpenAIClient(config);
      final responses = openai_responses.OpenAIResponses(client, config);

      final events =
          await responses.chatStream([ChatMessage.user('test')]).toList();

      final toolEvents = events.whereType<ToolCallDeltaEvent>().toList();
      expect(toolEvents, hasLength(3));

      // All chunks should share the same id, proving index → id tracking works.
      final ids = toolEvents.map((e) => e.toolCall.id).toSet();
      expect(ids.length, equals(1));
      expect(ids.single, equals('call_1'));

      // Arguments should reflect incremental updates in order.
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

/// Fake OpenAIClient that returns a synthetic SSE stream for testing Responses API.
class _FakeOpenAIClient extends openai_client.OpenAIClient {
  _FakeOpenAIClient(openai_config.OpenAIConfig config) : super(config);

  @override
  Stream<String> postStreamRaw(
    String endpoint,
    Map<String, dynamic> body, {
    CancelToken? cancelToken,
  }) async* {
    // Simulate an OpenAI Responses SSE stream with incremental tool_calls chunks.
    const chunks = <String>[
      'data: {"type":"response.output_text.delta","delta":""}\n',
      'data: {"tool_calls":[{"index":0,"id":"call_1","type":"function","function":{"name":"get_weather","arguments":""}}]}\n',
      'data: {"tool_calls":[{"index":0,"type":"function","function":{"arguments":"{\\"location\\": \\""}}]}\n',
      'data: {"tool_calls":[{"index":0,"type":"function","function":{"arguments":"New York\\"}"}}]}\n',
      'data: [DONE]\n',
    ];

    for (final chunk in chunks) {
      yield chunk;
    }
  }
}
