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

void main() {
  group('OpenAI Responses fixtures (Vercel)', () {
    final dir = Directory('test/fixtures/openai/responses');
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
        test('loads $name', () {
          final raw =
              jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;

          final error = raw['error'];
          if (error != null) {
            expect(error, isA<Map>());
            return;
          }

          final config = openai_client.OpenAIConfig(
            apiKey: 'test-key',
            baseUrl: 'https://api.openai.com/v1/',
            model: raw['model'] as String? ?? 'gpt-5-mini',
            useResponsesAPI: true,
          );

          final client = _FakeJsonOpenAIClient(config, response: raw);
          final responses = openai_responses.OpenAIResponses(client, config);

          expect(
            () => responses.chatWithTools([ChatMessage.user('Hi')], null),
            returnsNormally,
          );
        });

        test('parses $name', () async {
          final raw =
              jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;

          if (raw['error'] != null) return;
          if (raw['output'] is! List) return;

          final config = openai_client.OpenAIConfig(
            apiKey: 'test-key',
            baseUrl: 'https://api.openai.com/v1/',
            model: raw['model'] as String? ?? 'gpt-5-mini',
            useResponsesAPI: true,
          );

          final client = _FakeJsonOpenAIClient(config, response: raw);
          final responses = openai_responses.OpenAIResponses(client, config);

          final response =
              await responses.chatWithTools([ChatMessage.user('Hi')], null);

          final meta = response.providerMetadata?['openai'];
          expect(meta, isNotNull);
          expect(meta!['id'], equals(raw['id']));
          expect(meta['model'], equals(raw['model']));

          final output = raw['output'] as List;
          final hasWebSearch =
              output.any((i) => i is Map && i['type'] == 'web_search_call');
          final hasFileSearch =
              output.any((i) => i is Map && i['type'] == 'file_search_call');
          final hasComputer =
              output.any((i) => i is Map && i['type'] == 'computer_call');

          if (hasWebSearch) {
            expect(meta['webSearchCalls'], isNotNull);
          }
          if (hasFileSearch) {
            expect(meta['fileSearchCalls'], isNotNull);
          }
          if (hasComputer) {
            expect(meta['computerCalls'], isNotNull);
          }

          final hasServerToolCalls = output.any((i) {
            if (i is! Map) return false;
            final type = i['type'];
            if (type is! String) return false;
            if (type == 'message' ||
                type == 'reasoning' ||
                type == 'function_call') {
              return false;
            }
            return true;
          });
          if (hasServerToolCalls) {
            expect(meta['serverToolCalls'], isNotNull);
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
          final streams = sseStreamsFromChunkFileSplitByTerminalEvent(
            file.path,
            isTerminalEvent: isOpenAIResponsesTerminalEvent,
          );

          final config = openai_client.OpenAIConfig(
            apiKey: 'test-key',
            baseUrl: 'https://api.openai.com/v1/',
            model: 'gpt-5-mini',
            useResponsesAPI: true,
          );

          final combinedText = StringBuffer();
          final combinedThinking = StringBuffer();
          final finishes = <LLMFinishPart>[];
          final errors = <LLMErrorPart>[];

          for (final stream in streams) {
            final client = _FakeStreamOpenAIClient(config, stream: stream);
            final responses = openai_responses.OpenAIResponses(client, config);

            try {
              final parts = await responses
                  .chatStreamParts([ChatMessage.user('Hi')]).toList();
              finishes.addAll(parts.whereType<LLMFinishPart>());
              errors.addAll(parts.whereType<LLMErrorPart>());
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
