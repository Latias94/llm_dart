import 'dart:typed_data';

import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:test/test.dart';

void main() {
  group('v3 stream part codec: file data', () {
    test('decodes byte-array file.data', () {
      final parts = decodeV3StreamParts([
        {
          'type': 'file',
          'mediaType': 'application/octet-stream',
          'data': [0, 1, 255],
        }
      ]);

      final file = parts.whereType<LLMFilePart>().single;
      expect(file.data, isA<Uint8List>());
      expect((file.data as Uint8List).toList(), [0, 1, 255]);
    });

    test('encodes byte-array file.data when configured', () {
      final parts = <LLMStreamPart>[
        LLMFilePart(
          mediaType: 'application/octet-stream',
          data: Uint8List.fromList([0, 1, 255]),
        ),
      ];

      final objects = encodeV3StreamParts(
        parts,
        fileDataEncoding: V3FileDataEncoding.bytes,
      );

      expect(objects, hasLength(1));
      expect(objects.single['type'], 'file');
      expect(objects.single['data'], [0, 1, 255]);
    });
  });
}
