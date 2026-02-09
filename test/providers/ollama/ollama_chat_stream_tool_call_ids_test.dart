// ignore_for_file: deprecated_member_use
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

      final events = await chat
          .chatStream([ChatMessage.user('Hi')], tools: const [])
          .toList();

      final toolEvents = events.whereType<ToolCallDeltaEvent>().toList();
      expect(toolEvents, hasLength(2));
      expect(toolEvents[0].toolCall.id, equals('call_getWeather'));
      expect(toolEvents[1].toolCall.id, equals('call_getWeather_1'));

      expect(
        toolEvents.map((e) => e.toolCall.function.arguments).toList(),
        equals([
          jsonEncode({'city': 'London'}),
          jsonEncode({'city': 'Paris'}),
        ]),
      );

      expect(events.whereType<CompletionEvent>(), hasLength(1));
    });
  });
}
