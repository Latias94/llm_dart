import 'dart:convert';
import 'dart:io';

import 'package:llm_dart/llm_dart.dart';
import 'package:llm_dart_anthropic_compatible/client.dart';
import 'package:test/test.dart';

import '../../utils/fixture_replay.dart';

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
          final expected =
              expectedAnthropicTextThinkingFromChunkFile(file.path);
          final streams = sseStreamsFromChunkFileSplitByTerminalEvent(
            file.path,
            isTerminalEvent: isAnthropicMessagesTerminalEvent,
          );

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
