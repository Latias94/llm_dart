import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:test/test.dart';

void main() {
  group('Prompt error types (AI SDK parity)', () {
    test('decodeV3Prompt throws InvalidMessageRoleError for unknown role', () {
      expect(
        () => decodeV3Prompt([
          {
            'role': 'developer',
            'content': const [],
          },
        ]),
        throwsA(
          isA<InvalidMessageRoleError>()
              .having((e) => e.role, 'role', 'developer'),
        ),
      );
    });

    test('decodeV3Prompt throws InvalidDataContentError for invalid file.data',
        () {
      expect(
        () => decodeV3Prompt([
          {
            'role': 'user',
            'content': [
              {
                'type': 'file',
                'mediaType': 'application/pdf',
                'data': {'oops': true},
              },
            ],
          },
        ]),
        throwsA(isA<InvalidDataContentError>()),
      );
    });
  });
}
