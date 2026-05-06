import 'dart:io';

import 'package:test/test.dart';

import '../../tool/bootstrap_workspace_pubspec_overrides.dart';

void main() {
  group('generateWorkspacePubspecOverrides', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp(
        'llm_dart_workspace_bootstrap_test_',
      );
    });

    tearDown(() async {
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('writes root and package overrides with correct relative paths',
        () async {
      await _writeFile(
        File.fromUri(tempDir.uri.resolve('pubspec.yaml')),
        '''
name: llm_dart
dependencies:
  llm_dart_provider: ^0.11.0-alpha.1
  external_dep: ^1.0.0
dev_dependencies:
  llm_dart_core: ^0.11.0-alpha.1
  llm_dart_test:
    path: packages/llm_dart_test
''',
      );

      await _writePackagePubspec(
        tempDir,
        packageDirectory: 'packages/llm_dart_core',
        content: '''
name: llm_dart_core
dependencies:
  llm_dart_ai: ^0.11.0-alpha.1
  llm_dart_provider: ^0.11.0-alpha.1
''',
      );
      await _writePackagePubspec(
        tempDir,
        packageDirectory: 'packages/llm_dart_ai',
        content: '''
name: llm_dart_ai
dependencies:
  llm_dart_provider: ^0.11.0-alpha.1
''',
      );
      await _writePackagePubspec(
        tempDir,
        packageDirectory: 'packages/llm_dart_provider',
        content: '''
name: llm_dart_provider
''',
      );
      await _writePackagePubspec(
        tempDir,
        packageDirectory: 'packages/llm_dart_chat',
        content: '''
name: llm_dart_chat
dependencies:
  llm_dart_core: ^0.11.0-alpha.1
''',
      );
      await _writePackagePubspec(
        tempDir,
        packageDirectory: 'packages/llm_dart_test',
        content: '''
name: llm_dart_test
dependencies:
  llm_dart_provider:
    path: ../llm_dart_provider
''',
      );

      final result = await generateWorkspacePubspecOverrides(
        repoRoot: tempDir,
      );

      expect(result.writes.map((write) => write.packageName), [
        'llm_dart',
        'llm_dart_ai',
        'llm_dart_chat',
        'llm_dart_core',
        'llm_dart_test',
      ]);

      final rootOverrides = await File.fromUri(
        tempDir.uri.resolve('pubspec_overrides.yaml'),
      ).readAsString();
      expect(
        rootOverrides,
        contains('path: packages/llm_dart_core'),
      );
      expect(
        rootOverrides,
        contains('path: packages/llm_dart_test'),
      );
      expect(
        rootOverrides,
        contains('path: packages/llm_dart_provider'),
      );
      expect(
        rootOverrides,
        contains('path: packages/llm_dart_ai'),
      );
      expect(rootOverrides, isNot(contains('external_dep')));

      final aiOverrides = await File.fromUri(
        tempDir.uri.resolve('packages/llm_dart_ai/pubspec_overrides.yaml'),
      ).readAsString();
      expect(
        aiOverrides,
        contains('path: ../llm_dart_provider'),
      );

      final coreOverrides = await File.fromUri(
        tempDir.uri.resolve('packages/llm_dart_core/pubspec_overrides.yaml'),
      ).readAsString();
      expect(
        coreOverrides,
        contains('path: ../llm_dart_provider'),
      );
      expect(
        coreOverrides,
        contains('path: ../llm_dart_ai'),
      );

      final chatOverrides = await File.fromUri(
        tempDir.uri.resolve('packages/llm_dart_chat/pubspec_overrides.yaml'),
      ).readAsString();
      expect(
        chatOverrides,
        contains('path: ../llm_dart_core'),
      );
      expect(
        chatOverrides,
        contains('path: ../llm_dart_provider'),
      );
      expect(
        chatOverrides,
        contains('path: ../llm_dart_ai'),
      );
    });

    test('skips packages that do not depend on other workspace packages',
        () async {
      await _writeFile(
        File.fromUri(tempDir.uri.resolve('pubspec.yaml')),
        '''
name: llm_dart
dependencies:
  http: ^1.0.0
''',
      );
      await _writePackagePubspec(
        tempDir,
        packageDirectory: 'packages/llm_dart_core',
        content: '''
name: llm_dart_core
''',
      );

      final result = await generateWorkspacePubspecOverrides(
        repoRoot: tempDir,
      );

      expect(result.writes, isEmpty);
      expect(
        File.fromUri(tempDir.uri.resolve('pubspec_overrides.yaml'))
            .existsSync(),
        isFalse,
      );
    });
  });
}

Future<void> _writePackagePubspec(
  Directory repoRoot, {
  required String packageDirectory,
  required String content,
}) async {
  final directory =
      Directory.fromUri(repoRoot.uri.resolve('$packageDirectory/'));
  await directory.create(recursive: true);
  await _writeFile(
    File.fromUri(directory.uri.resolve('pubspec.yaml')),
    content,
  );
}

Future<void> _writeFile(File file, String content) async {
  await file.parent.create(recursive: true);
  await file.writeAsString(content.trimLeft());
}
