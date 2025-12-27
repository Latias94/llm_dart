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
  group('Anthropic chatStreamParts edge cases', () {
    test('message_start may include pre-populated tool_use blocks', () async {
      final llmConfig = LLMConfig(
        apiKey: 'test-key',
        baseUrl: 'https://api.anthropic.com/v1/',
        model: 'claude-sonnet-4-20250514',
      );
      final config = AnthropicConfig.fromLLMConfig(llmConfig);

      final sse = [
        'event: message_start\n'
            'data: {"type":"message_start","message":{"id":"msg_prefill","model":"claude-sonnet-4-20250514","usage":{"input_tokens":1,"output_tokens":0},"content":[{"type":"tool_use","id":"toolu_prefill","name":"getWeather","input":{"city":"London"}}]}}\n'
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

      final parts =
          await chat.chatStreamParts([ChatMessage.user('Hi')]).toList();

      final toolStarts = parts.whereType<LLMToolCallStartPart>().toList();
      expect(toolStarts, hasLength(1));
      expect(toolStarts.single.toolCall.id, equals('toolu_prefill'));
      expect(toolStarts.single.toolCall.function.name, equals('getWeather'));
      expect(
        toolStarts.single.toolCall.function.arguments,
        equals('{"city":"London"}'),
      );

      expect(parts.whereType<LLMToolCallEndPart>(), hasLength(1));

      final finish = parts.whereType<LLMFinishPart>().single;
      expect(finish.response.toolCalls, isNotNull);
      expect(finish.response.toolCalls, hasLength(1));
      expect(finish.response.toolCalls!.single.function.name,
          equals('getWeather'));
    });

    test('tool_use content_block_start may include non-empty input', () async {
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

      final parts =
          await chat.chatStreamParts([ChatMessage.user('Hi')]).toList();

      final toolStarts = parts.whereType<LLMToolCallStartPart>().toList();
      expect(toolStarts, hasLength(1));
      expect(toolStarts.single.toolCall.id, equals('toolu_1'));
      expect(toolStarts.single.toolCall.function.name, equals('getWeather'));
      expect(
        toolStarts.single.toolCall.function.arguments,
        equals('{"city":"London"}'),
      );

      expect(parts.whereType<LLMToolCallDeltaPart>(), isEmpty);
      expect(parts.whereType<LLMToolCallEndPart>().single.toolCallId,
          equals('toolu_1'));

      final finish = parts.whereType<LLMFinishPart>().single;
      final response = finish.response;

      expect(response.toolCalls, isNotNull);
      expect(response.toolCalls, hasLength(1));
      expect(response.toolCalls!.single.function.name, equals('getWeather'));
      expect(
        response.toolCalls!.single.function.arguments,
        equals('{"city":"London"}'),
      );

      final assistant =
          (response as ChatResponseWithAssistantMessage).assistantMessage;
      // Protocol-internal: content blocks are preserved via ChatMessage.extensions.
      // ignore: deprecated_member_use
      final anthropic =
          assistant.getExtension<Map<String, dynamic>>('anthropic');
      final blocks = (anthropic?['contentBlocks'] as List?)?.cast<dynamic>();
      expect(blocks, isNotNull);
      expect(blocks!, hasLength(1));
      expect((blocks.single as Map)['type'], equals('tool_use'));
      expect((blocks.single as Map)['name'], equals('getWeather'));
      expect((blocks.single as Map)['input'], equals({'city': 'London'}));
    });

    test(
        'server_tool_use and *_tool_result blocks are preserved as assistant content blocks',
        () async {
      final llmConfig = LLMConfig(
        apiKey: 'test-key',
        baseUrl: 'https://api.anthropic.com/v1/',
        model: 'claude-sonnet-4-20250514',
      );
      final config = AnthropicConfig.fromLLMConfig(llmConfig);

      final sse = [
        'event: message_start\n'
            'data: {"type":"message_start","message":{"id":"msg_ws","model":"claude-sonnet-4-20250514","usage":{"input_tokens":10,"output_tokens":0}}}\n'
            '\n'
            'event: content_block_start\n'
            'data: {"type":"content_block_start","index":0,"content_block":{"type":"server_tool_use","id":"srvtoolu_ws","name":"web_search","input":{"query":"dart"}}}\n'
            '\n'
            'event: content_block_stop\n'
            'data: {"type":"content_block_stop","index":0}\n'
            '\n'
            'event: content_block_start\n'
            'data: {"type":"content_block_start","index":1,"content_block":{"type":"web_search_tool_result","tool_use_id":"srvtoolu_ws","content":[{"type":"web_search_result","url":"https://example.com","title":"Example","encrypted_content":"...","page_age":"1d"}]}}\n'
            '\n'
            'event: content_block_stop\n'
            'data: {"type":"content_block_stop","index":1}\n'
            '\n'
            'event: message_delta\n'
            'data: {"type":"message_delta","delta":{"stop_reason":"end_turn"},"usage":{"output_tokens":1,"server_tool_use":{"web_search_requests":1}}}\n'
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

      final parts =
          await chat.chatStreamParts([ChatMessage.user('Hi')]).toList();

      expect(parts.whereType<LLMToolCallStartPart>(), isEmpty);
      expect(parts.whereType<LLMToolCallDeltaPart>(), isEmpty);
      expect(parts.whereType<LLMToolCallEndPart>(), isEmpty);

      final finish = parts.whereType<LLMFinishPart>().single;
      final response = finish.response;

      final metadata = response.providerMetadata;
      expect(metadata, isNotNull);
      expect(
        metadata!['anthropic']['usage']['serverToolUse']['webSearchRequests'],
        equals(1),
      );

      final assistant =
          (response as ChatResponseWithAssistantMessage).assistantMessage;
      // ignore: deprecated_member_use
      final anthropic =
          assistant.getExtension<Map<String, dynamic>>('anthropic');
      final blocks = (anthropic?['contentBlocks'] as List?)?.cast<dynamic>();
      expect(blocks, isNotNull);
      expect(blocks!, hasLength(2));
      expect((blocks[0] as Map)['type'], equals('server_tool_use'));
      expect((blocks[1] as Map)['type'], equals('web_search_tool_result'));
    });

    test(
        'mcp_tool_use and mcp_tool_result are preserved but not surfaced as toolCalls',
        () async {
      final llmConfig = LLMConfig(
        apiKey: 'test-key',
        baseUrl: 'https://api.anthropic.com/v1/',
        model: 'claude-sonnet-4-20250514',
      );
      final config = AnthropicConfig.fromLLMConfig(llmConfig);

      final sse = [
        'event: message_start\n'
            'data: {"type":"message_start","message":{"id":"msg_mcp","model":"claude-sonnet-4-20250514","usage":{"input_tokens":10,"output_tokens":0}}}\n'
            '\n'
            'event: content_block_start\n'
            'data: {"type":"content_block_start","index":0,"content_block":{"type":"mcp_tool_use","id":"tool_123","name":"calculate","server_name":"math-server","input":{"expression":"2+2"}}}\n'
            '\n'
            'event: content_block_stop\n'
            'data: {"type":"content_block_stop","index":0}\n'
            '\n'
            'event: content_block_start\n'
            'data: {"type":"content_block_start","index":1,"content_block":{"type":"mcp_tool_result","tool_use_id":"tool_123","is_error":false,"content":[{"type":"text","text":"4"}]}}\n'
            '\n'
            'event: content_block_stop\n'
            'data: {"type":"content_block_stop","index":1}\n'
            '\n'
            'event: message_delta\n'
            'data: {"type":"message_delta","delta":{"stop_reason":"end_turn"},"usage":{"output_tokens":1}}\n'
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

      final parts =
          await chat.chatStreamParts([ChatMessage.user('Hi')]).toList();

      expect(parts.whereType<LLMToolCallStartPart>(), isEmpty);
      expect(parts.whereType<LLMToolCallDeltaPart>(), isEmpty);
      expect(parts.whereType<LLMToolCallEndPart>(), isEmpty);

      final finish = parts.whereType<LLMFinishPart>().single;
      final response = finish.response as AnthropicChatResponse;

      expect(response.toolCalls, anyOf(isNull, isEmpty));
      expect(response.mcpToolUses, isNotNull);
      expect(response.mcpToolUses!, hasLength(1));
      expect(response.mcpToolResults, isNotNull);
      expect(response.mcpToolResults!, hasLength(1));

      final assistant =
          (response as ChatResponseWithAssistantMessage).assistantMessage;
      // ignore: deprecated_member_use
      final anthropic =
          assistant.getExtension<Map<String, dynamic>>('anthropic');
      final blocks = (anthropic?['contentBlocks'] as List?)?.cast<dynamic>();
      expect(blocks, isNotNull);
      expect(blocks!, hasLength(2));
      expect((blocks[0] as Map)['type'], equals('mcp_tool_use'));
      expect((blocks[1] as Map)['type'], equals('mcp_tool_result'));
    });
  });
}
