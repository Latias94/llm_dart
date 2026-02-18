import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_openai_compatible/llm_dart_openai_compatible.dart';
import 'package:llm_dart_xai/defaults.dart';
import 'package:llm_dart_xai/provider.dart';
import 'package:llm_dart_xai/responses_provider.dart';
import 'package:llm_dart_xai/xai.dart';
import 'package:test/test.dart';

import '../../utils/fakes/openai_fake_client.dart';

void main() {
  group('xAI ProviderV3 factory', () {
    test('creates a v3 provider and language models are per-model', () {
      final provider = createXai(
        apiKey: 'test-key',
        headers: const {'X-Test': '1'},
      );

      expect(provider.specificationVersion, equals('v3'));

      final model = provider('grok-3');
      expect(model, isA<ChatCapability>());
      expect(model, isA<XAIProvider>());

      final cfg = (model as XAIProvider).config;
      expect(cfg.model, equals('grok-3'));
      expect(cfg.baseUrl, equals('https://api.x.ai/v1'));
      expect(cfg.imageModel, equals(xaiDefaultImageModel));
      expect(cfg.videoModel, equals(xaiDefaultVideoModel));

      final options = cfg.originalConfig?.providerOptions['xai'];
      expect(options, isNotNull);
      expect(options!['headers'], equals(const {'X-Test': '1'}));
    });

    test('imageModel injects default model id into requests', () async {
      FakeOpenAIClient? lastClient;

      final provider = createXai(
        apiKey: 'test-key',
        clientFactory: (cfg) {
          final original = cfg.originalConfig ??
              LLMConfig(
                apiKey: cfg.apiKey,
                baseUrl: cfg.baseUrl,
                model: cfg.model,
                providerOptions: const {},
              );
          final openAIConfig = OpenAICompatibleConfig.fromLLMConfig(
            original,
            providerId: 'xai',
            providerName: 'xAI',
          );
          final client = FakeOpenAIClient(openAIConfig);
          lastClient = client;
          client.jsonResponse = <String, dynamic>{
            'data': [
              {
                'url': 'https://example.com/img.png',
              }
            ],
          };
          return client;
        },
      );

      final images = provider.imageModel('grok-2-image');
      await images.generateImages(
        const ImageGenerationRequest(prompt: 'hi', count: 1),
      );

      expect(lastClient, isNotNull);
      expect(lastClient!.lastEndpoint, equals('images/generations'));
      expect(lastClient!.lastJsonBody?['model'], equals('grok-2-image'));
    });

    test('videoModel injects default model id into requests', () async {
      FakeOpenAIClient? lastClient;

      final provider = createXai(
        apiKey: 'test-key',
        clientFactory: (cfg) {
          final original = cfg.originalConfig ??
              LLMConfig(
                apiKey: cfg.apiKey,
                baseUrl: cfg.baseUrl,
                model: cfg.model,
                providerOptions: const {},
              );
          final openAIConfig = OpenAICompatibleConfig.fromLLMConfig(
            original,
            providerId: 'xai',
            providerName: 'xAI',
          );
          final client = FakeOpenAIClient(openAIConfig);
          lastClient = client;
          client.jsonResponse = const <String, dynamic>{'request_id': 'req1'};
          client.getJsonQueue.add(
            (
              json: const <String, dynamic>{
                'status': 'done',
                'video': {'url': 'https://example.com/video.mp4'},
              },
              headers: const <String, String>{},
            ),
          );
          return client;
        },
      );

      final video = provider.videoModel('grok-imagine-video');
      await video.generateVideos(
        const ExperimentalVideoGenerationRequest(
          prompt: 'hi',
          providerOptions: {
            'xai': {
              'pollIntervalMs': 0,
              'pollTimeoutMs': 1000,
            },
          },
        ),
      );

      expect(lastClient, isNotNull);
      expect(lastClient!.lastJsonBody?['model'], equals('grok-imagine-video'));
    });

    test('responsesModel creates a responses provider', () {
      final provider = createXai(apiKey: 'test-key');

      final responses = provider.responsesModel('grok-4-fast');
      expect(responses, isA<ChatCapability>());
      expect(responses, isA<XAIResponsesProvider>());
      expect(
        (responses as XAIResponsesProvider).providerId,
        equals('xai.responses'),
      );
      expect(responses.modelId, equals('grok-4-fast'));
    });
  });
}
