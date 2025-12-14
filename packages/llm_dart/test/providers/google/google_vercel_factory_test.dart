import 'package:llm_dart/llm_dart.dart';
import 'package:test/test.dart';

void main() {
  group('GoogleGenerativeAI Vercel-style factory', () {
    test('chat() creates LanguageModel with correct metadata', () {
      final google = createGoogleGenerativeAI(
        apiKey: 'test-key',
        baseUrl: 'https://generativelanguage.test/v1beta',
        headers: const {'X-Custom': 'value'},
        name: 'my-google',
        timeout: const Duration(seconds: 15),
      );

      final model = google.chat('gemini-1.5-flash');

      expect(model, isA<LanguageModel>());
      expect(model.providerId, equals('my-google'));
      expect(model.modelId, equals('gemini-1.5-flash'));

      final config = model.config;
      expect(config.apiKey, equals('test-key'));
      expect(
        config.baseUrl,
        equals('https://generativelanguage.test/v1beta/'),
      );
      expect(config.model, equals('gemini-1.5-flash'));
      expect(config.timeout, equals(const Duration(seconds: 15)));

      final headers = config.extensions[LLMConfigKeys.customHeaders];
      expect(headers, isA<Map<String, String>>());
      expect(headers['X-Custom'], equals('value'));
    });

    test('embedding/image helpers create capabilities', () {
      final google = createGoogleGenerativeAI(apiKey: 'test-key');

      final embedding = google.embedding('text-embedding-004');
      final textEmbedding = google.textEmbedding('text-embedding-004');
      final textEmbeddingModel =
          google.textEmbeddingModel('text-embedding-004');
      final image = google.image('imagen-3.0');
      final imageModel = google.imageModel('imagen-3.0');

      expect(embedding, isA<EmbeddingCapability>());
      expect(textEmbedding, isA<EmbeddingCapability>());
      expect(textEmbeddingModel, isA<EmbeddingCapability>());
      expect(image, isA<ImageGenerationCapability>());
      expect(imageModel, isA<ImageGenerationCapability>());
    });

    test('google() alias forwards to createGoogleGenerativeAI', () {
      final instance = google(
        apiKey: 'test-key',
        name: 'alias-google',
      );

      final model = instance.chat('gemini-1.5-flash-latest');

      expect(model.providerId, equals('alias-google'));
      expect(
        model.modelId,
        equals('gemini-1.5-flash-latest'),
      );
    });
  });
}
