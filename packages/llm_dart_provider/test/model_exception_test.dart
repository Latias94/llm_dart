import 'package:llm_dart_provider/llm_dart_provider.dart';
import 'package:test/test.dart';

void main() {
  group('ModelException', () {
    test('projects typed model exceptions into serializable model errors', () {
      const exception = ModelException(
        kind: ModelErrorKind.provider,
        message: 'provider rejected the request',
        code: 'provider-bad-request',
        statusCode: 400,
        isRetryable: false,
        details: {
          'provider': 'test',
        },
      );

      final error = modelErrorFrom(exception);

      expect(error.kind, ModelErrorKind.provider);
      expect(error.message, 'provider rejected the request');
      expect(error.code, 'provider-bad-request');
      expect(error.statusCode, 400);
      expect(error.isRetryable, isFalse);
      expect(error.details, {'provider': 'test'});
      expect(error.originalType, 'ModelException');
    });

    test('wraps validation failures with typed context', () {
      final exception = ModelException.validation(
        message: 'Invalid response data.',
        code: 'invalid-response-data',
        details: {
          'path': r'$.choices[0]',
        },
      );

      final error = modelErrorFrom(exception);

      expect(error.kind, ModelErrorKind.validation);
      expect(error.message, 'Invalid response data.');
      expect(error.code, 'invalid-response-data');
      expect(error.details, {'path': r'$.choices[0]'});
    });
  });
}
