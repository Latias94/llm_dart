import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'runtime_executable.dart';

final class WorkspacePackageTestTarget {
  final String name;
  final String relativeDirectory;
  final String executable;
  final List<String> arguments;

  const WorkspacePackageTestTarget({
    required this.name,
    required this.relativeDirectory,
    required this.executable,
    required this.arguments,
  });

  String get commandText => [
        executable,
        ...resolveToolArguments(executable, arguments),
      ].join(' ');
}

const dartPackageTestDirectories = [
  'packages/llm_dart_provider',
  'packages/llm_dart_ai',
  'packages/llm_dart_core',
  'packages/llm_dart_transport',
  'packages/llm_dart_chat',
  'packages/llm_dart_openai',
  'packages/llm_dart_google',
  'packages/llm_dart_anthropic',
  'packages/llm_dart_ollama',
  'packages/llm_dart_elevenlabs',
];

const flutterPackageTestDirectory = 'packages/llm_dart_flutter';

List<WorkspacePackageTestTarget> buildWorkspacePackageTestTargets() {
  return [
    for (final relativeDirectory in dartPackageTestDirectories)
      WorkspacePackageTestTarget(
        name: relativeDirectory.split('/').last,
        relativeDirectory: relativeDirectory,
        executable: 'dart',
        arguments: const ['test'],
      ),
    WorkspacePackageTestTarget(
      name: flutterPackageTestDirectory.split('/').last,
      relativeDirectory: flutterPackageTestDirectory,
      executable: Platform.isWindows ? 'flutter.bat' : 'flutter',
      arguments: const ['test'],
    ),
  ];
}

Future<void> main() async {
  final repoRoot = Directory.current.absolute;
  final targets = buildWorkspacePackageTestTargets();

  stdout.writeln(
    'running workspace package tests for ${targets.length} package(s)...',
  );

  for (final target in targets) {
    final packageDirectory = Directory.fromUri(
      repoRoot.uri.resolve('${target.relativeDirectory}/'),
    );
    final pubspec = File.fromUri(packageDirectory.uri.resolve('pubspec.yaml'));
    if (!pubspec.existsSync()) {
      stderr.writeln(
        'workspace package tests failed: missing pubspec for '
        '`${target.name}` at ${packageDirectory.path}.',
      );
      exitCode = 1;
      return;
    }

    stdout.writeln('');
    stdout.writeln('==> ${target.name}');
    stdout.writeln('directory: ${target.relativeDirectory}');
    stdout.writeln('command: ${target.commandText}');

    ProcessResult result;
    try {
      result = await runWorkspacePackageTestProcess(
        packageDirectory,
        target: target,
      );
    } on ProcessException catch (error) {
      stderr.writeln(
        'workspace package tests could not start `${target.executable}` '
        'for `${target.name}`: ${error.message}',
      );
      if (target.executable == 'flutter' ||
          target.executable == 'flutter.bat') {
        stderr.writeln(
          'next action: install Flutter or run this package with '
          '`flutter test`.',
        );
      }
      exitCode = 69;
      return;
    }

    final stdoutText = result.stdout is String ? result.stdout as String : '';
    final stderrText = result.stderr is String ? result.stderr as String : '';
    writeProcessOutput(stdoutText: stdoutText, stderrText: stderrText);

    if (result.exitCode != 0) {
      stderr.writeln(
        'workspace package tests failed for `${target.name}` with exit code '
        '${result.exitCode}.',
      );
      exitCode = result.exitCode;
      return;
    }
  }

  stdout.writeln('');
  stdout.writeln(
    'workspace package tests passed for ${targets.length} package(s).',
  );
}

Future<ProcessResult> runWorkspacePackageTestProcess(
  Directory workingDirectory, {
  required WorkspacePackageTestTarget target,
}) {
  return Process.run(
    resolveToolExecutable(target.executable),
    resolveToolArguments(target.executable, target.arguments),
    workingDirectory: workingDirectory.path,
    environment: buildToolProcessEnvironment(),
    stdoutEncoding: utf8,
    stderrEncoding: utf8,
  );
}

void writeProcessOutput({
  required String stdoutText,
  required String stderrText,
}) {
  if (stdoutText.isNotEmpty) {
    stdout.write(stdoutText);
    if (!stdoutText.endsWith('\n')) {
      stdout.writeln();
    }
  }
  if (stderrText.isNotEmpty) {
    stderr.write(stderrText);
    if (!stderrText.endsWith('\n')) {
      stderr.writeln();
    }
  }
}
