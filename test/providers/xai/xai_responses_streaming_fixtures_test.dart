import 'dart:convert';
import 'dart:io';

import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_openai_compatible/llm_dart_openai_compatible.dart';
import 'package:llm_dart_openai_compatible/client.dart';
import 'package:llm_dart_xai/llm_dart_xai.dart';
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

({String text, String thinking}) _expectedFromChunkFile(String path) {
  final text = StringBuffer();
  final thinking = StringBuffer();

  final lines = File(path)
      .readAsLinesSync()
      .map((l) => l.trim())
      .where((l) => l.isNotEmpty)
      .toList(growable: false);

  for (final line in lines) {
    final json = jsonDecode(line) as Map<String, dynamic>;
    final type = json['type'] as String?;

    if (type == 'response.output_text.delta') {
      final delta = json['delta'] as String?;
      if (delta != null) text.write(delta);
    }

    if (type == 'response.reasoning_summary_text.delta') {
      final delta = json['delta'] as String?;
      if (delta != null) thinking.write(delta);
    }
  }

  return (text: text.toString(), thinking: thinking.toString());
}

void main() {
  group('xAI Responses streaming fixtures (Vercel)', () {
    test('replays xai-text-streaming.1.chunks.txt', () async {
      const fixturePath =
          'repo-ref/ai/packages/xai/src/responses/__fixtures__/xai-text-streaming.1.chunks.txt';
      final expected = _expectedFromChunkFile(fixturePath);

      final config = OpenAICompatibleConfig(
        providerId: 'xai.responses',
        providerName: 'xAI (Responses)',
        apiKey: 'test-key',
        baseUrl: 'https://api.x.ai/v1/',
        model: 'grok-code-fast-1',
      );

      final client = _FakeOpenAIClient(
        config,
        stream: _sseStreamFromChunkFile(fixturePath),
      );
      final responses = XAIResponses(client, config);

      final parts =
          await responses.chatStreamParts([ChatMessage.user('Hi')]).toList();

      expect(
        parts.whereType<LLMReasoningDeltaPart>().map((p) => p.delta).join(),
        equals(expected.thinking),
      );
      expect(parts.whereType<LLMTextDeltaPart>().map((p) => p.delta).join(),
          equals(expected.text));

      final finish = parts.whereType<LLMFinishPart>().single;
      expect(finish.response.text, equals(expected.text));
      expect(finish.response.thinking,
          equals(expected.thinking.isEmpty ? null : expected.thinking));
      expect(finish.response.toolCalls, isNull);
      expect(finish.response.providerMetadata?['xai.responses'], isNotNull);
    });

    test('replays xai-text-with-reasoning-streaming.1.chunks.txt', () async {
      const fixturePath =
          'repo-ref/ai/packages/xai/src/responses/__fixtures__/xai-text-with-reasoning-streaming.1.chunks.txt';
      final expected = _expectedFromChunkFile(fixturePath);

      final config = OpenAICompatibleConfig(
        providerId: 'xai.responses',
        providerName: 'xAI (Responses)',
        apiKey: 'test-key',
        baseUrl: 'https://api.x.ai/v1/',
        model: 'grok-code-fast-1',
      );

      final client = _FakeOpenAIClient(
        config,
        stream: _sseStreamFromChunkFile(fixturePath),
      );
      final responses = XAIResponses(client, config);

      final parts =
          await responses.chatStreamParts([ChatMessage.user('Hi')]).toList();

      expect(
        parts.whereType<LLMReasoningDeltaPart>().map((p) => p.delta).join(),
        equals(expected.thinking),
      );

      final finish = parts.whereType<LLMFinishPart>().single;
      expect(finish.response.thinking, equals(expected.thinking));
    });

    test('replays xai-web-search-tool.1.chunks.txt (server tool call)',
        () async {
      const fixturePath =
          'repo-ref/ai/packages/xai/src/responses/__fixtures__/xai-web-search-tool.1.chunks.txt';

      final config = OpenAICompatibleConfig(
        providerId: 'xai.responses',
        providerName: 'xAI (Responses)',
        apiKey: 'test-key',
        baseUrl: 'https://api.x.ai/v1/',
        model: 'grok-4-fast-reasoning',
      );

      final client = _FakeOpenAIClient(
        config,
        stream: _sseStreamFromChunkFile(fixturePath),
      );
      final responses = XAIResponses(client, config);

      final parts =
          await responses.chatStreamParts([ChatMessage.user('Hi')]).toList();

      final finish = parts.whereType<LLMFinishPart>().single;
      expect(finish.response.toolCalls, isNull);

      final metadata = finish.response.providerMetadata?['xai.responses'];
      expect(metadata, isNotNull);
      expect(metadata!['serverToolCalls'], isNotNull);
      expect((metadata['sources'] as List?)?.length, equals(5));
    });
  });
}
