import 'package:llm_dart_provider/llm_dart_provider.dart';
import 'package:test/test.dart';

void main() {
  group('ModelError', () {
    test('normalizes provider payload maps into structured errors', () {
      final error = ModelError.fromUnknown(
        {
          'type': 'server_error',
          'message': 'upstream failed',
          'statusCode': 503,
          'retryable': true,
        },
        kind: ModelErrorKind.provider,
      );

      expect(error.kind, ModelErrorKind.provider);
      expect(error.code, 'server_error');
      expect(error.message, 'upstream failed');
      expect(error.statusCode, 503);
      expect(error.isRetryable, isTrue);
      expect(
        error.details,
        {
          'type': 'server_error',
          'message': 'upstream failed',
          'statusCode': 503,
          'retryable': true,
        },
      );
    });

    test('freezes normalized structured details', () {
      final error = ModelError.fromUnknown(
        const FormatException(
          'Invalid JSON payload.',
          {
            'nested': [
              {'value': 1},
            ],
          },
          3,
        ),
      );

      final details = error.details as Map<String, Object?>;
      final source = details['source'] as Map<String, Object?>;
      final nested = source['nested'] as List<Object?>;
      final nestedMap = nested.single as Map<String, Object?>;

      expect(error.kind, ModelErrorKind.validation);
      expect(details['offset'], 3);
      expect(() => details['extra'] = true, throwsUnsupportedError);
      expect(() => source['extra'] = true, throwsUnsupportedError);
      expect(() => nested.add('extra'), throwsUnsupportedError);
      expect(() => nestedMap['extra'] = true, throwsUnsupportedError);
    });

    test('falls back to string details for non-json values', () {
      final error = ModelError.fromUnknown(
        'failed',
        details: Object(),
      );

      expect(error.details, startsWith('Instance of'));
    });

    test('deep equality and hash ignore map insertion order', () {
      const left = ModelError(
        kind: ModelErrorKind.provider,
        message: 'failed',
        details: {
          'b': 2,
          'a': [
            {'x': true},
          ],
        },
      );
      const right = ModelError(
        kind: ModelErrorKind.provider,
        message: 'failed',
        details: {
          'a': [
            {'x': true},
          ],
          'b': 2,
        },
      );

      expect(left, right);
      expect(left.hashCode, right.hashCode);
    });

    test('round-trips the current serialized error shape', () {
      const error = ModelError(
        kind: ModelErrorKind.transport,
        message: 'backend failed',
        code: 'transport_error',
        statusCode: 503,
        isRetryable: true,
        details: {
          'retryAfter': 3,
        },
        originalType: 'TransportHttpException',
      );

      expect(ModelError.fromJson(error.toJsonMap()), error);
    });
  });
}
