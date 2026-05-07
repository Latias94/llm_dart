import 'dart:io';

import '../../tool/check_root_package_boundary_guards.dart' as guard;
import 'package:test/test.dart';

void main() {
  group('check_root_package_boundary_guards', () {
    test('passes against the current repository root package', () async {
      final result = await guard.evaluateRootPackageBoundaryGuards(
        repoRoot: Directory.current,
      );

      expect(
        result.violations,
        isEmpty,
        reason: result.violations.join('\n'),
      );
    });

    test('reports unexpected root public entry files and src directories',
        () async {
      final repoRoot = await _createTempRootLayout();
      addTearDown(() async {
        if (repoRoot.existsSync()) {
          await repoRoot.delete(recursive: true);
        }
      });

      await _writeFile(
        repoRoot,
        'lib/flutter.dart',
        'library;\n',
      );
      await Directory(
        '${repoRoot.path}${Platform.pathSeparator}lib${Platform.pathSeparator}src${Platform.pathSeparator}runtime',
      ).create(recursive: true);

      final result = await guard.evaluateRootPackageBoundaryGuards(
        repoRoot: repoRoot,
      );

      expect(result.passed, isFalse);
      expect(
        result.violations,
        contains(
            contains('unexpected top-level public entry files: flutter.dart')),
      );
      expect(
        result.violations,
        contains(
            contains('lib/src/: unexpected top-level directories: runtime')),
      );
    });

    test('reports chat package imports outside lib/chat.dart', () async {
      final repoRoot = await _createTempRootLayout();
      addTearDown(() async {
        if (repoRoot.existsSync()) {
          await repoRoot.delete(recursive: true);
        }
      });

      await _writeFile(
        repoRoot,
        'lib/ai.dart',
        '''
export 'package:llm_dart_chat/llm_dart_chat.dart';
''',
      );

      final result = await guard.evaluateRootPackageBoundaryGuards(
        repoRoot: repoRoot,
      );

      expect(result.passed, isFalse);
      expect(
        result.violations,
        contains(
          contains(
              'only lib/chat.dart may import or export package:llm_dart_chat/...'),
        ),
      );
    });

    test('reports widened default root entrypoint', () async {
      final repoRoot = await _createTempRootLayout();
      addTearDown(() async {
        if (repoRoot.existsSync()) {
          await repoRoot.delete(recursive: true);
        }
      });

      await _writeFile(
        repoRoot,
        'lib/llm_dart.dart',
        '''
library;

export 'ai.dart';
export 'legacy.dart';
''',
      );

      final result = await guard.evaluateRootPackageBoundaryGuards(
        repoRoot: repoRoot,
      );

      expect(result.passed, isFalse);
      expect(
        result.violations,
        contains(
          contains('default root entrypoint must only export ai.dart'),
        ),
      );
    });

    test('reports widened modern aggregator entrypoint', () async {
      final repoRoot = await _createTempRootLayout();
      addTearDown(() async {
        if (repoRoot.existsSync()) {
          await repoRoot.delete(recursive: true);
        }
      });

      await _writeFile(
        repoRoot,
        'lib/ai.dart',
        '''
library;

export 'package:llm_dart_ai/llm_dart_ai.dart';
export 'builder/llm_builder.dart';
''',
      );

      final result = await guard.evaluateRootPackageBoundaryGuards(
        repoRoot: repoRoot,
      );

      expect(result.passed, isFalse);
      expect(
        result.violations,
        contains(
          contains('modern aggregator entrypoint must only compose stable'),
        ),
      );
    });

    test('reports widened focused provider entrypoints', () async {
      final repoRoot = await _createTempRootLayout();
      addTearDown(() async {
        if (repoRoot.existsSync()) {
          await repoRoot.delete(recursive: true);
        }
      });

      await _writeFile(
        repoRoot,
        'lib/openai.dart',
        '''
library;

export 'package:llm_dart_openai/llm_dart_openai.dart';
export 'providers/openai/openai.dart';
''',
      );

      final result = await guard.evaluateRootPackageBoundaryGuards(
        repoRoot: repoRoot,
      );

      expect(result.passed, isFalse);
      expect(
        result.violations,
        contains(
          contains(
              'focused root entrypoint must only export its package-owned surface'),
        ),
      );
    });

    test('reports any root import of llm_dart_flutter', () async {
      final repoRoot = await _createTempRootLayout();
      addTearDown(() async {
        if (repoRoot.existsSync()) {
          await repoRoot.delete(recursive: true);
        }
      });

      await _writeFile(
        repoRoot,
        'lib/legacy.dart',
        '''
export 'package:llm_dart_flutter/llm_dart_flutter.dart';
''',
      );

      final result = await guard.evaluateRootPackageBoundaryGuards(
        repoRoot: repoRoot,
      );

      expect(result.passed, isFalse);
      expect(
        result.violations,
        contains(
          contains(
              'root package must not import or export package:llm_dart_flutter/...'),
        ),
      );
    });

    test('reports legacy imports from examples', () async {
      final repoRoot = await _createTempRootLayout();
      addTearDown(() async {
        if (repoRoot.existsSync()) {
          await repoRoot.delete(recursive: true);
        }
      });

      await _writeFile(
        repoRoot,
        'example/02_core_features/legacy_builder_demo.dart',
        '''
import 'package:llm_dart/legacy.dart';

void main() {}
''',
      );

      final result = await guard.evaluateRootPackageBoundaryGuards(
        repoRoot: repoRoot,
      );

      expect(result.passed, isFalse);
      expect(
        result.violations,
        contains(
          contains('examples must use focused stable'),
        ),
      );
    });
  });
}

Future<Directory> _createTempRootLayout() async {
  final repoRoot = await Directory.systemTemp.createTemp(
    'llm_dart_root_boundary_guards_',
  );

  for (final directory in const [
    'lib/builder',
    'lib/core',
    'lib/models',
    'lib/providers',
    'lib/src',
    'lib/utils',
    'lib/src/bootstrap',
    'lib/src/compatibility',
    'lib/src/config',
    'lib/src/facade',
  ]) {
    await Directory(
      '${repoRoot.path}${Platform.pathSeparator}$directory',
    ).create(recursive: true);
  }

  for (final file in const [
    'lib/ai.dart',
    'lib/anthropic.dart',
    'lib/chat.dart',
    'lib/core.dart',
    'lib/google.dart',
    'lib/legacy.dart',
    'lib/llm_dart.dart',
    'lib/openai.dart',
    'lib/transport.dart',
  ]) {
    await _writeFile(repoRoot, file, 'library;\n');
  }

  await _writeFile(
    repoRoot,
    'lib/llm_dart.dart',
    '''
library;

export 'ai.dart';
''',
  );

  await _writeFile(
    repoRoot,
    'lib/ai.dart',
    '''
library;

export 'package:llm_dart_ai/llm_dart_ai.dart';

export 'anthropic.dart';
export 'core.dart';
export 'google.dart';
export 'openai.dart';
export 'transport.dart';
export 'src/facade/ai.dart' show AI;
''',
  );

  await _writeFile(
    repoRoot,
    'lib/anthropic.dart',
    '''
library;

export 'package:llm_dart_anthropic/llm_dart_anthropic.dart';
''',
  );

  await _writeFile(
    repoRoot,
    'lib/google.dart',
    '''
library;

export 'package:llm_dart_google/llm_dart_google.dart';
''',
  );

  await _writeFile(
    repoRoot,
    'lib/openai.dart',
    '''
library;

export 'package:llm_dart_openai/llm_dart_openai.dart';
''',
  );

  await _writeFile(
    repoRoot,
    'lib/chat.dart',
    '''
export 'package:llm_dart_chat/llm_dart_chat.dart';
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
