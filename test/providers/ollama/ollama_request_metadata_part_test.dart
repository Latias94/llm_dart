import 'dart:convert';

import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_ollama/llm_dart_ollama.dart';
import 'package:test/test.dart';

import '../../utils/fakes/ollama_fake_client.dart';

void main() {
  group('OllamaChat request metadata part', () {
    test('emits LLMRequestMetadataPart when enabled', () async {
      final llmConfig = LLMConfig(
        apiKey: 'test-key',
        baseUrl: 'http://localhost:11434',
        model: 'llama3.1',
        providerOptions: const {
          'ollama': {
            'emitRequestMetadata': true,
          },
        },
      );
      final config = OllamaConfig.fromLLMConfig(llmConfig);

      final chunks = <String>[
        '${jsonEncode({
              'message': {'role': 'assistant', 'content': 'Hello'},
              'done': true,
            })}\n',
      ];

      final client = FakeOllamaClient(config)
        ..streamResponse = Stream<String>.fromIterable(chunks);

      final chat = OllamaChat(client, config);
      final parts =
          await chat.chatStreamParts([ChatMessage.user('Hi')]).toList();

      final requestMeta = parts.whereType<LLMRequestMetadataPart>().toList();
      expect(requestMeta, hasLength(1));

      final body = requestMeta.single.body as Map<String, dynamic>;
      expect(body['messages'], isNotNull);
    });
  });
}
