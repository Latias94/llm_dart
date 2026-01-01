import 'dart:async';

import 'package:llm_dart/llm_dart.dart';
import 'package:llm_dart_openai/llm_dart_openai.dart' as openai_client;
import 'package:test/test.dart';

void main() {
  group('OpenAIResponses streaming tool calls', () {
    test(
        'should preserve tool call id and tool name across incremental tool_calls',
        () async {
      final config = openai_client.OpenAIConfig(
        apiKey: 'test-key',
        baseUrl: 'https://api.openai.com/v1/',
        model: 'gpt-4.1-mini',
        // Ensure Responses API is used
        useResponsesAPI: true,
        builtInTools: const [OpenAIWebSearchTool()],
      );

      final client = _FakeOpenAIClient(config);
      final responses = openai_client.OpenAIResponses(client, config);

      final collidingTool = Tool.function(
        name: 'web_search_preview',
        description: 'test',
        parameters: const ParametersSchema(
          schemaType: 'object',
          properties: {},
          required: [],
        ),
      );

      final events = await responses.chatStream(
        [ChatMessage.user('test')],
        tools: [collidingTool],
      ).toList();

      final toolEvents = events.whereType<ToolCallDeltaEvent>().toList();
      expect(toolEvents, hasLength(3));

      // All chunks should share the same id, proving index → id tracking works.
      final ids = toolEvents.map((e) => e.toolCall.id).toSet();
      expect(ids.length, equals(1));
      expect(ids.single, equals('call_1'));

      // All chunks should preserve the original tool name (request name is mapped back).
      expect(
        toolEvents.map((e) => e.toolCall.function.name).toSet(),
        equals({'web_search_preview'}),
      );

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
class _FakeOpenAIClient extends OpenAIClient {
  _FakeOpenAIClient(super.config);

  @override
  Stream<String> postStreamRaw(
    String endpoint,
    Map<String, dynamic> body, {
    CancelToken? cancelToken,
  }) async* {
    // Simulate an OpenAI Responses SSE stream with incremental tool_calls chunks.
    const chunks = <String>[
      'data: {"type":"response.output_text.delta","delta":""}\n',
      'data: {"tool_calls":[{"index":0,"id":"call_1","type":"function","function":{"name":"web_search_preview__1","arguments":""}}]}\n',
      'data: {"tool_calls":[{"index":0,"type":"function","function":{"arguments":"{\\"location\\": \\""}}]}\n',
      'data: {"tool_calls":[{"index":0,"type":"function","function":{"arguments":"New York\\"}"}}]}\n',
      'data: [DONE]\n',
    ];

    for (final chunk in chunks) {
      yield chunk;
    }
  }
}
