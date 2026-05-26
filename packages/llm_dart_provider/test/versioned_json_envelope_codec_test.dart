import 'package:llm_dart_provider/llm_dart_provider.dart';
import 'package:test/test.dart';

void main() {
  group('VersionedJsonEnvelopeCodec', () {
    test('encodes and decodes schema-versioned envelopes', () {
      const codec = VersionedJsonEnvelopeCodec();

      final encoded = codec.encode(
        kind: 'test-kind',
        data: const {'value': 1},
      );

      expect(encoded['schemaVersion'], llmDartJsonSchemaVersion);
      expect(encoded['kind'], 'test-kind');
      expect(
        codec.decode(encoded, expectedKind: 'test-kind'),
        {'value': 1},
      );
    });

    test('keeps caller-owned schema version diagnostics', () {
      const codec = VersionedJsonEnvelopeCodec(
        unsupportedSchemaVersionDescription: 'custom schema version',
      );

      expect(
        () => codec.decode(
          const {
            'schemaVersion': '2099-01-1',
            'kind': 'test-kind',
            'data': {},
          },
          expectedKind: 'test-kind',
        ),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            contains('Unsupported custom schema version "2099-01-1"'),
          ),
        ),
      );
    });
  });
}
