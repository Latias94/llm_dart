import 'dart:io';

final RegExp _legacyImportPattern = RegExp(
  r'''^\s*import\s+['"]package:llm_dart/legacy\.dart['"]''',
);

final RegExp _builderImportPattern = RegExp(
  r'''^\s*import\s+['"]package:llm_dart/builder/''',
);

final RegExp _providerCompatibilityImportPattern = RegExp(
  r'''^\s*import\s+['"]package:llm_dart/providers/''',
);

final RegExp _modelCompatibilityImportPattern = RegExp(
  r'''^\s*import\s+['"]package:llm_dart/models/''',
);

final RegExp _coreSubpathCompatibilityImportPattern = RegExp(
  r'''^\s*import\s+['"]package:llm_dart/core/''',
);

final RegExp _llmBuilderPattern = RegExp(r'\bLLMBuilder\s*\(');

final RegExp _removedAiHelperPattern = RegExp(r'(^|[^\w.])ai\s*\(');

final RegExp _groupedFacadePattern = RegExp(r'\bllm\s*\.\s*AI\b');

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
    final lines = await entity.readAsLines();
    for (var index = 0; index < lines.length; index += 1) {
      final violation = _findViolation(lines[index]);
      if (violation == null) {
        continue;
      }

      violations.add(
        '$path:${index + 1}: $violation. '
        'Default examples should teach model-first entrypoints and focused '
        'modern barrels; move provider-native material to focused provider '
        'entrypoints instead of legacy root subpaths.',
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
  if (_providerCompatibilityImportPattern.hasMatch(line)) {
    return 'legacy provider compatibility import found';
  }
  if (_modelCompatibilityImportPattern.hasMatch(line)) {
    return 'legacy model compatibility import found';
  }
  if (_coreSubpathCompatibilityImportPattern.hasMatch(line)) {
    return 'legacy core subpath import found';
  }
  if (_llmBuilderPattern.hasMatch(line)) {
    return 'LLMBuilder usage found';
  }
  if (_removedAiHelperPattern.hasMatch(line)) {
    return 'removed ai() helper usage found';
  }
  if (_groupedFacadePattern.hasMatch(line)) {
    return 'grouped AI facade usage found';
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
      'LLMBuilder(), legacy provider/model/core subpaths, the removed '
      'ai() helper, and grouped AI facade usage.',
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
