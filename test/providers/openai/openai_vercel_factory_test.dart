import 'package:llm_dart/llm_dart.dart';
import 'package:llm_dart/providers/openai/responses_capability.dart';
import 'package:test/test.dart';

void main() {
  group('OpenAI Vercel-style factory', () {
    test('chat() creates LanguageModel with correct metadata', () {
      final openai = createOpenAI(
        apiKey: 'test-key',
        baseUrl: 'https://api.custom-openai.test/v1',
        organization: 'org_123',
        project: 'proj_456',
        headers: const {'X-Custom': 'value'},
        name: 'my-openai',
        timeout: const Duration(seconds: 30),
      );

      final model = openai.chat('gpt-4o');

      expect(model, isA<LanguageModel>());
      expect(model.providerId, equals('my-openai'));
      expect(model.modelId, equals('gpt-4o'));

      final config = model.config;
      expect(config.apiKey, equals('test-key'));
      expect(config.baseUrl, equals('https://api.custom-openai.test/v1/'));
      expect(config.model, equals('gpt-4o'));
      expect(config.timeout, equals(const Duration(seconds: 30)));

      final headers = config.extensions[LLMConfigKeys.customHeaders];
      expect(headers, isA<Map<String, String>>());
      expect(headers['OpenAI-Organization'], equals('org_123'));
      expect(headers['OpenAI-Project'], equals('proj_456'));
      expect(headers['X-Custom'], equals('value'));
    });

    test('responses() uses responses providerId and config', () {
      final openai = createOpenAI(
        apiKey: 'test-key',
        name: 'my-openai',
      );

      final model = openai.responses('gpt-4.1-mini');

      expect(model, isA<OpenAIResponsesCapability>());
      expect(model.providerId, equals('my-openai.responses'));
      expect(model.modelId, equals('gpt-4.1-mini'));

      final config = model.config;
      expect(config.apiKey, equals('test-key'));
      expect(config.model, equals('gpt-4.1-mini'));
    });

    test('embedding/image/audio helpers create capabilities', () {
      final openai = createOpenAI(apiKey: 'test-key');

      final embedding = openai.embedding('text-embedding-3-small');
      final textEmbedding = openai.textEmbedding('text-embedding-3-large');
      final textEmbeddingModel =
          openai.textEmbeddingModel('text-embedding-3-large');
      final image = openai.image('dall-e-3');
      final imageModel = openai.imageModel('dall-e-3');
      final transcription = openai.transcription('gpt-4o-mini-transcribe');
      final speech = openai.speech('gpt-4o-mini-tts');

      expect(embedding, isA<EmbeddingCapability>());
      expect(textEmbedding, isA<EmbeddingCapability>());
      expect(textEmbeddingModel, isA<EmbeddingCapability>());
      expect(image, isA<ImageGenerationCapability>());
      expect(imageModel, isA<ImageGenerationCapability>());
      expect(transcription, isA<AudioCapability>());
      expect(speech, isA<AudioCapability>());
    });

    test('tools helpers mirror built-in tools', () {
      final openai = createOpenAI(apiKey: 'test-key');

      final webSearchTool = openai.tools.webSearch();
      final fileSearchTool = openai.tools.fileSearch(
        vectorStoreIds: const ['vs_1'],
        parameters: const {'foo': 'bar'},
      );
      final computerUseTool = openai.tools.computerUse(
        displayWidth: 1920,
        displayHeight: 1080,
        environment: 'browser',
        parameters: const {'mode': 'auto'},
      );

      expect(webSearchTool.type.toString(), contains('webSearch'));

      final fileParams = fileSearchTool.parameters;
      expect(fileSearchTool.vectorStoreIds, equals(const ['vs_1']));
      expect(fileParams?['foo'], equals('bar'));

      expect(computerUseTool.displayWidth, equals(1920));
      expect(computerUseTool.displayHeight, equals(1080));
      expect(computerUseTool.environment, equals('browser'));
      final computerParams = computerUseTool.parameters;
      expect(computerParams?['mode'], equals('auto'));
    });

    test('openai() alias forwards to createOpenAI', () {
      final instance = openai(
        apiKey: 'test-key',
        name: 'alias-openai',
      );

      final model = instance.chat('gpt-4o-mini');

      expect(model.providerId, equals('alias-openai'));
      expect(model.modelId, equals('gpt-4o-mini'));
    });
  });
}
