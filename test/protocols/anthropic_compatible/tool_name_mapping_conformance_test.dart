import 'package:llm_dart_anthropic_compatible/llm_dart_anthropic_compatible.dart';
import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:test/test.dart';

import '_fake_anthropic_compatible_client.dart';
import '_fake_anthropic_compatible_json_client.dart';

Tool _localWebSearchTool() {
  return Tool.function(
    name: 'web_search',
    description: 'local web search tool (collides with provider-native)',
    parameters: const ParametersSchema(
      schemaType: 'object',
      properties: {
        'query': ParameterProperty(
          propertyType: 'string',
          description: 'query',
        ),
      },
      required: ['query'],
    ),
  );
}

void main() {
  group('Anthropic-compatible tool name mapping conformance', () {
    test('maps renamed tool_use back to original tool name (non-streaming)',
        () async {
      const config = AnthropicConfig(
        apiKey: 'k',
        model: 'test-model',
        providerId: 'anthropic',
        webSearchToolType: 'web_search_20250305',
      );

      final client = FakeAnthropicCompatibleJsonClient(
        config,
        responses: [
          {
            'id': 'msg_1',
            'model': 'test-model',
            'stop_reason': 'tool_use',
            'usage': {
              'input_tokens': 10,
              'output_tokens': 5,
              'server_tool_use': {'web_search_requests': 1},
            },
            'content': [
              {
                // Provider-native tool call (should be filtered).
                'type': 'tool_use',
                'id': 'toolu_ws',
                'name': 'web_search',
                'input': {'query': 'dart'},
              },
              {
                // Local tool call rewritten to avoid collision.
                'type': 'tool_use',
                'id': 'toolu_1',
                'name': 'web_search__1',
                'input': {'query': 'dart'},
              },
            ],
          },
        ],
      );

      final chat = AnthropicChat(client, config);
      final resp = await chat.chatWithTools(
        [ChatMessage.user('Hi')],
        [_localWebSearchTool()],
      );

      final calls = resp.toolCalls;
      expect(calls, isNotNull);
      expect(calls!, hasLength(1));
      expect(calls.single.id, equals('toolu_1'));
      expect(calls.single.function.name, equals('web_search'));
      expect(calls.single.function.arguments, equals('{"query":"dart"}'));

      final meta = resp.providerMetadata;
      expect(meta, isNotNull);
      expect(
        meta!['anthropic']['usage']['serverToolUse']['webSearchRequests'],
        equals(1),
      );

      // Request side: local tool should be renamed, provider-native stays as web_search.
      expect(client.requests, hasLength(1));
      final requestTools = client.requests.single['tools'] as List<dynamic>;
      final names =
          requestTools.whereType<Map>().map((t) => t['name']).toList();
      expect(names, contains('web_search'));
      expect(names, contains('web_search__1'));
    });

    test(
        'streams tool call parts with original name when collision-safe renaming is used',
        () async {
      const config = AnthropicConfig(
        apiKey: 'k',
        model: 'test-model',
        providerId: 'anthropic',
        stream: true,
        webSearchToolType: 'web_search_20250305',
      );

      final client = FakeAnthropicCompatibleClient(
        config,
        chunks: const [
          'data: {"type":"message_start","message":{"id":"msg_1","model":"test-model","usage":{"input_tokens":10,"output_tokens":0}}}\n',
          'data: {"type":"content_block_start","index":0,"content_block":{"type":"tool_use","id":"toolu_ws","name":"web_search"}}\n',
          'data: {"type":"content_block_delta","index":0,"delta":{"type":"input_json_delta","partial_json":"{\\"query\\":\\"dart\\"}"}}\n',
          'data: {"type":"content_block_stop","index":0}\n',
          'data: {"type":"content_block_start","index":1,"content_block":{"type":"tool_use","id":"toolu_1","name":"web_search__1"}}\n',
          'data: {"type":"content_block_delta","index":1,"delta":{"type":"input_json_delta","partial_json":"{\\"query\\":\\"dart\\"}"}}\n',
          'data: {"type":"content_block_stop","index":1}\n',
          'data: {"type":"message_delta","delta":{"stop_reason":"tool_use"},"usage":{"output_tokens":5,"server_tool_use":{"web_search_requests":1}}}\n',
          'data: {"type":"message_stop"}\n',
        ],
      );

      final chat = AnthropicChat(client, config);
      final parts = await chat.chatStreamParts([ChatMessage.user('Hi')],
          tools: [_localWebSearchTool()]).toList();

      final toolStarts = parts.whereType<LLMToolCallStartPart>().toList();
      expect(toolStarts, hasLength(1));
      expect(toolStarts.single.toolCall.id, equals('toolu_1'));
      expect(toolStarts.single.toolCall.function.name, equals('web_search'));

      final toolDeltas = parts.whereType<LLMToolCallDeltaPart>().toList();
      expect(toolDeltas, hasLength(1));
      expect(toolDeltas.single.toolCall.function.name, equals('web_search'));
      expect(toolDeltas.single.toolCall.function.arguments,
          equals('{"query":"dart"}'));

      expect(
        parts.whereType<LLMToolCallEndPart>().single.toolCallId,
        equals('toolu_1'),
      );

      final finish = parts.whereType<LLMFinishPart>().single;
      final calls = finish.response.toolCalls;
      expect(calls, isNotNull);
      expect(calls!, hasLength(1));
      expect(calls.single.id, equals('toolu_1'));
      expect(calls.single.function.name, equals('web_search'));
      expect(calls.single.function.arguments, equals('{"query":"dart"}'));

      final meta = finish.response.providerMetadata;
      expect(meta, isNotNull);
      expect(
        meta!['anthropic']['usage']['serverToolUse']['webSearchRequests'],
        equals(1),
      );
    });
  });
}
