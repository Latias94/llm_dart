import 'dart:io';

const List<String> _providerImplementationRoots = [
  'packages/llm_dart_openai/lib/src',
  'packages/llm_dart_google/lib/src',
  'packages/llm_dart_anthropic/lib/src',
  'packages/llm_dart_ollama/lib/src',
  'packages/llm_dart_elevenlabs/lib/src',
];

final RegExp _directProviderMetadataConstructorPattern = RegExp(
  r'\bProviderMetadata\s*\(',
);

final class ProviderMetadataNamespaceGuardResult {
  final List<String> violations;

  const ProviderMetadataNamespaceGuardResult({
    required this.violations,
  });

  bool get passed => violations.isEmpty;
}

Future<ProviderMetadataNamespaceGuardResult>
    evaluateProviderMetadataNamespaceGuards({
  Directory? repoRoot,
}) async {
  final resolvedRepoRoot = repoRoot ?? Directory.current;
  final violations = <String>[];

  for (final rootPath in _providerImplementationRoots) {
    final root = Directory.fromUri(resolvedRepoRoot.uri.resolve('$rootPath/'));
    if (!root.existsSync()) {
      violations.add(
        'provider metadata namespace guard failed: missing $rootPath.',
      );
      continue;
    }

    await _collectDirectProviderMetadataConstructorViolations(
      repoRoot: resolvedRepoRoot,
      root: root,
      violations: violations,
    );
  }

  return ProviderMetadataNamespaceGuardResult(
    violations: List.unmodifiable(violations),
  );
}

Future<void> _collectDirectProviderMetadataConstructorViolations({
  required Directory repoRoot,
  required Directory root,
  required List<String> violations,
}) async {
  await for (final entity in root.list(recursive: true)) {
    if (entity is! File) {
      continue;
    }

    final normalizedPath = entity.path.replaceAll('\\', '/');
    if (!normalizedPath.endsWith('.dart')) {
      continue;
    }

    final lines = await entity.readAsLines();
    for (var index = 0; index < lines.length; index += 1) {
      final line = lines[index];
      if (!_directProviderMetadataConstructorPattern.hasMatch(line)) {
        continue;
      }

      violations.add(
        '${_displayPath(repoRoot, entity)}:${index + 1}: provider packages '
        'must construct provider metadata through ProviderMetadata.forNamespace '
        'or a package-local namespace helper, not the raw ProviderMetadata '
        'constructor.',
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
  final result = await evaluateProviderMetadataNamespaceGuards();

  if (result.passed) {
    stdout.writeln(
      'provider metadata namespace guard passed: provider implementations '
      'construct metadata through namespace helpers.',
    );
    return;
  }

  stderr.writeln(
    'provider metadata namespace guard found ${result.violations.length} '
    'violation(s):',
  );
  for (final violation in result.violations) {
    stderr.writeln(violation);
  }
  exitCode = 1;
}
