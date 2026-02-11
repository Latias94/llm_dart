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

        final parts =
            await chat.chatStreamParts([ChatMessage.user('Hi')]).toList();

        final text =
            parts.whereType<LLMTextDeltaPart>().map((p) => p.delta).join();
        final thinking =
            parts.whereType<LLMReasoningDeltaPart>().map((p) => p.delta).join();

        expect(text, equals('Hello world'));
        expect(thinking, equals('analyzing'));

        final toolStarts = parts.whereType<LLMToolCallStartPart>().toList();
        final toolDeltas = parts.whereType<LLMToolCallDeltaPart>().toList();
        final toolEnds = parts.whereType<LLMToolCallEndPart>().toList();
        expect(toolStarts, hasLength(1));
        expect(toolDeltas, hasLength(1));
        expect(toolEnds, hasLength(1));
        expect(toolStarts.single.toolCall.id, equals('call_1'));
        expect(toolStarts.single.toolCall.function.name, equals('getWeather'));
        expect(toolDeltas.single.toolCall.id, equals('call_1'));
        expect(toolDeltas.single.toolCall.function.arguments, equals('don"}'));
        expect(toolEnds.single.toolCallId, equals('call_1'));

        final idxStart = parts.indexOf(toolStarts.single);
        final idxDelta = parts.indexOf(toolDeltas.single);
        final idxEnd = parts.indexOf(toolEnds.single);
        expect(idxStart, lessThan(idxDelta));
        expect(idxDelta, lessThan(idxEnd));

        final finish = parts.whereType<LLMFinishPart>().single;
        expect(finish.response.text, equals('Hello world'));
        expect(finish.response.thinking, equals('analyzing'));

        final calls = finish.response.toolCalls;
        expect(calls, isNotNull);
        expect(calls!.single.function.name, equals('getWeather'));
        expect(calls.single.function.arguments, equals('{"city":"London"}'));
      }
    });

    test('handles interleaved multiple tool_calls with random splits',
        () async {
      final config = OpenAICompatibleConfig(
        providerId: 'openai',
        providerName: 'OpenAI',
        apiKey: 'test-key',
        baseUrl: 'https://api.example.com/v1/',
        model: 'gpt-4o',
      );

      final sse = [
        _sseData({
          'id': 'chatcmpl_multi_tool_fuzz',
          'model': 'gpt-4o',
          'choices': [
            {
              'index': 0,
              'delta': {'role': 'assistant'},
            }
          ],
        }),
        _sseData({
          'id': 'chatcmpl_multi_tool_fuzz',
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
                      'name': 'toolA',
                      'arguments': '{"a":1',
                    },
                  }
                ],
              },
            }
          ],
        }),
        _sseData({
          'id': 'chatcmpl_multi_tool_fuzz',
          'model': 'gpt-4o',
          'choices': [
            {
              'index': 0,
              'delta': {
                'tool_calls': [
                  {
                    'index': 1,
                    'id': 'call_2',
                    'type': 'function',
                    'function': {
                      'name': 'toolB',
                      'arguments': '{"b":',
                    },
                  }
                ],
              },
            }
          ],
        }),
        _sseData({
          'id': 'chatcmpl_multi_tool_fuzz',
          'model': 'gpt-4o',
          'choices': [
            {
              'index': 0,
              'delta': {
                'tool_calls': [
                  {
                    'index': 0,
                    'function': {
                      'arguments': ',"c":2}',
                    },
                  }
                ],
              },
            }
          ],
        }),
        _sseData({
          'id': 'chatcmpl_multi_tool_fuzz',
          'model': 'gpt-4o',
          'choices': [
            {
              'index': 0,
              'delta': {
                'tool_calls': [
                  {
                    'index': 1,
                    'function': {
                      'arguments': '3}',
                    },
                  }
                ],
              },
            }
          ],
        }),
        _sseData({
          'id': 'chatcmpl_multi_tool_fuzz',
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

      for (final seed in [2, 9, 77]) {
        final client = FakeOpenAIClient(config)
          ..streamResponse = Stream<String>.fromIterable(
            _splitRandom(sse, seed: seed),
          );
        final chat = OpenAIChat(client, config);

        final parts =
            await chat.chatStreamParts([ChatMessage.user('Hi')]).toList();

        final starts = parts.whereType<LLMToolCallStartPart>().toList();
        final deltas = parts.whereType<LLMToolCallDeltaPart>().toList();
        final ends = parts.whereType<LLMToolCallEndPart>().toList();

        expect(starts, hasLength(2));
        expect(deltas, hasLength(2));
        expect(ends, hasLength(2));

        final idsStarted = starts.map((p) => p.toolCall.id).toSet();
        expect(idsStarted, equals({'call_1', 'call_2'}));

        final idsEnded = ends.map((p) => p.toolCallId).toSet();
        expect(idsEnded, equals({'call_1', 'call_2'}));

        for (final id in ['call_1', 'call_2']) {
          final idxStart = parts.indexWhere(
            (p) => p is LLMToolCallStartPart && p.toolCall.id == id,
          );
          final idxEnd = parts.indexWhere(
            (p) => p is LLMToolCallEndPart && p.toolCallId == id,
          );
          expect(idxStart, isNonNegative);
          expect(idxEnd, isNonNegative);
          expect(idxStart, lessThan(idxEnd));
        }

        final finish = parts.whereType<LLMFinishPart>().single;
        final toolCalls = finish.response.toolCalls;
        expect(toolCalls, isNotNull);
        expect(toolCalls, hasLength(2));

        final byName = {for (final c in toolCalls!) c.function.name: c};
        expect(byName.keys.toSet(), equals({'toolA', 'toolB'}));
        expect(byName['toolA']!.function.arguments, equals('{"a":1,"c":2}'));
        expect(byName['toolB']!.function.arguments, equals('{"b":3}'));
      }
    });

    test('handles tool_calls with id arriving late', () async {
      final config = OpenAICompatibleConfig(
        providerId: 'openai',
        providerName: 'OpenAI',
        apiKey: 'test-key',
        baseUrl: 'https://api.example.com/v1/',
        model: 'gpt-4o',
      );

      final sse = [
        _sseData({
          'id': 'chatcmpl_tool_id_late_fuzz',
          'model': 'gpt-4o',
          'choices': [
            {
              'index': 0,
              'delta': {'role': 'assistant'},
            }
          ],
        }),
        // First tool delta: has index + name + args, but omits id.
        _sseData({
          'id': 'chatcmpl_tool_id_late_fuzz',
          'model': 'gpt-4o',
          'choices': [
            {
              'index': 0,
              'delta': {
                'tool_calls': [
                  {
                    'index': 0,
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
        // Second tool delta: provides id + more args (name omitted).
        _sseData({
          'id': 'chatcmpl_tool_id_late_fuzz',
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
                      'arguments': 'don"}',
                    },
                  }
                ],
              },
            }
          ],
        }),
        _sseData({
          'id': 'chatcmpl_tool_id_late_fuzz',
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

      for (final seed in [3, 13, 91]) {
        final client = FakeOpenAIClient(config)
          ..streamResponse = Stream<String>.fromIterable(
            _splitRandom(sse, seed: seed),
          );
        final chat = OpenAIChat(client, config);

        final parts =
            await chat.chatStreamParts([ChatMessage.user('Hi')]).toList();

        final starts = parts.whereType<LLMToolCallStartPart>().toList();
        final deltas = parts.whereType<LLMToolCallDeltaPart>().toList();
        final ends = parts.whereType<LLMToolCallEndPart>().toList();
        expect(starts, isNotEmpty);
        expect(deltas, isNotEmpty);
        expect(ends, hasLength(1));
        expect(ends.single.toolCallId, equals('call_1'));

        final finish = parts.whereType<LLMFinishPart>().single;
        final calls = finish.response.toolCalls;
        expect(calls, isNotNull);
        expect(calls, hasLength(1));
        expect(calls!.single.id, equals('call_1'));
        expect(calls.single.function.name, equals('getWeather'));
        expect(calls.single.function.arguments, equals('{"city":"London"}'));
      }
    });

    test(
        'captures usage from trailing chunk after finish_reason with random splits',
        () async {
      final config = OpenAICompatibleConfig(
        providerId: 'azure-openai',
        providerName: 'Azure OpenAI',
        apiKey: 'test-key',
        baseUrl: 'https://azure.example.com/v1/',
        model: 'gpt-4o-mini',
      );

      final sse = [
        _sseData({
          'id': 'chatcmpl_usage_fuzz',
          'model': 'gpt-4o-mini',
          'choices': [
            {
              'index': 0,
              'delta': {'role': 'assistant'},
            }
          ],
        }),
        _sseData({
          'id': 'chatcmpl_usage_fuzz',
          'model': 'gpt-4o-mini',
          'choices': [
            {
              'index': 0,
              'delta': {'content': 'Hello'},
            }
          ],
        }),
        _sseData({
          'id': 'chatcmpl_usage_fuzz',
          'model': 'gpt-4o-mini',
          'choices': [
            {
              'index': 0,
              'delta': <String, dynamic>{},
              'finish_reason': 'stop',
            }
          ],
        }),
        // Azure may send usage in a trailing chunk with empty choices.
        _sseData({
          'id': 'chatcmpl_usage_fuzz',
          'model': 'gpt-4o-mini',
          'choices': [],
          'usage': {
            'prompt_tokens': 3,
            'completion_tokens': 2,
            'total_tokens': 5,
            'prompt_tokens_details': {'cached_tokens': 1},
            'completion_tokens_details': {'reasoning_tokens': 1},
          },
        }),
        'data: [DONE]\n\n',
      ].join();

      for (final seed in [1, 7, 42]) {
        final client = FakeOpenAIClient(config)
          ..streamResponse =
              Stream<String>.fromIterable(_splitRandom(sse, seed: seed));
        final chat = OpenAIChat(client, config);

        final parts =
            await chat.chatStreamParts([ChatMessage.user('Hi')]).toList();

        final finish = parts.whereType<LLMFinishPart>().single;
        expect(finish.response.text, equals('Hello'));

        final usage = finish.response.usage;
        expect(usage, isNotNull);
        expect(usage!.promptTokens, equals(3));
        expect(usage.completionTokens, equals(2));
        expect(usage.totalTokens, equals(5));
        expect(usage.promptTokensCacheRead, equals(1));
        expect(usage.promptTokensNoCache, equals(2));
        expect(usage.reasoningTokens, equals(1));
        expect(usage.completionTokensText, equals(1));
      }
    });
  });
}
