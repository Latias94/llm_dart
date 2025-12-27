import 'package:llm_dart/llm_dart.dart';
import 'package:test/test.dart';

class _FakeAnthropicClient extends AnthropicClient {
  final Stream<String> _stream;

  _FakeAnthropicClient(
    super.config, {
    required Stream<String> stream,
  }) : _stream = stream;

  @override
  Stream<String> postStreamRaw(
    String endpoint,
    Map<String, dynamic> data, {
    CancelToken? cancelToken,
  }) {
    return _stream;
  }
}

void main() {
  group('Anthropic chatStream (legacy ChatStreamEvent) edge cases', () {
    test('does not emit CompletionEvent at message_delta', () async {
      final llmConfig = LLMConfig(
        apiKey: 'test-key',
        baseUrl: 'https://api.anthropic.com/v1/',
        model: 'claude-sonnet-4-20250514',
      );
      final config = AnthropicConfig.fromLLMConfig(llmConfig);

      final sse = [
        'event: message_start\n'
            'data: {"type":"message_start","message":{"id":"msg_123","model":"claude-sonnet-4-20250514","usage":{"input_tokens":10,"output_tokens":0}}}\n'
            '\n'
            'event: content_block_start\n'
            'data: {"type":"content_block_start","index":0,"content_block":{"type":"text","text":""}}\n'
            '\n'
            'event: content_block_delta\n'
            'data: {"type":"content_block_delta","index":0,"delta":{"type":"text_delta","text":"Hello"}}\n'
            '\n'
            'event: content_block_stop\n'
            'data: {"type":"content_block_stop","index":0}\n'
            '\n'
            'event: message_delta\n'
            'data: {"type":"message_delta","delta":{"stop_reason":"end_turn"},"usage":{"output_tokens":5}}\n'
            '\n'
            'event: message_stop\n'
            'data: {"type":"message_stop"}\n'
            '\n',
      ];

      final client = _FakeAnthropicClient(
        config,
        stream: Stream<String>.fromIterable(sse),
      );
      final chat = AnthropicChat(client, config);

      final events = await chat.chatStream([ChatMessage.user('Hi')]).toList();

      expect(events.whereType<TextDeltaEvent>().map((e) => e.delta).join(),
          equals('Hello'));
      expect(events.whereType<CompletionEvent>(), hasLength(1));

      final completion = events.whereType<CompletionEvent>().single;
      expect(completion.response.providerMetadata, isNotNull);
      expect(completion.response.providerMetadata!['anthropic']['stopReason'],
          equals('end_turn'));
      expect(
          completion.response.providerMetadata!['anthropic']['usage']
              ['outputTokens'],
          equals(5));
    });

    test('tool_use start may include non-empty input and emits a tool event',
        () async {
      final llmConfig = LLMConfig(
        apiKey: 'test-key',
        baseUrl: 'https://api.anthropic.com/v1/',
        model: 'claude-sonnet-4-20250514',
      );
      final config = AnthropicConfig.fromLLMConfig(llmConfig);

      final sse = [
        'event: message_start\n'
            'data: {"type":"message_start","message":{"id":"msg_1","model":"claude-sonnet-4-20250514","usage":{"input_tokens":1,"output_tokens":0}}}\n'
            '\n'
            'event: content_block_start\n'
            'data: {"type":"content_block_start","index":0,"content_block":{"type":"tool_use","id":"toolu_1","name":"getWeather","input":{"city":"London"}}}\n'
            '\n'
            'event: content_block_stop\n'
            'data: {"type":"content_block_stop","index":0}\n'
            '\n'
            'event: message_delta\n'
            'data: {"type":"message_delta","delta":{"stop_reason":"tool_use"},"usage":{"output_tokens":1}}\n'
            '\n'
            'event: message_stop\n'
            'data: {"type":"message_stop"}\n'
            '\n',
      ];

      final client = _FakeAnthropicClient(
        config,
        stream: Stream<String>.fromIterable(sse),
      );
      final chat = AnthropicChat(client, config);

      final events = await chat.chatStream([ChatMessage.user('Hi')]).toList();

      final toolEvents = events.whereType<ToolCallDeltaEvent>().toList();
      expect(toolEvents, hasLength(1));
      expect(toolEvents.single.toolCall.id, equals('toolu_1'));
      expect(toolEvents.single.toolCall.function.name, equals('getWeather'));
      expect(
        toolEvents.single.toolCall.function.arguments,
        equals('{"city":"London"}'),
      );

      final completion = events.whereType<CompletionEvent>().single;
      expect(completion.response.toolCalls, isNotNull);
      expect(completion.response.toolCalls, hasLength(1));
      expect(completion.response.toolCalls!.single.function.arguments,
          equals('{"city":"London"}'));
    });

    test('tool_use partial_json emits a single ToolCallDeltaEvent', () async {
      final llmConfig = LLMConfig(
        apiKey: 'test-key',
        baseUrl: 'https://api.anthropic.com/v1/',
        model: 'claude-sonnet-4-20250514',
      );
      final config = AnthropicConfig.fromLLMConfig(llmConfig);

      final sse = [
        'event: message_start\n'
            'data: {"type":"message_start","message":{"id":"msg_2","model":"claude-sonnet-4-20250514","usage":{"input_tokens":1,"output_tokens":0}}}\n'
            '\n'
            'event: content_block_start\n'
            'data: {"type":"content_block_start","index":0,"content_block":{"type":"tool_use","id":"toolu_2","name":"getWeather"}}\n'
            '\n'
            'event: content_block_delta\n'
            'data: {"type":"content_block_delta","index":0,"delta":{"type":"input_json_delta","partial_json":"{\\"city\\":\\"Lon"}}\n'
            '\n'
            'event: content_block_delta\n'
            'data: {"type":"content_block_delta","index":0,"delta":{"type":"input_json_delta","partial_json":"don\\"}"}}\n'
            '\n'
            'event: content_block_stop\n'
            'data: {"type":"content_block_stop","index":0}\n'
            '\n'
            'event: message_delta\n'
            'data: {"type":"message_delta","delta":{"stop_reason":"tool_use"},"usage":{"output_tokens":1}}\n'
            '\n'
            'event: message_stop\n'
            'data: {"type":"message_stop"}\n'
            '\n',
      ];

      final client = _FakeAnthropicClient(
        config,
        stream: Stream<String>.fromIterable(sse),
      );
      final chat = AnthropicChat(client, config);

      final events = await chat.chatStream([ChatMessage.user('Hi')]).toList();

      final toolEvents = events.whereType<ToolCallDeltaEvent>().toList();
      expect(toolEvents, hasLength(1));
      expect(toolEvents.single.toolCall.function.arguments,
          equals('{"city":"London"}'));

      final completion = events.whereType<CompletionEvent>().single;
      expect(completion.response.toolCalls, isNotNull);
      expect(completion.response.toolCalls, hasLength(1));
      expect(completion.response.toolCalls!.single.function.arguments,
          equals('{"city":"London"}'));
    });
  });
}
