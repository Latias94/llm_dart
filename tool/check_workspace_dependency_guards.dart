import 'dart:io';

final RegExp _rootPackageImportPattern = RegExp(
  r'''^\s*(import|export)\s+['"]package:llm_dart/[^'"]+['"]''',
);

const Map<String, Set<String>> _allowedRuntimeDependenciesByPackage = {
  'llm_dart': {
    'llm_dart_anthropic',
    'llm_dart_ai',
    'llm_dart_chat',
    'llm_dart_community',
    'llm_dart_google',
    'llm_dart_openai',
    'llm_dart_provider',
    'llm_dart_transport',
  },
  'llm_dart_anthropic': {
    'llm_dart_provider',
    'llm_dart_transport',
  },
  'llm_dart_ai': {
    'llm_dart_provider',
  },
  'llm_dart_chat': {
    'llm_dart_provider',
    'llm_dart_transport',
  },
  'llm_dart_community': {
    'llm_dart_provider',
    'llm_dart_transport',
  },
  'llm_dart_core': {
    'llm_dart_ai',
    'llm_dart_provider',
  },
  'llm_dart_flutter': {
    'flutter',
    'llm_dart_chat',
    'llm_dart_provider',
  },
  'llm_dart_google': {
    'llm_dart_provider',
    'llm_dart_transport',
  },
  'llm_dart_openai': {
    'llm_dart_provider',
    'llm_dart_transport',
  },
  'llm_dart_provider': {},
  'llm_dart_test': {
    'llm_dart_provider',
    'llm_dart_transport',
  },
  'llm_dart_transport': {
    'dio',
    'llm_dart_provider',
    'logging',
  },
};

final class WorkspaceDependencyGuardResult {
  final List<String> violations;

  const WorkspaceDependencyGuardResult({
    required this.violations,
  });

  bool get passed => violations.isEmpty;
}

Future<WorkspaceDependencyGuardResult> evaluateWorkspaceDependencyGuards({
  Directory? repoRoot,
}) async {
  final resolvedRepoRoot = repoRoot ?? Directory.current;
  final packagesDir = Directory.fromUri(
    resolvedRepoRoot.uri.resolve('packages/'),
  );
  final violations = <String>[];

  if (!packagesDir.existsSync()) {
    violations.add(
      'workspace guard failed: packages/ directory not found from '
      '${resolvedRepoRoot.path}',
    );
    return WorkspaceDependencyGuardResult(
      violations: List.unmodifiable(violations),
    );
  }

  await _collectImportViolations(
    repoRoot: resolvedRepoRoot,
    packagesDir: packagesDir,
    violations: violations,
  );
  await _collectPubspecPolicyViolations(
    repoRoot: resolvedRepoRoot,
    packagesDir: packagesDir,
    violations: violations,
  );

  return WorkspaceDependencyGuardResult(
    violations: List.unmodifiable(violations),
  );
}

Future<void> _collectImportViolations({
  required Directory repoRoot,
  required Directory packagesDir,
  required List<String> violations,
}) async {
  await for (final entity in packagesDir.list(recursive: true)) {
    if (entity is! File) {
      continue;
    }

    final normalizedPath = entity.path.replaceAll('\\', '/');
    if (!normalizedPath.endsWith('.dart')) {
      continue;
    }

    if (!normalizedPath.contains('/lib/')) {
      continue;
    }

    final lines = await entity.readAsLines();
    for (var index = 0; index < lines.length; index += 1) {
      final line = lines[index];
      if (!_rootPackageImportPattern.hasMatch(line)) {
        continue;
      }

      violations.add(
        '${_displayPath(repoRoot, entity)}:${index + 1}: '
        'package implementation files must not import or export '
        'package:llm_dart/...; depend on the owning workspace package instead.',
      );
    }
  }
}

Future<void> _collectPubspecPolicyViolations({
  required Directory repoRoot,
  required Directory packagesDir,
  required List<String> violations,
}) async {
  final pubspecFiles = <File>[];
  final rootPubspec = File.fromUri(repoRoot.uri.resolve('pubspec.yaml'));
  if (rootPubspec.existsSync()) {
    pubspecFiles.add(rootPubspec);
  } else {
    violations.add(
      'workspace guard failed: pubspec.yaml not found from ${repoRoot.path}',
    );
  }

  await for (final entity in packagesDir.list(recursive: true)) {
    if (entity is! File || entity.uri.pathSegments.last != 'pubspec.yaml') {
      continue;
    }
    pubspecFiles.add(entity);
  }

  for (final pubspecFile in pubspecFiles) {
    final lines = await pubspecFile.readAsLines();
    final packageName = _readPubspecName(lines);
    if (packageName == null) {
      violations.add(
        '${_displayPath(repoRoot, pubspecFile)}: missing top-level `name:`.',
      );
      continue;
    }

    final allowedDependencies =
        _allowedRuntimeDependenciesByPackage[packageName];
    if (allowedDependencies == null) {
      violations.add(
        '${_displayPath(repoRoot, pubspecFile)}: package `$packageName` is '
        'missing from the workspace dependency policy map.',
      );
      continue;
    }

    final runtimeDependencies = _readTopLevelSectionKeys(
      lines,
      sectionName: 'dependencies',
    );
    final unexpectedDependencies =
        runtimeDependencies.difference(allowedDependencies).toList()..sort();
    if (unexpectedDependencies.isEmpty) {
      continue;
    }

    violations.add(
      '${_displayPath(repoRoot, pubspecFile)}: package `$packageName` has '
      'unexpected runtime dependencies: ${unexpectedDependencies.join(', ')}. '
      'Allowed runtime dependencies: '
      '${allowedDependencies.toList()..sort()}.',
    );
  }
}

String? _readPubspecName(List<String> lines) {
  for (final rawLine in lines) {
    final line = rawLine.trim();
    if (line.isEmpty || line.startsWith('#')) {
      continue;
    }

    if (!line.startsWith('name:')) {
      continue;
    }

    final name = line.substring('name:'.length).trim();
    if (name.isEmpty) {
      return null;
    }
    return name;
  }

  return null;
}

Set<String> _readTopLevelSectionKeys(
  List<String> lines, {
  required String sectionName,
}) {
  final keys = <String>{};
  var inSection = false;

  for (final rawLine in lines) {
    final line = rawLine.replaceAll('\t', '  ');
    final trimmed = line.trim();

    if (trimmed.isEmpty || trimmed.startsWith('#')) {
      continue;
    }

    if (!line.startsWith(' ')) {
      if (trimmed == '$sectionName:') {
        inSection = true;
        continue;
      }

      if (inSection) {
        break;
      }
    }

    if (!inSection) {
      continue;
    }

    final match = RegExp(r'^  ([A-Za-z0-9_]+):(?:\s|$)').firstMatch(line);
    if (match != null) {
      keys.add(match.group(1)!);
    }
  }

  return keys;
}

String _displayPath(Directory repoRoot, File file) {
  final repoPath = repoRoot.absolute.path.replaceAll('\\', '/');
  final filePath = file.absolute.path.replaceAll('\\', '/');
  if (filePath.startsWith('$repoPath/')) {
    return filePath.substring(repoPath.length + 1);
  }
  return filePath;
}

Future<void> main() async {
  final result = await evaluateWorkspaceDependencyGuards();

  if (result.passed) {
    stdout.writeln(
      'workspace dependency guard passed: no package implementation files '
      'import package:llm_dart/... and no workspace pubspec policies were '
      'violated.',
    );
    return;
  }

  stderr.writeln(
    'workspace dependency guard found ${result.violations.length} violation(s):',
  );
  for (final violation in result.violations) {
    stderr.writeln(violation);
  }
  exitCode = 1;
}
