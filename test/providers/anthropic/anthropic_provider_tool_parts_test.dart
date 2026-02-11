import 'dart:convert';

import 'package:llm_dart/llm_dart.dart';
import 'package:test/test.dart';

import '../../utils/fakes/anthropic_fake_client.dart';

void main() {
  group('Anthropic provider tool parts (server tools)', () {
    test('emits provider tool call/result parts for web_search_tool_result',
        () async {
      final llmConfig = LLMConfig(
        apiKey: 'test-key',
        baseUrl: 'https://api.anthropic.com/v1/',
        model: 'claude-sonnet-4-20250514',
      );

      final config = AnthropicConfig.fromLLMConfig(llmConfig).copyWith(
        stream: true,
      );

      final sse = [
        'event: message_start\n'
            'data: {"type":"message_start","message":{"id":"msg_ws_1","model":"claude-sonnet-4-20250514","usage":{"input_tokens":10,"output_tokens":0}}}\n'
            '\n'
            'event: content_block_start\n'
            'data: {"type":"content_block_start","index":0,"content_block":{"type":"server_tool_use","id":"tool_1","name":"web_search","input":{"query":"latest AI news"}}}\n'
            '\n'
            'event: content_block_stop\n'
            'data: {"type":"content_block_stop","index":0}\n'
            '\n'
            'event: content_block_start\n'
            'data: {"type":"content_block_start","index":1,"content_block":{"type":"web_search_tool_result","tool_use_id":"tool_1","content":[{"type":"web_search_result","url":"https://example.com/ai-news","title":"Latest AI Developments","encrypted_content":"encrypted_content_123","page_age":"January 15, 2025"}]}}\n'
            '\n'
            'event: content_block_stop\n'
            'data: {"type":"content_block_stop","index":1}\n'
            '\n'
            'event: message_delta\n'
            'data: {"type":"message_delta","delta":{"stop_reason":"end_turn"},"usage":{"output_tokens":5,"server_tool_use":{"web_search_requests":1}}}\n'
            '\n'
            'event: message_stop\n'
            'data: {"type":"message_stop"}\n'
            '\n',
      ];

      final client = FakeAnthropicClient(config)
        ..streamResponse = Stream<String>.fromIterable(sse);
      final chat = AnthropicChat(client, config);

      final parts = await chat
          .chatStreamParts([ChatMessage.user('Hi')], tools: const []).toList();

      final toolInputStarts = parts.whereType<LLMToolInputStartPart>().toList();
      expect(toolInputStarts, hasLength(1));
      expect(toolInputStarts.single.id, equals('tool_1'));
      expect(toolInputStarts.single.toolName, equals('web_search'));
      expect(toolInputStarts.single.providerExecuted, isTrue);

      final toolInputEnds = parts.whereType<LLMToolInputEndPart>().toList();
      expect(toolInputEnds, hasLength(1));
      expect(toolInputEnds.single.id, equals('tool_1'));

      final calls = parts.whereType<LLMProviderToolCallPart>().toList();
      expect(calls, hasLength(1));
      expect(calls.single.toolCallId, equals('tool_1'));
      expect(calls.single.toolName, equals('web_search'));
      expect(calls.single.input, isA<String>());
      expect(jsonDecode(calls.single.input as String)['query'],
          equals('latest AI news'));

      final sources = parts.whereType<LLMSourceUrlPart>().toList();
      expect(sources, hasLength(1));
      expect(sources.single.url, equals('https://example.com/ai-news'));
      expect(sources.single.title, equals('Latest AI Developments'));

      final results = parts.whereType<LLMProviderToolResultPart>().toList();
      expect(results, hasLength(1));
      expect(results.single.toolCallId, equals('tool_1'));
      expect(results.single.toolName, equals('web_search'));
      expect(results.single.isError, anyOf(isNull, isFalse));
      expect(results.single.result, isA<List>());

      final finish = parts.whereType<LLMFinishPart>().single;
      expect(finish.response.toolCalls, anyOf(isNull, isEmpty));
    });

    test('infers toolName when tool result arrives without server_tool_use',
        () async {
      final llmConfig = LLMConfig(
        apiKey: 'test-key',
        baseUrl: 'https://api.anthropic.com/v1/',
        model: 'claude-sonnet-4-20250514',
      );

      final config = AnthropicConfig.fromLLMConfig(llmConfig).copyWith(
        stream: true,
      );

      final sse = [
        'event: message_start\n'
            'data: {"type":"message_start","message":{"id":"msg_ws_2","model":"claude-sonnet-4-20250514","usage":{"input_tokens":10,"output_tokens":0}}}\n'
            '\n'
            'event: content_block_start\n'
            'data: {"type":"content_block_start","index":0,"content_block":{"type":"web_search_tool_result","tool_use_id":"tool_1","content":{"type":"web_search_tool_result_error","error_code":"max_uses_exceeded"}}}\n'
            '\n'
            'event: content_block_stop\n'
            'data: {"type":"content_block_stop","index":0}\n'
            '\n'
            'event: message_delta\n'
            'data: {"type":"message_delta","delta":{"stop_reason":"end_turn"},"usage":{"output_tokens":1}}\n'
            '\n'
            'event: message_stop\n'
            'data: {"type":"message_stop"}\n'
            '\n',
      ];

      final client = FakeAnthropicClient(config)
        ..streamResponse = Stream<String>.fromIterable(sse);
      final chat = AnthropicChat(client, config);

      final parts = await chat
          .chatStreamParts([ChatMessage.user('Hi')], tools: const []).toList();

      final results = parts.whereType<LLMProviderToolResultPart>().toList();
      expect(results, hasLength(1));
      expect(results.single.toolCallId, equals('tool_1'));
      expect(results.single.toolName, equals('web_search'));
      expect(results.single.isError, isTrue);
      expect(results.single.result, isA<Map>());
      expect((results.single.result as Map)['error_code'],
          equals('max_uses_exceeded'));
    });
  });
}
