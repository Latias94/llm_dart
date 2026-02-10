import 'dart:convert';
import 'dart:math';

import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_openai_compatible/llm_dart_openai_compatible.dart';
import 'package:llm_dart_xai/responses.dart';
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
  group('xAI Responses streaming fuzz (chunk boundaries)', () {
    test('handles arbitrary chunk splits without losing provider tool/sources',
        () async {
      final config = OpenAICompatibleConfig(
        providerId: 'xai.responses',
        providerName: 'xAI (Responses)',
        apiKey: 'test-key',
        baseUrl: 'https://api.x.ai/v1/',
        model: 'grok-4-fast',
      );

      final sse = [
        _sseData({
          'type': 'response.created',
          'response': {
            'id': 'resp_fuzz',
            'model': 'grok-4-fast',
            'status': 'in_progress',
            'created_at': 1739145600,
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
        // Custom tool inputs can stream before the tool item appears.
        _sseData({
          'type': 'response.custom_tool_call_input.delta',
          'item_id': 'ct_1',
          'delta': '{"query":"OpenAI"}',
        }),
        _sseData({
          'type': 'response.output_item.added',
          'item': {
            'type': 'custom_tool_call',
            'id': 'ct_1',
            'name': 'web_search',
            'status': 'in_progress',
          },
        }),
        _sseData({
          'type': 'response.output_item.done',
          'item': {
            'type': 'custom_tool_call',
            'id': 'ct_1',
            'name': 'web_search',
            'status': 'completed',
            'output': {'results': []},
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
            'model': 'grok-4-fast',
            'status': 'completed',
            'created_at': 1739145600,
            'usage': {
              'input_tokens': 10,
              'output_tokens': 5,
              'total_tokens': 15,
            },
          },
        }),
        'data: [DONE]\n\n',
      ].join();

      for (final seed in [1, 7, 42]) {
        final client = FakeOpenAIClient(config)
          ..streamResponse =
              Stream<String>.fromIterable(_splitRandom(sse, seed: seed));
        final responses = XAIResponses(client, config);

        final parts =
            await responses.chatStreamParts([ChatMessage.user('Hi')]).toList();

        final text =
            parts.whereType<LLMTextDeltaPart>().map((p) => p.delta).join();
        expect(text, equals('Hello world'));

        final calls = parts.whereType<LLMProviderToolCallPart>().toList();
        final results = parts.whereType<LLMProviderToolResultPart>().toList();
        expect(calls, hasLength(1));
        expect(results, hasLength(1));
        expect(calls.single.toolCallId, equals('ct_1'));
        expect(results.single.toolCallId, equals('ct_1'));
        expect(calls.single.toolName, equals('web_search'));
        expect(results.single.toolName, equals('web_search'));

        final sources = parts.whereType<LLMSourceUrlPart>().toList();
        expect(sources, hasLength(1));
        expect(sources.single.url, equals('https://citation.example/'));

        final finish = parts.whereType<LLMFinishPart>().single;
        expect(finish.usage?.totalTokens, equals(15));
      }
    });
  });
}
