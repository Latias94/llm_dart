import 'dart:io';

const Set<String> _allowedRootTopLevelDirectories = {
  'builder',
  'core',
  'models',
  'providers',
  'src',
  'utils',
};

const Set<String> _allowedRootTopLevelFiles = {
  'ai.dart',
  'anthropic.dart',
  'chat.dart',
  'core.dart',
  'google.dart',
  'legacy.dart',
  'llm_dart.dart',
  'openai.dart',
  'transport.dart',
};

const Set<String> _allowedRootSrcTopLevelDirectories = {
  'bootstrap',
  'compatibility',
  'config',
  'facade',
};

const Set<String> _allowedRootSrcTopLevelFiles = {
  'dio_cancellation_adapter.dart',
  'dio_error_handler.dart',
  'google_openai_transformers.dart',
  'llm_error_types.dart',
  'openai_compatible_configs.dart',
  'provider_defaults.dart',
};

final RegExp _flutterImportPattern = RegExp(
  r'''^\s*(import|export)\s+['"]package:llm_dart_flutter/[^'"]+['"]''',
);

final RegExp _chatImportPattern = RegExp(
  r'''^\s*(import|export)\s+['"]package:llm_dart_chat/[^'"]+['"]''',
);

final RegExp _legacyImportPattern = RegExp(
  r'''^\s*(import|export)\s+['"]package:llm_dart/legacy\.dart['"]''',
);

const List<String> _expectedDefaultRootEntrypointDirectives = [
  'library;',
  "export 'ai.dart';",
];

const Map<String, List<String>> _expectedFocusedRootEntrypointDirectives = {
  'lib/anthropic.dart': [
    'library;',
    "export 'package:llm_dart_anthropic/llm_dart_anthropic.dart';",
  ],
  'lib/google.dart': [
    'library;',
    "export 'package:llm_dart_google/llm_dart_google.dart';",
  ],
  'lib/openai.dart': [
    'library;',
    "export 'package:llm_dart_openai/llm_dart_openai.dart';",
  ],
};

final class RootPackageBoundaryGuardResult {
  final List<String> violations;

  const RootPackageBoundaryGuardResult({
    required this.violations,
  });

  bool get passed => violations.isEmpty;
}

Future<RootPackageBoundaryGuardResult> evaluateRootPackageBoundaryGuards({
  Directory? repoRoot,
}) async {
  final resolvedRepoRoot = repoRoot ?? Directory.current;
  final libDir = Directory.fromUri(
    resolvedRepoRoot.uri.resolve('lib/'),
  );
  final violations = <String>[];

  if (!libDir.existsSync()) {
    violations.add(
      'root boundary guard failed: lib/ directory not found from '
      '${resolvedRepoRoot.path}',
    );
    return RootPackageBoundaryGuardResult(
      violations: List.unmodifiable(violations),
    );
  }

  await _collectLayoutViolations(
    repoRoot: resolvedRepoRoot,
    libDir: libDir,
    violations: violations,
  );
  await _collectDefaultRootEntrypointViolations(
    repoRoot: resolvedRepoRoot,
    violations: violations,
  );
  await _collectFocusedRootEntrypointViolations(
    repoRoot: resolvedRepoRoot,
    violations: violations,
  );
  await _collectImportViolations(
    repoRoot: resolvedRepoRoot,
    libDir: libDir,
    violations: violations,
  );
  await _collectExampleImportViolations(
    repoRoot: resolvedRepoRoot,
    violations: violations,
  );

  return RootPackageBoundaryGuardResult(
    violations: List.unmodifiable(violations),
  );
}

Future<void> _collectLayoutViolations({
  required Directory repoRoot,
  required Directory libDir,
  required List<String> violations,
}) async {
  final topLevelDirectories = <String>{};
  final topLevelFiles = <String>{};

  await for (final entity in libDir.list()) {
    if (entity is Directory) {
      topLevelDirectories.add(
          entity.uri.pathSegments.lastWhere((segment) => segment.isNotEmpty));
      continue;
    }

    if (entity is File) {
      topLevelFiles.add(entity.uri.pathSegments.last);
    }
  }

  final unexpectedRootDirectories = topLevelDirectories
      .difference(_allowedRootTopLevelDirectories)
      .toList()
    ..sort();
  if (unexpectedRootDirectories.isNotEmpty) {
    violations.add(
      'lib/: unexpected top-level directories: '
      '${unexpectedRootDirectories.join(', ')}. Allowed directories: '
      '${_sorted(_allowedRootTopLevelDirectories).join(', ')}.',
    );
  }

  final unexpectedRootFiles =
      topLevelFiles.difference(_allowedRootTopLevelFiles).toList()..sort();
  if (unexpectedRootFiles.isNotEmpty) {
    violations.add(
      'lib/: unexpected top-level public entry files: '
      '${unexpectedRootFiles.join(', ')}. Allowed files: '
      '${_sorted(_allowedRootTopLevelFiles).join(', ')}.',
    );
  }

  final srcDir = Directory.fromUri(libDir.uri.resolve('src/'));
  if (!srcDir.existsSync()) {
    violations.add('lib/src/: directory is missing.');
    return;
  }

  final srcTopLevelDirectories = <String>{};
  final srcTopLevelFiles = <String>{};

  await for (final entity in srcDir.list()) {
    if (entity is Directory) {
      srcTopLevelDirectories.add(
        entity.uri.pathSegments.lastWhere((segment) => segment.isNotEmpty),
      );
      continue;
    }

    if (entity is File) {
      srcTopLevelFiles.add(entity.uri.pathSegments.last);
    }
  }

  final unexpectedSrcDirectories = srcTopLevelDirectories
      .difference(_allowedRootSrcTopLevelDirectories)
      .toList()
    ..sort();
  if (unexpectedSrcDirectories.isNotEmpty) {
    violations.add(
      'lib/src/: unexpected top-level directories: '
      '${unexpectedSrcDirectories.join(', ')}. Allowed directories: '
      '${_sorted(_allowedRootSrcTopLevelDirectories).join(', ')}.',
    );
  }

  final unexpectedSrcFiles = srcTopLevelFiles
      .difference(_allowedRootSrcTopLevelFiles)
      .toList()
    ..sort();
  if (unexpectedSrcFiles.isNotEmpty) {
    violations.add(
      'lib/src/: unexpected top-level files: '
      '${unexpectedSrcFiles.join(', ')}. Allowed files: '
      '${_sorted(_allowedRootSrcTopLevelFiles).join(', ')}.',
    );
  }
}

Future<void> _collectDefaultRootEntrypointViolations({
  required Directory repoRoot,
  required List<String> violations,
}) async {
  final rootEntrypoint =
      File.fromUri(repoRoot.uri.resolve('lib/llm_dart.dart'));
  if (!rootEntrypoint.existsSync()) {
    violations.add('lib/llm_dart.dart: default root entrypoint is missing.');
    return;
  }

  final directives = await _readPublicDirectives(rootEntrypoint);

  if (_listEquals(directives, _expectedDefaultRootEntrypointDirectives)) {
    return;
  }

  violations.add(
    'lib/llm_dart.dart: default root entrypoint must only export ai.dart. '
    'Found directives: ${directives.join(' ')}. Expected directives: '
    '${_expectedDefaultRootEntrypointDirectives.join(' ')}.',
  );
}

Future<void> _collectFocusedRootEntrypointViolations({
  required Directory repoRoot,
  required List<String> violations,
}) async {
  for (final entry in _expectedFocusedRootEntrypointDirectives.entries) {
    final entrypoint = File.fromUri(repoRoot.uri.resolve(entry.key));
    if (!entrypoint.existsSync()) {
      violations.add('${entry.key}: focused root entrypoint is missing.');
      continue;
    }

    final directives = await _readPublicDirectives(entrypoint);
    if (_listEquals(directives, entry.value)) {
      continue;
    }

    violations.add(
      '${entry.key}: focused root entrypoint must only export its '
      'package-owned surface. Found directives: ${directives.join(' ')}. '
      'Expected directives: ${entry.value.join(' ')}.',
    );
  }
}

Future<void> _collectImportViolations({
  required Directory repoRoot,
  required Directory libDir,
  required List<String> violations,
}) async {
  await for (final entity in libDir.list(recursive: true)) {
    if (entity is! File) {
      continue;
    }

    final relativePath = _displayPath(repoRoot, entity);
    if (!relativePath.endsWith('.dart')) {
      continue;
    }

    final lines = await entity.readAsLines();
    for (var index = 0; index < lines.length; index += 1) {
      final line = lines[index];
      if (_flutterImportPattern.hasMatch(line)) {
        violations.add(
          '$relativePath:${index + 1}: root package must not import or export '
          'package:llm_dart_flutter/...; Flutter adapters stay outside the root package.',
        );
      }

      if (_chatImportPattern.hasMatch(line) &&
          relativePath != 'lib/chat.dart') {
        violations.add(
          '$relativePath:${index + 1}: only lib/chat.dart may import or export '
          'package:llm_dart_chat/...; keep the pure chat runtime on the focused '
          'chat entrypoint instead of widening the root surface.',
        );
      }
    }
  }
}

Future<void> _collectExampleImportViolations({
  required Directory repoRoot,
  required List<String> violations,
}) async {
  final exampleDir = Directory.fromUri(repoRoot.uri.resolve('example/'));
  if (!exampleDir.existsSync()) {
    return;
  }

  await for (final entity in exampleDir.list(recursive: true)) {
    if (entity is! File) {
      continue;
    }

    final relativePath = _displayPath(repoRoot, entity);
    if (!relativePath.endsWith('.dart')) {
      continue;
    }

    final lines = await entity.readAsLines();
    for (var index = 0; index < lines.length; index += 1) {
      if (!_legacyImportPattern.hasMatch(lines[index])) {
        continue;
      }

      violations.add(
        '$relativePath:${index + 1}: examples must use focused stable, '
        'builder, model, or provider-owned entrypoints instead of '
        'package:llm_dart/legacy.dart.',
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

List<String> _sorted(Set<String> values) {
  return values.toList()..sort();
}

Future<List<String>> _readPublicDirectives(File file) async {
  return (await file.readAsLines())
      .map((line) => line.trim())
      .where(
        (line) =>
            line.isNotEmpty &&
            !line.startsWith('///') &&
            !line.startsWith('//'),
      )
      .toList();
}

bool _listEquals(List<String> a, List<String> b) {
  if (a.length != b.length) {
    return false;
  }

  for (var index = 0; index < a.length; index += 1) {
    if (a[index] != b[index]) {
      return false;
    }
  }

  return true;
}

Future<void> main() async {
  final result = await evaluateRootPackageBoundaryGuards();

  if (result.passed) {
    stdout.writeln(
      'root boundary guard passed: root entrypoints, lib/src layout, and '
      'chat/flutter/example boundary imports match the frozen policy.',
    );
    return;
  }

  stderr.writeln(
    'root boundary guard found ${result.violations.length} violation(s):',
  );
  for (final violation in result.violations) {
    stderr.writeln(violation);
  }
  exitCode = 1;
}
