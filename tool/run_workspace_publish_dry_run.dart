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

    final workingDirectory = packageName == 'llm_dart'
        ? packageDirectory
        : await _preparePackageDryRunDirectory(
            packageDirectory: packageDirectory,
          );
    try {
      final result = await Process.run(
        'dart',
        const ['pub', 'publish', '--dry-run'],
        workingDirectory: workingDirectory.path,
      );

      final stdoutText = result.stdout is String ? result.stdout as String : '';
      final stderrText = result.stderr is String ? result.stderr as String : '';

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

      if (result.exitCode != 0) {
        stderr.writeln(
          'workspace publish dry-run failed for `$packageName` with exit code '
          '${result.exitCode}.',
        );
        exitCode = result.exitCode;
        return;
      }

      final summary = extractPublishDryRunSummary('$stdoutText\n$stderrText');
      if (summary != null && summary.warnings > 0) {
        stderr.writeln(
          'workspace publish dry-run failed for `$packageName`: '
          '${summary.warnings} warning(s) detected.',
        );
        exitCode = 1;
        return;
      }

      if (summary != null) {
        stdout.writeln(
          'dry-run summary for `$packageName`: '
          '${summary.warnings} warning(s), ${summary.hints} hint(s).',
        );
      }
    } finally {
      if (packageName != 'llm_dart' && workingDirectory.existsSync()) {
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

Directory _resolvePackageDirectory({
  required Directory repoRoot,
  required String packageName,
}) {
  if (packageName == 'llm_dart') {
    return repoRoot;
  }

  return Directory.fromUri(repoRoot.uri.resolve('packages/$packageName/'));
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

Future<Directory> _preparePackageDryRunDirectory({
  required Directory packageDirectory,
}) async {
  final tempDirectory = await Directory.systemTemp.createTemp(
    'llm_dart_publish_dry_run_',
  );
  await _copyDirectoryContents(
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
    if (relativePath.isEmpty || _shouldSkipCopiedPath(relativePath)) {
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

bool _shouldSkipCopiedPath(String relativePath) {
  final normalizedPath = relativePath.replaceAll('\\', '/');
  return normalizedPath == 'pubspec_overrides.yaml' ||
      normalizedPath == 'pubspec.lock' ||
      normalizedPath == '.dart_tool' ||
      normalizedPath.startsWith('.dart_tool/') ||
      normalizedPath == 'build' ||
      normalizedPath.startsWith('build/');
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
