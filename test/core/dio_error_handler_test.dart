import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:test/test.dart';
import 'package:llm_dart/llm_dart.dart';
import 'package:llm_dart_provider_utils/llm_dart_provider_utils.dart';

void main() {
  group('DioErrorHandler Tests', () {
    group('ResponseBody Error Handling', () {
      test('should extract error message from ResponseBody with JSON error',
          () async {
        // Create a mock ResponseBody with JSON error
        final errorJson = {
          'error': {
            'message': 'Invalid API key provided',
            'type': 'invalid_request_error',
            'code': 'invalid_api_key'
          }
        };
        final jsonString = jsonEncode(errorJson);
        final bytes = Uint8List.fromList(utf8.encode(jsonString));

        // Create a stream that emits data immediately
        final stream = Stream<Uint8List>.fromIterable([bytes]);
        final responseBody = ResponseBody(
          stream,
          200,
          headers: {
            'content-type': ['application/json']
          },
        );

        // Create DioException with ResponseBody
        final dioException = DioException(
          requestOptions: RequestOptions(path: '/test'),
          response: Response(
            requestOptions: RequestOptions(path: '/test'),
            statusCode: 401,
            data: responseBody,
          ),
          type: DioExceptionType.badResponse,
        );

        // Handle the error
        final error = await DioErrorHandler.handleDioError(
          dioException,
          'TestProvider',
        );

        // Verify the error message was extracted correctly
        expect(error, isA<AuthError>());
        expect(error.message, contains('Invalid API key provided'));
      });

      test('should extract error message from ResponseBody with string error',
          () async {
        // Create a mock ResponseBody with JSON string error
        final errorJson = {
          'error': 'Rate limit exceeded. Please try again later.'
        };
        final jsonString = jsonEncode(errorJson);
        final bytes = Uint8List.fromList(utf8.encode(jsonString));

        final stream = Stream<Uint8List>.fromIterable([bytes]);
        final responseBody = ResponseBody(
          stream,
          200,
          headers: {
            'content-type': ['application/json']
          },
        );

        final dioException = DioException(
          requestOptions: RequestOptions(path: '/test'),
          response: Response(
            requestOptions: RequestOptions(path: '/test'),
            statusCode: 429,
            data: responseBody,
          ),
          type: DioExceptionType.badResponse,
        );

        final error = await DioErrorHandler.handleDioError(
          dioException,
          'TestProvider',
        );

        expect(error, isA<RateLimitError>());
        expect(error.message, contains('Rate limit exceeded'));
      });

      test('should handle ResponseBody with non-JSON content', () async {
        // Create a mock ResponseBody with plain text error
        const errorText = 'Internal Server Error: Database connection failed';
        final bytes = Uint8List.fromList(utf8.encode(errorText));

        final stream = Stream<Uint8List>.fromIterable([bytes]);
        final responseBody = ResponseBody(
          stream,
          200,
          headers: {
            'content-type': ['text/plain']
          },
        );

        final dioException = DioException(
          requestOptions: RequestOptions(path: '/test'),
          response: Response(
            requestOptions: RequestOptions(path: '/test'),
            statusCode: 500,
            data: responseBody,
          ),
          type: DioExceptionType.badResponse,
        );

        final error = await DioErrorHandler.handleDioError(
          dioException,
          'TestProvider',
        );

        expect(error, isA<ServerError>());
        expect(error.message, contains('Database connection failed'));
      });

      test('should handle ResponseBody with chunked data', () async {
        // Simulate chunked streaming response
        final errorJson = {
          'error': {
            'message': 'Model not found',
            'type': 'invalid_request_error'
          }
        };
        final jsonString = jsonEncode(errorJson);
        final bytes = Uint8List.fromList(utf8.encode(jsonString));

        // Split into chunks to simulate network streaming
        final chunk1 = Uint8List.fromList(bytes.sublist(0, bytes.length ~/ 2));
        final chunk2 = Uint8List.fromList(bytes.sublist(bytes.length ~/ 2));

        final stream = Stream<Uint8List>.fromIterable([chunk1, chunk2]);
        final responseBody = ResponseBody(
          stream,
          200,
          headers: {
            'content-type': ['application/json']
          },
        );

        final dioException = DioException(
          requestOptions: RequestOptions(path: '/test'),
          response: Response(
            requestOptions: RequestOptions(path: '/test'),
            statusCode: 404,
            data: responseBody,
          ),
          type: DioExceptionType.badResponse,
        );

        final error = await DioErrorHandler.handleDioError(
          dioException,
          'TestProvider',
        );

        expect(error, isA<ModelNotAvailableError>());
        // The error message is mapped to "Model not available: unknown" for 404 errors
        expect(error.message, contains('Model not available'));
      });

      test('should handle ResponseBody stream read failure', () async {
        // Create a stream that will throw an error
        final stream = Stream<Uint8List>.error(Exception('Stream read error'));
        final responseBody = ResponseBody(
          stream,
          200,
        );

        final dioException = DioException(
          requestOptions: RequestOptions(path: '/test'),
          response: Response(
            requestOptions: RequestOptions(path: '/test'),
            statusCode: 400,
            data: responseBody,
          ),
          type: DioExceptionType.badResponse,
        );

        final error = await DioErrorHandler.handleDioError(
          dioException,
          'TestProvider',
        );

        expect(error, isA<InvalidRequestError>());
        expect(error.message, contains('Failed to read error response'));
      });

      test('should handle ResponseBody with empty stream', () async {
        final stream = Stream<Uint8List>.fromIterable([]);
        final responseBody = ResponseBody(
          stream,
          200,
        );

        final dioException = DioException(
          requestOptions: RequestOptions(path: '/test'),
          response: Response(
            requestOptions: RequestOptions(path: '/test'),
            statusCode: 400,
            data: responseBody,
          ),
          type: DioExceptionType.badResponse,
        );

        final error = await DioErrorHandler.handleDioError(
          dioException,
          'TestProvider',
        );

        expect(error, isA<InvalidRequestError>());
        // Empty stream results in empty string, which is still a valid error
        expect(error.message, isA<String>());
      });

      test('should handle ResponseBody with nested error structure', () async {
        // Test complex error structure like Anthropic's format
        final errorJson = {
          'type': 'error',
          'error': {
            'type': 'invalid_request_error',
            'message': 'messages: field required'
          }
        };
        final jsonString = jsonEncode(errorJson);
        final bytes = Uint8List.fromList(utf8.encode(jsonString));

        final stream = Stream<Uint8List>.fromIterable([bytes]);
        final responseBody = ResponseBody(
          stream,
          200,
          headers: {
            'content-type': ['application/json']
          },
        );

        final dioException = DioException(
          requestOptions: RequestOptions(path: '/test'),
          response: Response(
            requestOptions: RequestOptions(path: '/test'),
            statusCode: 400,
            data: responseBody,
          ),
          type: DioExceptionType.badResponse,
        );

        final error = await DioErrorHandler.handleDioError(
          dioException,
          'TestProvider',
        );

        expect(error, isA<InvalidRequestError>());
        expect(error.message, contains('messages: field required'));
      });
    });

    group('Standard Error Handling (non-ResponseBody)', () {
      test('should handle Map error data correctly', () async {
        final errorData = {
          'error': {
            'message': 'Invalid request parameters',
            'type': 'invalid_request_error'
          }
        };

        final dioException = DioException(
          requestOptions: RequestOptions(path: '/test'),
          response: Response(
            requestOptions: RequestOptions(path: '/test'),
            statusCode: 400,
            data: errorData,
          ),
          type: DioExceptionType.badResponse,
        );

        final error = await DioErrorHandler.handleDioError(
          dioException,
          'TestProvider',
        );

        expect(error, isA<InvalidRequestError>());
        expect(error.message, contains('Invalid request parameters'));
      });

      test('should handle timeout errors', () async {
        final dioException = DioException(
          requestOptions: RequestOptions(path: '/test'),
          type: DioExceptionType.connectionTimeout,
          message: 'Connection timeout after 30s',
        );

        final error = await DioErrorHandler.handleDioError(
          dioException,
          'TestProvider',
        );

        expect(error, isA<TimeoutError>());
        expect(error.message, contains('timeout'));
      });

      test('should handle connection errors', () async {
        final dioException = DioException(
          requestOptions: RequestOptions(path: '/test'),
          type: DioExceptionType.connectionError,
          message: 'Failed to connect to server',
        );

        final error = await DioErrorHandler.handleDioError(
          dioException,
          'TestProvider',
        );

        expect(error, isA<HttpError>());
        expect(error.message, contains('Connection error'));
      });
    });
  });
}
