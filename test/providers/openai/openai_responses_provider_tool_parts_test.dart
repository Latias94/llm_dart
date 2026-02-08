import 'dart:convert';
import 'dart:io';

import 'package:llm_dart/llm_dart.dart';
import 'package:llm_dart_openai/llm_dart_openai.dart' as openai_client;
import 'package:llm_dart_openai/responses.dart' as openai_responses;
import 'package:test/test.dart';

import '../../utils/fixture_replay.dart';
import '../../utils/fakes/fakes.dart';

Set<String> _expectedProviderToolCallIdsFromChunks(String fixturePath) {
  final ids = <String>{};

  for (final line in File(fixturePath).readAsLinesSync()) {
    final trimmed = line.trim();
    if (trimmed.isEmpty) continue;
    final json = jsonDecode(trimmed) as Map<String, dynamic>;

    final type = json['type'];
    if (type != 'response.output_item.added' && type != 'response.output_item.done') {
      continue;
    }

    final item = json['item'];
    if (item is! Map) continue;

    final itemType = item['type'];
    if (itemType is! String) continue;
    if (!itemType.endsWith('_call')) continue;
    if (itemType == 'function_call') continue;

    final id = item['id'];
    if (id is String && id.isNotEmpty) ids.add(id);
  }

  return ids;
}

void main() {
  group('OpenAI Responses provider tool parts (AI SDK parity)', () {
    test('emits provider tool call/result parts for web_search_call', () async {
      const fixturePath =
          'test/fixtures/openai/responses/openai-web-search-tool.1.chunks.txt';

      final expectedIds = _expectedProviderToolCallIdsFromChunks(fixturePath);
      expect(expectedIds, isNotEmpty);

      final config = openai_client.OpenAIConfig(
        apiKey: 'test-key',
        baseUrl: 'https://api.openai.com/v1/',
        model: 'gpt-5-mini',
        useResponsesAPI: true,
      );

      final client = FakeOpenAIClient(config)
        ..streamResponse = sseStreamFromChunkFile(fixturePath);
      final responses = openai_responses.OpenAIResponses(client, config);

      final parts =
          await responses.chatStreamParts([ChatMessage.user('Hi')]).toList();

      final calls = parts.whereType<LLMProviderToolCallPart>().toList();
      final results = parts.whereType<LLMProviderToolResultPart>().toList();

      expect(calls.map((p) => p.toolCallId).toSet(), equals(expectedIds));
      expect(results.map((p) => p.toolCallId).toSet(), equals(expectedIds));

      expect(
        calls.every((p) => p.toolName == 'web_search'),
        isTrue,
      );
      expect(
        results.every((p) => p.toolName == 'web_search'),
        isTrue,
      );
    });

    test('emits provider tool delta parts for web_search_call status events',
        () async {
      const fixturePath =
          'test/fixtures/openai/responses/openai-web-search-tool.1.chunks.txt';

      final expectedIds = _expectedProviderToolCallIdsFromChunks(fixturePath);
      expect(expectedIds, isNotEmpty);

      final config = openai_client.OpenAIConfig(
        apiKey: 'test-key',
        baseUrl: 'https://api.openai.com/v1/',
        model: 'gpt-5-mini',
        useResponsesAPI: true,
      );

      final client = FakeOpenAIClient(config)
        ..streamResponse = sseStreamFromChunkFile(fixturePath);
      final responses = openai_responses.OpenAIResponses(client, config);

      final parts =
          await responses.chatStreamParts([ChatMessage.user('Hi')]).toList();

      final deltas = parts.whereType<LLMProviderToolDeltaPart>().toList();
      expect(deltas, isNotEmpty);

      final deltaIds = deltas.map((p) => p.toolCallId).toSet();
      expect(deltaIds, containsAll(expectedIds));

      final statuses = deltas.map((p) => p.status).toSet();
      expect(statuses, containsAll(['in_progress', 'searching', 'completed']));

      expect(
        deltas.every((p) => p.toolName == 'web_search'),
        isTrue,
      );
    });

    test('emits provider tool call/result parts for file_search_call', () async {
      const fixturePath =
          'test/fixtures/openai/responses/openai-file-search-tool.1.chunks.txt';

      final expectedIds = _expectedProviderToolCallIdsFromChunks(fixturePath);
      expect(expectedIds, isNotEmpty);

      final config = openai_client.OpenAIConfig(
        apiKey: 'test-key',
        baseUrl: 'https://api.openai.com/v1/',
        model: 'gpt-5-mini',
        useResponsesAPI: true,
      );

      final client = FakeOpenAIClient(config)
        ..streamResponse = sseStreamFromChunkFile(fixturePath);
      final responses = openai_responses.OpenAIResponses(client, config);

      final parts =
          await responses.chatStreamParts([ChatMessage.user('Hi')]).toList();

      final calls = parts.whereType<LLMProviderToolCallPart>().toList();
      final results = parts.whereType<LLMProviderToolResultPart>().toList();

      expect(calls.map((p) => p.toolCallId).toSet(), equals(expectedIds));
      expect(results.map((p) => p.toolCallId).toSet(), equals(expectedIds));

      expect(
        calls.every((p) => p.toolName == 'file_search'),
        isTrue,
      );
      expect(
        results.every((p) => p.toolName == 'file_search'),
        isTrue,
      );
    });
  });
}
