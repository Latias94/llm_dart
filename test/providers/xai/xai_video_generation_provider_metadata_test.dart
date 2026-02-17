import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_openai_compatible/llm_dart_openai_compatible.dart';
import 'package:llm_dart_xai/llm_dart_xai.dart';
import 'package:test/test.dart';

import '../../utils/fakes/openai_fake_client.dart';

void main() {
  group('xAI experimental video generation (provider metadata)', () {
    test('polls and exposes responses.headers', () async {
      final xaiConfig = XAIConfig(
        apiKey: 'test-key',
        baseUrl: 'https://example.com/v1/',
        model: 'grok-3',
        videoModel: 'grok-imagine-video',
      );

      final openAIConfig = OpenAICompatibleConfig(
        providerId: 'xai',
        providerName: 'xAI',
        apiKey: 'test-key',
        baseUrl: 'https://example.com/v1/',
        model: 'grok-3',
      );

      final client = FakeOpenAIClient(openAIConfig)
        ..jsonResponse = const {'request_id': 'req_1'};

      client.getJsonQueue.add((
        json: const {'status': 'processing'},
        headers: const <String, String>{},
      ));
      client.getJsonQueue.add((
        json: const {
          'status': 'done',
          'video': {'url': 'https://example.com/video.mp4'},
        },
        headers: const {'x-poll': '1'},
      ));

      final provider = XAIProvider(xaiConfig, client: client);

      final response = await provider.generateVideosWithCallOptions(
        const ExperimentalVideoGenerationRequest(
          prompt: 'hi',
          providerOptions: {
            'xai': {
              'pollIntervalMs': 0,
              'pollTimeoutMs': 1000,
            },
          },
        ),
        callOptions: const LLMCallOptions(),
      );

      expect(client.lastEndpoint, equals('videos/req_1'));
      expect(client.lastJsonBody?['model'], equals('grok-imagine-video'));
      expect(response.videos, hasLength(1));
      expect(response.responses, hasLength(1));
      expect(response.responses.single.headers, equals(const {'x-poll': '1'}));
      expect(
        (response.video as ExperimentalGeneratedVideoUrl).url.toString(),
        equals('https://example.com/video.mp4'),
      );
    });
  });
}

