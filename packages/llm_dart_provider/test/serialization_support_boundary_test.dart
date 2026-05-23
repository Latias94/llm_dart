import 'dart:io';

import 'package:test/test.dart';

void main() {
  group('serialization support boundaries', () {
    test('internal codecs do not depend on the compatibility facade', () {
      final serializationDir = Directory(
        'packages/llm_dart_provider/lib/src/serialization',
      );

      final offenders = serializationDir
          .listSync()
          .whereType<File>()
          .where((file) => file.path.endsWith('_json_codec.dart'))
          .where((file) {
            final content = file.readAsStringSync();
            return content
                    .contains("import 'serialization_json_support.dart'") ||
                content.contains('SerializationJsonSupport.');
          })
          .map((file) => file.path.replaceAll(r'\', '/'))
          .toList()
        ..sort();

      expect(offenders, isEmpty);
    });
  });
}
