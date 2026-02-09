import 'dart:convert';

import 'package:llm_dart/llm_dart.dart';
import 'package:test/test.dart';

import '../../utils/fakes/google_fake_client.dart';

void main() {
  group('Google Vertex streaming endpoint (AI SDK parity)', () {
    test('uses streamGenerateContent without alt=sse', () async {
      final config = GoogleConfig(
        providerOptionsName: 'vertex',
        providerId: 'google-vertex',
        apiKey: 'test-key',
        baseUrl: googleVertexBaseUrl,
        model: googleVertexDefaultModel,
        stream: true,
      );

      final client = FakeGoogleClient(config)
        ..streamResponse = Stream<String>.fromIterable([
          'data: ${jsonEncode({
                'candidates': [
                  {
                    'content': {
                      'parts': [
                        {'text': 'ok'},
                      ],
                    },
                    'finishReason': 'STOP',
                  },
                ],
              })}\n\n',
        ]);

      final chat = GoogleChat(client, config);
      final parts = await chat
          .chatStreamParts([ChatMessage.user('hi')], tools: const []).toList();

      expect(
        client.lastEndpoint,
        equals('models/${config.model}:streamGenerateContent'),
      );
      expect(parts.whereType<LLMFinishPart>(), hasLength(1));
    });
  });
}
