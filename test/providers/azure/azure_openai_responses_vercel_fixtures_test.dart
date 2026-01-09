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
            baseUrl: 'https://example.azure.com/openai/',
            model: 'gpt-4.1-mini',
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
        });
      }
    });
  });
}
