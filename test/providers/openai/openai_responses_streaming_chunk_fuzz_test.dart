import 'dart:convert';
import 'dart:math';

import 'package:llm_dart/llm_dart.dart';
import 'package:llm_dart_openai/llm_dart_openai.dart' as openai_client;
import 'package:llm_dart_openai/responses.dart' as openai_responses;
import 'package:test/test.dart';

import '../../utils/fakes/fakes.dart';

String _sseData(Map<String, dynamic> json) => 'data: ${jsonEncode(json)}\n\n';

List<String> _splitRandom(String input, {required int seed, int maxLen = 11}) {
  final random = Random(seed);
  final chunks = <String>[];
  var i = 0;
  while (i < input.length) {
    final remaining = input.length - i;
    final size = min(remaining, 1 + random.nextInt(maxLen));
    chunks.add(input.substring(i, i + size));
    i += size;
  }
  return chunks;
}

void main() {
  group('OpenAI Responses streaming fuzz (chunk boundaries)', () {
    test('handles arbitrary chunk splits without losing provider tool/sources',
        () async {
      final config = openai_client.OpenAIConfig(
        apiKey: 'test-key',
        baseUrl: 'https://api.openai.com/v1/',
        model: 'gpt-5-mini',
        useResponsesAPI: true,
      );

      final sse = [
        _sseData({
          'type': 'response.created',
          'response': {
            'id': 'resp_fuzz',
            'model': 'gpt-5-mini',
            'status': 'in_progress',
            'created_at': 1739145600,
            'system_fingerprint': 'fp_fuzz',
          },
        }),
        _sseData({
          'type': 'response.output_text.delta',
          'delta': 'Hello ',
        }),
        _sseData({
          'type': 'response.output_text.annotation.added',
          'annotation': {
            'type': 'url_citation',
            'url': 'https://citation.example/',
            'title': 'Citation',
            'start_index': 0,
            'end_index': 5,
          },
        }),
        // Duplicate citation should be deduped into a single source part.
        _sseData({
          'type': 'response.output_text.annotation.added',
          'annotation': {
            'type': 'url_citation',
            'url': 'https://citation.example/',
            'title': 'Citation',
            'start_index': 0,
            'end_index': 5,
          },
        }),
        _sseData({
          'type': 'response.output_item.added',
          'output_index': 0,
          'item': {
            'type': 'web_search_call',
            'id': 'ws_1',
            'arguments': {'query': 'OpenAI'},
            'status': 'in_progress',
          },
        }),
        _sseData({
          'type': 'response.web_search_call.in_progress',
          'item_id': 'ws_1',
          'progress': 0.5,
        }),
        _sseData({
          'type': 'response.output_item.done',
          'output_index': 0,
          'item': {
            'type': 'web_search_call',
            'id': 'ws_1',
            'status': 'completed',
            'action': {
              'type': 'search',
              'sources': [
                {
                  'type': 'url',
                  'url': 'https://search.example/',
                  'title': 'Search',
                },
                // Duplicate sources should be deduped.
                {
                  'type': 'url',
                  'url': 'https://search.example/',
                  'title': 'Search',
                },
              ],
            },
          },
        }),
        _sseData({
          'type': 'response.output_text.delta',
          'delta': 'world',
        }),
        _sseData({
          'type': 'response.completed',
          'response': {
            'id': 'resp_fuzz',
            'model': 'gpt-5-mini',
            'status': 'completed',
            'created_at': 1739145600,
            'usage': {
              'input_tokens': 10,
              'output_tokens': 5,
              'total_tokens': 15,
            },
            'output': [
              {
                'type': 'message',
                'role': 'assistant',
                'content': [
                  {
                    'type': 'output_text',
                    'text': 'Hello world',
                    'annotations': [
                      {
                        'type': 'url_citation',
                        'url': 'https://citation.example/',
                        'title': 'Citation',
                        'start_index': 0,
                        'end_index': 5,
                      }
                    ],
                  }
                ],
              },
              {
                'type': 'web_search_call',
                'id': 'ws_1',
                'status': 'completed',
                'action': {
                  'type': 'search',
                  'sources': [
                    {
                      'type': 'url',
                      'url': 'https://search.example/',
                      'title': 'Search',
                    },
                  ],
                },
              }
            ],
          },
        }),
        'data: [DONE]\n\n',
      ].join();

      for (final seed in [1, 7, 42]) {
        final client = FakeOpenAIClient(config)
          ..streamResponse =
              Stream<String>.fromIterable(_splitRandom(sse, seed: seed));
        final responses = openai_responses.OpenAIResponses(client, config);

        final parts = await responses.chatStreamParts([ChatMessage.user('Hi')],
            tools: const []).toList();

        final text =
            parts.whereType<LLMTextDeltaPart>().map((p) => p.delta).join();
        expect(text, equals('Hello world'));

        final calls = parts.whereType<LLMProviderToolCallPart>().toList();
        final results = parts.whereType<LLMProviderToolResultPart>().toList();
        expect(calls, hasLength(1));
        expect(results, hasLength(1));
        expect(calls.single.toolName, equals('web_search'));
        expect(results.single.toolName, equals('web_search'));
        expect(results.single.toolCallId, equals(calls.single.toolCallId));

        final deltas = parts.whereType<LLMProviderToolDeltaPart>().toList();
        expect(deltas, hasLength(1));
        expect(deltas.single.toolCallId, equals('ws_1'));
        expect(deltas.single.toolName, equals('web_search'));

        final sources = parts.whereType<LLMSourceUrlPart>().toList();
        final urls = sources.map((p) => p.url).toSet();
        expect(urls,
            equals({'https://citation.example/', 'https://search.example/'}));

        final finish = parts.whereType<LLMFinishPart>().single;
        expect(finish.usage?.totalTokens, equals(15));
        expect(
            finish.finishReason?.unified, equals(LLMUnifiedFinishReason.stop));
      }
    });
  });
}
