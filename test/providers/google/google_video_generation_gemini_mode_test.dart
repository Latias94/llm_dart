import 'dart:typed_data';

import 'package:llm_dart/llm_dart.dart';
import 'package:llm_dart_google/model_path.dart';
import 'package:test/test.dart';

import '../../utils/fakes/google_fake_client.dart';

void main() {
  group('Google video generation (Gemini mode)', () {
    test('predictLongRunning uses inlineData and polls operation via GET',
        () async {
      final config = GoogleConfig(
        apiKey: 'test-key',
        model: 'veo-2.0-generate-001',
        baseUrl: 'https://generativelanguage.googleapis.com/v1beta/',
      );

      const operationName = 'operations/op123';
      final predictEndpoint =
          '${googleModelPath(config.model)}:predictLongRunning';

      final client = FakeGoogleClient(
        config,
        responsesByEndpoint: {
          predictEndpoint: {
            'name': operationName,
            'done': false,
          },
        },
        getResponsesByEndpoint: {
          operationName: {
            'name': operationName,
            'done': true,
            'response': {
              'generateVideoResponse': {
                'generatedSamples': [
                  {
                    'video': {
                      'uri': 'https://example.com/video.mp4',
                    },
                  },
                ],
              },
            },
          },
        },
      );

      final provider = GoogleProvider(config, client: client);

      final response = await provider.generateVideos(
        ExperimentalVideoGenerationRequest(
          prompt: 'hi',
          n: 2,
          image: ExperimentalInlineVideoFile(
            mediaType: 'image/png',
            data: Uint8List.fromList([1, 2, 3]),
          ),
          providerOptions: const {
            'google': {
              'pollIntervalMs': 0,
            },
          },
        ),
      );

      final predictCall = client.calls.firstWhere(
        (c) => c.method == 'POST' && c.endpoint == predictEndpoint,
      );
      final body = (predictCall.body as Map).cast<String, dynamic>();
      expect(body['instances'], isA<List>());
      expect(body['parameters'], isA<Map>());
      expect((body['parameters'] as Map)['sampleCount'], equals(2));

      final instances = (body['instances'] as List).cast<Map>();
      final instance0 = instances.first.cast<String, dynamic>();
      expect(instance0['prompt'], equals('hi'));

      final image = (instance0['image'] as Map).cast<String, dynamic>();
      final inlineData = (image['inlineData'] as Map).cast<String, dynamic>();
      expect(inlineData['mimeType'], equals('image/png'));
      expect(inlineData['data'], equals('AQID'));

      expect(response.videos, hasLength(1));
      final video = response.videos.single as ExperimentalGeneratedVideoUrl;
      expect(video.url.toString(), contains('key=test-key'));
    });

    test('URL image input is ignored with a warning', () async {
      final config = GoogleConfig(
        apiKey: 'test-key',
        model: 'veo-2.0-generate-001',
        baseUrl: 'https://generativelanguage.googleapis.com/v1beta/',
      );

      const operationName = 'operations/op-url-image';
      final predictEndpoint =
          '${googleModelPath(config.model)}:predictLongRunning';

      final client = FakeGoogleClient(
        config,
        responsesByEndpoint: {
          predictEndpoint: {
            'name': operationName,
            'done': true,
            'response': {
              'generateVideoResponse': {
                'generatedSamples': [
                  {
                    'video': {
                      'uri': 'https://example.com/video.mp4',
                    },
                  },
                ],
              },
            },
          },
        },
      );

      final provider = GoogleProvider(config, client: client);

      final response = await provider.generateVideos(
        ExperimentalVideoGenerationRequest(
          prompt: 'hi',
          image: ExperimentalUrlVideoFile(
            url: Uri.parse('https://example.com/input.png'),
          ),
          providerOptions: const {
            'google': {
              'pollIntervalMs': 0,
            },
          },
        ),
      );

      expect(response.warnings, isNotEmpty);

      final predictCall = client.calls.firstWhere(
        (c) => c.method == 'POST' && c.endpoint == predictEndpoint,
      );
      final body = (predictCall.body as Map).cast<String, dynamic>();
      final instances = (body['instances'] as List).cast<Map>();
      final instance0 = instances.first.cast<String, dynamic>();
      expect(instance0.containsKey('image'), isFalse);
    });
  });
}
