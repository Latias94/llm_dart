import 'dart:async';
import 'dart:io';

import 'bootstrap_workspace_pubspec_overrides.dart';

final class PublishDryRunSummary {
  final int warnings;
  final int hints;

  const PublishDryRunSummary({
    required this.warnings,
    required this.hints,
  });
}

const publishDryRunTimeout = Duration(minutes: 3);

Future<void> main() async {
  final repoRoot = Directory.current.absolute;
  await generateWorkspacePubspecOverrides(repoRoot: repoRoot);

  stdout.writeln(
    'running workspace publish dry-runs for '
    '${publishableWorkspacePackages.length} package(s)...',
  );

  for (final packageName in publishableWorkspacePackages) {
    final packageDirectory = _resolvePackageDirectory(
      repoRoot: repoRoot,
      packageName: packageName,
    );
    final pubspec = File.fromUri(packageDirectory.uri.resolve('pubspec.yaml'));
    if (!pubspec.existsSync()) {
      stderr.writeln(
        'workspace publish dry-run failed: missing pubspec for `$packageName` '
        'at ${packageDirectory.path}.',
      );
      exitCode = 1;
      return;
    }

    stdout.writeln('');
    stdout.writeln('==> $packageName');

    final workingDirectory = await preparePackageDryRunDirectory(
      packageName: packageName,
      packageDirectory: packageDirectory,
    );
    try {
      final command = await resolvePublishDryRunCommand(packageDirectory);
      stdout.writeln('command: ${command.commandText}');

      ProcessResult result;
      try {
        result = await runPublishDryRunProcess(
          workingDirectory,
          command: command,
        );
      } on TimeoutException catch (error) {
        final duration = error.duration ?? publishDryRunTimeout;
        stderr.writeln(
          'workspace publish dry-run timed out for `$packageName` after '
          '${duration.inSeconds}s.',
        );
        exitCode = 1;
        return;
      } on ProcessException catch (error) {
        stderr.writeln(
          'workspace publish dry-run could not start `${command.executable}` '
          'for `$packageName`: ${error.message}',
        );
        if (command.executable == 'flutter') {
          stderr.writeln(
            'next action: install Flutter or run this package with '
            '`flutter pub publish --dry-run`.',
          );
        }
        exitCode = 69;
        return;
      }

      final stdoutText = result.stdout is String ? result.stdout as String : '';
      final stderrText = result.stderr is String ? result.stderr as String : '';
      final combinedOutput = '$stdoutText\n$stderrText';
      final summary = extractPublishDryRunSummary(combinedOutput);
      final shouldPrintFullOutput =
          result.exitCode != 0 || (summary?.warnings ?? 0) > 0;

      if (shouldPrintFullOutput) {
        writeProcessOutput(stdoutText: stdoutText, stderrText: stderrText);
      }

      if (result.exitCode != 0) {
        stderr.writeln(
          'workspace publish dry-run failed for `$packageName` with exit code '
          '${result.exitCode}.',
        );
        exitCode = result.exitCode;
        return;
      }

      if (summary != null && summary.warnings > 0) {
        stderr.writeln(
          'workspace publish dry-run failed for `$packageName`: '
          '${summary.warnings} warning(s) detected.',
        );
        exitCode = 1;
        return;
      }

      if (summary != null) {
        final knownWorkspaceOverrideHints =
            countWorkspaceOverridePublishDryRunHints(combinedOutput);
        final suppressedKnownHints = knownWorkspaceOverrideHints > summary.hints
            ? summary.hints
            : knownWorkspaceOverrideHints;
        final hasOtherHints = summary.hints > suppressedKnownHints;

        if (!shouldPrintFullOutput && hasOtherHints) {
          final diagnostics = extractPublishDryRunValidationDiagnostics(
            combinedOutput,
          );
          if (diagnostics.isNotEmpty) {
            stdout.write(diagnostics);
            if (!diagnostics.endsWith('\n')) {
              stdout.writeln();
            }
          }
        }

        stdout.writeln(
          'dry-run summary for `$packageName`: '
          '${summary.warnings} warning(s), ${summary.hints} hint(s).',
        );
        if (suppressedKnownHints > 0 && !hasOtherHints) {
          stdout.writeln(
            'note: suppressed $suppressedKnownHints expected workspace '
            'override hint(s) from staged local path dependencies.',
          );
        }
      }
    } finally {
      if (workingDirectory.existsSync()) {
        await workingDirectory.delete(recursive: true);
      }
    }
  }

  stdout.writeln('');
  stdout.writeln(
    'workspace publish dry-run passed for '
    '${publishableWorkspacePackages.length} package(s).',
  );
}

final class PublishDryRunCommand {
  final String executable;
  final List<String> arguments;

  const PublishDryRunCommand({
    required this.executable,
    required this.arguments,
  });

  String get commandText => [
        executable,
        ...arguments,
      ].join(' ');
}

const dartPublishDryRunCommand = PublishDryRunCommand(
  executable: 'dart',
  arguments: ['pub', 'publish', '--dry-run'],
);

const flutterPublishDryRunCommand = PublishDryRunCommand(
  executable: 'flutter',
  arguments: ['pub', 'publish', '--dry-run'],
);

Future<PublishDryRunCommand> resolvePublishDryRunCommand(
  Directory packageDirectory,
) async {
  final pubspec = File.fromUri(packageDirectory.uri.resolve('pubspec.yaml'));
  if (!pubspec.existsSync()) {
    return dartPublishDryRunCommand;
  }

  final lines = await pubspec.readAsLines();
  return packagePubspecRequiresFlutter(lines)
      ? flutterPublishDryRunCommand
      : dartPublishDryRunCommand;
}

bool packagePubspecRequiresFlutter(List<String> lines) {
  String? currentTopLevelSection;
  String? currentSdkDependency;

  for (final rawLine in lines) {
    final line = rawLine.replaceAll('\t', '  ');
    final trimmed = line.trim();

    if (trimmed.isEmpty || trimmed.startsWith('#')) {
      continue;
    }

    if (!line.startsWith(' ')) {
      final sectionMatch =
          RegExp(r'^([A-Za-z0-9_]+):(?:\s.*)?$').firstMatch(line);
      currentTopLevelSection = sectionMatch?.group(1);
      currentSdkDependency = null;
      continue;
    }

    if (currentTopLevelSection == 'environment' &&
        RegExp(r'^  flutter:\s*.+$').hasMatch(line)) {
      return true;
    }

    if (!const {
      'dependencies',
      'dev_dependencies',
      'dependency_overrides',
    }.contains(currentTopLevelSection)) {
      continue;
    }

    final dependencyMatch =
        RegExp(r'^  ([A-Za-z0-9_]+):(?:\s.*)?$').firstMatch(line);
    if (dependencyMatch != null) {
      currentSdkDependency = dependencyMatch.group(1);
      continue;
    }

    if (currentSdkDependency != null &&
        RegExp(r'^\s{4,}sdk:\s*flutter\s*$').hasMatch(line)) {
      return true;
    }
  }

  return false;
}

Future<ProcessResult> runPublishDryRunProcess(
  Directory workingDirectory, {
  PublishDryRunCommand command = dartPublishDryRunCommand,
}) {
  return Process.run(
    command.executable,
    command.arguments,
    workingDirectory: workingDirectory.path,
  ).timeout(
    publishDryRunTimeout,
    onTimeout: () => throw TimeoutException(
      'workspace publish dry-run timed out',
      publishDryRunTimeout,
    ),
  );
}

Directory _resolvePackageDirectory({
  required Directory repoRoot,
  required String packageName,
}) {
  if (packageName == 'llm_dart') {
    return repoRoot;
  }

  return Directory.fromUri(repoRoot.uri.resolve('packages/$packageName/'));
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

PublishDryRunSummary? extractPublishDryRunSummary(String text) {
  final match = RegExp(
    r'Package has (\d+) warnings?(?: and (\d+) hints?)?\.',
  ).firstMatch(text);
  if (match == null) {
    return null;
  }

  return PublishDryRunSummary(
    warnings: int.parse(match.group(1)!),
    hints: match.group(2) == null ? 0 : int.parse(match.group(2)!),
  );
}

int countWorkspaceOverridePublishDryRunHints(String text) {
  return RegExp(
    r'Non-dev dependencies are overridden in pubspec_overrides\.yaml\.',
  ).allMatches(text).length;
}

String extractPublishDryRunValidationDiagnostics(String text) {
  final validationIndex = text.indexOf('Validating package...');
  if (validationIndex >= 0) {
    return text.substring(validationIndex).trimRight();
  }

  final packageValidationIndex = text.indexOf('Package validation found');
  if (packageValidationIndex >= 0) {
    return text.substring(packageValidationIndex).trimRight();
  }

  final summaryIndex = text.indexOf(RegExp(r'Package has \d+ warnings?'));
  if (summaryIndex >= 0) {
    return text.substring(summaryIndex).trimRight();
  }

  return '';
}

Future<Directory> preparePackageDryRunDirectory({
  required String packageName,
  required Directory packageDirectory,
}) async {
  final tempDirectory = await Directory.systemTemp.createTemp(
    'llm_dart_publish_dry_run_',
  );
  await _copyDirectoryContents(
    isRootPackage: packageName == 'llm_dart',
    source: packageDirectory,
    destination: tempDirectory,
  );
  await _rewriteStagedPubspecPathEntries(
    sourceDirectory: packageDirectory,
    stagedPubspec: File.fromUri(tempDirectory.uri.resolve('pubspec.yaml')),
  );

  final overridesFile = File.fromUri(
    packageDirectory.uri.resolve('pubspec_overrides.yaml'),
  );
  if (overridesFile.existsSync()) {
    final rewrittenOverrides = await _rewriteOverridesWithAbsolutePaths(
      sourceDirectory: packageDirectory,
      overridesFile: overridesFile,
    );
    await File.fromUri(tempDirectory.uri.resolve('pubspec_overrides.yaml'))
        .writeAsString(rewrittenOverrides);
  }

  return tempDirectory;
}

Future<void> _copyDirectoryContents({
  required bool isRootPackage,
  required Directory source,
  required Directory destination,
}) async {
  await for (final entity in source.list(recursive: true, followLinks: false)) {
    final normalizedEntityPath =
        entity.path.replaceAll('\\', '/').replaceAll(RegExp(r'/+$'), '');
    final normalizedSourcePath =
        source.path.replaceAll('\\', '/').replaceAll(RegExp(r'/+$'), '');
    var relativePath =
        normalizedEntityPath.substring(normalizedSourcePath.length);
    relativePath = relativePath.replaceFirst(RegExp(r'^/+'), '');
    if (relativePath.isEmpty ||
        _shouldSkipCopiedPath(
          relativePath,
          isRootPackage: isRootPackage,
        )) {
      continue;
    }

    final targetUri = destination.uri.resolve(relativePath);
    if (entity is Directory) {
      await Directory.fromUri(targetUri).create(recursive: true);
      continue;
    }
    if (entity is! File) {
      continue;
    }

    final targetFile = File.fromUri(targetUri);
    await targetFile.parent.create(recursive: true);
    await entity.copy(targetFile.path);
  }
}

bool _shouldSkipCopiedPath(
  String relativePath, {
  required bool isRootPackage,
}) {
  final normalizedPath = relativePath.replaceAll('\\', '/');
  final firstSegment = normalizedPath.split('/').first;
  if (firstSegment == '.git' ||
      firstSegment == '.dart_tool' ||
      firstSegment == 'build' ||
      normalizedPath == 'pubspec_overrides.yaml' ||
      normalizedPath == 'pubspec.lock') {
    return true;
  }

  if (!isRootPackage) {
    return false;
  }

  return !_isRootPackagePublishPath(normalizedPath);
}

bool _isRootPackagePublishPath(String normalizedPath) {
  const rootPublishFiles = {
    '.gitignore',
    '.pubignore',
    'analysis_options.yaml',
    'CHANGELOG.md',
    'LICENSE',
    'README.md',
    'pubspec.yaml',
  };
  const rootPublishDirectories = {
    'example',
    'lib',
    'test',
  };

  if (rootPublishFiles.contains(normalizedPath)) {
    return true;
  }

  return rootPublishDirectories.contains(normalizedPath.split('/').first);
}

Future<String> _rewriteOverridesWithAbsolutePaths({
  required Directory sourceDirectory,
  required File overridesFile,
}) async {
  final lines = await overridesFile.readAsLines();
  final buffer = StringBuffer()
    ..writeln('# Generated for workspace publish dry-run staging.')
    ..writeln('dependency_overrides:');
  String? currentDependencyName;

  for (final rawLine in lines) {
    final dependencyMatch = RegExp(r'^  ([A-Za-z0-9_]+):$').firstMatch(rawLine);
    if (dependencyMatch != null) {
      currentDependencyName = dependencyMatch.group(1)!;
      continue;
    }

    final pathMatch =
        RegExp(r'^    path:\s+(.+)$').firstMatch(rawLine.trimRight());
    if (pathMatch == null || currentDependencyName == null) {
      continue;
    }

    final rawPath = pathMatch.group(1)!.trim();
    final resolvedPath = Directory.fromUri(
      sourceDirectory.uri.resolve(_stripQuotes(rawPath)),
    ).absolute.path.replaceAll('\\', '/');
    buffer
      ..writeln('  $currentDependencyName:')
      ..writeln('    path: "$resolvedPath"');
    currentDependencyName = null;
  }

  return buffer.toString();
}

String _stripQuotes(String value) {
  if ((value.startsWith('"') && value.endsWith('"')) ||
      (value.startsWith("'") && value.endsWith("'"))) {
    return value.substring(1, value.length - 1);
  }
  return value;
}

Future<void> _rewriteStagedPubspecPathEntries({
  required Directory sourceDirectory,
  required File stagedPubspec,
}) async {
  if (!stagedPubspec.existsSync()) {
    return;
  }

  final lines = await stagedPubspec.readAsLines();
  final rewrittenLines = <String>[];

  for (final line in lines) {
    final pathMatch = RegExp(r'^(\s*)path:\s+(.+)$').firstMatch(line);
    if (pathMatch == null) {
      rewrittenLines.add(line);
      continue;
    }

    final indentation = pathMatch.group(1)!;
    final rawPath = pathMatch.group(2)!.trim();
    final resolvedPath = Directory.fromUri(
      sourceDirectory.uri.resolve(_stripQuotes(rawPath)),
    ).absolute.path.replaceAll('\\', '/');
    rewrittenLines.add('${indentation}path: "$resolvedPath"');
  }

  await stagedPubspec.writeAsString('${rewrittenLines.join('\n')}\n');
}
