import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_groq/groq.dart';
import 'package:llm_dart_groq/provider.dart';
import 'package:test/test.dart';

import '../../utils/fakes/openai_fake_client.dart';

void main() {
  group('Groq ProviderV3 factory', () {
    test('creates a v3 provider and language models are per-model', () {
      final provider = createGroq(
        apiKey: 'test-key',
        headers: const {'X-Test': '1'},
      );

      expect(provider.specificationVersion, equals('v3'));

      final model = provider('llama-3.3-70b-versatile');
      expect(model, isA<ChatCapability>());
      expect(model, isA<GroqProvider>());

      final cfg = (model as GroqProvider).config;
      expect(cfg.model, equals('llama-3.3-70b-versatile'));
      expect(cfg.baseUrl, equals('https://api.groq.com/openai/v1'));

      final options = cfg.originalConfig?.providerOptions['groq'];
      expect(options, isNotNull);
      expect(options!['headers'], equals(const {'X-Test': '1'}));
    });

    test('baseUrl is normalized (no trailing slash)', () {
      final provider = createGroq(
        apiKey: 'test-key',
        baseUrl: 'https://example.com/openai/v1/',
      );

      final model = provider('llama-3.1-8b-instant') as GroqProvider;
      expect(model.config.baseUrl, equals('https://example.com/openai/v1'));
    });

    test('transcriptionModel injects default model id into requests', () async {
      FakeOpenAIClient? lastClient;

      final provider = createGroq(
        apiKey: 'test-key',
        baseUrl: 'https://example.com/openai/v1/',
        clientFactory: (config) {
          final client = FakeOpenAIClient(config);
          lastClient = client;
          client.jsonResponse = <String, dynamic>{'text': 'hello'};
          return client;
        },
      );

      final stt = provider.transcriptionModel('whisper-large-v3');
      await stt.speechToText(const STTRequest(audioData: [1, 2, 3]));

      expect(lastClient, isNotNull);
      expect(lastClient!.lastEndpoint, equals('audio/transcriptions'));
      final form = lastClient!.lastFormData;
      expect(form, isNotNull);
      final modelField = form!.fields.firstWhere((e) => e.key == 'model').value;
      expect(modelField, equals('whisper-large-v3'));
    });
  });
}

