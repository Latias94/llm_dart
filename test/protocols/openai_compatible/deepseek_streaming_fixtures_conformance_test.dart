import 'dart:convert';
import 'dart:io';

import 'package:llm_dart_openai_compatible/llm_dart_openai_compatible.dart';
import 'package:llm_dart_core/core/cancellation.dart';
import 'package:llm_dart_core/core/stream_parts.dart';
import 'package:llm_dart_core/models/chat_models.dart';
import 'package:llm_dart_core/models/tool_models.dart';
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
    if (line.startsWith('data:')) {
      yield '$line\n\n';
      continue;
    }
    yield 'data: $line\n\n';
  }
}

class _ExpectedToolCall {
  final String id;
  final String name;
  final String arguments;

  const _ExpectedToolCall({
    required this.id,
    required this.name,
    required this.arguments,
  });
}

class _ExpectedFromChunks {
  final String? id;
  final String? model;
  final String? systemFingerprint;
  final String text;
  final String thinking;
  final String? finishReason;
  final Map<String, dynamic>? usage;
  final List<_ExpectedToolCall> toolCalls;

  const _ExpectedFromChunks({
    required this.id,
    required this.model,
    required this.systemFingerprint,
    required this.text,
    required this.thinking,
    required this.finishReason,
    required this.usage,
    required this.toolCalls,
  });
}

class _ToolCallAccum {
  String? name;
  final StringBuffer arguments = StringBuffer();
}

_ExpectedFromChunks _expectedFromChunkFile(String path) {
  final text = StringBuffer();
  final thinking = StringBuffer();

  final toolCallIdsByIndex = <int, String>{};
  final toolAccums = <String, _ToolCallAccum>{};

  String? id;
  String? model;
  String? systemFingerprint;
  String? finishReason;
  Map<String, dynamic>? usage;

  final lines = File(path)
      .readAsLinesSync()
      .map((l) => l.trim())
      .where((l) => l.isNotEmpty)
      .toList(growable: false);

  for (final line in lines) {
    final json = jsonDecode(line) as Map<String, dynamic>;

    id ??= json['id'] as String?;
    model ??= json['model'] as String?;
    systemFingerprint ??= json['system_fingerprint'] as String?;

    final rawUsage = json['usage'];
    if (rawUsage is Map<String, dynamic>) {
      usage = rawUsage;
    } else if (rawUsage is Map) {
      usage = Map<String, dynamic>.from(rawUsage);
    }

    final choices = json['choices'] as List?;
    if (choices == null || choices.isEmpty) continue;

    final choice = choices.first as Map<String, dynamic>;
    final delta = choice['delta'] as Map<String, dynamic>?;

    final content = delta?['content'];
    if (content is String && content.isNotEmpty) {
      text.write(content);
    }

    final reasoningContent = delta?['reasoning_content'];
    if (reasoningContent is String && reasoningContent.isNotEmpty) {
      thinking.write(reasoningContent);
    }

    final toolCalls = delta?['tool_calls'] as List?;
    if (toolCalls != null && toolCalls.isNotEmpty) {
      for (final rawCall in toolCalls) {
        if (rawCall is! Map) continue;

        final index = rawCall['index'];
        if (index is int) {
          final callId = rawCall['id'];
          if (callId is String && callId.isNotEmpty) {
            toolCallIdsByIndex[index] = callId;
          }

          final stableId = toolCallIdsByIndex[index];
          if (stableId == null || stableId.isEmpty) continue;

          final functionMap = rawCall['function'];
          if (functionMap is! Map) continue;

          final name = functionMap['name'];
          final args = functionMap['arguments'];

          final accum =
              toolAccums.putIfAbsent(stableId, () => _ToolCallAccum());

          if (name is String && name.isNotEmpty) {
            accum.name = name;
          }
          if (args is String && args.isNotEmpty) {
            accum.arguments.write(args);
          }
        }
      }
    }

    final fr = choice['finish_reason'];
    if (fr is String && fr.isNotEmpty) {
      finishReason = fr;
    }
  }

  final expectedToolCalls = toolAccums.entries
      .map(
        (e) => _ExpectedToolCall(
          id: e.key,
          name: e.value.name ?? '',
          arguments: e.value.arguments.toString(),
        ),
      )
      .toList(growable: false);

  return _ExpectedFromChunks(
    id: id,
    model: model,
    systemFingerprint: systemFingerprint,
    text: text.toString(),
    thinking: thinking.toString(),
    finishReason: finishReason,
    usage: usage,
    toolCalls: expectedToolCalls,
  );
}

void main() {
  group('OpenAI-compatible streaming fixtures (DeepSeek, Vercel)', () {
    test('replays deepseek-text.chunks.txt', () async {
      const fixturePath =
          'repo-ref/ai/packages/deepseek/src/chat/__fixtures__/deepseek-text.chunks.txt';
      final expected = _expectedFromChunkFile(fixturePath);

      final config = OpenAICompatibleConfig(
        providerId: 'deepseek',
        providerName: 'DeepSeek',
        apiKey: 'test-key',
        baseUrl: 'https://api.deepseek.com/v1/',
        model: 'deepseek-chat',
      );

      final client = _FakeOpenAIClient(
        config,
        stream: _sseStreamFromChunkFile(fixturePath),
      );
      final chat = OpenAIChat(client, config);

      final parts =
          await chat.chatStreamParts([ChatMessage.user('Hi')]).toList();

      expect(parts.whereType<LLMTextDeltaPart>().map((p) => p.delta).join(),
          equals(expected.text));
      expect(parts.whereType<LLMReasoningDeltaPart>(), isEmpty);

      final finish = parts.whereType<LLMFinishPart>().single;
      expect(finish.response.text, equals(expected.text));
      expect(finish.response.thinking, isNull);

      final metadata = finish.response.providerMetadata;
      expect(metadata, isNotNull);
      expect(metadata!['deepseek']['id'], equals(expected.id));
      expect(metadata['deepseek']['model'], equals(expected.model));
      expect(metadata['deepseek']['systemFingerprint'],
          equals(expected.systemFingerprint));
      expect(
          metadata['deepseek']['finishReason'], equals(expected.finishReason));

      final usage = finish.response.usage;
      expect(usage, isNotNull);
      expect(usage!.totalTokens,
          equals((expected.usage?['total_tokens'] as int?)));
    });

    test('replays deepseek-reasoning.chunks.txt', () async {
      const fixturePath =
          'repo-ref/ai/packages/deepseek/src/chat/__fixtures__/deepseek-reasoning.chunks.txt';
      final expected = _expectedFromChunkFile(fixturePath);

      final config = OpenAICompatibleConfig(
        providerId: 'deepseek',
        providerName: 'DeepSeek',
        apiKey: 'test-key',
        baseUrl: 'https://api.deepseek.com/v1/',
        model: 'deepseek-reasoner',
      );

      final client = _FakeOpenAIClient(
        config,
        stream: _sseStreamFromChunkFile(fixturePath),
      );
      final chat = OpenAIChat(client, config);

      final parts =
          await chat.chatStreamParts([ChatMessage.user('Hi')]).toList();

      expect(
        parts.whereType<LLMReasoningDeltaPart>().map((p) => p.delta).join(),
        equals(expected.thinking),
      );
      expect(parts.whereType<LLMTextDeltaPart>().map((p) => p.delta).join(),
          equals(expected.text));

      final finish = parts.whereType<LLMFinishPart>().single;
      expect(finish.response.text, equals(expected.text));
      expect(finish.response.thinking, equals(expected.thinking));
      expect(finish.response.toolCalls, isNull);
      expect(finish.response.usage, isNotNull);
    });

    test('replays deepseek-tool-call.chunks.txt', () async {
      const fixturePath =
          'repo-ref/ai/packages/deepseek/src/chat/__fixtures__/deepseek-tool-call.chunks.txt';
      final expected = _expectedFromChunkFile(fixturePath);

      final config = OpenAICompatibleConfig(
        providerId: 'deepseek',
        providerName: 'DeepSeek',
        apiKey: 'test-key',
        baseUrl: 'https://api.deepseek.com/v1/',
        model: 'deepseek-reasoner',
      );

      final client = _FakeOpenAIClient(
        config,
        stream: _sseStreamFromChunkFile(fixturePath),
      );
      final chat = OpenAIChat(client, config);

      final parts =
          await chat.chatStreamParts([ChatMessage.user('Hi')]).toList();

      expect(parts.whereType<LLMTextDeltaPart>(), isEmpty);
      expect(
        parts.whereType<LLMReasoningDeltaPart>().map((p) => p.delta).join(),
        equals(expected.thinking),
      );

      expect(expected.toolCalls, hasLength(1));
      final expectedTool = expected.toolCalls.single;

      final toolStart = parts.whereType<LLMToolCallStartPart>().single;
      expect(toolStart.toolCall.id, equals(expectedTool.id));
      expect(toolStart.toolCall.function.name, equals(expectedTool.name));

      final finish = parts.whereType<LLMFinishPart>().single;
      final calls = finish.response.toolCalls;
      expect(calls, isNotNull);
      expect(calls!, hasLength(1));

      final call = calls.single;
      expect(call.id, equals(expectedTool.id));
      expect(call.function.name, equals(expectedTool.name));
      expect(call.function.arguments, equals(expectedTool.arguments));
      expect(finish.response.thinking, equals(expected.thinking));
    });
  });
}
