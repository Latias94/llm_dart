import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:test/test.dart';

/// Tests for cancellation support
///
/// These tests verify the cancellation infrastructure works correctly
/// for all types of operations (chat, streaming, embeddings, audio).
void main() {
  group('CancellationHelper', () {
    test('isCancelled detects CancelledError', () {
      final error = CancelledError('User cancelled');
      expect(CancellationHelper.isCancelled(error), isTrue);
    });

    test('isCancelled returns false for non-cancel errors', () {
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

    test('getCancellationReason returns null for non-cancel errors', () {
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

  group('CancellationTokenSource & CancellationToken', () {
    test('token reflects cancellation state', () {
      final source = CancellationTokenSource();
      final token = source.token;

      expect(token.isCancellationRequested, isFalse);
      expect(token.reason, isNull);

      source.cancel('Test cancellation');

      expect(token.isCancellationRequested, isTrue);
      expect(token.reason, equals('Test cancellation'));
    });

    test('callbacks are invoked on cancel', () async {
      final source = CancellationTokenSource();
      final token = source.token;

      String? capturedReason;
      token.onCancelled((reason) {
        capturedReason = reason;
      });

      source.cancel('Callback reason');

      expect(capturedReason, equals('Callback reason'));
    });

    test('callbacks fire immediately when already cancelled', () {
      final source = CancellationTokenSource();
      source.cancel('Early cancel');

      final token = source.token;
      String? capturedReason;
      token.onCancelled((reason) {
        capturedReason = reason;
      });

      expect(capturedReason, equals('Early cancel'));
    });
  });
}
