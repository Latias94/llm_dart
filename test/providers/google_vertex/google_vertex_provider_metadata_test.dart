import 'package:llm_dart/llm_dart.dart';
import 'package:test/test.dart';

import '../../utils/fakes/google_fake_client.dart';

void main() {
  group('Google Vertex providerMetadata', () {
    test('namespaces metadata under vertex (AI SDK parity)', () async {
      final config = GoogleConfig(
        providerOptionsName: 'vertex',
        apiKey: 'test-key',
        baseUrl: googleVertexBaseUrl,
        model: googleVertexDefaultModel,
      );

      final endpoint = 'models/${config.model}:generateContent';
      final client = FakeGoogleClient(
        config,
        responsesByEndpoint: {
          endpoint: {
            'candidates': [
              {
                'content': {
                  'parts': [
                    {
                      'functionCall': {
                        'name': 'test',
                        'args': {'value': 'ok'},
                      },
                      'thoughtSignature': 'sig-vertex',
                    },
                  ],
                },
                'finishReason': 'STOP',
              },
            ],
            'usageMetadata': const {
              'promptTokenCount': 1,
              'candidatesTokenCount': 2,
              'totalTokenCount': 3,
            },
          },
        },
      );

      final provider = GoogleProvider(config, client: client);
      final response = await provider.chatWithTools(
        [ChatMessage.user('hi')],
        [
          Tool.function(
            name: 'test',
            description: 'Test',
            parameters: const ParametersSchema(
              schemaType: 'object',
              properties: {},
              required: [],
            ),
          ),
        ],
      );

      final meta = response.providerMetadata;
      expect(meta, isNotNull);
      expect(meta!.containsKey('vertex'), isTrue);
      expect(meta.containsKey('vertex.chat'), isTrue);
      expect(meta.containsKey('google'), isFalse);
      expect(meta.containsKey('google.generative-ai'), isFalse);

      final calls = response.toolCalls;
      expect(calls, isNotNull);
      expect(calls, isNotEmpty);
      expect(
        calls!.first.providerOptions['vertex']?['thoughtSignature'],
        equals('sig-vertex'),
      );
    });
  });
}
