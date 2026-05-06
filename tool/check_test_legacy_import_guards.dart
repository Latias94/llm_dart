import 'dart:io';

const List<String> _guardedTestDirs = [
  'test/core',
  'test/models',
  'test/builder',
  'test/utils',
];

const List<String> _guardedProviderTestFileSuffixes = [
  '_config_test.dart',
  '_factory_test.dart',
  '_client_test.dart',
  '_client_error_test.dart',
  '_provider_test.dart',
  '_tool_calling_test.dart',
  '_thinking_test.dart',
  '_tts_test.dart',
  '_audio_support_test.dart',
];

const Set<String> _guardedProviderTestFiles = {
  'test/providers/factories/base_factory_test.dart',
  'test/providers/openai/builtin_tools_test.dart',
  'test/providers/xai/live_search_test.dart',
  'test/providers/anthropic/anthropic_api_request_structure_test.dart',
  'test/providers/anthropic/anthropic_caching_test.dart',
  'test/providers/anthropic/anthropic_cache_invalidation_test.dart',
  'test/providers/anthropic/anthropic_cache_position_test.dart',
  'test/providers/anthropic/anthropic_chat_stream_support_test.dart',
  'test/providers/anthropic/anthropic_json_request_body_test.dart',
  'test/providers/anthropic/anthropic_messagebuilder_tools_fix_test.dart',
  'test/providers/anthropic/anthropic_prompt_caching_comprehensive_test.dart',
  'test/providers/anthropic/anthropic_tools_api_structure_test.dart',
  'test/providers/anthropic/anthropic_tools_duplication_fix_test.dart',
  'test/providers/anthropic/anthropic_tool_caching_unified_test.dart',
};

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
      category: 'foundational tests',
    );
  }

  final providerDir =
      Directory.fromUri(resolvedRepoRoot.uri.resolve('test/providers/'));
  if (providerDir.existsSync()) {
    await _collectLegacyImportViolations(
      repoRoot: resolvedRepoRoot,
      dir: providerDir,
      violations: violations,
      category: 'targeted provider tests',
      includeFile: (file) => _isGuardedProviderTestFile(
        repoRoot: resolvedRepoRoot,
        file: file,
      ),
    );
  }

  return TestLegacyImportGuardResult(
    violations: List.unmodifiable(violations),
  );
}

typedef _FileFilter = bool Function(File file);

Future<void> _collectLegacyImportViolations({
  required Directory repoRoot,
  required Directory dir,
  required List<String> violations,
  required String category,
  _FileFilter? includeFile,
}) async {
  await for (final entity in dir.list(recursive: true)) {
    if (entity is! File || !entity.path.endsWith('.dart')) {
      continue;
    }
    if (includeFile != null && !includeFile(entity)) {
      continue;
    }

    final lines = await entity.readAsLines();
    for (var index = 0; index < lines.length; index += 1) {
      final line = lines[index];
      if (!_legacyImportPattern.hasMatch(line)) {
        continue;
      }

      violations.add(
        '${_displayPath(repoRoot, entity)}:${index + 1}: $category '
        'must import focused entrypoints instead of package:llm_dart/legacy.dart. '
        'Keep legacy.dart imports limited to explicit compatibility, bridge, '
        'and integration coverage.',
      );
    }
  }
}

bool _isGuardedProviderTestFile({
  required Directory repoRoot,
  required File file,
}) {
  final path = _displayPath(repoRoot, file);
  return _guardedProviderTestFiles.contains(path) ||
      _guardedProviderTestFileSuffixes.any(path.endsWith);
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
      'test legacy import guard passed: guarded foundational and provider '
      'tests use focused entrypoints instead of the legacy barrel.',
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
