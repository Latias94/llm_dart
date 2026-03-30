import 'package:llm_dart_core/llm_dart_core.dart';
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

    test('classifies format exceptions as validation errors', () {
      final error = ModelError.fromUnknown(
        const FormatException('Invalid JSON payload.'),
      );

      expect(error.kind, ModelErrorKind.validation);
      expect(error.message, 'Invalid JSON payload.');
      expect(error.originalType, 'FormatException');
    });

    test('decodes legacy serialized error payloads', () {
      final error = ModelError.fromJson({
        'type': 'legacy_error',
        'message': 'legacy failure',
      });

      expect(error.kind, ModelErrorKind.unknown);
      expect(error.code, 'legacy_error');
      expect(error.message, 'legacy failure');
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

      final decoded = ModelError.fromJson(error.toJsonMap());

      expect(decoded, error);
    });
  });
}
