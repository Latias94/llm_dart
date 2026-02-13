import 'dart:convert';

import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_openai_compatible/llm_dart_openai_compatible.dart';
import 'package:llm_dart_openai_compatible/client.dart';
import 'package:test/test.dart';

import '../../utils/fixture_replay.dart';

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

String _expectedDeepSeekReasoningFromChunkFile(String path) {
  final buf = StringBuffer();

  for (final line in readFixtureLines(path)) {
    final json = jsonDecode(stripSseDataPrefix(line));
    if (json is! Map<String, dynamic>) continue;

    final choices = json['choices'];
    if (choices is! List || choices.isEmpty) continue;

    final choice = choices.first;
    if (choice is! Map<String, dynamic>) continue;

    final delta = choice['delta'];
    if (delta is! Map<String, dynamic>) continue;

    final reasoning = delta['reasoning_content'];
    if (reasoning is String && reasoning.isNotEmpty) buf.write(reasoning);
  }

  return buf.toString();
}

({String id, String name, String arguments})
    _expectedDeepSeekToolCallFromChunkFile(
  String path,
) {
  String? callId;
  String? name;
  final args = StringBuffer();

  for (final line in readFixtureLines(path)) {
    final json = jsonDecode(stripSseDataPrefix(line));
    if (json is! Map<String, dynamic>) continue;

    final choices = json['choices'];
    if (choices is! List || choices.isEmpty) continue;

    final choice = choices.first;
    if (choice is! Map<String, dynamic>) continue;

    final delta = choice['delta'];
    if (delta is! Map<String, dynamic>) continue;

    final toolCalls = delta['tool_calls'];
    if (toolCalls is! List || toolCalls.isEmpty) continue;

    final call = toolCalls.first;
    if (call is! Map<String, dynamic>) continue;

    callId ??= call['id'] as String?;

    final function = call['function'];
    if (function is Map<String, dynamic>) {
      name ??= function['name'] as String?;
      final a = function['arguments'];
      if (a is String && a.isNotEmpty) args.write(a);
    }
  }

  if (callId == null || callId.isEmpty) {
    throw StateError('Missing tool call id in fixture: $path');
  }
  if (name == null || name.isEmpty) {
    throw StateError('Missing tool call name in fixture: $path');
  }

  return (id: callId, name: name, arguments: args.toString());
}

void main() {
  group('DeepSeek streaming fixtures (Vercel)', () {
    const capabilities = {LLMCapability.chat, LLMCapability.streaming};

    test('replays deepseek-text.chunks.txt', () async {
      const fixturePath =
          'repo-ref/ai/packages/deepseek/src/chat/__fixtures__/deepseek-text.chunks.txt';
      final expectedText =
          expectedOpenAIChatCompletionsTextFromChunkFile(fixturePath);

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

      final parts =
          await provider.chatStreamParts([ChatMessage.user('Hi')]).toList();

      final deltas =
          parts.whereType<LLMTextDeltaPart>().map((p) => p.delta).join();
      expect(deltas, equals(expectedText));

      final finish = parts.whereType<LLMFinishPart>().single;
      expect(finish.response.text, equals(expectedText));
      expect(finish.response.thinking, isNull);
    });

    test('replays deepseek-reasoning.chunks.txt', () async {
      const fixturePath =
          'repo-ref/ai/packages/deepseek/src/chat/__fixtures__/deepseek-reasoning.chunks.txt';
      final expectedText =
          expectedOpenAIChatCompletionsTextFromChunkFile(fixturePath);
      final expectedThinking =
          _expectedDeepSeekReasoningFromChunkFile(fixturePath);

      final config = OpenAICompatibleConfig(
        providerId: 'deepseek',
        providerName: 'DeepSeek',
        apiKey: 'test-key',
        baseUrl: 'https://api.deepseek.com/',
        model: 'deepseek-reasoner',
      );

      final client = _FakeOpenAIClient(
        config,
        stream: sseStreamFromChunkFile(fixturePath),
      );

      final provider =
          OpenAICompatibleChatProvider(client, config, capabilities);

      final parts =
          await provider.chatStreamParts([ChatMessage.user('Hi')]).toList();

      expect(
        parts.whereType<LLMReasoningDeltaPart>().map((p) => p.delta).join(),
        equals(expectedThinking),
      );
      expect(
        parts.whereType<LLMTextDeltaPart>().map((p) => p.delta).join(),
        equals(expectedText),
      );

      final finish = parts.whereType<LLMFinishPart>().single;
      expect(finish.response.text ?? '', equals(expectedText));
      expect(finish.response.thinking, equals(expectedThinking));
    });

    test('replays deepseek-tool-call.chunks.txt', () async {
      const fixturePath =
          'repo-ref/ai/packages/deepseek/src/chat/__fixtures__/deepseek-tool-call.chunks.txt';
      final expected = _expectedDeepSeekToolCallFromChunkFile(fixturePath);

      final config = OpenAICompatibleConfig(
        providerId: 'deepseek',
        providerName: 'DeepSeek',
        apiKey: 'test-key',
        baseUrl: 'https://api.deepseek.com/',
        model: 'deepseek-reasoner',
      );

      final client = _FakeOpenAIClient(
        config,
        stream: sseStreamFromChunkFile(fixturePath),
      );

      final provider =
          OpenAICompatibleChatProvider(client, config, capabilities);

      final parts =
          await provider.chatStreamParts([ChatMessage.user('Hi')]).toList();

      expect(parts.whereType<LLMToolCallStartPart>(), hasLength(1));
      expect(parts.whereType<LLMToolCallEndPart>(), hasLength(1));

      final start = parts.whereType<LLMToolCallStartPart>().single.toolCall;
      expect(start.id, equals(expected.id));
      expect(start.function.name, equals(expected.name));

      final finish = parts.whereType<LLMFinishPart>().single;
      final calls = finish.response.toolCalls;
      expect(calls, isNotNull);
      expect(calls, hasLength(1));
      expect(calls!.single.id, equals(expected.id));
      expect(calls.single.function.name, equals(expected.name));
      expect(calls.single.function.arguments, equals(expected.arguments));
    });
  });
}
