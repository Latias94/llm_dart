import 'dart:convert';

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
}

void main() {
  group('Ollama chatStream tool call ids', () {
    test('assigns unique ids for repeated tool names', () async {
      final config = OllamaConfig(
        baseUrl: 'http://localhost:11434',
        model: 'llama3.1',
      );

      final chunks = <String>[
        '${jsonEncode({
              'message': {
                'role': 'assistant',
                'tool_calls': [
                  {
                    'function': {
                      'name': 'getWeather',
                      'arguments': {'city': 'London'},
                    },
                  },
                ],
              },
              'done': false,
            })}\n',
        '${jsonEncode({
              'message': {
                'role': 'assistant',
                'tool_calls': [
                  {
                    'function': {
                      'name': 'getWeather',
                      'arguments': {'city': 'Paris'},
                    },
                  },
                ],
              },
              'done': true,
            })}\n',
      ];

      final client = _FakeOllamaClient(
        config,
        stream: Stream<String>.fromIterable(chunks),
      );
      final chat = OllamaChat(client, config);

      final parts = await chat
          .chatStreamParts([ChatMessage.user('Hi')], tools: const []).toList();

      final toolCalls = parts
          .whereType<LLMToolCallStartPart>()
          .map((p) => p.toolCall)
          .toList();
      expect(toolCalls, hasLength(2));
      expect(toolCalls[0].id, equals('call_getWeather'));
      expect(toolCalls[1].id, equals('call_getWeather_1'));

      expect(
        toolCalls.map((c) => c.function.arguments).toList(),
        equals([
          jsonEncode({'city': 'London'}),
          jsonEncode({'city': 'Paris'}),
        ]),
      );

      expect(parts.whereType<LLMFinishPart>(), hasLength(1));
    });
  });
}
