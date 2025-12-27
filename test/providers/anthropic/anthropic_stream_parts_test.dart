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
  group('Anthropic chatStreamParts (provider-native parts)', () {
    test('streams text + tool call parts and finishes with toolCalls',
        () async {
      final llmConfig = LLMConfig(
        apiKey: 'test-key',
        baseUrl: 'https://api.anthropic.com/v1/',
        model: 'claude-sonnet-4-20250514',
      );

      final anthropicConfig = AnthropicConfig.fromLLMConfig(llmConfig);

      final sse = [
        'event: message_start\n'
            'data: {"type":"message_start","message":{"id":"msg_123","model":"claude-sonnet-4-20250514","usage":{"input_tokens":10,"output_tokens":0}}}\n'
            '\n'
            'event: content_block_start\n'
            'data: {"type":"content_block_start","index":0,"content_block":{"type":"text","text":""}}\n'
            '\n'
            'event: content_block_delta\n'
            'data: {"type":"content_block_delta","index":0,"delta":{"type":"text_delta","text":"Hello "}}\n'
            '\n'
            'event: content_block_delta\n'
            'data: {"type":"content_block_delta","index":0,"delta":{"type":"text_delta","text":"world"}}\n'
            '\n'
            'event: content_block_stop\n'
            'data: {"type":"content_block_stop","index":0}\n'
            '\n'
            'event: message_delta\n'
            'data: {"type":"message_delta","delta":{"stop_reason":"tool_use"},"usage":{"output_tokens":5}}\n'
            '\n'
            'event: content_block_start\n'
            'data: {"type":"content_block_start","index":1,"content_block":{"type":"tool_use","id":"toolu_1","name":"getWeather"}}\n'
            '\n'
            'event: content_block_delta\n'
            'data: {"type":"content_block_delta","index":1,"delta":{"type":"input_json_delta","partial_json":"{\\"city\\":\\"Lon"}}\n'
            '\n'
            'event: content_block_delta\n'
            'data: {"type":"content_block_delta","index":1,"delta":{"type":"input_json_delta","partial_json":"don\\"}"}}\n'
            '\n'
            'event: content_block_stop\n'
            'data: {"type":"content_block_stop","index":1}\n'
            '\n'
            'event: message_stop\n'
            'data: {"type":"message_stop"}\n'
            '\n',
      ];

      final client = _FakeAnthropicClient(
        anthropicConfig,
        stream: Stream<String>.fromIterable(sse),
      );
      final chat = AnthropicChat(client, anthropicConfig);

      final parts = await chat.chatStreamParts(
        [ChatMessage.user('Hi')],
        tools: const [],
      ).toList();

      expect(parts.whereType<LLMTextStartPart>(), hasLength(1));
      expect(parts.whereType<LLMTextDeltaPart>().map((p) => p.delta).join(),
          equals('Hello world'));
      expect(
          parts.whereType<LLMTextEndPart>().single.text, equals('Hello world'));

      final toolStarts = parts.whereType<LLMToolCallStartPart>().toList();
      expect(toolStarts, hasLength(1));
      expect(toolStarts.single.toolCall.id, equals('toolu_1'));
      expect(toolStarts.single.toolCall.function.name, equals('getWeather'));

      final toolDeltas = parts.whereType<LLMToolCallDeltaPart>().toList();
      expect(toolDeltas, hasLength(2));
      expect(toolDeltas.map((p) => p.toolCall.function.arguments).join(),
          equals('{"city":"London"}'));

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
      expect(metadata!['anthropic']['id'], equals('msg_123'));
      expect(
          metadata['anthropic']['model'], equals('claude-sonnet-4-20250514'));
      expect(metadata['anthropic']['stopReason'], equals('tool_use'));
      expect(metadata['anthropic']['usage']['inputTokens'], equals(10));
      expect(metadata['anthropic']['usage']['outputTokens'], equals(5));
    });

    test('does not surface web_search as a local tool call part', () async {
      final llmConfig = LLMConfig(
        apiKey: 'test-key',
        baseUrl: 'https://api.anthropic.com/v1/',
        model: 'claude-sonnet-4-20250514',
        providerOptions: const {
          'anthropic': {
            'webSearchEnabled': true,
          },
        },
      );

      final anthropicConfig = AnthropicConfig.fromLLMConfig(llmConfig);

      final sse = [
        'event: message_start\n'
            'data: {"type":"message_start","message":{"id":"msg_ws","model":"claude-sonnet-4-20250514","usage":{"input_tokens":10,"output_tokens":0}}}\n'
            '\n'
            'event: content_block_start\n'
            'data: {"type":"content_block_start","index":0,"content_block":{"type":"tool_use","id":"toolu_ws","name":"web_search"}}\n'
            '\n'
            'event: content_block_delta\n'
            'data: {"type":"content_block_delta","index":0,"delta":{"type":"input_json_delta","partial_json":"{\\"query\\":\\"dart\\"}"}}\n'
            '\n'
            'event: content_block_stop\n'
            'data: {"type":"content_block_stop","index":0}\n'
            '\n'
            'event: message_delta\n'
            'data: {"type":"message_delta","delta":{"stop_reason":"end_turn"},"usage":{"output_tokens":1,"server_tool_use":{"web_search_requests":1}}}\n'
            '\n'
            'event: message_stop\n'
            'data: {"type":"message_stop"}\n'
            '\n',
      ];

      final client = _FakeAnthropicClient(
        anthropicConfig,
        stream: Stream<String>.fromIterable(sse),
      );
      final chat = AnthropicChat(client, anthropicConfig);

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
          metadata!['anthropic']['usage']['serverToolUse']['webSearchRequests'],
          equals(1));
    });

    test('does not surface web_fetch as a local tool call part', () async {
      final llmConfig = LLMConfig(
        apiKey: 'test-key',
        baseUrl: 'https://api.anthropic.com/v1/',
        model: 'claude-sonnet-4-20250514',
        providerOptions: const {
          'anthropic': {
            'webFetchEnabled': true,
          },
        },
      );

      final anthropicConfig = AnthropicConfig.fromLLMConfig(llmConfig);

      final sse = [
        'event: message_start\n'
            'data: {"type":"message_start","message":{"id":"msg_wf","model":"claude-sonnet-4-20250514","usage":{"input_tokens":10,"output_tokens":0}}}\n'
            '\n'
            'event: content_block_start\n'
            'data: {"type":"content_block_start","index":0,"content_block":{"type":"tool_use","id":"toolu_wf","name":"web_fetch"}}\n'
            '\n'
            'event: content_block_delta\n'
            'data: {"type":"content_block_delta","index":0,"delta":{"type":"input_json_delta","partial_json":"{\\"url\\":\\"https://example.com\\"}"}}\n'
            '\n'
            'event: content_block_stop\n'
            'data: {"type":"content_block_stop","index":0}\n'
            '\n'
            'event: message_delta\n'
            'data: {"type":"message_delta","delta":{"stop_reason":"end_turn"},"usage":{"output_tokens":1,"server_tool_use":{"web_fetch_requests":1}}}\n'
            '\n'
            'event: message_stop\n'
            'data: {"type":"message_stop"}\n'
            '\n',
      ];

      final client = _FakeAnthropicClient(
        anthropicConfig,
        stream: Stream<String>.fromIterable(sse),
      );
      final chat = AnthropicChat(client, anthropicConfig);

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
          metadata!['anthropic']['usage']['serverToolUse']['webFetchRequests'],
          equals(1));
    });
  });
}
