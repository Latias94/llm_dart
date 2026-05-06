import 'package:llm_dart/core/llm_error.dart';
import 'package:llm_dart/providers/deepseek/deepseek.dart';
import 'package:llm_dart_transport/dio.dart';
import 'package:test/test.dart';

void main() {
  group('DeepSeekClient error handling', () {
    test('postJson uses DeepSeek-specific error mapping', () async {
      final client = DeepSeekClient(
        const DeepSeekConfig(
          apiKey: 'test-key',
          model: 'deepseek-chat',
        ),
      );

      client.dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 402,
                data: {
                  'error': {
                    'message': 'Insufficient balance',
                  },
                },
              ),
            );
          },
        ),
      );

      expect(
        () => client.postJson(
          'chat/completions',
          const {
            'model': 'deepseek-chat',
            'messages': [],
          },
        ),
        throwsA(
          isA<QuotaExceededError>().having(
            (error) => error.message,
            'message',
            contains('Please top up your DeepSeek account'),
          ),
        ),
      );
    });
  });
}
