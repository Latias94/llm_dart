import 'dart:convert';

import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_openai_compatible/llm_dart_openai_compatible.dart';
import 'package:llm_dart_xai/responses.dart';
import 'package:test/test.dart';

import '../../utils/fakes/fakes.dart';

String _sseData(Map<String, dynamic> json) => 'data: ${jsonEncode(json)}\n\n';

void main() {
  group('xAI Responses request metadata part', () {
    test('emits LLMRequestMetadataPart when enabled', () async {
      final llmConfig = LLMConfig(
        apiKey: 'test-key',
        baseUrl: 'https://api.x.ai/v1/',
        model: 'grok-4-fast-reasoning',
        providerOptions: const {
          'xai.responses': {
            'emitRequestMetadata': true,
          },
        },
      );
      final config = OpenAICompatibleConfig.fromLLMConfig(
        llmConfig,
        providerId: 'xai.responses',
        providerName: 'xAI (Responses)',
      );

      final chunks = <String>[
        _sseData({
          'type': 'response.created',
          'response': {
            'object': 'response',
            'id': 'resp_1',
            'created_at': 1700000001,
            'model': 'grok-4-fast-reasoning',
            'output': [],
            'status': 'in_progress',
          },
        }),
        _sseData({
          'type': 'response.completed',
          'response': {
            'object': 'response',
            'id': 'resp_1',
            'created_at': 1700000001,
            'model': 'grok-4-fast-reasoning',
            'output': [
              {
                'type': 'message',
                'id': 'msg_1',
                'role': 'assistant',
                'status': 'completed',
                'content': [
                  {'type': 'output_text', 'text': 'Hello'},
                ],
              },
            ],
            'status': 'completed',
            'usage': {
              'input_tokens': 1,
              'output_tokens': 1,
              'total_tokens': 2,
            },
          },
        }),
      ];

      final client = FakeOpenAIClient(config)
        ..streamHeaders = const {'x-test': '1'}
        ..streamResponse = Stream<String>.fromIterable(chunks);
      final responses = XAIResponses(client, config);

      final parts =
          await responses.chatStreamParts([ChatMessage.user('Hi')]).toList();

      final requestMeta = parts.whereType<LLMRequestMetadataPart>().toList();
      expect(requestMeta, hasLength(1));

      final body = requestMeta.single.body as Map<String, dynamic>;
      expect(body['input'], isNotNull);

      final meta = parts.whereType<LLMResponseMetadataPart>().first;
      expect(meta.headers, isNotNull);
      expect(meta.headers, containsPair('x-test', '1'));
    });
  });
}
