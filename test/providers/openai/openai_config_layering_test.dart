import 'package:dio/dio.dart';
import 'package:llm_dart/legacy.dart';
import 'package:test/test.dart';

void main() {
  group('OpenAI config layering', () {
    test('applies config voice to TTS request and response', () async {
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

      final llmConfig = LLMConfig(
        apiKey: 'test-key',
        baseUrl: 'https://api.openai.com/v1/',
        model: 'gpt-4o',
      ).withExtensions({
        'customDio': customDio,
      });

      final provider = OpenAIProvider(
        OpenAIConfig(
          apiKey: 'test-key',
          model: 'gpt-4o',
          voice: 'verse',
          originalConfig: llmConfig,
        ),
      );

      final response = await provider.textToSpeech(
        const TTSRequest(text: 'Hello from config voice'),
      );

      expect(capturedBody, isNotNull);
      expect(capturedBody!['voice'], equals('verse'));
      expect(response.voice, equals('verse'));
    });
  });
}
