import 'dart:io';

final RegExp _rootOrCoreImportPattern = RegExp(
  r'''^\s*(import|export)\s+['"]package:llm_dart(?:_core)?/[^'"]+['"]''',
);

final RegExp _transportPublicProviderLeakPattern = RegExp(
  r'ProviderCancellation|ProviderCancelledException',
);

final class TransportBoundaryGuardResult {
  final List<String> violations;

  const TransportBoundaryGuardResult({
    required this.violations,
  });

  bool get passed => violations.isEmpty;
}

Future<TransportBoundaryGuardResult> evaluateTransportBoundaryGuards({
  Directory? repoRoot,
}) async {
  final resolvedRepoRoot = repoRoot ?? Directory.current;
  final transportLibDir = Directory.fromUri(
    resolvedRepoRoot.uri.resolve('packages/llm_dart_transport/lib/'),
  );
  final violations = <String>[];

  if (!transportLibDir.existsSync()) {
    violations.add(
      'transport boundary guard failed: packages/llm_dart_transport/lib/ '
      'directory not found from ${resolvedRepoRoot.path}',
    );
    return TransportBoundaryGuardResult(
      violations: List.unmodifiable(violations),
    );
  }

  await _collectImportViolations(
    repoRoot: resolvedRepoRoot,
    transportLibDir: transportLibDir,
    violations: violations,
  );
  await _collectPublicSurfaceViolations(
    repoRoot: resolvedRepoRoot,
    transportLibDir: transportLibDir,
    violations: violations,
  );

  return TransportBoundaryGuardResult(
    violations: List.unmodifiable(violations),
  );
}

Future<void> _collectImportViolations({
  required Directory repoRoot,
  required Directory transportLibDir,
  required List<String> violations,
}) async {
  await for (final entity in transportLibDir.list(recursive: true)) {
    if (entity is! File || !entity.path.endsWith('.dart')) {
      continue;
    }

    final lines = await entity.readAsLines();
    for (var index = 0; index < lines.length; index += 1) {
      final line = lines[index];
      if (!_rootOrCoreImportPattern.hasMatch(line)) {
        continue;
      }

      violations.add(
        '${_displayPath(repoRoot, entity)}:${index + 1}: transport library '
        'files must not import or export package:llm_dart/... or '
        'package:llm_dart_core/...; keep transport dependent only on its own '
        'package surface and llm_dart_provider.',
      );
    }
  }
}

Future<void> _collectPublicSurfaceViolations({
  required Directory repoRoot,
  required Directory transportLibDir,
  required List<String> violations,
}) async {
  final publicBarrel = File.fromUri(
    transportLibDir.uri.resolve('llm_dart_transport.dart'),
  );

  if (!publicBarrel.existsSync()) {
    violations.add(
      'transport boundary guard failed: public barrel not found at '
      '${_displayPath(repoRoot, publicBarrel)}',
    );
    return;
  }

  final lines = await publicBarrel.readAsLines();
  for (var index = 0; index < lines.length; index += 1) {
    final line = lines[index];
    if (!_transportPublicProviderLeakPattern.hasMatch(line)) {
      continue;
    }

    violations.add(
      '${_displayPath(repoRoot, publicBarrel)}:${index + 1}: public transport '
      'surface must expose TransportCancellation names, not provider legacy '
      'aliases. Disallowed line: ${_preview(line.trim())}',
    );
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

String _preview(String value) {
  const maxLength = 96;
  if (value.length <= maxLength) {
    return value;
  }
  return '${value.substring(0, maxLength - 3)}...';
}

Future<void> main() async {
  final result = await evaluateTransportBoundaryGuards();

  if (result.passed) {
    stdout.writeln(
      'transport boundary guard passed: transport lib does not leak root/core '
      'imports and the public barrel stays on transport-owned names.',
    );
    return;
  }

  stderr.writeln(
    'transport boundary guard found ${result.violations.length} violation(s):',
  );
  for (final violation in result.violations) {
    stderr.writeln(violation);
  }
  exitCode = 1;
}
