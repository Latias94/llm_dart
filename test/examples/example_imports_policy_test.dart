import 'dart:io';

import 'package:test/test.dart';

void main() {
  group('Example imports policy', () {
    test('examples must not import non-stable entrypoints', () {
      final exampleDir = Directory('example');
      if (!exampleDir.existsSync()) {
        fail('Expected `example/` directory to exist.');
      }

      final dartFiles = exampleDir
          .listSync(recursive: true, followLinks: false)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))
          .toList(growable: false);

      final violations = <String>[];

      for (final file in dartFiles) {
        final relPath = file.path;
        final lines = file.readAsLinesSync();
        for (var i = 0; i < lines.length; i++) {
          final line = lines[i];

          // Strongly discourage examples from importing implementation details.
          if (line.contains("package:llm_dart_") && line.contains('/src/')) {
            violations.add('$relPath:${i + 1}: $line');
          }

          // `testing.dart` is explicitly not a stable API surface and should not
          // be used in examples that users may copy into production code.
          if (line.contains("package:llm_dart_") &&
              line.contains('/testing.dart')) {
            violations.add('$relPath:${i + 1}: $line');
          }
        }
      }

      if (violations.isNotEmpty) {
        fail(
          'Found non-stable imports in examples:\n'
          '${violations.join('\n')}\n\n'
          'Use package entrypoints (e.g. `llm_dart_google.dart`) or the explicit '
          '`protocol.dart` entrypoint when low-level access is required.',
        );
      }
    });
  });
}
