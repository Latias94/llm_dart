import 'dart:async';
import 'dart:convert';

import 'package:llm_dart/llm_dart.dart';
import 'package:llm_dart_openai/client.dart';
import 'package:llm_dart_openai/llm_dart_openai.dart' as openai_client;
import 'package:llm_dart_openai/responses.dart' as openai_responses;
import 'package:test/test.dart';

String _sseData(Map<String, dynamic> json) => 'data: ${jsonEncode(json)}\n\n';

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

  @override
  Future<({Stream<String> stream, Map<String, String> headers})>
      postStreamRawWithHeaders(
    String endpoint,
    Map<String, dynamic> body, {
    CancelToken? cancelToken,
  }) async {
    return (
      stream: postStreamRaw(endpoint, body, cancelToken: cancelToken),
      headers: const <String, String>{},
    );
  }
}

void main() {
  group('OpenAI Responses source dedupe (AI SDK parity)', () {
    test('dedupes identical url sources across repeated annotations', () async {
      final config = openai_client.OpenAIConfig(
        apiKey: 'test-key',
        baseUrl: 'https://api.openai.com/v1/',
        model: 'gpt-4o',
        useResponsesAPI: true,
      );

      final chunks = <String>[
        _sseData({
          'type': 'response.created',
          'response': {
            'object': 'response',
            'id': 'resp_1',
            'created_at': 1700000000,
            'model': 'gpt-4o',
            'status': 'in_progress',
            'output': [],
          },
        }),
        _sseData({
          'type': 'response.output_text.annotation.added',
          'annotation': {
            'type': 'url_citation',
            'url': 'https://example.com/',
            'start_index': 0,
            'end_index': 4,
          },
        }),
        // Duplicate annotation: should not emit a new source part.
        _sseData({
          'type': 'response.output_text.annotation.added',
          'annotation': {
            'type': 'url_citation',
            'url': 'https://example.com/',
            'start_index': 0,
            'end_index': 4,
          },
        }),
        _sseData({
          'type': 'response.output_text.delta',
          'delta': 'Hello',
        }),
        _sseData({
          'type': 'response.completed',
          'response': {
            'object': 'response',
            'id': 'resp_1',
            'created_at': 1700000000,
            'model': 'gpt-4o',
            'status': 'completed',
            'output': [],
            'usage': {
              'input_tokens': 1,
              'output_tokens': 1,
              'total_tokens': 2,
            },
          },
        }),
        'data: [DONE]\n\n',
      ];

      final client = _FakeOpenAIClient(config, chunks);
      final responses = openai_responses.OpenAIResponses(client, config);

      final parts =
          await responses.chatStreamParts([ChatMessage.user('x')]).toList();

      final sources = parts.whereType<LLMSourceUrlPart>().toList();
      expect(sources, hasLength(1));
      expect(sources.single.url, equals('https://example.com/'));

      final finish = parts.whereType<LLMFinishPart>().single;
      expect(finish.response.text, equals('Hello'));
    });
  });
}
