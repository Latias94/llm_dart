import 'package:test/test.dart';
import 'package:llm_dart/llm_dart.dart';

void main() {
  group('Error Handling Tests', () {
    group('LLMError Base Class', () {
      test('should create error with message', () {
        final error = GenericError('Test error message');
        expect(error.message, equals('Test error message'));
        expect(error.toString(), equals('Test error message'));
      });
    });

    group('HttpError', () {
      test('should create and format correctly', () {
        final error = HttpError('Connection failed');
        expect(error.message, equals('Connection failed'));
        expect(error.toString(), equals('HTTP error: Connection failed'));
        expect(error, isA<LLMError>());
      });
    });

    group('AuthError', () {
      test('should create and format correctly', () {
        final error = AuthError('Invalid API key');
        expect(error.message, equals('Invalid API key'));
        expect(
            error.toString(), equals('Authentication error: Invalid API key'));
        expect(error, isA<LLMError>());
      });
    });

    group('ProviderError', () {
      test('should create and format correctly', () {
        final error = ProviderError('Model not found');
        expect(error.message, equals('Model not found'));
        expect(error.toString(), equals('Provider error: Model not found'));
        expect(error, isA<LLMError>());
      });
    });

    group('InvalidRequestError', () {
      test('should create and format correctly', () {
        final error = InvalidRequestError('Invalid parameters');
        expect(error.message, equals('Invalid parameters'));
        expect(error.toString(), equals('Invalid request: Invalid parameters'));
        expect(error, isA<LLMError>());
      });
    });

    group('RateLimitError', () {
      test('should create and format correctly', () {
        final error = RateLimitError('Rate limit exceeded');
        expect(error.message, equals('Rate limit exceeded'));
        expect(error.toString(),
            equals('Rate limit exceeded: Rate limit exceeded'));
        expect(error, isA<LLMError>());
      });
    });

    group('UnsupportedCapabilityError', () {
      test('should create and format correctly', () {
        final error = UnsupportedCapabilityError('Audio not supported');
        expect(error.message, equals('Audio not supported'));
        expect(error.toString(),
            equals('Unsupported capability: Audio not supported'));
        expect(error, isA<LLMError>());
      });
    });

    group('GenericError', () {
      test('should create and format correctly', () {
        final error = GenericError('Something went wrong');
        expect(error.message, equals('Something went wrong'));
        expect(error.toString(), equals('Something went wrong'));
        expect(error, isA<LLMError>());
      });
    });

    group('TimeoutError', () {
      test('should create and format correctly', () {
        final error = TimeoutError('Request timed out');
        expect(error.message, equals('Request timed out'));
        expect(error.toString(), equals('Request timeout: Request timed out'));
        expect(error, isA<LLMError>());
      });
    });

    group('NotFoundError', () {
      test('should create and format correctly', () {
        final error = NotFoundError('Resource not found');
        expect(error.message, equals('Resource not found'));
        expect(
            error.toString(), equals('Resource not found: Resource not found'));
        expect(error, isA<LLMError>());
      });
    });

    group('JsonError', () {
      test('should create and format correctly', () {
        final error = JsonError('Invalid JSON format');
        expect(error.message, equals('Invalid JSON format'));
        expect(error.toString(),
            equals('JSON parsing error: Invalid JSON format'));
        expect(error, isA<LLMError>());
      });
    });

    group('Error Hierarchy', () {
      test('all errors should extend LLMError', () {
        final errors = [
          HttpError('test'),
          AuthError('test'),
          ProviderError('test'),
          InvalidRequestError('test'),
          RateLimitError('test'),
          UnsupportedCapabilityError('test'),
          GenericError('test'),
          TimeoutError('test'),
          NotFoundError('test'),
          JsonError('test'),
        ];

        for (final error in errors) {
          expect(error, isA<LLMError>());
          expect(error, isA<Exception>());
        }
      });

      test('errors should be catchable as LLMError', () {
        void throwError() {
          throw AuthError('Test auth error');
        }

        expect(() => throwError(), throwsA(isA<LLMError>()));
        expect(() => throwError(), throwsA(isA<AuthError>()));

        try {
          throwError();
        } on LLMError catch (e) {
          expect(e, isA<AuthError>());
          expect(e.message, equals('Test auth error'));
        }
      });
    });
  });
}
