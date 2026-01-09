import 'dart:convert';
import 'dart:io';

import 'package:llm_dart/llm_dart.dart';
import 'package:llm_dart_openai/client.dart';
import 'package:llm_dart_openai/llm_dart_openai.dart' as openai_client;
import 'package:llm_dart_openai/responses.dart' as openai_responses;
import 'package:test/test.dart';

import '../../utils/fixture_replay.dart';

class _FakeJsonOpenAIClient extends OpenAIClient {
  final Map<String, dynamic> _response;

  _FakeJsonOpenAIClient(
    super.config, {
    required Map<String, dynamic> response,
  }) : _response = response;

  @override
  Future<Map<String, dynamic>> postJson(
    String endpoint,
    Map<String, dynamic> body, {
    CancelToken? cancelToken,
  }) async {
    return _response;
  }
}

class _FakeStreamOpenAIClient extends OpenAIClient {
  final Stream<String> _stream;

  _FakeStreamOpenAIClient(
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

bool _sessionHasOutputItemType(List<String> sessionLines, String itemType) {
  for (final line in sessionLines) {
    final decoded = jsonDecode(line);
    if (decoded is! Map<String, dynamic>) continue;

    final type = decoded['type'];

    if (type == 'response.output_item.added' ||
        type == 'response.output_item.done') {
      final item = decoded['item'];
      if (item is Map && item['type'] == itemType) return true;
    }

    if (type == 'response.completed') {
      final response = decoded['response'];
      if (response is! Map) continue;

      final output = response['output'];
      if (output is! List) continue;

      if (output.any((o) => o is Map && o['type'] == itemType)) return true;
    }
  }
  return false;
}

void _expectMetaContainsOutputItemType(
  Map<String, dynamic> meta,
  String key,
  String itemType,
) {
  final calls = meta[key] as List?;
  expect(calls, isNotNull);
  expect(calls, isNotEmpty);
  expect((calls!.first as Map)['type'], equals(itemType));
}

void _expectMetaContainsCalls(Map<String, dynamic> meta, String key) {
  final calls = meta[key] as List?;
  expect(calls, isNotNull);
  expect(calls, isNotEmpty);
}

void main() {
  group('Azure OpenAI Responses fixtures (Vercel)', () {
    final dir = Directory('test/fixtures/azure/responses');
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
          final raw = jsonDecode(file.readAsStringSync());
          if (raw is! Map<String, dynamic>) return;

          final error = raw['error'];
          if (error != null) {
            expect(error, isA<Map>());
            return;
          }

          final config = openai_client.OpenAIConfig(
            apiKey: 'test-key',
            baseUrl: 'https://example.azure.com/openai/',
            model: raw['model'] as String? ?? 'gpt-4.1-mini',
            useResponsesAPI: true,
          );

          final client = _FakeJsonOpenAIClient(config, response: raw);
          final responses = openai_responses.OpenAIResponses(client, config);

          final response =
              await responses.chatWithTools([ChatMessage.user('Hi')], null);
          expect(response.providerMetadata, isNotNull);

          if (raw['output'] is! List) return;
          final output = raw['output'] as List;

          final meta =
              response.providerMetadata?['openai'] as Map<String, dynamic>?;
          expect(meta, isNotNull);

          if (output.any((i) => i is Map && i['type'] == 'web_search_call')) {
            expect(meta!['webSearchCalls'], isNotNull);
          }
          if (output.any((i) => i is Map && i['type'] == 'file_search_call')) {
            expect(meta!['fileSearchCalls'], isNotNull);
          }
          if (output.any((i) => i is Map && i['type'] == 'computer_call')) {
            expect(meta!['computerCalls'], isNotNull);
          }
          if (output
              .any((i) => i is Map && i['type'] == 'code_interpreter_call')) {
            _expectMetaContainsOutputItemType(
              meta!,
              'codeInterpreterCalls',
              'code_interpreter_call',
            );
          }
          if (output
              .any((i) => i is Map && i['type'] == 'image_generation_call')) {
            _expectMetaContainsOutputItemType(
              meta!,
              'imageGenerationCalls',
              'image_generation_call',
            );
          }
        });
      }
    });

    group('streaming', () {
      for (final file in chunkFixtures) {
        final name = file.uri.pathSegments.last;
        test('replays $name', () async {
          final expected =
              expectedOpenAIResponsesTextThinkingFromChunkFile(file.path);
          final sessionLines = splitJsonLinesIntoSessions(
            readFixtureLines(file.path),
            isTerminalEvent: isOpenAIResponsesTerminalEvent,
          );
          final streams =
              sessionLines.map(sseStreamFromJsonLines).toList(growable: false);

          final config = openai_client.OpenAIConfig(
            apiKey: 'test-key',
            baseUrl: 'https://example.azure.com/openai/',
            model: 'gpt-4.1-mini',
            useResponsesAPI: true,
          );

          final combinedText = StringBuffer();
          final combinedThinking = StringBuffer();
          final finishes = <LLMFinishPart>[];
          final errors = <LLMErrorPart>[];

          for (var sessionIndex = 0;
              sessionIndex < streams.length;
              sessionIndex++) {
            final stream = streams[sessionIndex];
            final client = _FakeStreamOpenAIClient(config, stream: stream);
            final responses = openai_responses.OpenAIResponses(client, config);

            try {
              final parts = await responses
                  .chatStreamParts([ChatMessage.user('Hi')]).toList();
              finishes.addAll(parts.whereType<LLMFinishPart>());
              errors.addAll(parts.whereType<LLMErrorPart>());

              final finishParts = parts.whereType<LLMFinishPart>().toList();
              if (finishParts.isEmpty) continue;
              final finish = finishParts.last;

              final meta =
                  finish.response.providerMetadata?['openai'] as Map? ??
                      const {};
              final openaiMeta = meta is Map<String, dynamic>
                  ? meta
                  : Map<String, dynamic>.from(meta as Map);

              final lines = sessionLines[sessionIndex];

              if (_sessionHasOutputItemType(lines, 'code_interpreter_call')) {
                _expectMetaContainsOutputItemType(
                  openaiMeta,
                  'codeInterpreterCalls',
                  'code_interpreter_call',
                );
              }
              if (_sessionHasOutputItemType(lines, 'image_generation_call')) {
                _expectMetaContainsOutputItemType(
                  openaiMeta,
                  'imageGenerationCalls',
                  'image_generation_call',
                );
              }
              if (_sessionHasOutputItemType(lines, 'file_search_call')) {
                _expectMetaContainsCalls(
                  openaiMeta,
                  'fileSearchCalls',
                );
              }
              if (_sessionHasOutputItemType(lines, 'web_search_call')) {
                _expectMetaContainsCalls(
                  openaiMeta,
                  'webSearchCalls',
                );
              }
            } catch (e) {
              errors.add(LLMErrorPart(GenericError('Stream error: $e')));
            }
          }

          if (errors.isNotEmpty) {
            expect(expected.text, isEmpty);
            expect(expected.thinking, isEmpty);
            return;
          }

          for (final finish in finishes) {
            final text = finish.response.text;
            if (text != null) combinedText.write(text);

            final thinking = finish.response.thinking;
            if (thinking != null) combinedThinking.write(thinking);
          }

          expect(combinedText.toString(), equals(expected.text));
          expect(
            combinedThinking.toString().isEmpty
                ? null
                : combinedThinking.toString(),
            equals(expected.thinking.isEmpty ? null : expected.thinking),
          );

          final lastMeta = finishes.isEmpty
              ? null
              : finishes.last.response.providerMetadata?['openai'];
          if (lastMeta is Map) {
            expect(lastMeta['id'], isNotNull);
            expect(lastMeta['model'], isNotNull);
          }
        });
      }
    });
  });
}
