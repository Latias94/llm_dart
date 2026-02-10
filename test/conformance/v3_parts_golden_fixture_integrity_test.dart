import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

void main() {
  group('v3 parts goldens integrity', () {
    test('template meta json parses', () {
      final template = File('test/fixtures/v3_parts/_template.meta.json');
      expect(template.existsSync(), isTrue);

      final decoded = jsonDecode(template.readAsStringSync());
      expect(decoded, isA<Map>());

      final map = (decoded as Map).cast<String, dynamic>();
      expect(map['provider'], isA<String>());
      expect(map['scenario'], isA<String>());
      expect(map['description'], isA<String>());
      expect(map['assertions'], isA<Map>());
    });

    test('all .jsonl goldens parse as JSON objects with type', () {
      final dir = Directory('test/fixtures/v3_parts');
      expect(dir.existsSync(), isTrue);

      final files = dir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.jsonl'))
          .toList(growable: false);

      // It's OK if the directory is still empty early in the refactor.
      if (files.isEmpty) {
        expect(files, isEmpty);
        return;
      }

      for (final file in files) {
        final lines = file
            .readAsLinesSync()
            .map((l) => l.trim())
            .where((l) => l.isNotEmpty)
            .toList(growable: false);

        for (var i = 0; i < lines.length; i++) {
          final decoded = jsonDecode(lines[i]);
          if (decoded is! Map) {
            fail('Expected JSON object at ${file.path}:${i + 1}');
          }
          final map = decoded.cast<String, dynamic>();
          final type = map['type'];
          if (type is! String || type.isEmpty) {
            fail('Missing/invalid "type" at ${file.path}:${i + 1}');
          }
        }
      }
    });
  });
}
