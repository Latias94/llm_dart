import 'package:llm_dart_anthropic_compatible/llm_dart_anthropic_compatible.dart';
import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:test/test.dart';

import '_fake_anthropic_compatible_client.dart';

void main() {
  group('Anthropic-compatible tool search deferred result streaming', () {
    test(
        'maps tool_search_tool_result without server_tool_use to configured request name',
        () async {
      const config = AnthropicConfig(
        apiKey: 'k',
        providerId: 'anthropic',
        stream: true,
      );

      final client = FakeAnthropicCompatibleClient(
        config,
        chunks: const [
          'data: {"type":"message_start","message":{"id":"msg_ts","model":"test-model","usage":{"input_tokens":10,"output_tokens":0}}}\n\n',
          'data: {"type":"content_block_start","index":0,"content_block":{"type":"tool_search_tool_result","tool_use_id":"srvtoolu_1","content":{"type":"tool_search_tool_search_result","tool_references":[{"type":"tool_reference","tool_name":"get_weather"}]}}}\n\n',
          'data: {"type":"content_block_stop","index":0}\n\n',
          'data: {"type":"message_delta","delta":{"stop_reason":"end_turn"},"usage":{"output_tokens":1}}\n\n',
          'data: {"type":"message_stop"}\n\n',
        ],
      );

      final chat = AnthropicChat(client, config);

      final parts = await chat.chatStreamParts(
        [ChatMessage.user('Hi')],
        tools: const [],
        providerTools: const [
          ProviderTool(
            id: 'anthropic.tool_search_regex_20251119',
            name: 'tool_search',
            supportsDeferredResults: true,
          ),
        ],
      ).toList();

      final providerToolResults =
          parts.whereType<LLMProviderToolResultPart>().toList();
      expect(providerToolResults, hasLength(1));

      final result = providerToolResults.single;
      expect(result.toolCallId, equals('srvtoolu_1'));
      expect(result.toolName, equals('tool_search'));

      final payload = result.result;
      expect(payload, isA<List>());
      final refs = (payload as List).whereType<Map>().toList();
      expect(refs, hasLength(1));
      expect(refs.single['type'], equals('tool_reference'));
      expect(refs.single['toolName'], equals('get_weather'));
    });
  });
}
