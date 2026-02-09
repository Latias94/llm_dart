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
}

void main() {
  group('OpenAI Responses provider metadata dedupe (conformance)', () {
    test(
        'dedupes identical metadata snapshots across repeated output_item.done',
        () async {
      final config = openai_client.OpenAIConfig(
        apiKey: 'test-key',
        baseUrl: 'https://api.openai.com/v1/',
        model: 'gpt-4o',
        useResponsesAPI: true,
      );

      const messageItem = {
        'type': 'message',
        'id': 'msg_1',
        'role': 'assistant',
        'status': 'completed',
        'content': [
          {
            'type': 'output_text',
            'text': 'Hello',
            'annotations': [],
          }
        ],
      };

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
          'type': 'response.output_item.done',
          'output_index': 0,
          'item': messageItem,
        }),
        // Duplicate done event with the same payload: should not emit a new
        // LLMProviderMetadataPart snapshot.
        _sseData({
          'type': 'response.output_item.done',
          'output_index': 0,
          'item': messageItem,
        }),
        _sseData({
          'type': 'response.completed',
          'response': {
            'object': 'response',
            'id': 'resp_1',
            'created_at': 1700000000,
            'model': 'gpt-4o',
            'status': 'completed',
            'output': [messageItem],
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

      final providerMetadataParts =
          parts.whereType<LLMProviderMetadataPart>().toList();

      // Provider metadata does not currently include response `status`, so
      // repeated events that don't change (id/model/etc.) would otherwise spam
      // identical snapshots. Ensure we only emit a single snapshot.
      expect(providerMetadataParts, hasLength(1));
      expect(
          providerMetadataParts.single.providerMetadata['openai'], isA<Map>());

      final finish = parts.whereType<LLMFinishPart>().single;
      expect(finish.response.text, equals('Hello'));
    });
  });
}
