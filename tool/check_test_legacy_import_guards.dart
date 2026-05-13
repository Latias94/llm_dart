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
  'test/compat_transport_test.dart',
  'test/integration/memorial_on_dispatching_troops_streaming_test.dart',
  'test/integration/thinking_content_extraction_test.dart',
  'test/integration/thinking_tags_streaming_test.dart',
  'test/integration/utf8_streaming_test.dart',
  'test/user_message_tool_caching_test.dart',
};

final RegExp _legacyImportPattern = RegExp(
  r'''^\s*import\s+['"]package:llm_dart/legacy\.dart['"]''',
);

final RegExp _legacySubpathImportPattern = RegExp(
  r'''^\s*import\s+['"]package:llm_dart/(builder|models|providers|core)/''',
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
  bool strictRootLegacySubpaths = true,
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
      strictRootLegacySubpaths: strictRootLegacySubpaths,
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
      strictRootLegacySubpaths: strictRootLegacySubpaths,
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
  required bool strictRootLegacySubpaths,
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
        if (!strictRootLegacySubpaths ||
            !_legacySubpathImportPattern.hasMatch(line)) {
          continue;
        }

        violations.add(
          '${_displayPath(repoRoot, entity)}:${index + 1}: $category '
          'must import focused entrypoints instead of root legacy subpaths '
          '`builder`, `models`, `providers`, or legacy `core`. Keep remaining '
          'root subpath imports limited to explicit migration inventory until '
          'the root legacy implementation is deleted.',
        );
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

Future<void> main(List<String> arguments) async {
  var strictRootLegacySubpaths = true;
  for (final argument in arguments) {
    switch (argument) {
      case '--strict-root-legacy-subpaths':
        strictRootLegacySubpaths = true;
      case '--allow-root-legacy-subpaths':
        strictRootLegacySubpaths = false;
      default:
        stderr.writeln('unknown option `$argument`');
        stderr.writeln(
          'usage: dart tool/check_test_legacy_import_guards.dart '
          '[--strict-root-legacy-subpaths|--allow-root-legacy-subpaths]',
        );
        exitCode = 64;
        return;
    }
  }

  final result = await evaluateTestLegacyImportGuards(
    strictRootLegacySubpaths: strictRootLegacySubpaths,
  );

  if (result.passed) {
    stdout.writeln(
      'test legacy import guard passed: guarded foundational and provider '
      'tests use focused entrypoints instead of the legacy barrel'
      '${strictRootLegacySubpaths ? ' and root legacy subpaths' : ''}.',
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
