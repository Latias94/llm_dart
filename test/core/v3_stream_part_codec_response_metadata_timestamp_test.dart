import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:test/test.dart';

void main() {
  group('v3 stream part codec: response-metadata timestamp', () {
    test('accepts epoch milliseconds number', () {
      final parts = decodeV3StreamParts([
        {
          'type': 'response-metadata',
          'timestamp': 1700000000000,
        }
      ]);

      final meta = parts.whereType<LLMResponseMetadataPart>().single;
      expect(meta.timestamp, isNotNull);
      expect(meta.timestamp!.toUtc().millisecondsSinceEpoch, 1700000000000);
    });

    test('accepts epoch seconds number', () {
      final parts = decodeV3StreamParts([
        {
          'type': 'response-metadata',
          'timestamp': 1700000000,
        }
      ]);

      final meta = parts.whereType<LLMResponseMetadataPart>().single;
      expect(meta.timestamp, isNotNull);
      expect(meta.timestamp!.toUtc().millisecondsSinceEpoch, 1700000000000);
    });
  });
}
