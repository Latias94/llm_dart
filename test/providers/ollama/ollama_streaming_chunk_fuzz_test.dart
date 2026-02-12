import 'dart:convert';
import 'dart:math';

import 'package:llm_dart/llm_dart.dart';
import 'package:llm_dart_ollama/client.dart';
import 'package:test/test.dart';

class _FakeOllamaClient extends OllamaClient {
  final Stream<String> _stream;

  _FakeOllamaClient(
    super.config, {
    required Stream<String> stream,
  }) : _stream = stream;

  @override
  Stream<String> postStreamRaw(
    String endpoint,
    Map<String, dynamic> data, {
    CancelToken? cancelToken,
  }) {
    return _stream;
  }

  @override
  Future<({Stream<String> stream, Map<String, String> headers})>
      postStreamRawWithHeaders(
    String endpoint,
    Map<String, dynamic> data, {
    CancelToken? cancelToken,
  }) async {
    return (stream: _stream, headers: const <String, String>{});
  }
}

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
  group('Ollama chatStreamParts fuzz (chunk boundaries)', () {
    test('handles arbitrary chunk splits without losing parts', () async {
      final config = OllamaConfig(
        baseUrl: 'http://localhost:11434',
        model: 'llama3.1',
      );

      final jsonl = [
        jsonEncode({
          'message': {
            'role': 'assistant',
            'thinking': '思考中...',
          },
          'done': false,
        }),
        jsonEncode({
          'message': {'role': 'assistant', 'content': 'Hello '},
          'done': false,
        }),
        jsonEncode({
          'message': {'role': 'assistant', 'content': 'world'},
          'done': false,
        }),
        jsonEncode({
          'message': {
            'role': 'assistant',
            'tool_calls': [
              {
                'function': {
                  'name': 'get_weather',
                  'arguments': {'location': 'London'},
                },
              },
            ],
          },
          'done': true,
        }),
      ].map((line) => '$line\n').join();

      for (final seed in [1, 7, 42]) {
        final client = _FakeOllamaClient(
          config,
          stream: Stream<String>.fromIterable(
            _splitRandom(jsonl, seed: seed),
          ),
        );
        final chat = OllamaChat(client, config);

        final parts = await chat.chatStreamParts([ChatMessage.user('Hi')],
            tools: const []).toList();

        final text =
            parts.whereType<LLMTextDeltaPart>().map((p) => p.delta).join();
        final thinking =
            parts.whereType<LLMReasoningDeltaPart>().map((p) => p.delta).join();

        expect(text, equals('Hello world'));
        expect(thinking, equals('思考中...'));

        final toolStart = parts.whereType<LLMToolCallStartPart>().single;
        expect(toolStart.toolCall.id, equals('call_get_weather'));
        expect(toolStart.toolCall.function.name, equals('get_weather'));
        expect(
          toolStart.toolCall.function.arguments,
          equals(jsonEncode({'location': 'London'})),
        );

        expect(parts.whereType<LLMToolCallEndPart>().single.toolCallId,
            equals('call_get_weather'));

        final finish = parts.whereType<LLMFinishPart>().single;
        expect(finish.response.text, equals('Hello world'));
        expect(finish.response.thinking, equals('思考中...'));
        expect(finish.response.toolCalls, isNotNull);
        expect(
            finish.response.toolCalls!.single.id, equals('call_get_weather'));
      }
    });
  });
}
