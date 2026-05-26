import 'dart:io';

import 'package:test/test.dart';

import '../../tool/check_root_package_boundary_guards.dart' as guard;
import '../../tool/root_legacy_classification.dart' as classification;

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

    test('exposes the current root legacy surface classification', () {
      final keepFiles = classification.rootLegacySurfaceDecisions
          .where((decision) =>
              decision.status == classification.RootLegacySurfaceStatus.keep)
          .map((decision) => decision.rootTopLevelFile)
          .whereType<String>()
          .toSet();

      expect(
        keepFiles,
        {
          'llm_dart.dart',
          'ai.dart',
          'core.dart',
          'provider_authoring.dart',
          'transport.dart',
          'chat.dart',
        },
      );

      final removeSurfaces = classification.rootLegacySurfaceDecisions
          .where((decision) =>
              decision.status == classification.RootLegacySurfaceStatus.remove)
          .map((decision) => decision.surface)
          .toSet();

      expect(
        removeSurfaces,
        containsAll({
          'legacy barrel',
          'builder-era root directory',
          'legacy model root directory',
          'legacy provider root directory',
          'legacy root core subpaths',
          'root implementation internals',
          'root bootstrap internals',
          'root compatibility internals',
          'root config internals',
        }),
      );

      final documentSurfaces = classification.rootLegacySurfaceDecisions
          .where((decision) =>
              decision.status ==
              classification.RootLegacySurfaceStatus.document)
          .map((decision) => decision.surface)
          .toSet();

      expect(
        documentSurfaces,
        {
          'provider-facing PromptMessage input',
          'generateObject and streamObject helpers',
        },
      );
    });

    test('passes when root is only the provider-neutral facade shell',
        () async {
      final repoRoot = await _createTempRootLayout();
      addTearDown(() async {
        if (repoRoot.existsSync()) {
          await repoRoot.delete(recursive: true);
        }
      });

      final result = await guard.evaluateRootPackageBoundaryGuards(
        repoRoot: repoRoot,
      );

      expect(
        result.violations,
        isEmpty,
        reason: result.violations.join('\n'),
      );
    });

    test('reports legacy root implementation ownership if it returns',
        () async {
      final repoRoot = await _createTempRootLayout();
      addTearDown(() async {
        if (repoRoot.existsSync()) {
          await repoRoot.delete(recursive: true);
        }
      });

      await _writeFile(repoRoot, 'lib/legacy.dart', 'library;\n');
      for (final directory in const [
        'lib/builder',
        'lib/core',
        'lib/models',
        'lib/providers',
        'lib/src/bootstrap',
        'lib/src/compatibility',
        'lib/src/config',
      ]) {
        await Directory(
          '${repoRoot.path}${Platform.pathSeparator}$directory',
        ).create(recursive: true);
      }

      final result = await guard.evaluateRootPackageBoundaryGuards(
        repoRoot: repoRoot,
      );

      expect(result.passed, isFalse);
      expect(
        result.violations,
        contains(
          contains(
            'unexpected top-level directories: builder, core, models, providers, src',
          ),
        ),
      );
      expect(
        result.violations,
        contains(
            contains('unexpected top-level public entry files: legacy.dart')),
      );
      expect(
        result.violations,
        contains(
          contains(
            'lib/src/: unexpected top-level directories: bootstrap, compatibility, config',
          ),
        ),
      );
    });

    test('reports unexpected root public entry files and directories',
        () async {
      final repoRoot = await _createTempRootLayout();
      addTearDown(() async {
        if (repoRoot.existsSync()) {
          await repoRoot.delete(recursive: true);
        }
      });

      await _writeFile(repoRoot, 'lib/flutter.dart', 'library;\n');
      await Directory(
        '${repoRoot.path}${Platform.pathSeparator}lib${Platform.pathSeparator}utils',
      ).create(recursive: true);
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
          contains('unexpected top-level public entry files: flutter.dart'),
        ),
      );
      expect(
        result.violations,
        contains(
          contains('lib/: unexpected top-level directories: src, utils'),
        ),
      );
      expect(
        result.violations,
        contains(
          contains('lib/src/: unexpected top-level directories: runtime'),
        ),
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
library;

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
            'only lib/chat.dart may import or export package:llm_dart_chat/...',
          ),
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
export 'openai.dart';
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

export 'package:llm_dart_ai/app.dart';
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
          contains('modern aggregator entrypoint must only compose the stable'),
        ),
      );
    });

    test('reports deleted root provider entrypoints if they return', () async {
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
            'unexpected top-level public entry files: openai.dart',
          ),
        ),
      );
    });

    test('reports widened focused core, transport, and chat entrypoints',
        () async {
      final repoRoot = await _createTempRootLayout();
      addTearDown(() async {
        if (repoRoot.existsSync()) {
          await repoRoot.delete(recursive: true);
        }
      });

      await _writeFile(
        repoRoot,
        'lib/core.dart',
        '''
library;

export 'package:llm_dart_ai/llm_dart_ai.dart';
export 'transport.dart';
''',
      );
      await _writeFile(
        repoRoot,
        'lib/transport.dart',
        '''
library;

export 'package:llm_dart_transport/llm_dart_transport.dart';
''',
      );
      await _writeFile(
        repoRoot,
        'lib/chat.dart',
        '''
library;

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
            'lib/core.dart: focused root entrypoint must only export its package-owned surface',
          ),
        ),
      );
      expect(
        result.violations,
        contains(
          contains(
            'lib/transport.dart: focused root entrypoint must only export its package-owned surface',
          ),
        ),
      );
      expect(
        result.violations,
        contains(
          contains(
            'lib/chat.dart: focused root entrypoint must only export its package-owned surface',
          ),
        ),
      );
    });

    test('reports implementation declarations in root public entrypoints',
        () async {
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

final class RootImplementation {}
''',
      );

      final result = await guard.evaluateRootPackageBoundaryGuards(
        repoRoot: repoRoot,
      );

      expect(result.passed, isFalse);
      expect(
        result.violations,
        contains(
          contains('root public entrypoints must stay as facades'),
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
        'lib/ai.dart',
        '''
library;

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
            'root package must not import or export package:llm_dart_flutter/...',
          ),
        ),
      );
    });

    test('reports legacy root subpath imports from examples', () async {
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
import 'package:llm_dart/builder/llm_builder.dart';
import 'package:llm_dart/core/capability.dart';
import 'package:llm_dart/models/chat_models.dart';
import 'package:llm_dart/providers/openai/openai.dart';

void main() {}
''',
      );

      final result = await guard.evaluateRootPackageBoundaryGuards(
        repoRoot: repoRoot,
      );

      expect(result.passed, isFalse);
      expect(
        result.violations,
        contains(contains('examples must use focused stable')),
      );
      expect(result.violations, contains(contains('legacy.dart')));
      expect(result.violations, contains(contains('builder/')));
      expect(result.violations, contains(contains('core/')));
      expect(result.violations, contains(contains('models/')));
      expect(result.violations, contains(contains('providers/')));
    });
  });
}

Future<Directory> _createTempRootLayout() async {
  final repoRoot = await Directory.systemTemp.createTemp(
    'llm_dart_root_boundary_guards_',
  );

  await Directory(
    '${repoRoot.path}${Platform.pathSeparator}lib',
  ).create(recursive: true);

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

export 'core.dart';
export 'transport.dart';
''',
  );

  await _writeFile(
    repoRoot,
    'lib/core.dart',
    '''
library;

export 'package:llm_dart_ai/app.dart';
''',
  );

  await _writeFile(
    repoRoot,
    'lib/provider_authoring.dart',
    '''
library;

export 'package:llm_dart_ai/provider_authoring.dart';
''',
  );

  await _writeFile(
    repoRoot,
    'lib/transport.dart',
    '''
library;

export 'core.dart';
export 'package:llm_dart_transport/llm_dart_transport.dart';
''',
  );

  await _writeFile(
    repoRoot,
    'lib/chat.dart',
    '''
library;

export 'core.dart';
export 'transport.dart';
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
