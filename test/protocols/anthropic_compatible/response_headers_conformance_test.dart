import 'package:llm_dart_anthropic_compatible/llm_dart_anthropic_compatible.dart';
import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:test/test.dart';

import '_fake_anthropic_compatible_client.dart';

void main() {
  group('Anthropic-compatible response headers (conformance)', () {
    test('exposes response headers in response-metadata part', () async {
      final llmConfig = LLMConfig(
        apiKey: 'test-key',
        baseUrl: 'https://api.anthropic.com/v1/',
        model: 'claude-sonnet-4-20250514',
      );
      final config = AnthropicConfig.fromLLMConfig(llmConfig);

      const chunks = [
        'data: {"type":"message_start","message":{"id":"msg_1","model":"claude-sonnet-4-20250514","usage":{"input_tokens":1,"output_tokens":0}}}\n\n',
        'data: {"type":"content_block_start","index":0,"content_block":{"type":"text","text":""}}\n\n',
        'data: {"type":"content_block_delta","index":0,"delta":{"type":"text_delta","text":"Hello"}}\n\n',
        'data: {"type":"content_block_stop","index":0}\n\n',
        'data: {"type":"message_delta","delta":{"stop_reason":"end_turn"},"usage":{"output_tokens":1}}\n\n',
        'data: {"type":"message_stop"}\n\n',
      ];

      final client = FakeAnthropicCompatibleClient(
        config,
        chunks: chunks,
        headers: const {'x-test': '1'},
      );
      final chat = AnthropicChat(client, config);

      final parts =
          await chat.chatStreamParts([ChatMessage.user('hi')]).toList();

      final meta = parts.whereType<LLMResponseMetadataPart>().single;
      expect(meta.headers, isNotNull);
      expect(meta.headers, containsPair('x-test', '1'));
    });
  });
}
