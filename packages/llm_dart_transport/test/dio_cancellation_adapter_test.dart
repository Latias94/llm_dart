import 'package:llm_dart_transport/llm_dart_transport.dart';
import 'package:dio/dio.dart';
import 'package:test/test.dart';

void main() {
  group('bindDioCancellation', () {
    test('returns null when cancellation is absent', () {
      expect(bindDioCancellation(null), isNull);
    });

    test('cancels the Dio token when transport cancellation fires', () async {
      final cancellation = TransportCancellation();
      final cancelToken = bindDioCancellation(cancellation);

      expect(cancelToken, isNotNull);
      expect(cancelToken!.isCancelled, isFalse);

      cancellation.cancel('stop');
      await cancellation.whenCancelled;
      await Future<void>.delayed(Duration.zero);

      expect(cancelToken.isCancelled, isTrue);
      expect(cancelToken.cancelError, isA<Object>());
      expect(cancelToken.cancelError.toString(), contains('stop'));
    });
  });

  group('dio cancellation helpers', () {
    test('detects Dio cancellation exceptions', () {
      final error = DioException(
        requestOptions: RequestOptions(path: '/test'),
        type: DioExceptionType.cancel,
        message: 'user cancelled',
      );

      expect(isDioCancellationError(error), isTrue);
      expect(getDioCancellationReason(error), 'user cancelled');
    });

    test('ignores non-cancellation Dio exceptions', () {
      final error = DioException(
        requestOptions: RequestOptions(path: '/test'),
        type: DioExceptionType.connectionTimeout,
        message: 'timeout',
      );

      expect(isDioCancellationError(error), isFalse);
      expect(getDioCancellationReason(error), isNull);
    });
  });
}
