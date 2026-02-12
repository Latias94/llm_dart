import 'dart:convert';

import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_openai_compatible/llm_dart_openai_compatible.dart';
import 'package:test/test.dart';

import '../../utils/fakes/fakes.dart';

String _sseData(Map<String, dynamic> json) => 'data: ${jsonEncode(json)}\n\n';

void main() {
  group('OpenAI-compatible response headers (conformance)', () {
    test('exposes response headers in response-metadata part', () async {
      final config = OpenAICompatibleConfig(
        providerId: 'openai-compatible',
        providerName: 'OpenAI-compatible',
        apiKey: 'test-key',
        baseUrl: 'https://api.example.com/v1/',
        model: 'gpt-4o-mini',
      );

      final client = FakeOpenAIClient(config)
        ..streamHeaders = const {'x-test': '1'}
        ..streamResponse = Stream.fromIterable([
          _sseData({
            'id': 'chatcmpl_1',
            'model': 'gpt-4o-mini',
            'created': 1700000000,
            'choices': [
              {
                'index': 0,
                'delta': {'content': 'Hello'},
              },
            ],
          }),
          _sseData({
            'id': 'chatcmpl_1',
            'model': 'gpt-4o-mini',
            'choices': [
              {
                'index': 0,
                'delta': <String, dynamic>{},
                'finish_reason': 'stop',
              },
            ],
          }),
        ]);

      final chat = OpenAIChat(client, config);
      final parts =
          await chat.chatStreamParts([ChatMessage.user('Hi')]).toList();

      final meta = parts.whereType<LLMResponseMetadataPart>().first;
      expect(meta.headers, isNotNull);
      expect(meta.headers, containsPair('x-test', '1'));
    });
  });
}
