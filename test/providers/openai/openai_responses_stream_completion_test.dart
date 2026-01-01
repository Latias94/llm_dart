import 'dart:async';

import 'package:llm_dart/llm_dart.dart';
import 'package:llm_dart_openai/llm_dart_openai.dart' as openai_client;
import 'package:llm_dart_openai/responses.dart' as openai_responses;
import 'package:llm_dart_openai/client.dart';
import 'package:test/test.dart';

void main() {
  group('OpenAI Responses streaming completion', () {
    test('should emit CompletionEvent when stream ends with [DONE]', () async {
      final config = openai_client.OpenAIConfig(
        apiKey: 'test-key',
        baseUrl: 'https://api.openai.com/v1/',
        model: 'gpt-4o',
        useResponsesAPI: true,
      );

      final client = _FakeOpenAIClient(config, const [
        'data: {"type":"response.created","response":{"id":"resp_1","model":"gpt-4o","output":[]}}\n',
        'data: {"type":"response.output_text.delta","delta":"Hello"}\n',
        'data: [DONE]\n',
      ]);

      final responses = openai_responses.OpenAIResponses(client, config);
      final events =
          await responses.chatStream([ChatMessage.user('test')]).toList();

      expect(events.whereType<TextDeltaEvent>(), hasLength(1));
      final completion = events.whereType<CompletionEvent>().single;

      expect(completion.response.text, equals('Hello'));
      expect(completion.response.providerMetadata, isNotNull);
      expect(
        completion.response.providerMetadata!['openai'],
        containsPair('id', 'resp_1'),
      );
      expect(
        completion.response.providerMetadata!['openai'],
        containsPair('model', 'gpt-4o'),
      );
    });

    test('should accumulate output items and annotations for providerMetadata',
        () async {
      final config = openai_client.OpenAIConfig(
        apiKey: 'test-key',
        baseUrl: 'https://api.openai.com/v1/',
        model: 'gpt-4o-search-preview',
        useResponsesAPI: true,
      );

      final client = _FakeOpenAIClient(config, const [
        'data: {"type":"response.created","response":{"id":"resp_2","model":"gpt-4o-search-preview","output":[]}}\n',
        'data: {"type":"response.output_item.done","output_index":0,"item":{"type":"web_search_call","id":"ws_1","status":"completed","action":{"type":"search","query":"test","sources":[{"type":"url","url":"https://example.com"}]}}}\n',
        'data: {"type":"response.output_text.annotation.added","annotation":{"type":"url_citation","url":"https://example.com","start_index":0,"end_index":4}}\n',
        'data: [DONE]\n',
      ]);

      final responses = openai_responses.OpenAIResponses(client, config);
      final events =
          await responses.chatStream([ChatMessage.user('test')]).toList();

      final completion = events.whereType<CompletionEvent>().single;
      final openai = completion.response.providerMetadata!['openai']
          as Map<String, dynamic>;

      final webSearchCalls = openai['webSearchCalls'] as List;
      expect(webSearchCalls, hasLength(1));
      expect(webSearchCalls.single, containsPair('id', 'ws_1'));

      final annotations = openai['annotations'] as List;
      expect(annotations, hasLength(1));
      expect(annotations.single, containsPair('url', 'https://example.com'));
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
