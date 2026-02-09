import 'dart:convert';

import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_openai_compatible/llm_dart_openai_compatible.dart';
import 'package:llm_dart_xai/responses.dart';
import 'package:test/test.dart';

import '../../utils/fakes/fakes.dart';

String _sseData(Map<String, dynamic> json) => 'data: ${jsonEncode(json)}\n\n';

void main() {
  group('xAI Responses provider metadata dedupe (conformance)', () {
    test('dedupes identical metadata snapshots across repeated citations',
        () async {
      final config = OpenAICompatibleConfig(
        providerId: 'xai.responses',
        providerName: 'xAI (Responses)',
        apiKey: 'test-key',
        baseUrl: 'https://api.x.ai/v1/',
        model: 'grok-4-fast-reasoning',
      );

      const url = 'https://x.com/i/status/1';

      const messageItem = {
        'type': 'message',
        'id': 'msg_1',
        'role': 'assistant',
        'status': 'completed',
        'content': [
          {
            'type': 'output_text',
            'text': 'Hello',
            'annotations': [
              {
                'type': 'url_citation',
                'url': url,
              },
            ],
          },
        ],
      };

      final chunks = <String>[
        _sseData({
          'type': 'response.created',
          'response': {
            'object': 'response',
            'id': 'resp_1',
            'created_at': 1700000001,
            'model': 'grok-4-fast-reasoning',
            'output': [],
            'status': 'in_progress',
          },
        }),
        _sseData({
          'type': 'response.output_text.annotation.added',
          'item_id': 'msg_1',
          'output_index': 0,
          'content_index': 0,
          'annotation_index': 0,
          'annotation': {
            'type': 'url_citation',
            'url': url,
          },
        }),
        // Duplicate citation annotation: should not emit a new provider metadata
        // snapshot when it doesn't change the effective metadata.
        _sseData({
          'type': 'response.output_text.annotation.added',
          'item_id': 'msg_1',
          'output_index': 0,
          'content_index': 0,
          'annotation_index': 0,
          'annotation': {
            'type': 'url_citation',
            'url': url,
          },
        }),
        _sseData({
          'type': 'response.output_text.delta',
          'item_id': 'msg_1',
          'output_index': 0,
          'content_index': 0,
          'delta': 'Hello',
        }),
        _sseData({
          'type': 'response.completed',
          'response': {
            'object': 'response',
            'id': 'resp_1',
            'created_at': 1700000001,
            'model': 'grok-4-fast-reasoning',
            'output': [messageItem],
            'status': 'completed',
            'usage': {
              'input_tokens': 1,
              'output_tokens': 1,
              'total_tokens': 2,
            },
          },
        }),
      ];

      final client = FakeOpenAIClient(config)
        ..streamResponse = Stream<String>.fromIterable(chunks);
      final responses = XAIResponses(client, config);

      final parts =
          await responses.chatStreamParts([ChatMessage.user('Hi')]).toList();

      final providerMetadataParts =
          parts.whereType<LLMProviderMetadataPart>().toList();

      // Expect:
      // - 1 snapshot after the first citation (sources: [url]),
      // - 1 snapshot at completion (status becomes completed).
      // The duplicate citation must not create extra snapshots.
      expect(providerMetadataParts, hasLength(2));

      final finish = parts.whereType<LLMFinishPart>().single;
      expect(finish.response.text, equals('Hello'));
      expect(finish.response.toolCalls, isNull);
    });
  });
}
