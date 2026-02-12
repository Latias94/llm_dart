import 'dart:convert';

import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_ollama/llm_dart_ollama.dart';
import 'package:test/test.dart';

import '../../utils/fakes/ollama_fake_client.dart';

void main() {
  group('OllamaChat response headers in response-metadata', () {
    test('exposes response headers when available', () async {
      final config = OllamaConfig(
        baseUrl: 'http://localhost:11434',
        model: 'llama3.1',
      );

      final chunks = <String>[
        '${jsonEncode({
              'model': 'llama3.1',
              'message': {'role': 'assistant', 'content': 'Hello'},
              'done': true,
            })}\n',
      ];

      final client = FakeOllamaClient(config)
        ..streamHeaders = const {'x-test': '1'}
        ..streamResponse = Stream<String>.fromIterable(chunks);

      final chat = OllamaChat(client, config);
      final parts =
          await chat.chatStreamParts([ChatMessage.user('Hi')]).toList();

      final meta = parts.whereType<LLMResponseMetadataPart>().single;
      expect(meta.headers, isNotNull);
      expect(meta.headers, containsPair('x-test', '1'));
    });
  });
}
