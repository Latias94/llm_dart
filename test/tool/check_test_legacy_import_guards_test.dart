import 'dart:io';

import '../../tool/check_test_legacy_import_guards.dart' as guard;
import 'package:test/test.dart';

void main() {
  group('check_test_legacy_import_guards', () {
    test('passes against current foundational test directories', () async {
      final result = await guard.evaluateTestLegacyImportGuards(
        repoRoot: Directory.current,
      );

      expect(
        result.violations,
        isEmpty,
        reason: result.violations.join('\n'),
      );
    });

    test('reports legacy imports inside guarded test directories', () async {
      final repoRoot = await _createTempWorkspace();
      addTearDown(() async {
        if (repoRoot.existsSync()) {
          await repoRoot.delete(recursive: true);
        }
      });

      await _writeFile(
        repoRoot,
        'test/core/example_test.dart',
        '''
import 'package:llm_dart/legacy.dart';

void main() {}
''',
      );

      final result = await guard.evaluateTestLegacyImportGuards(
        repoRoot: repoRoot,
      );

      expect(result.passed, isFalse);
      expect(
        result.violations,
        contains(
          contains('foundational tests must import focused entrypoints'),
        ),
      );
    });

    test('allows explicit compatibility tests outside guarded directories',
        () async {
      final repoRoot = await _createTempWorkspace();
      addTearDown(() async {
        if (repoRoot.existsSync()) {
          await repoRoot.delete(recursive: true);
        }
      });

      await _writeFile(
        repoRoot,
        'test/providers/openai/example_test.dart',
        '''
import 'package:llm_dart/legacy.dart' as legacy;

void main() {}
''',
      );

      final result = await guard.evaluateTestLegacyImportGuards(
        repoRoot: repoRoot,
      );

      expect(
        result.violations,
        isEmpty,
        reason: result.violations.join('\n'),
      );
    });
  });
}

Future<Directory> _createTempWorkspace() async {
  final repoRoot = await Directory.systemTemp.createTemp(
    'llm_dart_test_legacy_import_guard_',
  );

  await _writeFile(
    repoRoot,
    'test/core/focused_test.dart',
    '''
import 'package:llm_dart/core/config.dart';

void main() {}
''',
  );

  return repoRoot;
}

Future<void> _writeFile(
  Directory repoRoot,
  String relativePath,
  String content,
) async {
  final file = File('${repoRoot.path}${Platform.pathSeparator}$relativePath');
  await file.parent.create(recursive: true);
  await file.writeAsString(content);
}
