import 'package:llm_dart_provider/llm_dart_provider.dart';
import 'package:test/test.dart';

void main() {
  group('PromptJsonCodec', () {
    test('rejects unsupported schema versions', () {
      const codec = PromptJsonCodec();

      expect(
        () => codec.decodeMessages({
          'schemaVersion': '2099-01-1',
          'kind': PromptJsonCodec.envelopeKind,
          'data': {
            'messages': const [],
          },
        }),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            contains('Unsupported llm_dart JSON schema version "2099-01-1"'),
          ),
        ),
      );
    });
  });
}
