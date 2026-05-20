import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'bootstrap_workspace_pubspec_overrides.dart'
    show publishableWorkspacePackages;
import 'runtime_executable.dart';

final class ReleaseReadinessOptions {
  final bool skipTests;
  final bool skipConsumerSmoke;
  final bool skipPublishDryRun;
  final bool skipPubVersionCheck;
  final bool showHelp;
  final bool includeConsumerSmokeChecklist;
  final String? proxy;
  final String? reportPath;

  const ReleaseReadinessOptions({
    this.skipTests = false,
    this.skipConsumerSmoke = false,
    this.skipPublishDryRun = false,
    this.skipPubVersionCheck = false,
    this.showHelp = false,
    this.includeConsumerSmokeChecklist = true,
    this.proxy,
    this.reportPath,
  });
}

final class ReleaseReadinessStep {
  final String name;
  final String executable;
  final List<String> arguments;
  final String failureHint;

  const ReleaseReadinessStep({
    required this.name,
    required this.executable,
    required this.arguments,
    required this.failureHint,
  });

  String get commandText => [
        executable,
        ...resolveToolArguments(executable, arguments),
      ].map(_quoteCommandPart).join(' ');
}

final class ReleaseReadinessStepResult {
  final ReleaseReadinessStep step;
  final int exitCode;
  final Duration elapsed;

  const ReleaseReadinessStepResult({
    required this.step,
    required this.exitCode,
    required this.elapsed,
  });

  bool get passed => exitCode == 0;
}

final class ReleaseReadinessRunResult {
  final Directory repoRoot;
  final String packageVersion;
  final DateTime startedAt;
  final DateTime finishedAt;
  final List<ReleaseReadinessStepResult> steps;
  final bool consumerSmokeChecklistIncluded;

  const ReleaseReadinessRunResult({
    required this.repoRoot,
    required this.packageVersion,
    required this.startedAt,
    required this.finishedAt,
    required this.steps,
    required this.consumerSmokeChecklistIncluded,
  });

  bool get passed => steps.every((step) => step.passed);

  Duration get elapsed => finishedAt.difference(startedAt);
}

Future<void> main(List<String> arguments) async {
  late final ReleaseReadinessOptions options;
  try {
    options = parseReleaseReadinessOptions(arguments);
  } on FormatException catch (error) {
    stderr.writeln('release readiness argument error: ${error.message}');
    stderr.writeln('');
    stderr.write(releaseReadinessUsage);
    exitCode = 64;
    return;
  }

  if (options.showHelp) {
    stdout.write(releaseReadinessUsage);
    return;
  }

  final repoRoot = Directory.current.absolute;
  final result = await runReleaseReadiness(
    repoRoot: repoRoot,
    options: options,
  );

  final report = buildReleaseReadinessReport(result);
  stdout.writeln('');
  stdout.write(report);

  if (options.reportPath != null) {
    final reportFile = File(options.reportPath!);
    await reportFile.parent.create(recursive: true);
    await reportFile.writeAsString(report);
    stdout.writeln('');
    stdout.writeln(
      'release readiness report written to ${reportFile.absolute.path}',
    );
  }

  if (!result.passed) {
    final failedStep = result.steps.firstWhere((step) => !step.passed);
    stderr.writeln('');
    stderr.writeln('release readiness failed at: ${failedStep.step.name}');
    stderr.writeln('next action: ${failedStep.step.failureHint}');
    exitCode = failedStep.exitCode == 0 ? 1 : failedStep.exitCode;
  }
}

Future<ReleaseReadinessRunResult> runReleaseReadiness({
  required Directory repoRoot,
  required ReleaseReadinessOptions options,
}) async {
  final startedAt = DateTime.now();
  final packageVersion = await readRootPackageVersion(repoRoot);
  final steps = buildReleaseReadinessSteps(options);
  final results = <ReleaseReadinessStepResult>[];
  final environment = buildReleaseReadinessEnvironment(options);

  stdout.writeln('release readiness gate');
  stdout.writeln('repository: ${repoRoot.path}');
  stdout.writeln('version: $packageVersion');
  if (options.proxy != null) {
    stdout.writeln('proxy: ${options.proxy}');
  }
  stdout.writeln('steps: ${steps.length}');

  for (var index = 0; index < steps.length; index++) {
    final step = steps[index];
    stdout.writeln('');
    stdout.writeln('==> ${index + 1}/${steps.length}: ${step.name}');
    stdout.writeln(r'$ ' + step.commandText);

    final result = await runReleaseReadinessStep(
      step,
      repoRoot: repoRoot,
      environment: environment,
    );
    results.add(result);

    stdout.writeln(
      result.passed
          ? 'passed in ${formatDuration(result.elapsed)}'
          : 'failed with exit code ${result.exitCode} '
              'after ${formatDuration(result.elapsed)}',
    );

    if (!result.passed) {
      break;
    }
  }

  return ReleaseReadinessRunResult(
    repoRoot: repoRoot,
    packageVersion: packageVersion,
    startedAt: startedAt,
    finishedAt: DateTime.now(),
    steps: List.unmodifiable(results),
    consumerSmokeChecklistIncluded: options.includeConsumerSmokeChecklist,
  );
}

Future<ReleaseReadinessStepResult> runReleaseReadinessStep(
  ReleaseReadinessStep step, {
  required Directory repoRoot,
  required Map<String, String>? environment,
}) async {
  final stopwatch = Stopwatch()..start();
  final process = await Process.start(
    resolveToolExecutable(step.executable),
    resolveToolArguments(step.executable, step.arguments),
    workingDirectory: repoRoot.path,
    environment: environment,
  );

  final stdoutDone = _pipeProcessOutput(process.stdout, stdout);
  final stderrDone = _pipeProcessOutput(process.stderr, stderr);
  final processExitCode = await process.exitCode;
  await Future.wait([stdoutDone, stderrDone]);
  stopwatch.stop();

  return ReleaseReadinessStepResult(
    step: step,
    exitCode: processExitCode,
    elapsed: stopwatch.elapsed,
  );
}

Future<void> _pipeProcessOutput(
  Stream<List<int>> source,
  IOSink destination,
) async {
  await for (final chunk in source.transform(utf8.decoder)) {
    destination.write(chunk);
  }
}

ReleaseReadinessOptions parseReleaseReadinessOptions(List<String> arguments) {
  var skipTests = false;
  var skipConsumerSmoke = false;
  var skipPublishDryRun = false;
  var skipPubVersionCheck = false;
  var showHelp = false;
  var includeConsumerSmokeChecklist = true;
  String? proxy;
  String? reportPath;

  for (final argument in arguments) {
    switch (argument) {
      case '-h' || '--help':
        showHelp = true;
      case '--skip-tests':
        skipTests = true;
      case '--skip-consumer-smoke':
        skipConsumerSmoke = true;
      case '--skip-publish-dry-run':
        skipPublishDryRun = true;
      case '--skip-pub-version-check':
        skipPubVersionCheck = true;
      case '--no-consumer-smoke-checklist':
        includeConsumerSmokeChecklist = false;
      default:
        if (argument.startsWith('--proxy=')) {
          proxy = _readFlagValue(argument, '--proxy=');
          continue;
        }
        if (argument.startsWith('--report=')) {
          reportPath = _readFlagValue(argument, '--report=');
          continue;
        }
        throw FormatException('unknown option `$argument`');
    }
  }

  return ReleaseReadinessOptions(
    skipTests: skipTests,
    skipConsumerSmoke: skipConsumerSmoke,
    skipPublishDryRun: skipPublishDryRun,
    skipPubVersionCheck: skipPubVersionCheck,
    showHelp: showHelp,
    includeConsumerSmokeChecklist: includeConsumerSmokeChecklist,
    proxy: proxy,
    reportPath: reportPath,
  );
}

String _readFlagValue(String argument, String prefix) {
  final value = argument.substring(prefix.length).trim();
  if (value.isEmpty) {
    throw FormatException(
        '`${prefix.substring(0, prefix.length - 1)}` needs a value');
  }
  return value;
}

List<ReleaseReadinessStep> buildReleaseReadinessSteps(
  ReleaseReadinessOptions options,
) {
  return [
    const ReleaseReadinessStep(
      name: 'Workspace dependency guards',
      executable: 'dart',
      arguments: ['run', 'tool/check_workspace_dependency_guards.dart'],
      failureHint:
          'Fix workspace package dependency direction or update the guard policy intentionally.',
    ),
    const ReleaseReadinessStep(
      name: 'Root package boundary guards',
      executable: 'dart',
      arguments: ['run', 'tool/check_root_package_boundary_guards.dart'],
      failureHint:
          'Move implementation ownership out of root compatibility areas or update the boundary guard intentionally.',
    ),
    const ReleaseReadinessStep(
      name: 'Core compatibility shell guard',
      executable: 'dart',
      arguments: ['run', 'tool/check_core_compatibility_shell_guard.dart'],
      failureHint:
          'Keep llm_dart_core as a compatibility shell and move new implementation ownership to focused packages.',
    ),
    const ReleaseReadinessStep(
      name: 'Provider replay metadata guard',
      executable: 'dart',
      arguments: ['run', 'tool/check_provider_replay_metadata_guards.dart'],
      failureHint:
          'Keep replay continuation metadata in explicit replay prompt options and approved provider replay helpers.',
    ),
    const ReleaseReadinessStep(
      name: 'OpenAI provider layout guard',
      executable: 'dart',
      arguments: ['run', 'tool/check_openai_provider_layout_guard.dart'],
      failureHint:
          'Keep OpenAI provider implementation files in route/capability directories.',
    ),
    const ReleaseReadinessStep(
      name: 'Provider metadata namespace guard',
      executable: 'dart',
      arguments: ['run', 'tool/check_provider_metadata_namespace_guards.dart'],
      failureHint:
          'Construct provider metadata through ProviderMetadata.forNamespace or package-local namespace helpers.',
    ),
    const ReleaseReadinessStep(
      name: 'Transport boundary guard',
      executable: 'dart',
      arguments: ['run', 'tool/check_transport_boundary_guards.dart'],
      failureHint:
          'Keep transport-owned public names and avoid leaking provider legacy aliases through transport barrels.',
    ),
    const ReleaseReadinessStep(
      name: 'Test legacy-import guard',
      executable: 'dart',
      arguments: ['run', 'tool/check_test_legacy_import_guards.dart'],
      failureHint:
          'Move foundational tests to focused imports and keep legacy.dart imports only for explicit compatibility coverage.',
    ),
    const ReleaseReadinessStep(
      name: 'Example API guard',
      executable: 'dart',
      arguments: ['run', 'tool/check_example_api_guards.dart'],
      failureHint:
          'Keep default examples on model-first entrypoints and move legacy builder material to explicit compatibility appendices.',
    ),
    const ReleaseReadinessStep(
      name: 'Workspace analysis',
      executable: 'dart',
      arguments: ['analyze', 'lib', 'test', 'example', 'tool'],
      failureHint:
          'Fix analyzer diagnostics before running release tests or publish dry-runs.',
    ),
    if (!options.skipTests)
      const ReleaseReadinessStep(
        name: 'Workspace tests',
        executable: 'dart',
        arguments: ['test'],
        failureHint:
            'Fix failing tests or intentionally update expectations before release.',
      ),
    if (!options.skipTests)
      const ReleaseReadinessStep(
        name: 'Workspace package tests',
        executable: 'dart',
        arguments: ['run', 'tool/run_workspace_package_tests.dart'],
        failureHint:
            'Fix failing focused package tests before release; root tests alone do not cover the split packages.',
      ),
    if (!options.skipConsumerSmoke)
      ReleaseReadinessStep(
        name: 'Consumer smoke',
        executable: 'dart',
        arguments: [
          'run',
          'tool/run_consumer_smoke.dart',
          if (options.proxy != null) '--proxy=${options.proxy}',
        ],
        failureHint:
            'Fix clean-consumer dependency resolution, exports, or Flutter smoke coverage before release.',
      ),
    if (!options.skipPublishDryRun)
      const ReleaseReadinessStep(
        name: 'Workspace publish dry-run',
        executable: 'dart',
        arguments: ['run', 'tool/run_workspace_publish_dry_run.dart'],
        failureHint:
            'Fix package metadata, dependency resolution, or publish warnings before publishing.',
      ),
    if (!options.skipPublishDryRun && !options.skipPubVersionCheck)
      ReleaseReadinessStep(
        name: 'Pub version availability',
        executable: 'dart',
        arguments: [
          'run',
          'tool/check_pub_version_availability.dart',
          if (options.proxy != null) '--proxy=${options.proxy}',
        ],
        failureHint:
            'Choose a new package version or verify pub.dev availability before publishing.',
      ),
  ];
}

Map<String, String> buildReleaseReadinessEnvironment(
  ReleaseReadinessOptions options,
) {
  final proxy = options.proxy;
  return buildToolProcessEnvironment(
    proxy == null
        ? null
        : {
            'HTTP_PROXY': proxy,
            'HTTPS_PROXY': proxy,
          },
  );
}

Future<String> readRootPackageVersion(Directory repoRoot) async {
  final pubspec = File.fromUri(repoRoot.uri.resolve('pubspec.yaml'));
  if (!pubspec.existsSync()) {
    throw StateError('pubspec.yaml not found at ${pubspec.path}');
  }

  final lines = await pubspec.readAsLines();
  for (final rawLine in lines) {
    final line = rawLine.trim();
    if (line.startsWith('version:')) {
      final version = line.substring('version:'.length).trim();
      if (version.isEmpty) {
        break;
      }
      return version;
    }
  }

  throw StateError('pubspec.yaml is missing a top-level version.');
}

String buildReleaseReadinessReport(ReleaseReadinessRunResult result) {
  final buffer = StringBuffer()
    ..writeln('# Release Readiness Report')
    ..writeln()
    ..writeln('- Repository: `${result.repoRoot.path.replaceAll('\\', '/')}`')
    ..writeln('- Version: `${result.packageVersion}`')
    ..writeln('- Started: `${result.startedAt.toIso8601String()}`')
    ..writeln('- Finished: `${result.finishedAt.toIso8601String()}`')
    ..writeln('- Elapsed: `${formatDuration(result.elapsed)}`')
    ..writeln('- Result: `${result.passed ? 'passed' : 'failed'}`')
    ..writeln()
    ..writeln('## Steps')
    ..writeln()
    ..writeln('| Step | Status | Exit Code | Elapsed |')
    ..writeln('| --- | --- | ---: | ---: |');

  for (final resultStep in result.steps) {
    buffer.writeln(
      '| ${resultStep.step.name} | '
      '${resultStep.passed ? 'passed' : 'failed'} | '
      '${resultStep.exitCode} | '
      '${formatDuration(resultStep.elapsed)} |',
    );
  }

  buffer
    ..writeln()
    ..writeln('## Publish Order')
    ..writeln();

  for (final packageName in publishableWorkspacePackages) {
    buffer.writeln('- `$packageName`');
  }

  if (!result.passed && result.steps.isNotEmpty) {
    final failedStep = result.steps.firstWhere((step) => !step.passed);
    buffer
      ..writeln()
      ..writeln('## Failure')
      ..writeln()
      ..writeln('- Step: `${failedStep.step.name}`')
      ..writeln('- Command: `${failedStep.step.commandText}`')
      ..writeln('- Next action: ${failedStep.step.failureHint}');
  }

  if (result.consumerSmokeChecklistIncluded) {
    buffer
      ..writeln()
      ..writeln('## Post-Publish Consumer Smoke')
      ..writeln()
      ..writeln('- Repeat consumer smoke against the published pub.dev '
          'versions after the packages are released with '
          '`dart tool/run_consumer_smoke.dart --published`.')
      ..writeln('- Validate clean root Dart, OpenAI-only, split-package, and '
          'Flutter consumers without local path overrides.')
      ..writeln('- Keep `test(...)` for pure controller/import smoke tests; '
          'reserve `testWidgets(...)` for tests that pump widgets.');
  }

  return buffer.toString();
}

String formatDuration(Duration duration) {
  final minutes = duration.inMinutes;
  final seconds = duration.inSeconds.remainder(60);
  final milliseconds = duration.inMilliseconds.remainder(1000);
  if (minutes > 0) {
    return '${minutes}m ${seconds}s';
  }
  if (seconds > 0) {
    return '$seconds.${milliseconds.toString().padLeft(3, '0')}s';
  }
  return '${milliseconds}ms';
}

String _quoteCommandPart(String value) {
  if (!value.contains(RegExp(r'\s'))) {
    return value;
  }
  return '"${value.replaceAll('"', r'\"')}"';
}

const releaseReadinessUsage = '''
Usage: dart tool/release_readiness.dart [options]

Runs the alpha release readiness gate from the repository root.

Options:
  --skip-tests                 Skip `dart test`.
                               This also skips focused workspace package tests.
  --skip-consumer-smoke        Skip clean Dart and Flutter consumer smoke.
  --skip-publish-dry-run       Skip workspace publish dry-runs.
  --skip-pub-version-check     Skip pub.dev target-version availability checks.
                               This is also skipped when publish dry-run is skipped.
  --proxy=<url>                Set HTTP_PROXY and HTTPS_PROXY for child steps.
  --report=<path>              Write the release readiness report to a file.
  --no-consumer-smoke-checklist
                               Omit the post-publish consumer smoke checklist from
                               the report.
  -h, --help                   Print this help text.
''';
