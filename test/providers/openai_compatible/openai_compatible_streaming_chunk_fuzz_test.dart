import 'dart:convert';
import 'dart:math';

import 'package:llm_dart/llm_dart.dart';
import 'package:test/test.dart';

import '../../utils/fakes/openai_fake_client.dart';

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
  group('OpenAI-compatible streaming fuzz (chunk boundaries)', () {
    test('handles arbitrary chunk splits without losing parts', () async {
      final config = OpenAICompatibleConfig(
        providerId: 'openai',
        providerName: 'OpenAI',
        apiKey: 'test-key',
        baseUrl: 'https://api.example.com/v1/',
        model: 'gpt-4o',
      );

      final sse = [
        _sseData({
          'id': 'chatcmpl_fuzz',
          'model': 'gpt-4o',
          'choices': [
            {
              'index': 0,
              'delta': {'role': 'assistant'},
            }
          ],
        }),
        _sseData({
          'id': 'chatcmpl_fuzz',
          'model': 'gpt-4o',
          'choices': [
            {
              'index': 0,
              'delta': {'content': 'Hello <thi'},
            }
          ],
        }),
        _sseData({
          'id': 'chatcmpl_fuzz',
          'model': 'gpt-4o',
          'choices': [
            {
              'index': 0,
              'delta': {'content': 'nk>ana'},
            }
          ],
        }),
        _sseData({
          'id': 'chatcmpl_fuzz',
          'model': 'gpt-4o',
          'choices': [
            {
              'index': 0,
              'delta': {'content': 'lyzing</th'},
            }
          ],
        }),
        _sseData({
          'id': 'chatcmpl_fuzz',
          'model': 'gpt-4o',
          'choices': [
            {
              'index': 0,
              'delta': {'content': 'ink>world'},
            }
          ],
        }),
        _sseData({
          'id': 'chatcmpl_fuzz',
          'model': 'gpt-4o',
          'choices': [
            {
              'index': 0,
              'delta': {
                'tool_calls': [
                  {
                    'index': 0,
                    'id': 'call_1',
                    'type': 'function',
                    'function': {
                      'name': 'getWeather',
                      'arguments': '{"city":"Lon',
                    },
                  }
                ],
              },
            }
          ],
        }),
        _sseData({
          'id': 'chatcmpl_fuzz',
          'model': 'gpt-4o',
          'choices': [
            {
              'index': 0,
              'delta': {
                'tool_calls': [
                  {
                    'index': 0,
                    'function': {
                      'arguments': 'don"}',
                    },
                  }
                ],
              },
            }
          ],
        }),
        _sseData({
          'id': 'chatcmpl_fuzz',
          'model': 'gpt-4o',
          'choices': [
            {
              'index': 0,
              'delta': <String, dynamic>{},
              'finish_reason': 'tool_calls',
            }
          ],
        }),
        'data: [DONE]\n\n',
      ].join();

      for (final seed in [1, 7, 42]) {
        final client = FakeOpenAIClient(config)
          ..streamResponse = Stream<String>.fromIterable(
            _splitRandom(sse, seed: seed),
          );
        final chat = OpenAIChat(client, config);

        final parts = await chat.chatStreamParts([ChatMessage.user('Hi')]).toList();

        final text =
            parts.whereType<LLMTextDeltaPart>().map((p) => p.delta).join();
        final thinking =
            parts.whereType<LLMReasoningDeltaPart>().map((p) => p.delta).join();

        expect(text, equals('Hello world'));
        expect(thinking, equals('analyzing'));

        final finish = parts.whereType<LLMFinishPart>().single;
        expect(finish.response.text, equals('Hello world'));
        expect(finish.response.thinking, equals('analyzing'));

        final calls = finish.response.toolCalls;
        expect(calls, isNotNull);
        expect(calls!.single.function.name, equals('getWeather'));
        expect(calls.single.function.arguments, equals('{"city":"London"}'));
      }
    });
  });
}

