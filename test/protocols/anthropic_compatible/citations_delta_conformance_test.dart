import 'package:llm_dart_anthropic_compatible/llm_dart_anthropic_compatible.dart';
import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:test/test.dart';

import '_fake_anthropic_compatible_client.dart';

void main() {
  group('Anthropic-compatible citations_delta conformance', () {
    test('preserves citations on text blocks in chatStreamParts', () async {
      const config = AnthropicConfig(
        apiKey: 'k',
        model: 'test-model',
        providerId: 'anthropic',
        stream: true,
      );

      final client = FakeAnthropicCompatibleClient(
        config,
        chunks: const [
          'data: {"type":"message_start","message":{"id":"msg_cite","model":"test-model","usage":{"input_tokens":1,"output_tokens":0}}}\n',
          'data: {"type":"content_block_start","index":0,"content_block":{"type":"text","text":"","citations":[]}}\n',
          'data: {"type":"content_block_delta","index":0,"delta":{"type":"citations_delta","citation":{"type":"web_search_result_location","url":"https://example.com","title":"Example","cited_text":"hello"}}}\n',
          'data: {"type":"content_block_delta","index":0,"delta":{"type":"text_delta","text":"hello"}}\n',
          'data: {"type":"content_block_stop","index":0}\n',
          'data: {"type":"message_delta","delta":{"stop_reason":"end_turn"},"usage":{"output_tokens":1}}\n',
          'data: {"type":"message_stop"}\n',
        ],
      );

      final chat = AnthropicChat(client, config);

      final parts =
          await chat.chatStreamParts([ChatMessage.user('Hi')]).toList();
      final finish = parts.whereType<LLMFinishPart>().single;
      final response = finish.response as ChatResponseWithAssistantMessage;
      final assistant = response.assistantMessage;

      final anthropic = assistant.getProtocolPayload<Map<String, dynamic>>(
        'anthropic',
      );
      final blocks = (anthropic?['contentBlocks'] as List?)?.cast<dynamic>();
      expect(blocks, isNotNull);

      final textBlock = blocks!.whereType<Map>().firstWhere(
            (b) => b['type'] == 'text',
          );
      expect(textBlock['text'], equals('hello'));

      final citations = textBlock['citations'] as List?;
      expect(citations, isNotNull);
      expect(citations, hasLength(1));
      expect((citations!.first as Map)['type'],
          equals('web_search_result_location'));
    });

    test('preserves citations on text blocks in legacy chatStream completion',
        () async {
      const config = AnthropicConfig(
        apiKey: 'k',
        model: 'test-model',
        providerId: 'anthropic',
        stream: true,
      );

      final client = FakeAnthropicCompatibleClient(
        config,
        chunks: const [
          'data: {"type":"message_start","message":{"id":"msg_cite_2","model":"test-model","usage":{"input_tokens":1,"output_tokens":0}}}\n',
          'data: {"type":"content_block_start","index":0,"content_block":{"type":"text","text":"","citations":[]}}\n',
          'data: {"type":"content_block_delta","index":0,"delta":{"type":"citations_delta","citation":{"type":"web_search_result_location","url":"https://example.com","title":"Example","cited_text":"hello"}}}\n',
          'data: {"type":"content_block_delta","index":0,"delta":{"type":"text_delta","text":"hello"}}\n',
          'data: {"type":"content_block_stop","index":0}\n',
          'data: {"type":"message_delta","delta":{"stop_reason":"end_turn"},"usage":{"output_tokens":1}}\n',
          'data: {"type":"message_stop"}\n',
        ],
      );

      final chat = AnthropicChat(client, config);
      final events = await chat.chatStream([ChatMessage.user('Hi')]).toList();
      final completion = events.whereType<CompletionEvent>().single;
      final response = completion.response as ChatResponseWithAssistantMessage;
      final assistant = response.assistantMessage;

      final anthropic = assistant.getProtocolPayload<Map<String, dynamic>>(
        'anthropic',
      );
      final blocks = (anthropic?['contentBlocks'] as List?)?.cast<dynamic>();
      expect(blocks, isNotNull);

      final textBlock = blocks!.whereType<Map>().firstWhere(
            (b) => b['type'] == 'text',
          );
      expect(textBlock['text'], equals('hello'));

      final citations = textBlock['citations'] as List?;
      expect(citations, isNotNull);
      expect(citations, hasLength(1));
    });
  });
}
