import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:test/test.dart';

void main() {
  group('v3 stream part codec: error raw payload', () {
    test('preserves unknown error fields on round-trip', () {
      final objects = [
        {
          'type': 'error',
          'error': {
            'name': 'ResponseFormatError',
            'message': 'oops',
            'code': 'insufficient_quota',
            'nested': {'a': 1, 'b': true},
          },
        },
      ];

      final parts = decodeV3StreamParts(objects);
      expect(parts.single, isA<LLMErrorRawPart>());

      final encoded = encodeV3StreamParts(parts);
      expect(encoded, objects);
    });

    test('decodes typed error best-effort', () {
      final parts = decodeV3StreamParts([
        {
          'type': 'error',
          'error': {
            'name': 'QuotaExceededError',
            'message': 'quota',
          },
        }
      ]);

      final error = parts.single as LLMErrorRawPart;
      expect(error.decodedError, isA<QuotaExceededError>());
    });
  });
}
