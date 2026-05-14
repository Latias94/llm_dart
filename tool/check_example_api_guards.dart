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

final RegExp _providerPromptTypePattern = RegExp(
  r'\b(?:PromptMessage|UserPromptMessage|SystemPromptMessage|'
  r'AssistantPromptMessage|ToolPromptMessage|PromptPart|PromptRole)\b',
);

final RegExp _textCallStartPattern = RegExp(
  r'\b(?:generateTextCall|streamTextCall)(?:<[^(\n]*>)?\s*\(',
);

final RegExp _promptArgumentPattern = RegExp(r'(^|[({,\s])prompt\s*:');

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
    if (entity is! File || !_isScannableExampleFile(entity)) {
      continue;
    }

    final path = _displayPath(resolvedRepoRoot, entity);
    final lines = await entity.readAsLines();
    final isDefaultTeachingFile = _isDefaultTeachingFile(path);
    final checksTextCallPromptBoundary =
        isDefaultTeachingFile || _isProviderReadmeFile(path);
    final shouldCheckLegacyApi =
        path.endsWith('.dart') || isDefaultTeachingFile;

    for (var index = 0; index < lines.length; index += 1) {
      if (shouldCheckLegacyApi) {
        final violation = _findLegacyApiViolation(lines[index]);
        if (violation != null) {
          violations.add(
            '$path:${index + 1}: $violation. '
            'Default examples should teach model-first entrypoints and '
            'focused modern barrels; move provider-native material to focused '
            'provider entrypoints instead of legacy root subpaths.',
          );
        }
      }

      if (!isDefaultTeachingFile) {
        continue;
      }

      final violation = _findProviderPromptBoundaryViolation(lines[index]);
      if (violation == null) {
        continue;
      }
      violations.add(
        '$path:${index + 1}: $violation. '
        'Default app-facing examples should use ModelMessage with messages:; '
        'reserve PromptMessage and prompt: for provider-contract, replay, '
        'transport, snapshot, and advanced runtime boundaries.',
      );
    }

    if (checksTextCallPromptBoundary) {
      for (final violation in _findTextCallPromptArgumentViolations(lines)) {
        violations.add(
          '$path:${violation.lineNumber}: ${violation.message}. '
          'Default app-facing examples should use ModelMessage with messages:; '
          'reserve PromptMessage and prompt: for provider-contract, replay, '
          'transport, snapshot, and advanced runtime boundaries.',
        );
      }
    }
  }

  return ExampleApiGuardResult(
    violations: List.unmodifiable(violations),
  );
}

String? _findLegacyApiViolation(String line) {
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

String? _findProviderPromptBoundaryViolation(String line) {
  if (_providerPromptTypePattern.hasMatch(line)) {
    return 'provider prompt message type found';
  }
  return null;
}

List<_LineViolation> _findTextCallPromptArgumentViolations(
  List<String> lines,
) {
  final violations = <_LineViolation>[];
  var inTextCall = false;
  var parenthesisBalance = 0;

  for (var index = 0; index < lines.length; index += 1) {
    final line = lines[index];

    if (!inTextCall && _textCallStartPattern.hasMatch(line)) {
      inTextCall = true;
      parenthesisBalance = 0;
    }

    if (!inTextCall) {
      continue;
    }

    if (_promptArgumentPattern.hasMatch(line)) {
      violations.add(
        _LineViolation(
          lineNumber: index + 1,
          message: 'text-call prompt argument found',
        ),
      );
    }

    parenthesisBalance += _parenthesisDelta(line);
    if (parenthesisBalance <= 0 && line.contains(')')) {
      inTextCall = false;
    }
  }

  return violations;
}

int _parenthesisDelta(String line) {
  var delta = 0;
  for (final codeUnit in line.codeUnits) {
    if (codeUnit == 40) {
      delta += 1;
    } else if (codeUnit == 41) {
      delta -= 1;
    }
  }
  return delta;
}

bool _isScannableExampleFile(File file) {
  return file.path.endsWith('.dart') || file.path.endsWith('.md');
}

bool _isDefaultTeachingFile(String path) {
  return path.startsWith('example/01_getting_started/') ||
      path.startsWith('example/02_core_features/') ||
      path.startsWith('example/05_use_cases/');
}

bool _isProviderReadmeFile(String path) {
  return path.startsWith('example/04_providers/') &&
      path.endsWith('/README.md');
}

String _displayPath(Directory repoRoot, File file) {
  final repoPath = repoRoot.absolute.path.replaceAll('\\', '/');
  final filePath = file.absolute.path.replaceAll('\\', '/');
  if (filePath.startsWith('$repoPath/')) {
    return filePath.substring(repoPath.length + 1);
  }
  return filePath;
}

final class _LineViolation {
  final int lineNumber;
  final String message;

  const _LineViolation({
    required this.lineNumber,
    required this.message,
  });
}

Future<void> main() async {
  final result = await evaluateExampleApiGuards();

  if (result.passed) {
    stdout.writeln(
      'example API guard passed: default examples avoid legacy.dart, '
      'LLMBuilder(), legacy provider/model/core subpaths, the removed '
      'ai() helper, grouped AI facade usage, and provider prompt surfaces in '
      'app-facing text calls.',
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
