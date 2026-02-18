import 'dart:convert';

import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_openai_compatible/openai_compatible.dart';
import 'package:llm_dart_openai_compatible/provider.dart';
import 'package:test/test.dart';

import '../../utils/fakes/openai_fake_client.dart';

void main() {
  group('OpenAICompatible ProviderV3 factory', () {
    test('creates a v3 provider and language models are per-model', () {
      final compatible = createOpenAICompatible(
        baseUrl: 'https://example.com/v1/',
        name: 'openrouter',
      );

      expect(compatible.specificationVersion, equals('v3'));

      final model = compatible('gpt-4.1');
      expect(model, isA<ChatCapability>());
      expect(model, isA<OpenAICompatibleChatProvider>());

      final config = (model as OpenAICompatibleChatProvider).config;
      expect(config.providerId, equals('openrouter'));
      expect(config.providerName, equals('openrouter'));
      expect(config.baseUrl, equals('https://example.com/v1'));
      expect(config.model, equals('gpt-4.1'));
    });

    test('imageModel injects default model id into requests', () async {
      FakeOpenAIClient? lastClient;

      final compatible = createOpenAICompatible(
        baseUrl: 'https://example.com/v1/',
        name: 'openrouter',
        clientFactory: (config) {
          final client = FakeOpenAIClient(config);
          lastClient = client;
          client.jsonResponse = <String, dynamic>{
            'data': [
              {
                'b64_json': base64Encode(const [1, 2, 3]),
              }
            ],
          };
          return client;
        },
      );

      final images = compatible.imageModel('gpt-image-1');
      await images.generateImages(
        const ImageGenerationRequest(prompt: 'hi', count: 1),
      );

      expect(lastClient, isNotNull);
      expect(lastClient!.lastEndpoint, equals('images/generations'));
      expect(lastClient!.lastJsonBody?['model'], equals('gpt-image-1'));
    });

    test('speechModel injects default model id into requests', () async {
      FakeOpenAIClient? lastClient;

      final compatible = createOpenAICompatible(
        baseUrl: 'https://example.com/v1/',
        name: 'openrouter',
        clientFactory: (config) {
          final client = FakeOpenAIClient(config);
          lastClient = client;
          return client;
        },
      );

      final tts = compatible.speechModel('tts-1');
      await tts.textToSpeech(const TTSRequest(text: 'hi'));

      expect(lastClient, isNotNull);
      expect(lastClient!.lastEndpoint, equals('audio/speech'));
      expect(lastClient!.lastJsonBody?['model'], equals('tts-1'));
    });

    test('transcriptionModel injects default model id into requests', () async {
      FakeOpenAIClient? lastClient;

      final compatible = createOpenAICompatible(
        baseUrl: 'https://example.com/v1/',
        name: 'openrouter',
        clientFactory: (config) {
          final client = FakeOpenAIClient(config);
          lastClient = client;
          return client;
        },
      );

      final stt = compatible.transcriptionModel('whisper-1');
      await stt.speechToText(const STTRequest(audioData: [1, 2, 3]));

      expect(lastClient, isNotNull);
      expect(lastClient!.lastEndpoint, equals('audio/transcriptions'));
      final form = lastClient!.lastFormData;
      expect(form, isNotNull);
      final modelField = form!.fields.firstWhere((e) => e.key == 'model').value;
      expect(modelField, equals('whisper-1'));
    });
  });
}

