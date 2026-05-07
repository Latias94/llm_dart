import 'package:llm_dart/core/config.dart';
import 'package:llm_dart/models/audio_models.dart';
import 'package:llm_dart/providers/openai/openai.dart';
import 'package:llm_dart/src/compatibility/providers/openai_family_compat_support.dart'
    show createLegacyOpenAIConfig;
import 'package:llm_dart_transport/dio.dart';
import 'package:test/test.dart';

void main() {
  group('OpenAI audio support extraction', () {
    test('textToSpeech preserves voice and content-type shaping', () async {
      Map<String, dynamic>? capturedBody;

      final customDio = Dio();
      customDio.options.baseUrl = 'https://api.openai.com/v1/';
      customDio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            capturedBody = Map<String, dynamic>.from(
              options.data as Map<String, dynamic>,
            );
            handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                data: <int>[1, 2, 3],
              ),
            );
          },
        ),
      );

      final provider = _buildProvider(customDio);
      final response = await provider.textToSpeech(
        const TTSRequest(
          text: 'Hello audio',
          format: 'wav',
          speed: 1.2,
        ),
      );

      expect(capturedBody, isNotNull);
      expect(capturedBody!['voice'], equals('verse'));
      expect(capturedBody!['response_format'], equals('wav'));
      expect(capturedBody!['speed'], equals(1.2));
      expect(response.voice, equals('verse'));
      expect(response.contentType, equals('audio/wav'));
    });

    test('speechToText preserves multipart fields and word timings', () async {
      FormData? capturedFormData;

      final customDio = Dio();
      customDio.options.baseUrl = 'https://api.openai.com/v1/';
      customDio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            capturedFormData = options.data as FormData;
            handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                data: {
                  'text': 'Hello world',
                  'language': 'en',
                  'duration': 2.5,
                  'words': [
                    {
                      'word': 'Hello',
                      'start': 0.0,
                      'end': 0.5,
                    },
                    {
                      'word': 'world',
                      'start': 0.5,
                      'end': 1.0,
                    },
                  ],
                },
              ),
            );
          },
        ),
      );

      final provider = _buildProvider(customDio);
      final response = await provider.speechToText(
        STTRequest.fromAudio(
          [1, 2, 3, 4],
          format: 'mp3',
          language: 'en',
          prompt: 'Transcribe clearly',
          responseFormat: 'verbose_json',
          temperature: 0.2,
          includeWordTiming: true,
        ),
      );

      expect(capturedFormData, isNotNull);
      final fieldMap = {
        for (final field in capturedFormData!.fields) field.key: field.value,
      };
      expect(fieldMap['model'], equals('whisper-1'));
      expect(fieldMap['language'], equals('en'));
      expect(fieldMap['prompt'], equals('Transcribe clearly'));
      expect(fieldMap['response_format'], equals('verbose_json'));
      expect(fieldMap['temperature'], equals('0.2'));
      expect(
        capturedFormData!.fields
            .where((field) => field.key == 'timestamp_granularities[]')
            .map((field) => field.value),
        contains('word'),
      );
      expect(response.text, equals('Hello world'));
      expect(response.language, equals('en'));
      expect(response.words, hasLength(2));
      expect(response.words!.first.word, equals('Hello'));
    });

    test('translateAudio preserves multipart shaping and english response',
        () async {
      FormData? capturedFormData;
      String? capturedPath;

      final customDio = Dio();
      customDio.options.baseUrl = 'https://api.openai.com/v1/';
      customDio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            capturedPath = options.path;
            capturedFormData = options.data as FormData;
            handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                data: {
                  'text': 'Translated text',
                  'duration': 4.0,
                },
              ),
            );
          },
        ),
      );

      final provider = _buildProvider(customDio);
      final response = await provider.translateAudio(
        AudioTranslationRequest.fromAudio(
          [9, 8, 7],
          format: 'wav',
          prompt: 'Translate this',
          responseFormat: 'json',
          temperature: 0.1,
        ),
      );

      expect(capturedPath, equals('audio/translations'));
      expect(capturedFormData, isNotNull);
      final fieldMap = {
        for (final field in capturedFormData!.fields) field.key: field.value,
      };
      expect(fieldMap['model'], equals('whisper-1'));
      expect(fieldMap['prompt'], equals('Translate this'));
      expect(fieldMap['response_format'], equals('json'));
      expect(fieldMap['temperature'], equals('0.1'));
      expect(response.text, equals('Translated text'));
      expect(response.language, equals('en'));
    });
  });
}

OpenAIProvider _buildProvider(Dio dio) {
  final llmConfig = LLMConfig(
    apiKey: 'test-key',
    baseUrl: 'https://api.openai.com/v1/',
    model: 'gpt-4o',
  ).withExtensions({
    'customDio': dio,
  });

  return OpenAIProvider(
    createLegacyOpenAIConfig(llmConfig).copyWith(
      voice: 'verse',
    ),
  );
}
