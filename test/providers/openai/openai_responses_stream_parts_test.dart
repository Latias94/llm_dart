import 'dart:async';

import 'package:llm_dart/llm_dart.dart';
import 'package:llm_dart_openai/llm_dart_openai.dart' as openai_client;
import 'package:llm_dart_openai/responses.dart' as openai_responses;
import 'package:test/test.dart';

void main() {
  group('OpenAI Responses chatStreamParts', () {
    test('should emit provider metadata parts for annotations and web search',
        () async {
      final config = openai_client.OpenAIConfig(
        apiKey: 'test-key',
        baseUrl: 'https://api.openai.com/v1/',
        model: 'gpt-4o-search-preview',
        useResponsesAPI: true,
      );

      final client = _FakeOpenAIClient(config, const [
        'data: {"type":"response.created","response":{"id":"resp_1","model":"gpt-4o-search-preview","output":[]}}\n',
        'data: {"type":"response.output_item.done","output_index":0,"item":{"type":"web_search_call","id":"ws_1","status":"completed","action":{"type":"search","query":"test","sources":[{"type":"url","url":"https://example.com"}]}}}\n',
        'data: {"type":"response.output_text.annotation.added","annotation":{"type":"url_citation","url":"https://example.com","start_index":0,"end_index":4}}\n',
        'data: {"type":"response.output_text.delta","delta":"Hello"}\n',
        'data: [DONE]\n',
      ]);

      final responses = openai_responses.OpenAIResponses(client, config);

      final parts =
          await responses.chatStreamParts([ChatMessage.user('x')]).toList();

      final providerMetadataParts =
          parts.whereType<LLMProviderMetadataPart>().toList();
      expect(providerMetadataParts, isNotEmpty);

      final lastMetadata = providerMetadataParts.last.providerMetadata;
      final openai = lastMetadata['openai'] as Map<String, dynamic>;
      expect(openai['id'], equals('resp_1'));
      expect(openai['model'], equals('gpt-4o-search-preview'));
      expect(openai['webSearchCalls'], isA<List>());
      expect(openai['annotations'], isA<List>());

      expect(parts.whereType<LLMFinishPart>(), hasLength(1));
      expect(parts.whereType<LLMTextDeltaPart>(), hasLength(1));
    });
  });
}

class _FakeOpenAIClient extends OpenAIClient {
  final List<String> _chunks;

  _FakeOpenAIClient(super.config, this._chunks);

  @override
  Stream<String> postStreamRaw(
    String endpoint,
    Map<String, dynamic> body, {
    CancelToken? cancelToken,
  }) async* {
    for (final chunk in _chunks) {
      yield chunk;
    }
  }
}
