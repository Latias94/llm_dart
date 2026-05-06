import 'dart:io';

const String _coreLibPath = 'packages/llm_dart_core/lib';

const Map<String, Set<String>> _allowedTypedefsByPath = {
  'packages/llm_dart_core/lib/src/common/transport_cancellation.dart': {
    'TransportCancellation',
    'TransportCancelledException',
  },
};

final RegExp _directiveStartPattern = RegExp(
  r'''^\s*(import|export)\s+['"]''',
);

final RegExp _typedefPattern = RegExp(
  r'^\s*typedef\s+([A-Za-z_][A-Za-z0-9_]*)\s*=\s*[^;]+;\s*$',
);

final class CoreCompatibilityShellGuardResult {
  final List<String> violations;

  const CoreCompatibilityShellGuardResult({
    required this.violations,
  });

  bool get passed => violations.isEmpty;
}

Future<CoreCompatibilityShellGuardResult> evaluateCoreCompatibilityShellGuard({
  Directory? repoRoot,
}) async {
  final resolvedRepoRoot = repoRoot ?? Directory.current;
  final coreLibDir = Directory.fromUri(
    resolvedRepoRoot.uri.resolve('$_coreLibPath/'),
  );
  final violations = <String>[];

  if (!coreLibDir.existsSync()) {
    violations.add(
      'core compatibility shell guard failed: $_coreLibPath/ directory not '
      'found from ${resolvedRepoRoot.path}',
    );
    return CoreCompatibilityShellGuardResult(
      violations: List.unmodifiable(violations),
    );
  }

  await for (final entity in coreLibDir.list(recursive: true)) {
    if (entity is! File || !entity.path.endsWith('.dart')) {
      continue;
    }

    await _collectFileViolations(
      repoRoot: resolvedRepoRoot,
      file: entity,
      violations: violations,
    );
  }

  return CoreCompatibilityShellGuardResult(
    violations: List.unmodifiable(violations),
  );
}

Future<void> _collectFileViolations({
  required Directory repoRoot,
  required File file,
  required List<String> violations,
}) async {
  final relativePath = _displayPath(repoRoot, file);
  final allowedTypedefs = _allowedTypedefsByPath[relativePath] ?? const {};
  final lines = await file.readAsLines();
  var inDirective = false;

  for (var index = 0; index < lines.length; index += 1) {
    final line = lines[index];
    final trimmed = line.trim();

    if (inDirective) {
      if (trimmed.endsWith(';')) {
        inDirective = false;
      }
      continue;
    }

    if (_isAllowedTrivia(trimmed) || trimmed == 'library;') {
      continue;
    }

    if (_directiveStartPattern.hasMatch(line)) {
      if (!trimmed.endsWith(';')) {
        inDirective = true;
      }
      continue;
    }

    if (trimmed.startsWith('@Deprecated(') && allowedTypedefs.isNotEmpty) {
      continue;
    }

    final typedefMatch = _typedefPattern.firstMatch(line);
    if (typedefMatch != null) {
      final typedefName = typedefMatch.group(1)!;
      if (allowedTypedefs.contains(typedefName)) {
        continue;
      }

      violations.add(
        '$relativePath:${index + 1}: unexpected typedef `$typedefName`. '
        'Only compatibility aliases explicitly listed in the core shell guard '
        'are allowed in llm_dart_core.',
      );
      continue;
    }

    violations.add(
      '$relativePath:${index + 1}: llm_dart_core is a compatibility shell; '
      'move implementation ownership to llm_dart_provider or llm_dart_ai. '
      'Disallowed line: ${_preview(trimmed)}',
    );
  }
}

bool _isAllowedTrivia(String trimmed) {
  return trimmed.isEmpty ||
      trimmed.startsWith('//') ||
      trimmed.startsWith('/*') ||
      trimmed.startsWith('*') ||
      trimmed.startsWith('*/');
}

String _displayPath(Directory repoRoot, File file) {
  final repoPath = repoRoot.absolute.path.replaceAll('\\', '/');
  final filePath = file.absolute.path.replaceAll('\\', '/');
  if (filePath.startsWith('$repoPath/')) {
    return filePath.substring(repoPath.length + 1);
  }
  return filePath;
}

String _preview(String value) {
  const maxLength = 96;
  if (value.length <= maxLength) {
    return value;
  }
  return '${value.substring(0, maxLength - 3)}...';
}

Future<void> main() async {
  final result = await evaluateCoreCompatibilityShellGuard();

  if (result.passed) {
    stdout.writeln(
      'core compatibility shell guard passed: llm_dart_core/lib only contains '
      'public re-exports and approved compatibility aliases.',
    );
    return;
  }

  stderr.writeln(
    'core compatibility shell guard found ${result.violations.length} '
    'violation(s):',
  );
  for (final violation in result.violations) {
    stderr.writeln(violation);
  }
  exitCode = 1;
}
