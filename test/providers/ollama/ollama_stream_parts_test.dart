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
  group('Ollama chatStreamParts (NDJSON stream)', () {
    test('streams text + tool call parts and finishes with toolCalls',
        () async {
      final config = OllamaConfig(
        baseUrl: 'http://localhost:11434',
        model: 'llama3.1',
      );

      final chunks = <String>[
        '${jsonEncode({
              'message': {'role': 'assistant', 'content': 'Hello '},
              'done': false,
            })}\n',
        '${jsonEncode({
              'message': {'role': 'assistant', 'content': 'world'},
              'done': false,
            })}\n',
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

      expect(parts.whereType<LLMTextStartPart>(), hasLength(1));
      expect(parts.whereType<LLMTextDeltaPart>().map((p) => p.delta).join(),
          equals('Hello world'));
      expect(
          parts.whereType<LLMTextEndPart>().single.text, equals('Hello world'));

      final toolStart = parts.whereType<LLMToolCallStartPart>().single;
      expect(toolStart.toolCall.id, equals('call_getWeather'));
      expect(toolStart.toolCall.function.name, equals('getWeather'));
      expect(toolStart.toolCall.function.arguments,
          equals(jsonEncode({'city': 'London'})));

      expect(parts.whereType<LLMToolCallEndPart>().single.toolCallId,
          equals('call_getWeather'));

      final finish = parts.last as LLMFinishPart;
      expect(finish.response.text, equals('Hello world'));
      expect(finish.response.thinking, isNull);

      final calls = finish.response.toolCalls;
      expect(calls, isNotNull);
      expect(calls!, hasLength(1));
      expect(calls.single.id, equals('call_getWeather'));
      expect(calls.single.function.name, equals('getWeather'));
      expect(calls.single.function.arguments,
          equals(jsonEncode({'city': 'London'})));

      final metadata = finish.response.providerMetadata;
      expect(metadata, isNotNull);
      expect(metadata!['ollama']['model'], equals('llama3.1'));
    });
  });
}
