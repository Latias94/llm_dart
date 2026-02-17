import 'dart:typed_data';

import 'package:llm_dart/llm_dart.dart';
import 'package:llm_dart_google/model_path.dart';
import 'package:test/test.dart';

import '../../utils/fakes/google_fake_client.dart';

void main() {
  group('Google video generation (Vertex express mode)', () {
    test(
        'predictLongRunning uses bytesBase64Encoded and polls via fetchPredictOperation',
        () async {
      final config = GoogleConfig(
        providerId: 'google-vertex',
        providerOptionsName: 'google-vertex',
        apiKey: 'test-key',
        model: 'veo-2.0-generate-001',
        baseUrl: 'https://us-central1-aiplatform.googleapis.com/v1/',
      );

      const operationName = 'operations/vertex-op-1';
      final modelPath = googleModelPath(config.model);
      final predictEndpoint = '$modelPath:predictLongRunning';
      final pollEndpoint = '$modelPath:fetchPredictOperation';

      final client = FakeGoogleClient(
        config,
        responsesByEndpoint: {
          predictEndpoint: {
            'name': operationName,
            'done': false,
          },
          pollEndpoint: {
            'name': operationName,
            'done': true,
            'response': {
              'videos': [
                {
                  'bytesBase64Encoded': 'Zm9v',
                  'mimeType': 'video/mp4',
                },
              ],
            },
          },
        },
      );

      final provider = GoogleProvider(config, client: client);

      final response = await provider.generateVideos(
        ExperimentalVideoGenerationRequest(
          prompt: 'hi',
          n: 1,
          image: ExperimentalInlineVideoFile(
            mediaType: 'image/png',
            data: Uint8List.fromList([1, 2, 3]),
          ),
          // Vercel-style alias key for Vertex video options.
          providerOptions: const {
            'vertex': {
              'pollIntervalMs': 0,
            },
          },
        ),
      );

      final predictCall = client.calls.firstWhere(
        (c) => c.method == 'POST' && c.endpoint == predictEndpoint,
      );
      final predictBody = (predictCall.body as Map).cast<String, dynamic>();
      final instances = (predictBody['instances'] as List).cast<Map>();
      final instance0 = instances.first.cast<String, dynamic>();
      expect(instance0['prompt'], equals('hi'));

      final image = (instance0['image'] as Map).cast<String, dynamic>();
      expect(image['bytesBase64Encoded'], equals('AQID'));
      expect(image['mimeType'], equals('image/png'));

      final pollCall = client.calls.firstWhere(
        (c) => c.method == 'POST' && c.endpoint == pollEndpoint,
      );
      final pollBody = (pollCall.body as Map).cast<String, dynamic>();
      expect(pollBody['operationName'], equals(operationName));

      expect(response.videos, hasLength(1));
      final video = response.videos.single as ExperimentalGeneratedVideoBase64;
      expect(video.data, equals('Zm9v'));
      expect(video.mediaType, equals('video/mp4'));
    });
  });
}
