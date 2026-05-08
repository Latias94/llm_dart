import 'dart:io';

const Map<String, String> _allowedCompatibilityExamples = {
  'example/02_core_features/capability_detection.dart':
      'registry metadata still uses the compatibility provider registry',
  'example/02_core_features/capability_factory_methods.dart':
      'documents typed build* migration helpers for the legacy builder',
  'example/02_core_features/provider_specific_builders.dart':
      'documents provider callback migration helpers for the legacy builder',
};

final RegExp _legacyImportPattern = RegExp(
  r'''^\s*import\s+['"]package:llm_dart/legacy\.dart['"]''',
);

final RegExp _builderImportPattern = RegExp(
  r'''^\s*import\s+['"]package:llm_dart/builder/''',
);

final RegExp _llmBuilderPattern = RegExp(r'\bLLMBuilder\s*\(');

final RegExp _deprecatedAiHelperPattern = RegExp(r'(^|[^\w.])ai\s*\(');

final class ExampleApiGuardResult {
  final List<String> violations;

  const ExampleApiGuardResult({
    required this.violations,
  });

  bool get passed => violations.isEmpty;
}

Future<ExampleApiGuardResult> evaluateExampleApiGuards({
  Directory? repoRoot,
}) async {
  final resolvedRepoRoot = repoRoot ?? Directory.current;
  final exampleDir =
      Directory.fromUri(resolvedRepoRoot.uri.resolve('example/'));
  final violations = <String>[];

  if (!exampleDir.existsSync()) {
    return const ExampleApiGuardResult(violations: []);
  }

  await for (final entity in exampleDir.list(recursive: true)) {
    if (entity is! File || !entity.path.endsWith('.dart')) {
      continue;
    }

    final path = _displayPath(resolvedRepoRoot, entity);
    if (_allowedCompatibilityExamples.containsKey(path)) {
      continue;
    }

    final lines = await entity.readAsLines();
    for (var index = 0; index < lines.length; index += 1) {
      final violation = _findViolation(lines[index]);
      if (violation == null) {
        continue;
      }

      violations.add(
        '$path:${index + 1}: $violation. '
        'Default examples should teach model-first entrypoints; move '
        'compatibility material to an explicitly allowlisted appendix or '
        'update this guard with a reason.',
      );
    }
  }

  return ExampleApiGuardResult(
    violations: List.unmodifiable(violations),
  );
}

String? _findViolation(String line) {
  if (_legacyImportPattern.hasMatch(line)) {
    return 'legacy barrel import found';
  }
  if (_builderImportPattern.hasMatch(line)) {
    return 'legacy builder import found';
  }
  if (_llmBuilderPattern.hasMatch(line)) {
    return 'LLMBuilder usage found';
  }
  if (_deprecatedAiHelperPattern.hasMatch(line)) {
    return 'deprecated ai() helper usage found';
  }
  return null;
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
  final result = await evaluateExampleApiGuards();

  if (result.passed) {
    stdout.writeln(
      'example API guard passed: default examples avoid legacy.dart, '
      'LLMBuilder(), and the deprecated ai() helper outside explicit '
      'compatibility appendices.',
    );
    return;
  }

  stderr.writeln(
    'example API guard found ${result.violations.length} violation(s):',
  );
  for (final violation in result.violations) {
    stderr.writeln(violation);
  }
  exitCode = 1;
}
