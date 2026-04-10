import 'dart:async';

import 'package:llm_dart/legacy.dart';
import 'package:llm_dart/providers/openai/chat.dart' as openai_chat;
import 'package:llm_dart/providers/openai/client.dart' as openai_client;
import 'package:llm_dart/providers/openai/config.dart' as openai_config;
import 'package:llm_dart/providers/openai/responses.dart' as openai_responses;
import 'package:test/test.dart';

void main() {
  group('OpenAI stream parsing support', () {
    test('OpenAIChat preserves tool call ids across incremental chunks',
        () async {
      final config = openai_config.OpenAIConfig(
        apiKey: 'test-key',
        baseUrl: 'https://api.openai.com/v1/',
        model: 'gpt-4.1-mini',
      );

      final client = _FakeOpenAIChatClient(config);
      final chat = openai_chat.OpenAIChat(client, config);

      final events = await chat.chatStream([ChatMessage.user('test')]).toList();
      final toolEvents = events.whereType<ToolCallDeltaEvent>().toList();

      expect(toolEvents, hasLength(3));
      expect(toolEvents.map((event) => event.toolCall.id).toSet(), {'call_1'});
      expect(
        toolEvents.map((event) => event.toolCall.function.arguments).toList(),
        equals([
          '',
          '{"location":"',
          'Hong Kong"}',
        ]),
      );
    });

    test(
        'OpenAIResponses maps think tags into thinking deltas and completion thinking',
        () async {
      final config = openai_config.OpenAIConfig(
        apiKey: 'test-key',
        baseUrl: 'https://api.openai.com/v1/',
        model: 'gpt-4.1-mini',
        useResponsesAPI: true,
      );

      final client = _FakeOpenAIResponsesClient(config);
      final responses = openai_responses.OpenAIResponses(client, config);

      final events =
          await responses.chatStream([ChatMessage.user('test')]).toList();

      final thinkingEvent = events.whereType<ThinkingDeltaEvent>().single;
      expect(thinkingEvent.delta, 'Need search');

      final completion = events.whereType<CompletionEvent>().single;
      expect(completion.response.thinking, 'Need search');
      expect(completion.response.text, 'Done.');
    });
  });
}

class _FakeOpenAIChatClient extends openai_client.OpenAIClient {
  _FakeOpenAIChatClient(super.config);

  @override
  Stream<String> postStreamRaw(
    String endpoint,
    Map<String, dynamic> body, {
    TransportCancellation? cancelToken,
  }) async* {
    const chunks = <String>[
      'data: {"choices":[{"delta":{"tool_calls":[{"index":0,"id":"call_1","type":"function","function":{"name":"get_weather","arguments":""}}]}}]}\n',
      'data: {"choices":[{"delta":{"tool_calls":[{"index":0,"type":"function","function":{"arguments":"{\\"location\\":\\"" }}]}}]}\n',
      'data: {"choices":[{"delta":{"tool_calls":[{"index":0,"type":"function","function":{"arguments":"Hong Kong\\"}"}}]}}]}\n',
      'data: [DONE]\n',
    ];

    for (final chunk in chunks) {
      yield chunk;
    }
  }
}

class _FakeOpenAIResponsesClient extends openai_client.OpenAIClient {
  _FakeOpenAIResponsesClient(super.config);

  @override
  Stream<String> postStreamRaw(
    String endpoint,
    Map<String, dynamic> body, {
    TransportCancellation? cancelToken,
  }) async* {
    const chunks = <String>[
      'data: {"type":"response.output_text.delta","delta":"<think>Need search</think>"}\n',
      'data: {"type":"response.completed","response":{"id":"resp_1","status":"completed","output":[{"id":"msg_1","type":"message","status":"completed","role":"assistant","content":[{"type":"output_text","text":"Done.","annotations":[]}]}]}}\n',
      'data: [DONE]\n',
    ];

    for (final chunk in chunks) {
      yield chunk;
    }
  }
}
