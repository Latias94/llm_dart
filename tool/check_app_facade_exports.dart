import 'dart:convert';
import 'dart:io';

const String _manifestPath = 'docs/release/app_facade_exports.json';

final class AppFacadeExportGuardResult {
  final List<String> violations;

  const AppFacadeExportGuardResult({
    required this.violations,
  });

  bool get passed => violations.isEmpty;
}

Future<AppFacadeExportGuardResult> evaluateAppFacadeExportGuard({
  Directory? repoRoot,
}) async {
  final resolvedRepoRoot = repoRoot ?? Directory.current;
  final violations = <String>[];
  final manifestFile =
      File.fromUri(resolvedRepoRoot.uri.resolve(_manifestPath));

  if (!manifestFile.existsSync()) {
    return const AppFacadeExportGuardResult(
      violations: ['docs/release/app_facade_exports.json is missing.'],
    );
  }

  final manifest = _readJsonObject(
    manifestFile,
    violations: violations,
    context: _manifestPath,
  );
  if (manifest == null) {
    return AppFacadeExportGuardResult(
      violations: List.unmodifiable(violations),
    );
  }

  if (manifest['schemaVersion'] != 1) {
    violations.add('$_manifestPath: schemaVersion must be 1.');
  }

  _validateRootEntrypoints(
    resolvedRepoRoot,
    manifest,
    violations,
  );
  _validateAppProviderFoundationSymbols(
    resolvedRepoRoot,
    manifest,
    violations,
  );

  return AppFacadeExportGuardResult(
    violations: List.unmodifiable(violations),
  );
}

void _validateRootEntrypoints(
  Directory repoRoot,
  Map<String, Object?> manifest,
  List<String> violations,
) {
  final entrypoints = _objectList(
    manifest,
    'rootEntrypoints',
    violations,
  );
  if (entrypoints == null) {
    return;
  }

  for (final entrypoint in entrypoints) {
    final path = _stringValue(entrypoint, 'path');
    final expectedDirectives = _stringList(
      entrypoint,
      'directives',
      violations,
      context: '$path directives',
    );
    if (path == null || expectedDirectives == null) {
      violations.add(
        '$_manifestPath: rootEntrypoints entries need path and directives.',
      );
      continue;
    }

    final file = File.fromUri(repoRoot.uri.resolve(path));
    if (!file.existsSync()) {
      violations.add('$_manifestPath: root entrypoint missing: $path.');
      continue;
    }

    final actualDirectives = _readPublicDirectives(file);
    if (!_listEquals(actualDirectives, expectedDirectives)) {
      violations.add(
        '$path: directives drifted from app facade manifest. '
        'Expected ${expectedDirectives.join(' ')}; found '
        '${actualDirectives.join(' ')}.',
      );
    }
  }
}

void _validateAppProviderFoundationSymbols(
  Directory repoRoot,
  Map<String, Object?> manifest,
  List<String> violations,
) {
  final appEntrypoint = manifest['appEntrypoint'];
  if (appEntrypoint is! Map) {
    violations.add('$_manifestPath: appEntrypoint must be an object.');
    return;
  }

  final appObject = appEntrypoint.cast<String, Object?>();
  final path = _stringValue(appObject, 'path');
  final providerFoundationExport = _stringValue(
    appObject,
    'providerFoundationExport',
  );
  if (path == null || providerFoundationExport == null) {
    violations.add(
      '$_manifestPath: appEntrypoint needs path and providerFoundationExport.',
    );
    return;
  }

  final groups = _objectList(
    appObject,
    'providerFoundationExportGroups',
    violations,
  );
  if (groups == null) {
    return;
  }

  final expectedSymbols = <String>{};
  for (final group in groups) {
    final name = _stringValue(group, 'name');
    final symbols = _stringList(
      group,
      'symbols',
      violations,
      context: 'providerFoundationExportGroups.${name ?? '<unnamed>'}',
    );
    if (name == null || symbols == null || symbols.isEmpty) {
      violations.add(
        '$_manifestPath: provider foundation groups need name and symbols.',
      );
      continue;
    }
    for (final symbol in symbols) {
      if (!expectedSymbols.add(symbol)) {
        violations.add(
          '$_manifestPath: provider foundation symbol `$symbol` appears in more than one group.',
        );
      }
    }
  }

  final appFile = File.fromUri(repoRoot.uri.resolve(path));
  if (!appFile.existsSync()) {
    violations.add('$_manifestPath: app entrypoint missing: $path.');
    return;
  }

  final actualSymbols = _readProviderFoundationShowSymbols(
    appFile,
    providerFoundationExport,
  );
  if (actualSymbols == null) {
    violations.add(
      '$path: export for `$providerFoundationExport` was not found.',
    );
    return;
  }

  final missing = expectedSymbols.difference(actualSymbols).toList()..sort();
  final unexpected = actualSymbols.difference(expectedSymbols).toList()..sort();
  if (missing.isNotEmpty || unexpected.isNotEmpty) {
    violations.add(
      '$path: provider foundation export drifted from manifest. '
      'Missing: ${missing.join(', ')}. Unexpected: ${unexpected.join(', ')}.',
    );
  }
}

Set<String>? _readProviderFoundationShowSymbols(
  File file,
  String providerFoundationExport,
) {
  final lines = file.readAsLinesSync();
  var inTargetExport = false;
  var inShow = false;
  final symbols = <String>{};

  for (final rawLine in lines) {
    final line = rawLine.trim();
    if (!inTargetExport &&
        line.startsWith('export ') &&
        line.contains(providerFoundationExport)) {
      inTargetExport = true;
      continue;
    }

    if (!inTargetExport) {
      continue;
    }

    if (!inShow) {
      if (line == 'show') {
        inShow = true;
      }
      continue;
    }

    final symbol = line.replaceAll(',', '').replaceAll(';', '').trim();
    if (symbol.isNotEmpty) {
      symbols.add(symbol);
    }
    if (line.endsWith(';')) {
      return symbols;
    }
  }

  return null;
}

List<String> _readPublicDirectives(File file) {
  final directives = <String>[];
  var pendingDirective = '';

  for (final rawLine in file.readAsLinesSync()) {
    final line = rawLine.trim();
    if (line.isEmpty || line.startsWith('///') || line.startsWith('//')) {
      continue;
    }

    pendingDirective =
        pendingDirective.isEmpty ? line : '$pendingDirective $line';

    if (line.endsWith(';')) {
      directives.add(pendingDirective);
      pendingDirective = '';
    }
  }

  if (pendingDirective.isNotEmpty) {
    directives.add(pendingDirective);
  }

  return directives;
}

Map<String, Object?>? _readJsonObject(
  File file, {
  required List<String> violations,
  required String context,
}) {
  try {
    final decoded = jsonDecode(file.readAsStringSync());
    if (decoded is Map) {
      return decoded.cast<String, Object?>();
    }
    violations.add('$context: expected a JSON object.');
  } on FormatException catch (error) {
    violations.add('$context: invalid JSON: ${error.message}.');
  }
  return null;
}

List<Map<String, Object?>>? _objectList(
  Map<String, Object?> object,
  String key,
  List<String> violations,
) {
  final value = object[key];
  if (value is! List) {
    violations.add('$_manifestPath: `$key` must be a list of objects.');
    return null;
  }

  final objects = <Map<String, Object?>>[];
  for (final item in value) {
    if (item is Map) {
      objects.add(item.cast<String, Object?>());
      continue;
    }
    violations.add('$_manifestPath: `$key` must be a list of objects.');
    return null;
  }
  return objects;
}

List<String>? _stringList(
  Map<String, Object?> object,
  String key,
  List<String> violations, {
  required String context,
}) {
  final value = object[key];
  if (value is! List || value.any((item) => item is! String)) {
    violations
        .add('$_manifestPath: `$context.$key` must be a list of strings.');
    return null;
  }
  return value.cast<String>();
}

String? _stringValue(Map<String, Object?> object, String key) {
  final value = object[key];
  if (value is String && value.isNotEmpty) {
    return value;
  }
  return null;
}

bool _listEquals(List<String> left, List<String> right) {
  if (left.length != right.length) {
    return false;
  }
  for (var index = 0; index < left.length; index += 1) {
    if (left[index] != right[index]) {
      return false;
    }
  }
  return true;
}

Future<void> main() async {
  final result = await evaluateAppFacadeExportGuard();

  if (result.passed) {
    stdout.writeln(
      'app facade export guard passed: root entrypoint directives and '
      'llm_dart_ai app provider-foundation exports match the release manifest.',
    );
    return;
  }

  stderr.writeln(
    'app facade export guard found ${result.violations.length} violation(s):',
  );
  for (final violation in result.violations) {
    stderr.writeln(violation);
  }
  exitCode = 1;
}
