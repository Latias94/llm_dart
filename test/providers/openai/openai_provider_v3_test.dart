import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_openai/openai.dart';
import 'package:test/test.dart';

import '../../utils/fakes/openai_fake_client.dart';

void main() {
  group('OpenAI ProviderV3 factory', () {
    test('creates a v3 provider and language models are per-model', () {
      final openai = createOpenAI(
        apiKey: 'test-key',
        baseUrl: 'https://example.com',
      );

      expect(openai.specificationVersion, equals('v3'));

      final model = openai('gpt-4.1');
      expect(model, isA<ChatCapability>());
      expect(model, isA<OpenAIProvider>());
      expect((model as OpenAIProvider).config.model, equals('gpt-4.1'));
      expect(model.config.useResponsesAPI, isTrue);
    });

    test('speechModel injects default model id into requests', () async {
      FakeOpenAIClient? lastClient;

      final openai = createOpenAI(
        apiKey: 'test-key',
        baseUrl: 'https://example.com',
        providerFactory: (config) {
          final client = FakeOpenAIClient(config);
          lastClient = client;
          return OpenAIProvider(config, client: client);
        },
      );

      final tts = openai.speechModel('tts-1');
      await tts.textToSpeech(const TTSRequest(text: 'hi'));

      expect(lastClient, isNotNull);
      expect(lastClient!.lastEndpoint, equals('audio/speech'));
      expect(lastClient!.lastJsonBody?['model'], equals('tts-1'));
    });

    test('transcriptionModel injects default model id into requests', () async {
      FakeOpenAIClient? lastClient;

      final openai = createOpenAI(
        apiKey: 'test-key',
        baseUrl: 'https://example.com',
        providerFactory: (config) {
          final client = FakeOpenAIClient(config);
          lastClient = client;
          return OpenAIProvider(config, client: client);
        },
      );

      final stt = openai.transcriptionModel('whisper-1');
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
