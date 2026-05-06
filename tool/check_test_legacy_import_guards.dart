import 'dart:io';

const List<String> _guardedTestDirs = [
  'test/core',
  'test/models',
  'test/builder',
  'test/utils',
];

final RegExp _legacyImportPattern = RegExp(
  r'''^\s*import\s+['"]package:llm_dart/legacy\.dart['"]''',
);

final class TestLegacyImportGuardResult {
  final List<String> violations;

  const TestLegacyImportGuardResult({
    required this.violations,
  });

  bool get passed => violations.isEmpty;
}

Future<TestLegacyImportGuardResult> evaluateTestLegacyImportGuards({
  Directory? repoRoot,
}) async {
  final resolvedRepoRoot = repoRoot ?? Directory.current;
  final violations = <String>[];

  for (final relativeDir in _guardedTestDirs) {
    final dir =
        Directory.fromUri(resolvedRepoRoot.uri.resolve('$relativeDir/'));
    if (!dir.existsSync()) {
      continue;
    }

    await _collectLegacyImportViolations(
      repoRoot: resolvedRepoRoot,
      dir: dir,
      violations: violations,
    );
  }

  return TestLegacyImportGuardResult(
    violations: List.unmodifiable(violations),
  );
}

Future<void> _collectLegacyImportViolations({
  required Directory repoRoot,
  required Directory dir,
  required List<String> violations,
}) async {
  await for (final entity in dir.list(recursive: true)) {
    if (entity is! File || !entity.path.endsWith('.dart')) {
      continue;
    }

    final lines = await entity.readAsLines();
    for (var index = 0; index < lines.length; index += 1) {
      final line = lines[index];
      if (!_legacyImportPattern.hasMatch(line)) {
        continue;
      }

      violations.add(
        '${_displayPath(repoRoot, entity)}:${index + 1}: foundational tests '
        'must import focused entrypoints instead of package:llm_dart/legacy.dart. '
        'Keep legacy.dart imports limited to explicit compatibility, provider, '
        'and integration coverage.',
      );
    }
  }
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
  final result = await evaluateTestLegacyImportGuards();

  if (result.passed) {
    stdout.writeln(
      'test legacy import guard passed: foundational test directories use '
      'focused entrypoints instead of the legacy barrel.',
    );
    return;
  }

  stderr.writeln(
    'test legacy import guard found ${result.violations.length} violation(s):',
  );
  for (final violation in result.violations) {
    stderr.writeln(violation);
  }
  exitCode = 1;
}
