import 'dart:convert';
import 'dart:io';

const String _ledgerPath = 'docs/release/release_ledger.json';

final class ReleaseLedgerGuardResult {
  final List<String> violations;

  const ReleaseLedgerGuardResult({
    required this.violations,
  });

  bool get passed => violations.isEmpty;
}

Future<ReleaseLedgerGuardResult> evaluateReleaseLedgerGuard({
  Directory? repoRoot,
}) async {
  final resolvedRepoRoot = repoRoot ?? Directory.current;
  final violations = <String>[];
  final ledgerFile = File.fromUri(resolvedRepoRoot.uri.resolve(_ledgerPath));

  if (!ledgerFile.existsSync()) {
    return ReleaseLedgerGuardResult(
      violations: ['$_ledgerPath: release ledger is missing.'],
    );
  }

  final ledger = _readJsonObject(
    ledgerFile,
    violations: violations,
    context: _ledgerPath,
  );
  if (ledger == null) {
    return ReleaseLedgerGuardResult(
      violations: List.unmodifiable(violations),
    );
  }

  _expectValue(
    ledger,
    key: 'schemaVersion',
    expected: 1,
    violations: violations,
  );
  _expectString(
    ledger,
    key: 'release',
    violations: violations,
  );
  _expectOneOf(
    ledger,
    key: 'status',
    allowed: const {
      'planning',
      'pre_release_freeze',
      'release_ready',
      'published',
      'blocked',
    },
    violations: violations,
  );
  _expectOneOf(
    ledger,
    key: 'publishAction',
    allowed: const {
      'manual_maintainer_approval_required',
      'published',
      'not_applicable',
    },
    violations: violations,
  );

  _validateGeneratedFrom(
    resolvedRepoRoot,
    ledger,
    violations,
  );
  _validatePackages(
    resolvedRepoRoot,
    ledger,
    violations,
  );
  _validateWorkstreams(
    resolvedRepoRoot,
    ledger,
    violations,
  );
  _validateRequiredGates(
    resolvedRepoRoot,
    ledger,
    violations,
  );
  _validateDeferrals(
    ledger,
    violations,
  );

  return ReleaseLedgerGuardResult(
    violations: List.unmodifiable(violations),
  );
}

void _validateGeneratedFrom(
  Directory repoRoot,
  Map<String, Object?> ledger,
  List<String> violations,
) {
  final generatedFrom = _expectStringList(
    ledger,
    key: 'generatedFrom',
    violations: violations,
  );
  if (generatedFrom == null) {
    return;
  }

  for (final path in generatedFrom) {
    if (!File.fromUri(repoRoot.uri.resolve(path)).existsSync()) {
      violations.add('$_ledgerPath: generatedFrom path does not exist: $path');
    }
  }
}

void _validatePackages(
  Directory repoRoot,
  Map<String, Object?> ledger,
  List<String> violations,
) {
  final publishablePackages = _expectObjectList(
    ledger,
    key: 'publishablePackages',
    violations: violations,
  );
  if (publishablePackages != null) {
    final names = <String>{};
    for (final package in publishablePackages) {
      final name = _stringValue(package, 'name');
      final path = _stringValue(package, 'path');
      if (name == null || path == null) {
        violations.add(
          '$_ledgerPath: publishablePackages entries need name and path.',
        );
        continue;
      }
      if (!names.add(name)) {
        violations.add('$_ledgerPath: duplicate publishable package `$name`.');
      }
      _validatePubspecName(
        repoRoot,
        packageName: name,
        packagePath: path,
        violations: violations,
      );
    }
  }

  final nonPublishablePackages = _expectObjectList(
    ledger,
    key: 'nonPublishablePackages',
    violations: violations,
  );
  if (nonPublishablePackages == null) {
    return;
  }

  for (final package in nonPublishablePackages) {
    final name = _stringValue(package, 'name');
    final path = _stringValue(package, 'path');
    final reason = _stringValue(package, 'reason');
    if (name == null || path == null || reason == null || reason.isEmpty) {
      violations.add(
        '$_ledgerPath: nonPublishablePackages entries need name, path, and reason.',
      );
      continue;
    }
    _validatePubspecName(
      repoRoot,
      packageName: name,
      packagePath: path,
      violations: violations,
    );
  }
}

void _validatePubspecName(
  Directory repoRoot, {
  required String packageName,
  required String packagePath,
  required List<String> violations,
}) {
  final pubspec =
      File.fromUri(repoRoot.uri.resolve('$packagePath/pubspec.yaml'));
  if (!pubspec.existsSync()) {
    violations.add(
      '$_ledgerPath: package `$packageName` pubspec missing at '
      '$packagePath/pubspec.yaml.',
    );
    return;
  }

  final actualName = _readPubspecName(pubspec);
  if (actualName != packageName) {
    violations.add(
      '$_ledgerPath: package path `$packagePath` has pubspec name '
      '`$actualName`, expected `$packageName`.',
    );
  }
}

void _validateWorkstreams(
  Directory repoRoot,
  Map<String, Object?> ledger,
  List<String> violations,
) {
  final workstreams = _expectObjectList(
    ledger,
    key: 'workstreams',
    violations: violations,
  );
  if (workstreams == null) {
    return;
  }

  for (final entry in workstreams) {
    final slug = _stringValue(entry, 'slug');
    final path = _stringValue(entry, 'path');
    final expectedStatus = _stringValue(entry, 'expectedStatus');
    final releaseRole = _stringValue(entry, 'releaseRole');
    if (slug == null ||
        path == null ||
        expectedStatus == null ||
        releaseRole == null ||
        releaseRole.isEmpty) {
      violations.add(
        '$_ledgerPath: workstream entries need slug, path, expectedStatus, and releaseRole.',
      );
      continue;
    }

    final file = File.fromUri(repoRoot.uri.resolve(path));
    if (!file.existsSync()) {
      violations.add('$_ledgerPath: workstream `$slug` path missing: $path');
      continue;
    }

    final json = _readJsonObject(
      file,
      violations: violations,
      context: path,
    );
    if (json == null) {
      continue;
    }

    final actualSlug = _stringValue(json, 'slug');
    final actualStatus = _stringValue(json, 'status');
    if (actualSlug != slug) {
      violations.add(
        '$_ledgerPath: workstream `$slug` points to slug `$actualSlug`.',
      );
    }
    if (actualStatus != expectedStatus) {
      violations.add(
        '$_ledgerPath: workstream `$slug` status `$actualStatus`, expected `$expectedStatus`.',
      );
    }
  }
}

void _validateRequiredGates(
  Directory repoRoot,
  Map<String, Object?> ledger,
  List<String> violations,
) {
  final gates = _expectObjectList(
    ledger,
    key: 'requiredGates',
    violations: violations,
  );
  if (gates == null) {
    return;
  }

  final names = <String>{};
  for (final gate in gates) {
    final name = _stringValue(gate, 'name');
    final command = _stringValue(gate, 'command');
    if (name == null || command == null) {
      violations
          .add('$_ledgerPath: requiredGates entries need name and command.');
      continue;
    }
    if (!names.add(name)) {
      violations.add('$_ledgerPath: duplicate required gate `$name`.');
    }

    final toolMatch =
        RegExp(r'dart --suppress-analytics run (tool/[^ ]+\.dart)$')
            .firstMatch(command.replaceAll('\\', '/'));
    if (toolMatch != null) {
      final toolPath = toolMatch.group(1)!;
      if (!File.fromUri(repoRoot.uri.resolve(toolPath)).existsSync()) {
        violations.add('$_ledgerPath: required gate tool missing: $toolPath');
      }
    }
  }
}

void _validateDeferrals(
  Map<String, Object?> ledger,
  List<String> violations,
) {
  final deferrals = _expectObjectList(
    ledger,
    key: 'knownDeferrals',
    violations: violations,
  );
  if (deferrals == null) {
    return;
  }

  final ids = <String>{};
  for (final deferral in deferrals) {
    final id = _stringValue(deferral, 'id');
    final owner = _stringValue(deferral, 'owner');
    final reviewWindow = _stringValue(deferral, 'reviewWindow');
    final reason = _stringValue(deferral, 'reason');
    final releaseBlocking = deferral['releaseBlocking'];
    if (id == null ||
        owner == null ||
        reviewWindow == null ||
        reason == null ||
        releaseBlocking is! bool) {
      violations.add(
        '$_ledgerPath: knownDeferrals entries need id, owner, reviewWindow, reason, and boolean releaseBlocking.',
      );
      continue;
    }
    if (!ids.add(id)) {
      violations.add('$_ledgerPath: duplicate deferral `$id`.');
    }
  }
}

Map<String, Object?>? _readJsonObject(
  File file, {
  required List<String> violations,
  required String context,
}) {
  try {
    final decoded = jsonDecode(file.readAsStringSync());
    if (decoded is Map<String, Object?>) {
      return decoded;
    }
    violations.add('$context: expected a JSON object.');
  } on FormatException catch (error) {
    violations.add('$context: invalid JSON: ${error.message}.');
  }
  return null;
}

void _expectValue(
  Map<String, Object?> object, {
  required String key,
  required Object? expected,
  required List<String> violations,
}) {
  if (object[key] != expected) {
    violations.add('$_ledgerPath: `$key` must be `$expected`.');
  }
}

void _expectString(
  Map<String, Object?> object, {
  required String key,
  required List<String> violations,
}) {
  final value = object[key];
  if (value is! String || value.isEmpty) {
    violations.add('$_ledgerPath: `$key` must be a non-empty string.');
  }
}

void _expectOneOf(
  Map<String, Object?> object, {
  required String key,
  required Set<String> allowed,
  required List<String> violations,
}) {
  final value = object[key];
  if (value is! String || !allowed.contains(value)) {
    violations.add(
      '$_ledgerPath: `$key` must be one of ${allowed.join(', ')}.',
    );
  }
}

List<String>? _expectStringList(
  Map<String, Object?> object, {
  required String key,
  required List<String> violations,
}) {
  final value = object[key];
  if (value is! List || value.any((item) => item is! String)) {
    violations.add('$_ledgerPath: `$key` must be a list of strings.');
    return null;
  }
  return value.cast<String>();
}

List<Map<String, Object?>>? _expectObjectList(
  Map<String, Object?> object, {
  required String key,
  required List<String> violations,
}) {
  final value = object[key];
  if (value is! List) {
    violations.add('$_ledgerPath: `$key` must be a list of objects.');
    return null;
  }

  final objects = <Map<String, Object?>>[];
  for (final item in value) {
    if (item is Map) {
      objects.add(item.cast<String, Object?>());
      continue;
    }
    violations.add('$_ledgerPath: `$key` must be a list of objects.');
    return null;
  }
  return objects;
}

String? _stringValue(Map<String, Object?> object, String key) {
  final value = object[key];
  if (value is String && value.isNotEmpty) {
    return value;
  }
  return null;
}

String? _readPubspecName(File pubspec) {
  for (final rawLine in pubspec.readAsLinesSync()) {
    final line = rawLine.trim();
    if (line.startsWith('name:')) {
      return line.substring('name:'.length).trim();
    }
  }
  return null;
}

Future<void> main() async {
  final result = await evaluateReleaseLedgerGuard();

  if (result.passed) {
    stdout.writeln(
      'release ledger guard passed: release posture, package list, '
      'workstream evidence, gate tools, and known deferrals are consistent.',
    );
    return;
  }

  stderr.writeln(
    'release ledger guard found ${result.violations.length} violation(s):',
  );
  for (final violation in result.violations) {
    stderr.writeln(violation);
  }
  exitCode = 1;
}
