import 'dart:io';

final RegExp _rootPackageImportPattern = RegExp(
  r"^\s*(import|export)\s+'package:llm_dart/[^']+'",
);

Future<void> main() async {
  final repoRoot = Directory.current;
  final packagesDir = Directory.fromUri(
    repoRoot.uri.resolve('packages/'),
  );

  if (!packagesDir.existsSync()) {
    stderr.writeln(
      'workspace guard failed: packages/ directory not found from ${repoRoot.path}',
    );
    exitCode = 1;
    return;
  }

  final violations = <String>[];

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
        '${entity.path.replaceAll('\\', '/')}:${index + 1}: '
        'package implementation files must not import or export '
        'package:llm_dart/...; depend on the owning workspace package instead.',
      );
    }
  }

  if (violations.isEmpty) {
    stdout.writeln(
      'workspace dependency guard passed: no package implementation files '
      'import package:llm_dart/...',
    );
    return;
  }

  stderr.writeln('workspace dependency guard found ${violations.length} violation(s):');
  for (final violation in violations) {
    stderr.writeln(violation);
  }
  exitCode = 1;
}
