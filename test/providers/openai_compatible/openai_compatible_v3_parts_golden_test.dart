import 'dart:convert';
import 'dart:io';

import 'package:llm_dart_ai/llm_dart_ai.dart' as llm_ai;
import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_openai_compatible/llm_dart_openai_compatible.dart';
import 'package:llm_dart_openai_compatible/client.dart';
import 'package:test/test.dart';

import '../../utils/fixture_replay.dart';
import '../../utils/v3_parts_golden.dart';

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

({String text, String reasoning}) _expectedFromDeepSeekFixture(String path) {
  final text = StringBuffer();
  final reasoning = StringBuffer();

  for (final line in readFixtureLines(path)) {
    final json = jsonDecode(stripSseDataPrefix(line));
    if (json is! Map<String, dynamic>) continue;

    final choices = json['choices'];
    if (choices is! List || choices.isEmpty) continue;

    final choice = choices.first;
    if (choice is! Map<String, dynamic>) continue;

    final delta = choice['delta'];
    if (delta is! Map<String, dynamic>) continue;

    final content = delta['content'];
    if (content is String && content.isNotEmpty) text.write(content);

    final reasoningContent = delta['reasoning_content'];
    if (reasoningContent is String && reasoningContent.isNotEmpty) {
      reasoning.write(reasoningContent);
    }
  }

  return (text: text.toString(), reasoning: reasoning.toString());
}

void main() {
  group('OpenAI-compatible v3 parts goldens (Vercel fixtures)', () {
    const capabilities = {LLMCapability.chat, LLMCapability.streaming};

    Future<void> runDeepSeekFixtureGolden(String baseName) async {
      final fixturePath =
          'test/fixtures/openai_compatible/$baseName.chunks.txt';

      final config = OpenAICompatibleConfig(
        providerId: 'deepseek',
        providerName: 'DeepSeek',
        apiKey: 'test-key',
        baseUrl: 'https://api.deepseek.com/',
        model: 'deepseek-chat',
      );

      final client = _FakeOpenAIClient(
        config,
        stream: sseStreamFromChunkFile(fixturePath),
      );

      final provider =
          OpenAICompatibleChatProvider(client, config, capabilities);

      final parts = await llm_ai.streamChatParts(
          model: provider, messages: [ChatMessage.user('Hi')]).toList();

      // Sanity: ensure we at least match the expected DeepSeek extraction
      // (for the vendored DeepSeek fixtures).
      if (baseName.startsWith('deepseek-')) {
        final expected = _expectedFromDeepSeekFixture(fixturePath);
        final finish = parts.whereType<LLMFinishPart>().last;
        expect(finish.response.text ?? '', equals(expected.text));
      }

      final goldenPath =
          'test/fixtures/v3_parts/openai_compatible/$baseName.jsonl';
      final actual = encodeV3StreamParts(parts);

      expectStableJsonlGolden(
        goldenPath: goldenPath,
        actualObjects: actual,
      );

      final meta = File(
        'test/fixtures/v3_parts/openai_compatible/$baseName.meta.json',
      );
      expect(meta.existsSync(), isTrue);
    }

    final metaDir = Directory('test/fixtures/v3_parts/openai_compatible');
    final baseNames = metaDir
        .listSync(followLinks: false)
        .whereType<File>()
        .where((f) => f.path.endsWith('.meta.json'))
        .map((f) => f.uri.pathSegments.last.replaceAll('.meta.json', ''))
        .toList()
      ..sort();

    for (final baseName in baseNames) {
      test(baseName, () async {
        await runDeepSeekFixtureGolden(baseName);
      });
    }
  });
}
