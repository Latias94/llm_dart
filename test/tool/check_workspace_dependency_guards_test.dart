import 'dart:io';

import '../../tool/check_workspace_dependency_guards.dart' as guard;
import 'package:test/test.dart';

void main() {
  group('check_workspace_dependency_guards', () {
    test('passes against the current repository workspace', () async {
      final result = await guard.evaluateWorkspaceDependencyGuards(
        repoRoot: Directory.current,
      );

      expect(
        result.violations,
        isEmpty,
        reason: result.violations.join('\n'),
      );
    });

    test('reports package implementation imports from the root package',
        () async {
      final repoRoot = await _createTempWorkspace();
      addTearDown(() async {
        if (repoRoot.existsSync()) {
          await repoRoot.delete(recursive: true);
        }
      });

      await _writeFile(
        repoRoot,
        'packages/llm_dart_openai/lib/src/example.dart',
        '''
import 'package:llm_dart/openai.dart';

void main() {}
''',
      );

      final result = await guard.evaluateWorkspaceDependencyGuards(
        repoRoot: repoRoot,
      );

      expect(result.passed, isFalse);
      expect(
        result.violations,
        contains(
          contains(
            'package implementation files must not import or export package:llm_dart/...',
          ),
        ),
      );
    });

    test('reports unexpected runtime dependencies in workspace pubspecs',
        () async {
      final repoRoot = await _createTempWorkspace();
      addTearDown(() async {
        if (repoRoot.existsSync()) {
          await repoRoot.delete(recursive: true);
        }
      });

      await _writeFile(
        repoRoot,
        'packages/llm_dart_openai/pubspec.yaml',
        '''
name: llm_dart_openai
dependencies:
  llm_dart_provider:
    path: ../llm_dart_provider
  llm_dart_transport:
    path: ../llm_dart_transport
  llm_dart_google:
    path: ../llm_dart_google
''',
      );

      final result = await guard.evaluateWorkspaceDependencyGuards(
        repoRoot: repoRoot,
      );

      expect(result.passed, isFalse);
      expect(
        result.violations,
        contains(
          contains('unexpected runtime dependencies: llm_dart_google'),
        ),
      );
    });
  });
}

Future<Directory> _createTempWorkspace() async {
  final repoRoot = await Directory.systemTemp.createTemp(
    'llm_dart_dependency_guards_',
  );

  await _writeFile(
    repoRoot,
    'pubspec.yaml',
    '''
name: llm_dart
dependencies:
  llm_dart_core:
    path: packages/llm_dart_core
  llm_dart_ai:
    path: packages/llm_dart_ai
  llm_dart_openai:
    path: packages/llm_dart_openai
  llm_dart_transport:
    path: packages/llm_dart_transport
''',
  );
  await _writeFile(
    repoRoot,
    'packages/llm_dart_core/pubspec.yaml',
    '''
name: llm_dart_core
dependencies:
  llm_dart_ai:
    path: ../llm_dart_ai
  llm_dart_provider:
    path: ../llm_dart_provider
''',
  );
  await _writeFile(
    repoRoot,
    'packages/llm_dart_ai/pubspec.yaml',
    '''
name: llm_dart_ai
dependencies:
  llm_dart_provider:
    path: ../llm_dart_provider
''',
  );
  await _writeFile(
    repoRoot,
    'packages/llm_dart_provider/pubspec.yaml',
    '''
name: llm_dart_provider
''',
  );
  await _writeFile(
    repoRoot,
    'packages/llm_dart_transport/pubspec.yaml',
    '''
name: llm_dart_transport
dependencies:
  dio: ^5.9.0
  llm_dart_provider:
    path: ../llm_dart_provider
  logging: ^1.2.0
''',
  );
  await _writeFile(
    repoRoot,
    'packages/llm_dart_openai/pubspec.yaml',
    '''
name: llm_dart_openai
dependencies:
  llm_dart_provider:
    path: ../llm_dart_provider
  llm_dart_transport:
    path: ../llm_dart_transport
''',
  );
  await _writeFile(
    repoRoot,
    'packages/llm_dart_openai/lib/src/example.dart',
    'void main() {}\n',
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
