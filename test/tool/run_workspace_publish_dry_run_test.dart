import 'dart:io';

import 'package:test/test.dart';

import '../../tool/run_workspace_publish_dry_run.dart';

void main() {
  group('packagePubspecRequiresFlutter', () {
    test('detects Flutter environment constraints', () {
      expect(
        packagePubspecRequiresFlutter(const [
          'name: llm_dart_flutter',
          'environment:',
          "  sdk: '>=3.5.0 <4.0.0'",
          "  flutter: '>=3.24.0'",
        ]),
        isTrue,
      );
    });

    test('detects Flutter SDK dependencies', () {
      expect(
        packagePubspecRequiresFlutter(const [
          'name: llm_dart_flutter',
          'dependencies:',
          '  flutter:',
          '    sdk: flutter',
        ]),
        isTrue,
      );
    });

    test('keeps pure Dart packages on dart pub', () {
      expect(
        packagePubspecRequiresFlutter(const [
          'name: llm_dart_openai',
          'environment:',
          "  sdk: '>=3.5.0 <4.0.0'",
          'dependencies:',
          '  llm_dart_ai: ^0.11.0-alpha.1',
        ]),
        isFalse,
      );
    });
  });

  group('resolvePublishDryRunCommand', () {
    test('uses flutter pub for Flutter packages', () async {
      final packageDirectory = await Directory.systemTemp.createTemp(
        'llm_dart_publish_command_test_',
      );

      try {
        await File.fromUri(packageDirectory.uri.resolve('pubspec.yaml'))
            .writeAsString('''
name: llm_dart_flutter
environment:
  sdk: '>=3.5.0 <4.0.0'
  flutter: '>=3.24.0'
dependencies:
  flutter:
    sdk: flutter
''');

        final command = await resolvePublishDryRunCommand(packageDirectory);

        expect(command.executable, 'flutter');
        expect(command.arguments, ['pub', 'publish', '--dry-run']);
      } finally {
        if (packageDirectory.existsSync()) {
          await packageDirectory.delete(recursive: true);
        }
      }
    });

    test('uses dart pub for pure Dart packages', () async {
      final packageDirectory = await Directory.systemTemp.createTemp(
        'llm_dart_publish_command_test_',
      );

      try {
        await File.fromUri(packageDirectory.uri.resolve('pubspec.yaml'))
            .writeAsString('''
name: llm_dart_openai
environment:
  sdk: '>=3.5.0 <4.0.0'
dependencies:
  llm_dart_ai: ^0.11.0-alpha.1
''');

        final command = await resolvePublishDryRunCommand(packageDirectory);

        expect(command.executable, 'dart');
        expect(command.arguments, ['pub', 'publish', '--dry-run']);
      } finally {
        if (packageDirectory.existsSync()) {
          await packageDirectory.delete(recursive: true);
        }
      }
    });
  });

  group('extractPublishDryRunSummary', () {
    test('parses warnings and hints', () {
      final summary = extractPublishDryRunSummary(
        'Package has 0 warnings and 7 hints.',
      );

      expect(summary, isNotNull);
      expect(summary!.warnings, 0);
      expect(summary.hints, 7);
    });

    test('parses warnings without hints', () {
      final summary = extractPublishDryRunSummary(
        'Package has 1 warning.',
      );

      expect(summary, isNotNull);
      expect(summary!.warnings, 1);
      expect(summary.hints, 0);
    });

    test('returns null when no summary is present', () {
      expect(
        extractPublishDryRunSummary('Publishing package...'),
        isNull,
      );
    });
  });

  group('publish dry-run output helpers', () {
    test('counts workspace override hints', () {
      final count = countWorkspaceOverridePublishDryRunHints('''
* Non-dev dependencies are overridden in pubspec_overrides.yaml.
* Non-dev dependencies are overridden in pubspec_overrides.yaml.
''');

      expect(count, 2);
    });

    test('extracts validation diagnostics without archive listing', () {
      final diagnostics = extractPublishDryRunValidationDiagnostics('''
Building package archive...
├── lib
│   └── example.dart

Validating package...
Package validation found the following 1 hint:
* Some hint.

Package has 0 warnings and 1 hint.
''');

      expect(diagnostics, startsWith('Validating package...'));
      expect(diagnostics, isNot(contains('Building package archive')));
      expect(diagnostics, contains('Package has 0 warnings and 1 hint.'));
    });
  });

  group('preparePackageDryRunDirectory', () {
    test('stages root package without workspace-only and local files',
        () async {
      final sourceDirectory = await Directory.systemTemp.createTemp(
        'llm_dart_publish_dry_run_test_source_',
      );
      Directory? stagedDirectory;

      try {
        await File.fromUri(sourceDirectory.uri.resolve('pubspec.yaml'))
            .writeAsString('name: llm_dart\n');
        await File.fromUri(sourceDirectory.uri.resolve('README.md'))
            .writeAsString('# llm_dart\n');
        await Directory.fromUri(sourceDirectory.uri.resolve('lib/'))
            .create(recursive: true);
        await File.fromUri(sourceDirectory.uri.resolve('lib/llm_dart.dart'))
            .writeAsString('library;\n');

        await Directory.fromUri(sourceDirectory.uri.resolve('.git/'))
            .create(recursive: true);
        await File.fromUri(sourceDirectory.uri.resolve('.git/index'))
            .writeAsString('local git data');
        await Directory.fromUri(sourceDirectory.uri.resolve('packages/local/'))
            .create(recursive: true);
        await File.fromUri(sourceDirectory.uri.resolve('packages/local/file'))
            .writeAsString('workspace package');
        await File.fromUri(sourceDirectory.uri.resolve('darthelp.err'))
            .writeAsString('local error output');

        stagedDirectory = await preparePackageDryRunDirectory(
          packageName: 'llm_dart',
          packageDirectory: sourceDirectory,
        );

        expect(
          File.fromUri(stagedDirectory.uri.resolve('pubspec.yaml'))
              .existsSync(),
          isTrue,
        );
        expect(
          File.fromUri(stagedDirectory.uri.resolve('lib/llm_dart.dart'))
              .existsSync(),
          isTrue,
        );
        expect(
          Directory.fromUri(stagedDirectory.uri.resolve('.git/')).existsSync(),
          isFalse,
        );
        expect(
          Directory.fromUri(stagedDirectory.uri.resolve('packages/'))
              .existsSync(),
          isFalse,
        );
        expect(
          File.fromUri(stagedDirectory.uri.resolve('darthelp.err'))
              .existsSync(),
          isFalse,
        );
      } finally {
        if (stagedDirectory != null && stagedDirectory.existsSync()) {
          await stagedDirectory.delete(recursive: true);
        }
        if (sourceDirectory.existsSync()) {
          await sourceDirectory.delete(recursive: true);
        }
      }
    });
  });
}
