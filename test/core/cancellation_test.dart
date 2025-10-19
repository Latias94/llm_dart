import 'package:dio/dio.dart';
import 'package:llm_dart/core/cancellation.dart';
import 'package:llm_dart/core/llm_error.dart';
import 'package:test/test.dart';

/// Tests for cancellation support
///
/// These tests verify the cancellation infrastructure works correctly
/// for all types of operations (chat, streaming, embeddings, audio).
void main() {
  group('CancelToken', () {
    test('can be created', () {
      final token = CancelToken();
      expect(token, isNotNull);
      expect(token.isCancelled, isFalse);
    });

    test('can be cancelled', () {
      final token = CancelToken();
      token.cancel('Test cancellation');
      expect(token.isCancelled, isTrue);
    });

    test('can be cancelled without reason', () {
      final token = CancelToken();
      token.cancel();
      expect(token.isCancelled, isTrue);
    });

    test('calling cancel multiple times is safe', () {
      final token = CancelToken();
      token.cancel('First');
      token.cancel('Second'); // Should not throw
      expect(token.isCancelled, isTrue);
    });
  });

  group('CancellationHelper', () {
    test('isCancelled detects CancelledError', () {
      final error = CancelledError('User cancelled');
      expect(CancellationHelper.isCancelled(error), isTrue);
    });

    test('isCancelled detects DioException cancellation errors', () {
      final error = DioException(
        requestOptions: RequestOptions(path: '/test'),
        type: DioExceptionType.cancel,
      );
      expect(CancellationHelper.isCancelled(error), isTrue);
    });

    test('isCancelled returns false for non-cancel errors', () {
      final error = DioException(
        requestOptions: RequestOptions(path: '/test'),
        type: DioExceptionType.connectionTimeout,
      );
      expect(CancellationHelper.isCancelled(error), isFalse);
    });

    test('isCancelled returns false for non-DioException errors', () {
      final error = Exception('Some other error');
      expect(CancellationHelper.isCancelled(error), isFalse);
    });

    test('getCancellationReason extracts reason from CancelledError', () {
      final error = CancelledError('User cancelled');
      expect(
        CancellationHelper.getCancellationReason(error),
        equals('User cancelled'),
      );
    });

    test('getCancellationReason extracts reason from DioException cancel error',
        () {
      final error = DioException(
        requestOptions: RequestOptions(path: '/test'),
        type: DioExceptionType.cancel,
        message: 'User cancelled',
      );
      expect(
        CancellationHelper.getCancellationReason(error),
        equals('User cancelled'),
      );
    });

    test('getCancellationReason returns null for non-cancel errors', () {
      final error = DioException(
        requestOptions: RequestOptions(path: '/test'),
        type: DioExceptionType.connectionTimeout,
        message: 'Timeout',
      );
      expect(CancellationHelper.getCancellationReason(error), isNull);
    });

    test('getCancellationReason returns null for non-DioException', () {
      final error = Exception('Some error');
      expect(CancellationHelper.getCancellationReason(error), isNull);
    });
  });

  group('CancelledError', () {
    test('can be created with default message', () {
      final error = CancelledError();
      expect(error, isA<LLMError>());
      expect(error.message, equals('Request cancelled'));
      expect(error.toString(), equals('Request cancelled: Request cancelled'));
    });

    test('can be created with custom message', () {
      final error = CancelledError('User cancelled operation');
      expect(error.message, equals('User cancelled operation'));
      expect(
        error.toString(),
        equals('Request cancelled: User cancelled operation'),
      );
    });

    test('is recognized by CancellationHelper', () {
      final error = CancelledError('Test cancellation');
      expect(CancellationHelper.isCancelled(error), isTrue);
      expect(
        CancellationHelper.getCancellationReason(error),
        equals('Test cancellation'),
      );
    });
  });

  group('CancelToken usage patterns', () {
    test('same token can be shared across operations', () {
      final sharedToken = CancelToken();

      // This token could be used for multiple operations
      expect(sharedToken.isCancelled, isFalse);

      // Cancel affects all operations using this token
      sharedToken.cancel('Cancel all');
      expect(sharedToken.isCancelled, isTrue);
    });

    test('different tokens are independent', () {
      final token1 = CancelToken();
      final token2 = CancelToken();

      token1.cancel('Cancel first');

      expect(token1.isCancelled, isTrue);
      expect(token2.isCancelled, isFalse);
    });

    test('CancelToken.isCancel static method works', () {
      final cancelError = DioException(
        requestOptions: RequestOptions(path: '/test'),
        type: DioExceptionType.cancel,
      );
      final otherError = DioException(
        requestOptions: RequestOptions(path: '/test'),
        type: DioExceptionType.badResponse,
      );

      expect(CancelToken.isCancel(cancelError), isTrue);
      expect(CancelToken.isCancel(otherError), isFalse);
    });
  });
}
