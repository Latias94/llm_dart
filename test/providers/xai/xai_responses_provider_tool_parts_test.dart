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
    if (!itemType.endsWith('_call')) continue;
    if (itemType == 'function_call') continue;

    final id = item['id'];
    if (id is String && id.isNotEmpty) ids.add(id);
  }

  return ids;
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
  });
}

