import 'dart:convert';

import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_openai_compatible/client.dart';
import 'package:llm_dart_openai_compatible/llm_dart_openai_compatible.dart';
import 'package:test/test.dart';

class _FakeOpenAIClient extends OpenAIClient {
  final Stream<String> _stream;

  _FakeOpenAIClient(
    super.config, {
    required Stream<String> stream,
  }) : _stream = stream;

  @override
  Stream<String> postStreamRaw(
    String endpoint,
    Map<String, dynamic> body, {
    CancelToken? cancelToken,
  }) {
    return _stream;
  }

  @override
  Future<({Stream<String> stream, Map<String, String> headers})>
      postStreamRawWithHeaders(
    String endpoint,
    Map<String, dynamic> body, {
    Map<String, String>? headers,
    CancelToken? cancelToken,
  }) async {
    return (stream: _stream, headers: const <String, String>{});
  }
}

String _sseData(Map<String, dynamic> json) => 'data: ${jsonEncode(json)}\n\n';

void main() {
  group('OpenAI-compatible streaming tool call conformance', () {
    test('buffers tool call deltas until id arrives (index-based)', () async {
      final config = OpenAICompatibleConfig(
        providerId: 'openai-compatible',
        providerName: 'OpenAI-compatible',
        apiKey: 'test-key',
        baseUrl: 'https://api.example.com/v1/',
        model: 'gpt-4o-mini',
      );

      final chunks = <String>[
        _sseData({
          'id': 'chatcmpl_1',
          'model': 'gpt-4o-mini',
          'choices': [
            {
              'index': 0,
              'delta': {
                'tool_calls': [
                  {
                    'index': 0,
                    // id intentionally missing
                    'function': {
                      'name': 'sum',
                      'arguments': '{"a":',
                    },
                  }
                ],
              },
            }
          ],
        }),
        _sseData({
          'id': 'chatcmpl_1',
          'model': 'gpt-4o-mini',
          'choices': [
            {
              'index': 0,
              'delta': {
                'tool_calls': [
                  {
                    'index': 0,
                    'id': 'call_1',
                    'function': {
                      'name': 'sum',
                      'arguments': '1,"b":2}',
                    },
                  }
                ],
              },
            }
          ],
        }),
        _sseData({
          'id': 'chatcmpl_1',
          'model': 'gpt-4o-mini',
          'choices': [
            {
              'index': 0,
              'delta': <String, dynamic>{},
              'finish_reason': 'tool_calls',
            }
          ],
          'usage': {
            'prompt_tokens': 3,
            'completion_tokens': 2,
            'total_tokens': 5
          },
        }),
      ];

      final client = _FakeOpenAIClient(
        config,
        stream: Stream<String>.fromIterable(chunks),
      );
      final chat = OpenAIChat(client, config);

      final parts =
          await chat.chatStreamParts([ChatMessage.user('Hi')]).toList();

      final toolStarts = parts.whereType<LLMToolCallStartPart>().toList();
      final toolDeltas = parts.whereType<LLMToolCallDeltaPart>().toList();
      final toolEnds = parts.whereType<LLMToolCallEndPart>().toList();

      expect(toolStarts, hasLength(1));
      expect(toolStarts.single.toolCall.id, equals('call_1'));
      expect(toolStarts.single.toolCall.function.name, equals('sum'));

      // Once the id arrives, the buffered delta should be flushed first.
      expect(toolDeltas, hasLength(2));
      expect(toolDeltas[0].toolCall.id, equals('call_1'));
      expect(toolDeltas[0].toolCall.function.arguments, equals('{"a":'));
      expect(toolDeltas[1].toolCall.id, equals('call_1'));
      expect(toolDeltas[1].toolCall.function.arguments, equals('1,"b":2}'));

      expect(toolEnds, hasLength(1));
      expect(toolEnds.single.toolCallId, equals('call_1'));

      final finish = parts.whereType<LLMFinishPart>().single;
      final calls = finish.response.toolCalls;
      expect(calls, isNotNull);
      expect(calls!, hasLength(1));
      expect(calls.single.id, equals('call_1'));
      expect(calls.single.function.name, equals('sum'));
      expect(calls.single.function.arguments, equals('{"a":1,"b":2}'));
    });

    test('supports multiple tool calls interleaved across chunks', () async {
      final config = OpenAICompatibleConfig(
        providerId: 'openai-compatible',
        providerName: 'OpenAI-compatible',
        apiKey: 'test-key',
        baseUrl: 'https://api.example.com/v1/',
        model: 'gpt-4o-mini',
      );

      final chunks = <String>[
        _sseData({
          'id': 'chatcmpl_2',
          'model': 'gpt-4o-mini',
          'choices': [
            {
              'index': 0,
              'delta': {
                'tool_calls': [
                  {
                    'index': 0,
                    'id': 'call_1',
                    'function': {'name': 'toolA', 'arguments': '{"x":'},
                  },
                  {
                    'index': 1,
                    'id': 'call_2',
                    'function': {'name': 'toolB', 'arguments': '{"y":'},
                  },
                ],
              },
            }
          ],
        }),
        _sseData({
          'id': 'chatcmpl_2',
          'model': 'gpt-4o-mini',
          'choices': [
            {
              'index': 0,
              'delta': {
                'tool_calls': [
                  {
                    'index': 0,
                    'id': 'call_1',
                    'function': {'arguments': '1}'},
                  },
                ],
              },
            }
          ],
        }),
        _sseData({
          'id': 'chatcmpl_2',
          'model': 'gpt-4o-mini',
          'choices': [
            {
              'index': 0,
              'delta': {
                'tool_calls': [
                  {
                    'index': 1,
                    'id': 'call_2',
                    'function': {'arguments': '2}'},
                  },
                ],
              },
            }
          ],
        }),
        _sseData({
          'id': 'chatcmpl_2',
          'model': 'gpt-4o-mini',
          'choices': [
            {
              'index': 0,
              'delta': <String, dynamic>{},
              'finish_reason': 'tool_calls',
            }
          ],
        }),
      ];

      final client = _FakeOpenAIClient(
        config,
        stream: Stream<String>.fromIterable(chunks),
      );
      final chat = OpenAIChat(client, config);

      final parts =
          await chat.chatStreamParts([ChatMessage.user('Hi')]).toList();

      final toolEnds = parts.whereType<LLMToolCallEndPart>().toList();
      expect(
          toolEnds.map((e) => e.toolCallId), containsAll(['call_1', 'call_2']));

      final finish = parts.whereType<LLMFinishPart>().single;
      final calls = finish.response.toolCalls;
      expect(calls, isNotNull);
      expect(calls!, hasLength(2));

      calls.sort((a, b) => a.id.compareTo(b.id));
      expect(calls[0].id, equals('call_1'));
      expect(calls[0].function.name, equals('toolA'));
      expect(calls[0].function.arguments, equals('{"x":1}'));

      expect(calls[1].id, equals('call_2'));
      expect(calls[1].function.name, equals('toolB'));
      expect(calls[1].function.arguments, equals('{"y":2}'));
    });

    test('does not surface incomplete tool calls in the final response',
        () async {
      final config = OpenAICompatibleConfig(
        providerId: 'openai-compatible',
        providerName: 'OpenAI-compatible',
        apiKey: 'test-key',
        baseUrl: 'https://api.example.com/v1/',
        model: 'gpt-4o-mini',
      );

      final chunks = <String>[
        _sseData({
          'id': 'chatcmpl_3',
          'model': 'gpt-4o-mini',
          'choices': [
            {
              'index': 0,
              'delta': {
                'tool_calls': [
                  {
                    'index': 0,
                    'id': 'call_1',
                    'function': {
                      'name': 'sum',
                      // Invalid JSON on purpose.
                      'arguments': '{"a":1,',
                    },
                  },
                ],
              },
            }
          ],
        }),
        _sseData({
          'id': 'chatcmpl_3',
          'model': 'gpt-4o-mini',
          'choices': [
            {
              'index': 0,
              'delta': <String, dynamic>{},
              'finish_reason': 'tool_calls',
            }
          ],
        }),
      ];

      final client = _FakeOpenAIClient(
        config,
        stream: Stream<String>.fromIterable(chunks),
      );
      final chat = OpenAIChat(client, config);

      final parts =
          await chat.chatStreamParts([ChatMessage.user('Hi')]).toList();

      // Start may be emitted, but we must not emit an end for invalid JSON.
      expect(parts.whereType<LLMToolCallStartPart>(), hasLength(1));
      expect(parts.whereType<LLMToolCallEndPart>(), isEmpty);

      final finish = parts.whereType<LLMFinishPart>().single;
      expect(finish.response.toolCalls, anyOf(isNull, isEmpty));
    });

    test('captures extra_content.google.thought_signature into providerOptions',
        () async {
      final config = OpenAICompatibleConfig(
        providerId: 'deepseek',
        providerName: 'DeepSeek',
        apiKey: 'test-key',
        baseUrl: 'https://api.deepseek.com/v1/',
        model: 'deepseek-chat',
      );

      final chunks = <String>[
        _sseData({
          'id': 'chatcmpl_4',
          'model': 'deepseek-chat',
          'choices': [
            {
              'index': 0,
              'delta': {
                'tool_calls': [
                  {
                    'index': 0,
                    'id': 'call_1',
                    'function': {
                      'name': 'sum',
                      'arguments': '{"a":',
                    },
                    'extra_content': {
                      'google': {'thought_signature': 'ts_1'}
                    },
                  }
                ],
              },
            }
          ],
        }),
        _sseData({
          'id': 'chatcmpl_4',
          'model': 'deepseek-chat',
          'choices': [
            {
              'index': 0,
              'delta': {
                'tool_calls': [
                  {
                    'index': 0,
                    'id': 'call_1',
                    'function': {'arguments': '1}'},
                  }
                ],
              },
            }
          ],
        }),
        _sseData({
          'id': 'chatcmpl_4',
          'model': 'deepseek-chat',
          'choices': [
            {
              'index': 0,
              'delta': <String, dynamic>{},
              'finish_reason': 'tool_calls',
            }
          ],
        }),
      ];

      final client = _FakeOpenAIClient(
        config,
        stream: Stream<String>.fromIterable(chunks),
      );
      final chat = OpenAIChat(client, config);

      final parts =
          await chat.chatStreamParts([ChatMessage.user('Hi')]).toList();

      final toolStart = parts.whereType<LLMToolCallStartPart>().single;
      expect(toolStart.toolCall.id, equals('call_1'));
      expect(toolStart.toolCall.function.name, equals('sum'));
      expect(
          toolStart.toolCall.providerOptions['deepseek']?['thoughtSignature'],
          equals('ts_1'));

      final finish = parts.whereType<LLMFinishPart>().single;
      final calls = finish.response.toolCalls;
      expect(calls, isNotNull);
      expect(calls!, hasLength(1));
      expect(calls.single.providerOptions['deepseek']?['thoughtSignature'],
          equals('ts_1'));
    });
  });
}
