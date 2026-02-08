import 'dart:convert';
import 'dart:io';

import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_openai_compatible/llm_dart_openai_compatible.dart';
import 'package:llm_dart_xai/responses.dart';
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
    if (itemType == 'function_call') continue;

    final isProviderToolCall =
        itemType.endsWith('_call') || itemType == 'custom_tool_call';
    if (!isProviderToolCall) continue;

    final id = item['id'];
    if (id is String && id.isNotEmpty) ids.add(id);
  }

  return ids;
}

Map<String, String> _expectedCustomToolCallIdToNameFromChunks(String fixturePath) {
  const xSearchSubTools = {
    'x_user_search',
    'x_keyword_search',
    'x_semantic_search',
    'x_thread_fetch',
  };

  final out = <String, String>{};

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
    if (item['type'] != 'custom_tool_call') continue;

    final id = item['id'];
    final rawName = item['name'];
    if (id is! String || id.isEmpty) continue;
    if (rawName is! String || rawName.isEmpty) continue;

    final expectedName = xSearchSubTools.contains(rawName) ? 'x_search' : rawName;
    out[id] = expectedName;
  }

  return out;
}

void main() {
  group('xAI Responses provider tool parts (AI SDK parity)', () {
    test('emits provider tool call/result parts for web_search_call', () async {
      const fixturePath =
          'test/fixtures/xai/responses/xai-web-search-tool.1.chunks.txt';

      final expectedIds = _expectedProviderToolCallIdsFromChunks(fixturePath);
      expect(expectedIds, isNotEmpty);

      final config = OpenAICompatibleConfig(
        providerId: 'xai.responses',
        providerName: 'xAI (Responses)',
        apiKey: 'test-key',
        baseUrl: 'https://api.x.ai/v1/',
        model: 'grok-4-fast',
      );

      final client = FakeOpenAIClient(config)
        ..streamResponse = sseStreamFromChunkFile(fixturePath);
      final responses = XAIResponses(client, config);

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
          'test/fixtures/xai/responses/xai-x-search-tool.chunks.txt';

      final config = OpenAICompatibleConfig(
        providerId: 'xai.responses',
        providerName: 'xAI (Responses)',
        apiKey: 'test-key',
        baseUrl: 'https://api.x.ai/v1/',
        model: 'grok-4-fast',
      );

      final client = FakeOpenAIClient(config)
        ..streamResponse = sseStreamFromChunkFile(fixturePath);
      final responses = XAIResponses(client, config);

      final parts =
          await responses.chatStreamParts([ChatMessage.user('Hi')]).toList();

      final deltas = parts.whereType<LLMProviderToolDeltaPart>().toList();
      expect(deltas, isNotEmpty);

      final webSearchDeltas =
          deltas.where((p) => p.toolName == 'web_search').toList();
      expect(webSearchDeltas, isNotEmpty);

      final statuses = webSearchDeltas.map((p) => p.status).toSet();
      expect(statuses, containsAll(['in_progress', 'searching', 'completed']));

      expect(
        deltas.where((p) => p.status.startsWith('input_')).map((p) => p.toolName).toSet(),
        containsAll(['x_search', 'view_x_video']),
      );
    });

    test('emits provider tool call/result parts for custom_tool_call', () async {
      const fixturePath =
          'test/fixtures/xai/responses/xai-x-search-tool.chunks.txt';

      final expected = _expectedCustomToolCallIdToNameFromChunks(fixturePath);
      expect(expected, isNotEmpty);

      final config = OpenAICompatibleConfig(
        providerId: 'xai.responses',
        providerName: 'xAI (Responses)',
        apiKey: 'test-key',
        baseUrl: 'https://api.x.ai/v1/',
        model: 'grok-4-fast',
      );

      final client = FakeOpenAIClient(config)
        ..streamResponse = sseStreamFromChunkFile(fixturePath);
      final responses = XAIResponses(client, config);

      final parts =
          await responses.chatStreamParts([ChatMessage.user('Hi')]).toList();

      final calls = parts
          .whereType<LLMProviderToolCallPart>()
          .where((p) => expected.containsKey(p.toolCallId))
          .toList();
      final results = parts
          .whereType<LLMProviderToolResultPart>()
          .where((p) => expected.containsKey(p.toolCallId))
          .toList();

      expect(calls.map((p) => p.toolCallId).toSet(), equals(expected.keys.toSet()));
      expect(results.map((p) => p.toolCallId).toSet(), equals(expected.keys.toSet()));

      for (final c in calls) {
        expect(c.toolName, equals(expected[c.toolCallId]));
      }
      for (final r in results) {
        expect(r.toolName, equals(expected[r.toolCallId]));
      }
    });
  });
}
