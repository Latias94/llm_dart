import 'dart:convert';

import 'package:llm_dart/llm_dart.dart';
import 'package:test/test.dart';

import '../../utils/fakes/google_fake_client.dart';

String _sseData(Map<String, dynamic> json) => 'data: ${jsonEncode(json)}\n\n';

void main() {
  group('Google Vertex grounding sources (AI SDK parity)', () {
    test('emits source parts and namespaces metadata under google-vertex',
        () async {
      final config = GoogleConfig(
        providerId: 'google-vertex',
        providerOptionsName: 'google-vertex',
        apiKey: 'test-key',
        baseUrl: googleVertexBaseUrl,
        model: googleVertexDefaultModel,
        stream: true,
      );

      final client = FakeGoogleClient(config)
        ..streamResponse = Stream<String>.fromIterable([
          _sseData({
            'modelVersion': config.model,
            'candidates': [
              {
                'content': {
                  'parts': [
                    {'text': 'Hi'}
                  ],
                },
                'groundingMetadata': {
                  'groundingChunks': [
                    {
                      'web': {
                        'uri': 'https://example.com',
                        'title': 'Example',
                      },
                    },
                  ],
                },
              },
            ],
          }),
          _sseData({
            'candidates': [
              {
                'content': {
                  'parts': [
                    {'text': '!'}
                  ],
                },
                'finishReason': 'STOP',
              },
            ],
          }),
        ]);

      final chat = GoogleChat(client, config);
      final parts = await chat.chatStreamParts(
        [ChatMessage.user('hello')],
        tools: const [],
      ).toList();

      final sources = parts.whereType<LLMSourceUrlPart>().toList();
      expect(sources, hasLength(1));
      expect(sources.single.url, equals('https://example.com'));
      expect(sources.single.title, equals('Example'));

      final sourceMeta =
          sources.single.providerMetadata?['google-vertex'] as Map?;
      expect(sourceMeta, isNotNull);
      expect(sourceMeta!['type'], equals('groundingMetadata'));

      final finish = parts.whereType<LLMFinishPart>().single;
      final meta = finish.response.providerMetadata;
      expect(meta, isNotNull);
      expect(meta!.containsKey('google-vertex'), isTrue);
      expect(meta.containsKey('google-vertex.chat'), isTrue);
      expect(meta.containsKey('google'), isFalse);
    });
  });
}
