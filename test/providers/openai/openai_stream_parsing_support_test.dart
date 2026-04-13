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
        toolEvents.map((event) => event.toolCall.function.name).toSet(),
        {'get_weather'},
      );
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

    test(
        'OpenAIResponses preserves split think tags and mixed visible text across chunks',
        () async {
      final config = openai_config.OpenAIConfig(
        apiKey: 'test-key',
        baseUrl: 'https://api.openai.com/v1/',
        model: 'gpt-4.1-mini',
        useResponsesAPI: true,
      );

      final client = _SplitThinkTagsResponsesClient(config);
      final responses = openai_responses.OpenAIResponses(client, config);

      final events =
          await responses.chatStream([ChatMessage.user('test')]).toList();

      expect(
        events.whereType<TextDeltaEvent>().map((event) => event.delta).toList(),
        ['Hello ', ' world'],
      );
      expect(
        events
            .whereType<ThinkingDeltaEvent>()
            .map((event) => event.delta)
            .join(),
        'Need search',
      );

      final completion = events.whereType<CompletionEvent>().single;
      expect(completion.response.thinking, 'Need search');
      expect(completion.response.text, 'Hello world');
    });

    test('OpenAIChat completion aggregates streamed text and tool calls',
        () async {
      final config = openai_config.OpenAIConfig(
        apiKey: 'test-key',
        baseUrl: 'https://api.openai.com/v1/',
        model: 'gpt-4.1-mini',
      );

      final client = _AggregatingOpenAIChatClient(config);
      final chat = openai_chat.OpenAIChat(client, config);

      final events = await chat.chatStream([ChatMessage.user('test')]).toList();

      expect(
        events.whereType<TextDeltaEvent>().map((event) => event.delta).toList(),
        ['Hello ', 'world'],
      );
      expect(
        events
            .whereType<ThinkingDeltaEvent>()
            .map((event) => event.delta)
            .join(),
        'Plan first.',
      );

      final completion = events.whereType<CompletionEvent>().single;
      expect(completion.response.text, 'Hello world');
      expect(completion.response.thinking, 'Plan first.');
      expect(completion.response.toolCalls, hasLength(1));
      expect(completion.response.toolCalls!.single.id, 'call_7');
      expect(
        completion.response.toolCalls!.single.function.name,
        'get_weather',
      );
      expect(
        completion.response.toolCalls!.single.function.arguments,
        '{"city":"Hong Kong"}',
      );
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

class _SplitThinkTagsResponsesClient extends openai_client.OpenAIClient {
  _SplitThinkTagsResponsesClient(super.config);

  @override
  Stream<String> postStreamRaw(
    String endpoint,
    Map<String, dynamic> body, {
    TransportCancellation? cancelToken,
  }) async* {
    const chunks = <String>[
      'data: {"type":"response.output_text.delta","delta":"Hello <thi"}\n',
      'data: {"type":"response.output_text.delta","delta":"nk>Need"}\n',
      'data: {"type":"response.output_text.delta","delta":" search</th"}\n',
      'data: {"type":"response.output_text.delta","delta":"ink> world"}\n',
      'data: {"type":"response.completed","response":{"id":"resp_split","status":"completed","output":[{"id":"msg_1","type":"message","status":"completed","role":"assistant","content":[{"type":"output_text","text":"Hello world","annotations":[]}]}]}}\n',
      'data: [DONE]\n',
    ];

    for (final chunk in chunks) {
      yield chunk;
    }
  }
}

class _AggregatingOpenAIChatClient extends openai_client.OpenAIClient {
  _AggregatingOpenAIChatClient(super.config);

  @override
  Stream<String> postStreamRaw(
    String endpoint,
    Map<String, dynamic> body, {
    TransportCancellation? cancelToken,
  }) async* {
    const chunks = <String>[
      'data: {"choices":[{"delta":{"content":"Hello "},"finish_reason":null}]}\n',
      'data: {"choices":[{"delta":{"content":"<think>Plan "},"finish_reason":null}]}\n',
      'data: {"choices":[{"delta":{"content":"first.</think>world"},"finish_reason":null}]}\n',
      'data: {"choices":[{"delta":{"tool_calls":[{"index":0,"id":"call_7","type":"function","function":{"name":"get_weather","arguments":"{\\"city\\":\\"" }}]},"finish_reason":null}]}\n',
      'data: {"choices":[{"delta":{"tool_calls":[{"index":0,"type":"function","function":{"arguments":"Hong Kong\\"}"}}]},"finish_reason":null}]}\n',
      'data: {"choices":[{"delta":{},"finish_reason":"tool_calls"}],"usage":{"prompt_tokens":2,"completion_tokens":4,"total_tokens":6}}\n',
      'data: [DONE]\n',
    ];

    for (final chunk in chunks) {
      yield chunk;
    }
  }
}
