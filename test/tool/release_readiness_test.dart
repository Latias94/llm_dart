import 'dart:io';

import 'package:test/test.dart';

import '../../tool/release_readiness.dart';

void main() {
  group('parseReleaseReadinessOptions', () {
    test('parses skip, proxy, and report flags', () {
      final options = parseReleaseReadinessOptions([
        '--skip-tests',
        '--skip-consumer-smoke',
        '--skip-publish-dry-run',
        '--skip-pub-version-check',
        '--proxy=http://127.0.0.1:10809',
        '--report=build/release-report.md',
      ]);

      expect(options.skipTests, isTrue);
      expect(options.skipConsumerSmoke, isTrue);
      expect(options.skipPublishDryRun, isTrue);
      expect(options.skipPubVersionCheck, isTrue);
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
      final consumerSmokeStep = steps.firstWhere(
        (step) => step.name == 'Consumer smoke',
      );
      final workspaceGuardStep = steps.firstWhere(
        (step) => step.name == 'Workspace dependency guards',
      );
      final providerMetadataNamespaceGuardStep = steps.firstWhere(
        (step) => step.name == 'Provider metadata namespace guard',
      );
      final publishDryRunStep = steps.firstWhere(
        (step) => step.name == 'Workspace publish dry-run',
      );

      expect(
        steps.map((step) => step.name),
        containsAll([
          'Provider replay metadata guard',
          'Provider metadata namespace guard',
          'Example API guard',
          'Workspace tests',
          'Workspace package tests',
          'Consumer smoke',
          'Workspace publish dry-run',
          'Pub version availability',
        ]),
      );
      expect(
        consumerSmokeStep.commandText,
        'dart tool/run_consumer_smoke.dart',
      );
      expect(
        workspaceGuardStep.commandText,
        'dart tool/check_workspace_dependency_guards.dart',
      );
      expect(
        providerMetadataNamespaceGuardStep.commandText,
        'dart tool/check_provider_metadata_namespace_guards.dart',
      );
      expect(
        publishDryRunStep.commandText,
        'dart tool/run_workspace_publish_dry_run.dart',
      );
    });

    test('skips long steps when requested', () {
      final steps = buildReleaseReadinessSteps(
        const ReleaseReadinessOptions(
          skipTests: true,
          skipConsumerSmoke: true,
          skipPublishDryRun: true,
        ),
      );

      expect(
        steps.map((step) => step.name),
        isNot(contains('Workspace tests')),
      );
      expect(
        steps.map((step) => step.name),
        isNot(contains('Workspace package tests')),
      );
      expect(
        steps.map((step) => step.name),
        isNot(contains('Consumer smoke')),
      );
      expect(
        steps.map((step) => step.name),
        isNot(contains('Workspace publish dry-run')),
      );
      expect(
        steps.map((step) => step.name),
        isNot(contains('Pub version availability')),
      );
      expect(
        steps.map((step) => step.name),
        contains('Workspace analysis'),
      );
    });

    test('skips pub version availability when requested', () {
      final steps = buildReleaseReadinessSteps(
        const ReleaseReadinessOptions(skipPubVersionCheck: true),
      );

      expect(
        steps.map((step) => step.name),
        contains('Workspace publish dry-run'),
      );
      expect(
        steps.map((step) => step.name),
        isNot(contains('Pub version availability')),
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
    test('includes failed step context and post-publish smoke checklist', () {
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
      expect(report, contains('## Publish Order'));
      expect(report, contains('- `llm_dart_provider`'));
      expect(report, contains('- `llm_dart`'));
      expect(report, contains('Post-Publish Consumer Smoke'));
    });
  });
}
