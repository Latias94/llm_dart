import 'package:llm_dart/legacy.dart';
import 'package:llm_dart_transport/dio.dart';
import 'package:test/test.dart';

void main() {
  group('OpenAI provider support extraction', () {
    test('checkModel preserves lightweight validation request', () async {
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
                data: {
                  'id': 'chatcmpl_support_1',
                  'choices': [
                    {
                      'message': {
                        'role': 'assistant',
                        'content': 'ok',
                      },
                    },
                  ],
                },
              ),
            );
          },
        ),
      );

      final provider = _buildProvider(customDio);
      final result = await provider.checkModel();

      expect(result.valid, isTrue);
      expect(result.error, isNull);
      expect(capturedBody, isNotNull);
      expect(capturedBody!['model'], equals('gpt-4o'));
      expect(capturedBody!['stream'], isFalse);
      expect(capturedBody!['max_tokens'], equals(1));
    });

    test('generateSuggestions returns parsed questions from helper prompt',
        () async {
      int requestCount = 0;

      final customDio = Dio();
      customDio.options.baseUrl = 'https://api.openai.com/v1/';
      customDio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            requestCount += 1;
            handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                data: {
                  'id': 'chatcmpl_support_2',
                  'choices': [
                    {
                      'message': {
                        'role': 'assistant',
                        'content': '''
1. What timeline should we target?
- Who are the main users?
Can we reuse the current API?
This line is not a question
• What risks matter most?
Should we phase the rollout?
Any final question beyond limit?
''',
                      },
                    },
                  ],
                },
              ),
            );
          },
        ),
      );

      final provider = _buildProvider(customDio);
      final suggestions = await provider.generateSuggestions([
        ChatMessage.user('Help me plan the refactor'),
      ]);

      expect(requestCount, equals(1));
      expect(
        suggestions,
        equals([
          'What timeline should we target?',
          'Who are the main users?',
          'Can we reuse the current API?',
          'What risks matter most?',
          'Should we phase the rollout?',
        ]),
      );
    });

    test('generateSuggestions short-circuits empty conversations', () async {
      int requestCount = 0;

      final customDio = Dio();
      customDio.options.baseUrl = 'https://api.openai.com/v1/';
      customDio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            requestCount += 1;
            handler.reject(
              DioException(
                requestOptions: options,
                error: StateError('Should not be called'),
              ),
            );
          },
        ),
      );

      final provider = _buildProvider(customDio);
      final suggestions = await provider.generateSuggestions(const []);

      expect(suggestions, isEmpty);
      expect(requestCount, equals(0));
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
    OpenAIConfig(
      apiKey: 'test-key',
      model: 'gpt-4o',
      originalConfig: llmConfig,
    ),
  );
}
