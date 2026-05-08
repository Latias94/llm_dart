import 'dart:io';

import 'package:test/test.dart';

import '../../tool/release_readiness.dart';

void main() {
  group('parseReleaseReadinessOptions', () {
    test('parses skip, proxy, and report flags', () {
      final options = parseReleaseReadinessOptions([
        '--skip-tests',
        '--skip-publish-dry-run',
        '--proxy=http://127.0.0.1:10809',
        '--report=build/release-report.md',
      ]);

      expect(options.skipTests, isTrue);
      expect(options.skipPublishDryRun, isTrue);
      expect(options.proxy, 'http://127.0.0.1:10809');
      expect(options.reportPath, 'build/release-report.md');
    });

    test('rejects unknown flags', () {
      expect(
        () => parseReleaseReadinessOptions(['--unknown']),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('buildReleaseReadinessSteps', () {
    test('includes tests and publish dry-run by default', () {
      final steps = buildReleaseReadinessSteps(
        const ReleaseReadinessOptions(),
      );

      expect(
        steps.map((step) => step.name),
        containsAll([
          'Workspace tests',
          'Workspace publish dry-run',
        ]),
      );
    });

    test('skips long steps when requested', () {
      final steps = buildReleaseReadinessSteps(
        const ReleaseReadinessOptions(
          skipTests: true,
          skipPublishDryRun: true,
        ),
      );

      expect(
        steps.map((step) => step.name),
        isNot(contains('Workspace tests')),
      );
      expect(
        steps.map((step) => step.name),
        isNot(contains('Workspace publish dry-run')),
      );
      expect(
        steps.map((step) => step.name),
        contains('Workspace analysis'),
      );
    });
  });

  group('buildReleaseReadinessEnvironment', () {
    test('returns proxy overrides when configured', () {
      final environment = buildReleaseReadinessEnvironment(
        const ReleaseReadinessOptions(proxy: 'http://127.0.0.1:10809'),
      );

      expect(environment, isNotNull);
      expect(environment!['HTTP_PROXY'], 'http://127.0.0.1:10809');
      expect(environment['HTTPS_PROXY'], 'http://127.0.0.1:10809');
    });

    test('returns null without proxy', () {
      expect(
        buildReleaseReadinessEnvironment(const ReleaseReadinessOptions()),
        isNull,
      );
    });
  });

  group('readRootPackageVersion', () {
    test('reads the top-level pubspec version', () async {
      final directory = await Directory.systemTemp.createTemp(
        'llm_dart_release_readiness_version_',
      );
      addTearDown(() async {
        if (directory.existsSync()) {
          await directory.delete(recursive: true);
        }
      });

      await File.fromUri(directory.uri.resolve('pubspec.yaml')).writeAsString(
        '''
name: example
version: 1.2.3-alpha.1
''',
      );

      expect(await readRootPackageVersion(directory), '1.2.3-alpha.1');
    });
  });

  group('buildReleaseReadinessReport', () {
    test('includes failed step context and manual consumer smoke checklist',
        () {
      const step = ReleaseReadinessStep(
        name: 'Example step',
        executable: 'dart',
        arguments: ['test'],
        failureHint: 'Fix the test failure.',
      );
      final startedAt = DateTime.utc(2026, 5, 8, 1);
      final finishedAt = DateTime.utc(2026, 5, 8, 1, 0, 2);
      final report = buildReleaseReadinessReport(
        ReleaseReadinessRunResult(
          repoRoot: Directory('F:/SourceCodes/Github/llm_dart'),
          packageVersion: '0.11.0-alpha.1',
          startedAt: startedAt,
          finishedAt: finishedAt,
          steps: const [
            ReleaseReadinessStepResult(
              step: step,
              exitCode: 1,
              elapsed: Duration(seconds: 2),
            ),
          ],
          consumerSmokeChecklistIncluded: true,
        ),
      );

      expect(report, contains('Result: `failed`'));
      expect(report, contains('Fix the test failure.'));
      expect(report, contains('Manual Consumer Smoke'));
    });
  });
}
