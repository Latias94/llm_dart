import 'dart:convert';
import 'dart:typed_data';

import 'package:llm_dart/legacy.dart';
import 'package:llm_dart_transport/dio.dart';
import 'package:test/test.dart';

void main() {
  group('OpenAIClient error handling', () {
    late OpenAIClient client;

    setUp(() {
      client = OpenAIClient(
        const OpenAIConfig(
          apiKey: 'test-key',
          model: 'gpt-4o',
        ),
      );
    });

    test('preserves OpenAI type and code in mapped badResponse errors',
        () async {
      final dioException = DioException(
        requestOptions: RequestOptions(path: '/chat/completions'),
        response: Response(
          requestOptions: RequestOptions(path: '/chat/completions'),
          statusCode: 401,
          data: {
            'error': {
              'message': 'Invalid API key provided',
              'type': 'invalid_request_error',
              'code': 'invalid_api_key',
            },
          },
        ),
        type: DioExceptionType.badResponse,
      );

      final error = await client.handleDioError(dioException);

      expect(error, isA<AuthError>());
      expect(error.message, contains('Invalid API key provided'));
      expect(error.message, contains('type: invalid_request_error'));
      expect(error.message, contains('code: invalid_api_key'));
    });

    test('preserves OpenAI type and code from ResponseBody errors', () async {
      final responseBody = ResponseBody(
        Stream<Uint8List>.fromIterable([
          Uint8List.fromList(
            utf8.encode(
              jsonEncode({
                'error': {
                  'message': 'Quota exceeded',
                  'type': 'insufficient_quota',
                  'code': 'insufficient_quota',
                },
              }),
            ),
          ),
        ]),
        200,
        headers: {
          'content-type': ['application/json'],
        },
      );

      final dioException = DioException(
        requestOptions: RequestOptions(path: '/responses'),
        response: Response(
          requestOptions: RequestOptions(path: '/responses'),
          statusCode: 429,
          data: responseBody,
        ),
        type: DioExceptionType.badResponse,
      );

      final error = await client.handleDioError(dioException);

      expect(error, isA<QuotaExceededError>());
      expect(error.message, contains('Quota exceeded'));
      expect(error.message, contains('type: insufficient_quota'));
      expect(error.message, contains('code: insufficient_quota'));
    });
  });
}
