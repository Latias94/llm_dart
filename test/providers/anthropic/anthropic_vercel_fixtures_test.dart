import 'dart:convert';
import 'dart:io';

import 'package:llm_dart/llm_dart.dart';
import 'package:llm_dart_anthropic_compatible/client.dart';
import 'package:test/test.dart';

class _FakeJsonAnthropicClient extends AnthropicClient {
  final Map<String, dynamic> _response;

  _FakeJsonAnthropicClient(
    super.config, {
    required Map<String, dynamic> response,
  }) : _response = response;

  @override
  Future<Map<String, dynamic>> postJson(
    String endpoint,
    Map<String, dynamic> data, {
    CancelToken? cancelToken,
  }) async {
    return _response;
  }
}

class _FakeStreamAnthropicClient extends AnthropicClient {
  final Stream<String> _stream;

  _FakeStreamAnthropicClient(
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

Stream<String> _sseStreamFromLines(Iterable<String> lines) async* {
  for (final line in lines) {
    yield 'data: $line\n\n';
  }
}

List<Stream<String>> _sseStreamsFromChunkFile(String path) {
  final lines = File(path)
      .readAsLinesSync()
      .map((l) => l.trim())
      .where((l) => l.isNotEmpty)
      .toList(growable: false);

  final sessions = <List<String>>[];
  var current = <String>[];

  for (final line in lines) {
    current.add(line);

    final json = jsonDecode(line);
    if (json is Map<String, dynamic> && json['type'] == 'message_stop') {
      sessions.add(current);
      current = <String>[];
    }
  }

  if (current.isNotEmpty) {
    sessions.add(current);
  }

  return sessions.map(_sseStreamFromLines).toList(growable: false);
}

({String text, String thinking}) _expectedFromChunkFile(String path) {
  final textBlocks = <String>[];
  final thinkingBlocks = <String>[];

  final blockTypes = <int, String>{};
  final textBuffers = <int, StringBuffer>{};
  final thinkingBuffers = <int, StringBuffer>{};

  final lines = File(path)
      .readAsLinesSync()
      .map((l) => l.trim())
      .where((l) => l.isNotEmpty)
      .toList(growable: false);

  for (final line in lines) {
    final json = jsonDecode(line) as Map<String, dynamic>;
    final type = json['type'] as String?;

    if (type == 'content_block_start') {
      final index = json['index'] as int?;
      final block = json['content_block'];
      if (index == null || block is! Map) continue;

      final blockType = block['type'];
      if (blockType is! String) continue;
      blockTypes[index] = blockType;

      if (blockType == 'text') {
        textBuffers[index] = StringBuffer();
      } else if (blockType == 'thinking') {
        thinkingBuffers[index] = StringBuffer();
      } else if (blockType == 'redacted_thinking') {
        // Mirrors `AnthropicChatResponse.thinking`.
        thinkingBlocks
            .add('[Redacted thinking content - encrypted for safety]');
      }

      continue;
    }

    if (type == 'content_block_delta') {
      final index = json['index'] as int?;
      final delta = json['delta'];
      if (index == null || delta is! Map) continue;

      final deltaType = delta['type'];
      if (deltaType == 'text_delta') {
        final t = delta['text'];
        if (t is String) {
          (textBuffers[index] ??= StringBuffer()).write(t);
        }
      }
      if (deltaType == 'thinking_delta') {
        final t = delta['thinking'];
        if (t is String) {
          (thinkingBuffers[index] ??= StringBuffer()).write(t);
        }
      }
      continue;
    }

    if (type == 'content_block_stop') {
      final index = json['index'] as int?;
      if (index == null) continue;

      final blockType = blockTypes[index];
      if (blockType == 'text') {
        final text = textBuffers[index]?.toString() ?? '';
        if (text.isNotEmpty) textBlocks.add(text);
      } else if (blockType == 'thinking') {
        final thinking = thinkingBuffers[index]?.toString() ?? '';
        if (thinking.isNotEmpty) thinkingBlocks.add(thinking);
      }

      blockTypes.remove(index);
      textBuffers.remove(index);
      thinkingBuffers.remove(index);
    }
  }

  return (
    text: textBlocks.join('\n'),
    thinking: thinkingBlocks.join('\n\n'),
  );
}

void main() {
  group('Anthropic fixtures (Vercel)', () {
    final dir = Directory('test/fixtures/anthropic/messages');
    final jsonFixtures = dir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.json'))
        .toList(growable: false)
      ..sort((a, b) => a.path.compareTo(b.path));

    final chunkFixtures = dir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.chunks.txt'))
        .toList(growable: false)
      ..sort((a, b) => a.path.compareTo(b.path));

    group('non-stream', () {
      for (final file in jsonFixtures) {
        final name = file.uri.pathSegments.last;
        test('parses $name', () async {
          final raw =
              jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;

          // Some fixtures are explicit error payloads.
          if (raw['error'] != null) {
            expect(raw['error'], isA<Map>());
            return;
          }

          final config = AnthropicConfig(
            providerId: 'anthropic',
            apiKey: 'test-key',
            model: raw['model'] as String? ?? 'claude-sonnet-4-20250514',
            baseUrl: 'https://api.anthropic.com/v1/',
          );

          final client = _FakeJsonAnthropicClient(config, response: raw);
          final chat = AnthropicChat(client, config);

          final response = await chat.chat([ChatMessage.user('Hi')]);
          expect(response.providerMetadata?['anthropic'], isNotNull);
        });
      }
    });

    group('streaming', () {
      for (final file in chunkFixtures) {
        final name = file.uri.pathSegments.last;
        test('replays $name', () async {
          final expected = _expectedFromChunkFile(file.path);
          final streams = _sseStreamsFromChunkFile(file.path);

          final config = AnthropicConfig(
            providerId: 'anthropic',
            apiKey: 'test-key',
            model: 'claude-sonnet-4-20250514',
            baseUrl: 'https://api.anthropic.com/v1/',
            stream: true,
          );

          var combinedText = '';
          var combinedThinking = '';

          for (final stream in streams) {
            final client = _FakeStreamAnthropicClient(config, stream: stream);
            final chat = AnthropicChat(client, config);

            final parts =
                await chat.chatStreamParts([ChatMessage.user('Hi')]).toList();
            final finish = parts.whereType<LLMFinishPart>().single;

            final text = finish.response.text ?? '';
            if (text.isNotEmpty) {
              if (combinedText.isNotEmpty) combinedText += '\n';
              combinedText += text;
            }

            final thinking = finish.response.thinking;
            if (thinking != null && thinking.isNotEmpty) {
              if (combinedThinking.isNotEmpty) combinedThinking += '\n\n';
              combinedThinking += thinking;
            }
          }

          expect(combinedText, equals(expected.text));

          if (expected.thinking.isNotEmpty) {
            expect(combinedThinking, isNotEmpty);
          }
        });
      }
    });
  });
}
