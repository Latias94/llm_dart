import 'dart:convert';
import 'dart:io';

import 'package:llm_dart/llm_dart.dart';
import 'package:llm_dart_anthropic_compatible/client.dart';
import 'package:test/test.dart';

import '../../utils/fixture_replay.dart';
import '../../utils/fakes/fakes.dart';

bool _sessionHasContentBlockType(List<String> sessionLines, String blockType) {
  for (final line in sessionLines) {
    final decoded = jsonDecode(line);
    if (decoded is! Map<String, dynamic>) continue;

    if (decoded['type'] != 'content_block_start') continue;
    final block = decoded['content_block'];
    if (block is! Map) continue;
    if (block['type'] == blockType) return true;
  }
  return false;
}

String? _sessionStopReason(List<String> sessionLines) {
  for (final line in sessionLines) {
    final decoded = jsonDecode(line);
    if (decoded is! Map<String, dynamic>) continue;

    if (decoded['type'] != 'message_delta') continue;
    final delta = decoded['delta'];
    if (delta is! Map) continue;
    final stopReason = delta['stop_reason'];
    if (stopReason is String && stopReason.isNotEmpty) return stopReason;
  }
  return null;
}

Map<String, int>? _sessionServerToolUseCounts(List<String> sessionLines) {
  for (final line in sessionLines) {
    final decoded = jsonDecode(line);
    if (decoded is! Map<String, dynamic>) continue;

    if (decoded['type'] != 'message_delta') continue;
    final usage = decoded['usage'];
    if (usage is! Map) continue;

    final serverToolUse = usage['server_tool_use'];
    if (serverToolUse is! Map) continue;

    final webSearch = serverToolUse['web_search_requests'];
    final webFetch = serverToolUse['web_fetch_requests'];

    final counts = <String, int>{};
    if (webSearch is int) counts['webSearchRequests'] = webSearch;
    if (webFetch is int) counts['webFetchRequests'] = webFetch;

    return counts.isEmpty ? null : counts;
  }
  return null;
}

({String name, Map<String, dynamic> input})? _firstToolUseFromSession(
  List<String> sessionLines,
) {
  int? toolIndex;
  String? name;
  Map<String, dynamic>? startInput;
  final inputJson = StringBuffer();

  for (final line in sessionLines) {
    final decoded = jsonDecode(line);
    if (decoded is! Map<String, dynamic>) continue;

    final type = decoded['type'];

    if (type == 'content_block_start') {
      final block = decoded['content_block'];
      if (block is! Map) continue;
      if (block['type'] != 'tool_use') continue;

      final idx = decoded['index'];
      final n = block['name'];
      if (idx is! int || n is! String || n.isEmpty) continue;

      toolIndex = idx;
      name = n;

      final input = block['input'];
      if (input is Map<String, dynamic>) {
        startInput = input;
      } else if (input is Map) {
        startInput = Map<String, dynamic>.from(input);
      }
      continue;
    }

    if (toolIndex != null && type == 'content_block_delta') {
      final idx = decoded['index'];
      if (idx != toolIndex) continue;

      final delta = decoded['delta'];
      if (delta is! Map) continue;
      if (delta['type'] != 'input_json_delta') continue;
      final partial = delta['partial_json'];
      if (partial is String) inputJson.write(partial);
      continue;
    }

    if (toolIndex != null && type == 'content_block_stop') {
      final idx = decoded['index'];
      if (idx != toolIndex) continue;
      break;
    }
  }

  if (name == null) return null;

  final rawJson = inputJson.toString().trim();
  if (rawJson.isEmpty) return (name: name!, input: startInput ?? const {});

  final decoded = jsonDecode(rawJson);
  if (decoded is Map<String, dynamic>) return (name: name!, input: decoded);
  if (decoded is Map) {
    return (name: name!, input: Map<String, dynamic>.from(decoded));
  }

  return (name: name!, input: startInput ?? const {});
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

          final client = FakeAnthropicClient(config)..response = raw;
          final chat = AnthropicChat(client, config);

          final response = await chat.chat([ChatMessage.user('Hi')]);
          final meta =
              response.providerMetadata?['anthropic'] as Map<String, dynamic>?;
          expect(meta, isNotNull);
          expect(meta!['id'], equals(raw['id']));
          expect(meta['model'], equals(raw['model']));
          expect(meta['finishReason'], equals(raw['stop_reason']));

          final rawUsage = raw['usage'];
          if (rawUsage is Map) {
            final usage = meta['usage'] as Map?;
            expect(usage, isNotNull);
            expect(usage!['inputTokens'], equals(rawUsage['input_tokens']));
            expect(usage['outputTokens'], equals(rawUsage['output_tokens']));

            final serverToolUse = rawUsage['server_tool_use'];
            if (serverToolUse is Map) {
              final metaServerToolUse = (usage['serverToolUse'] as Map?) ?? {};
              if (serverToolUse['web_search_requests'] != null) {
                expect(
                  metaServerToolUse['webSearchRequests'],
                  equals(serverToolUse['web_search_requests']),
                );
              }
              if (serverToolUse['web_fetch_requests'] != null) {
                expect(
                  metaServerToolUse['webFetchRequests'],
                  equals(serverToolUse['web_fetch_requests']),
                );
              }
            }
          }

          if (raw['container'] != null) {
            expect(meta['container'], isNotNull);
          }

          final content = raw['content'];
          if (content is List) {
            final hasToolUse =
                content.any((b) => b is Map && b['type'] == 'tool_use');
            if (hasToolUse) {
              final calls = response.toolCalls;
              expect(calls, isNotNull);
              expect(calls, isNotEmpty);
            }

            final hasServerToolUse =
                content.any((b) => b is Map && b['type'] == 'server_tool_use');
            if (hasServerToolUse) {
              final calls = response.toolCalls;
              if (calls != null) {
                expect(
                  calls.any((c) =>
                      c.function.name == 'web_search' ||
                      c.function.name == 'web_fetch'),
                  isFalse,
                );
              }
            }
          }
        });
      }
    });

    group('streaming', () {
      for (final file in chunkFixtures) {
        final name = file.uri.pathSegments.last;
        test('replays $name', () async {
          final expected =
              expectedAnthropicTextThinkingFromChunkFile(file.path);
          final sessionLines = splitJsonLinesIntoSessions(
            readFixtureLines(file.path),
            isTerminalEvent: isAnthropicMessagesTerminalEvent,
          );
          final streams =
              sessionLines.map(sseStreamFromJsonLines).toList(growable: false);

          final config = AnthropicConfig(
            providerId: 'anthropic',
            apiKey: 'test-key',
            model: 'claude-sonnet-4-20250514',
            baseUrl: 'https://api.anthropic.com/v1/',
            stream: true,
          );

          var combinedText = '';
          var combinedThinking = '';

          for (var sessionIndex = 0;
              sessionIndex < streams.length;
              sessionIndex++) {
            final stream = streams[sessionIndex];
            final client = FakeAnthropicClient(config)..streamResponse = stream;
            final chat = AnthropicChat(client, config);

            final parts =
                await chat.chatStreamParts([ChatMessage.user('Hi')]).toList();
            final finishParts = parts.whereType<LLMFinishPart>().toList();
            expect(finishParts, isNotEmpty);
            final finish = finishParts.single;

            final lines = sessionLines[sessionIndex];

            final meta = finish.response.providerMetadata?['anthropic'] as Map?;
            expect(meta, isNotNull);
            expect(meta!['id'], isNotNull);
            expect(meta['model'], isNotNull);

            final stopReason = _sessionStopReason(lines);
            if (stopReason != null) {
              expect(meta['stopReason'], equals(stopReason));
              expect(meta['finishReason'], equals(stopReason));
            }

            final serverToolUseCounts = _sessionServerToolUseCounts(lines);
            if (serverToolUseCounts != null && serverToolUseCounts.isNotEmpty) {
              final usage = meta['usage'] as Map?;
              expect(usage, isNotNull);
              final serverToolUse = usage!['serverToolUse'] as Map?;
              expect(serverToolUse, isNotNull);
              for (final entry in serverToolUseCounts.entries) {
                expect(serverToolUse![entry.key], equals(entry.value));
              }
            }

            final toolUse = _firstToolUseFromSession(lines);
            if (toolUse != null &&
                toolUse.name != 'web_search' &&
                toolUse.name != 'web_fetch') {
              final toolCalls = finish.response.toolCalls;
              expect(toolCalls, isNotNull);
              expect(toolCalls, isNotEmpty);
              expect(
                toolCalls!.any((c) => c.function.name == toolUse.name),
                isTrue,
              );
              final call =
                  toolCalls.firstWhere((c) => c.function.name == toolUse.name);
              expect(
                  jsonDecode(call.function.arguments), equals(toolUse.input));
            }

            final hasServerToolUse =
                _sessionHasContentBlockType(lines, 'server_tool_use');
            final hasMcpToolUse =
                _sessionHasContentBlockType(lines, 'mcp_tool_use');
            if (hasServerToolUse || hasMcpToolUse) {
              final toolCalls = finish.response.toolCalls;
              if (toolCalls != null) {
                expect(
                  toolCalls.any((c) =>
                      c.function.name == 'web_search' ||
                      c.function.name == 'web_fetch'),
                  isFalse,
                );
              }
            }

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
          expect(
            combinedThinking.isEmpty ? '' : combinedThinking,
            equals(expected.thinking),
          );
        });
      }
    });
  });
}
