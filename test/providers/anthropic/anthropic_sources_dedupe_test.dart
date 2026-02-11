import 'package:llm_dart/llm_dart.dart';
import 'package:test/test.dart';

import '../../utils/fakes/anthropic_fake_client.dart';

void main() {
  group('Anthropic source parts dedupe (AI SDK parity)', () {
    test('dedupes URL sources across web_search results and citations',
        () async {
      final llmConfig = LLMConfig(
        apiKey: 'test-key',
        baseUrl: 'https://api.anthropic.com/v1/',
        model: 'claude-sonnet-4-20250514',
      );

      final config = AnthropicConfig.fromLLMConfig(llmConfig).copyWith(
        stream: true,
      );

      const url = 'https://example.com';

      final sse = [
        'event: message_start\n'
            'data: {"type":"message_start","message":{"id":"msg_1","model":"claude-sonnet-4-20250514","usage":{"input_tokens":1,"output_tokens":0}}}\n'
            '\n'
            'event: content_block_start\n'
            'data: {"type":"content_block_start","index":0,"content_block":{"type":"server_tool_use","id":"tool_1","name":"web_search","input":{"query":"test"}}}\n'
            '\n'
            'event: content_block_stop\n'
            'data: {"type":"content_block_stop","index":0}\n'
            '\n'
            'event: content_block_start\n'
            'data: {"type":"content_block_start","index":1,"content_block":{"type":"web_search_tool_result","tool_use_id":"tool_1","content":[{"type":"web_search_result","url":"$url","title":"Example","page_age":"January 1, 2025"}]}}\n'
            '\n'
            'event: content_block_stop\n'
            'data: {"type":"content_block_stop","index":1}\n'
            '\n'
            'event: content_block_start\n'
            'data: {"type":"content_block_start","index":2,"content_block":{"type":"text","text":"","citations":[]}}\n'
            '\n'
            'event: content_block_delta\n'
            'data: {"type":"content_block_delta","index":2,"delta":{"type":"citations_delta","citation":{"type":"web_search_result_location","url":"$url","title":"Example","cited_text":"hello"}}}\n'
            '\n'
            'event: content_block_delta\n'
            'data: {"type":"content_block_delta","index":2,"delta":{"type":"text_delta","text":"hello"}}\n'
            '\n'
            'event: content_block_stop\n'
            'data: {"type":"content_block_stop","index":2}\n'
            '\n'
            'event: message_delta\n'
            'data: {"type":"message_delta","delta":{"stop_reason":"end_turn"},"usage":{"output_tokens":1,"server_tool_use":{"web_search_requests":1}}}\n'
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

      final sources = parts.whereType<LLMSourceUrlPart>().toList();
      expect(sources, hasLength(1));
      expect(sources.single.url, equals(url));
    });
  });
}
