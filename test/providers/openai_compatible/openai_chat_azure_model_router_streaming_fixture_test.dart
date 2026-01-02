import 'dart:convert';
import 'dart:io';

import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_openai_compatible/llm_dart_openai_compatible.dart';
import 'package:llm_dart_openai_compatible/client.dart';
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
}

Stream<String> _sseStreamFromChunkFile(String path) async* {
  final lines = File(path)
      .readAsLinesSync()
      .map((l) => l.trim())
      .where((l) => l.isNotEmpty)
      .toList(growable: false);

  for (final line in lines) {
    yield 'data: $line\n\n';
  }
}

String _expectedTextFromChunks(String path) {
  final buf = StringBuffer();

  final lines = File(path)
      .readAsLinesSync()
      .map((l) => l.trim())
      .where((l) => l.isNotEmpty)
      .toList(growable: false);

  for (final line in lines) {
    final json = jsonDecode(line) as Map<String, dynamic>;
    final choices = json['choices'] as List?;
    if (choices == null || choices.isEmpty) continue;
    final choice = choices.first as Map<String, dynamic>;
    final delta = choice['delta'] as Map<String, dynamic>?;
    final content = delta?['content'];
    if (content is String) buf.write(content);
  }

  return buf.toString();
}

void main() {
  group('OpenAI chat streaming fixture (Vercel)', () {
    test('replays azure-model-router.1.chunks.txt', () async {
      const fixturePath =
          'test/fixtures/openai/chat/azure-model-router.1.chunks.txt';
      final expectedText = _expectedTextFromChunks(fixturePath);

      final config = OpenAICompatibleConfig(
        providerId: 'openai',
        providerName: 'OpenAI',
        apiKey: 'test-key',
        baseUrl: 'https://api.openai.com/v1/',
        model: 'gpt-5-nano',
      );

      final client = _FakeOpenAIClient(
        config,
        stream: _sseStreamFromChunkFile(fixturePath),
      );

      final provider = OpenAICompatibleChatProvider(
        client,
        config,
        const {LLMCapability.chat, LLMCapability.streaming},
      );

      final parts =
          await provider.chatStreamParts([ChatMessage.user('Hi')]).toList();

      final deltas =
          parts.whereType<LLMTextDeltaPart>().map((p) => p.delta).join();
      expect(deltas, equals(expectedText));

      final finish = parts.whereType<LLMFinishPart>().single;
      expect(finish.response.text, equals(expectedText));
    });
  });
}
