import 'package:llm_dart_transport/llm_dart_transport.dart';
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
}
