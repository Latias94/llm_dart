import 'dart:io';

/// A tiny, non-interactive versioning helper for this monorepo.
///
/// We intentionally avoid Melos versioning here because:
/// - This repo uses Dart pub workspaces for local linking.
/// - Some environments (e.g. CI / non-TTY) cannot handle interactive prompts.
///
/// Usage:
///   dart run tool/bump_version.dart set-all --version 0.12.0
///   dart run tool/bump_version.dart set --package llm_dart_openai --version 0.11.1
///
/// Notes:
/// - `set-all` updates versions for all publishable packages under `packages/`
///   and updates internal dependency constraints to `^<version>`.
/// - `set` only updates the target package's `version:` field.
void main(List<String> args) {
  if (args.isEmpty || args.first == '-h' || args.first == '--help') {
    _printUsage();
    return;
  }

  final command = args.first;
  final flags = _parseArgs(args.skip(1).toList());

  switch (command) {
    case 'set-all':
      {
        final version = flags.string('version');
        if (version == null || version.isEmpty) {
          stderr.writeln('Missing required flag: --version');
          exitCode = 2;
          return;
        }

        final updateConstraints =
            flags.boolFlag('update-constraints', defaultValue: true);

        final packages = _discoverPackages(Directory.current);
        if (packages.isEmpty) {
          stderr.writeln('No packages found under `packages/`.');
          exitCode = 2;
          return;
        }

        final packageNames = packages.map((p) => p.name).toSet();

        for (final pkg in packages) {
          final pubspec = pkg.pubspec;
          final original = pubspec.readAsStringSync();
          final updated = _setVersionInPubspec(
            original,
            version: version,
            updateInternalConstraints: updateConstraints,
            internalPackageNames: packageNames,
          );
          if (updated != original) {
            pubspec.writeAsStringSync(updated);
          }
        }

        _writeProviderUtilsVersionFile(rootDir, version);

        stdout.writeln(
          'Updated ${packages.length} packages to version $version'
          '${updateConstraints ? ' (constraints updated)' : ''}.',
        );
        return;
      }
    case 'set':
      {
        final packageName = flags.string('package');
        final version = flags.string('version');
        if (packageName == null || packageName.isEmpty) {
          stderr.writeln('Missing required flag: --package');
          exitCode = 2;
          return;
        }
        if (version == null || version.isEmpty) {
          stderr.writeln('Missing required flag: --version');
          exitCode = 2;
          return;
        }

        final packages = _discoverPackages(Directory.current);
        final pkg = packages.where((p) => p.name == packageName).firstOrNull;
        if (pkg == null) {
          stderr.writeln(
            'Package not found: $packageName (expected in `packages/<name>/pubspec.yaml`).',
          );
          exitCode = 2;
          return;
        }

        final pubspec = pkg.pubspec;
        final original = pubspec.readAsStringSync();
        final updated = _setVersionInPubspec(
          original,
          version: version,
          updateInternalConstraints: false,
          internalPackageNames: const {},
        );
        if (updated != original) {
          pubspec.writeAsStringSync(updated);
        }

        if (packageName == 'llm_dart_provider_utils') {
          _writeProviderUtilsVersionFile(Directory.current, version);
        }

        stdout.writeln('Updated $packageName to version $version.');
        return;
      }
    default:
      {
        stderr.writeln('Unknown command: $command');
        _printUsage();
        exitCode = 2;
        return;
      }
  }
}

void _writeProviderUtilsVersionFile(Directory rootDir, String version) {
  final file = File(
    '${rootDir.path}/packages/llm_dart_provider_utils/lib/utils/user_agent.dart',
  );
  if (!file.existsSync()) return;

  final original = file.readAsStringSync();
  final re = RegExp(
    r"^(const String llmDartVersion\s*=\s*)'[^']*';\s*$",
    multiLine: true,
  );
  final updated = re.hasMatch(original)
      ? original.replaceFirstMapped(re, (m) => "${m.group(1)}'$version';")
      : original;

  if (updated != original) file.writeAsStringSync(updated);
}

void _printUsage() {
  stdout.writeln('''
Versioning helper (non-interactive)

Commands:
  set-all   Set version for all packages under `packages/` and update internal dependency constraints.
  set       Set version for a single package under `packages/`.

Examples:
  dart run tool/bump_version.dart set-all --version 0.12.0
  dart run tool/bump_version.dart set-all --version 0.12.0-alpha.1
  dart run tool/bump_version.dart set --package llm_dart_openai --version 0.11.1

Flags:
  --version <semver>        Required.
  --package <name>          Required for `set`.
  --update-constraints      (set-all) default: true. Use --no-update-constraints to disable.
''');
}

String _setVersionInPubspec(
  String text, {
  required String version,
  required bool updateInternalConstraints,
  required Set<String> internalPackageNames,
}) {
  var updated = text;

  final versionRe = RegExp(r'^(version:\s*)(\S+)\s*$', multiLine: true);
  if (!versionRe.hasMatch(updated)) {
    // Packages should always have a version; if missing, add it near the top.
    // Keep it minimal and non-destructive.
    updated = updated.replaceFirstMapped(
      RegExp(r'^(name:\s*\S+\s*)$', multiLine: true),
      (m) => '${m.group(0)}\nversion: $version',
    );
  } else {
    updated = updated.replaceFirstMapped(versionRe, (m) {
      return '${m.group(1)}$version';
    });
  }

  if (!updateInternalConstraints || internalPackageNames.isEmpty) {
    return updated;
  }

  final caretConstraint = '^$version';

  final lines = updated.split('\n');
  final out = <String>[];

  String? currentSection;

  for (final line in lines) {
    final trimmed = line.trimRight();

    final sectionMatch =
        RegExp(r'^([a-zA-Z_][a-zA-Z0-9_]*):\s*$').firstMatch(trimmed);
    if (sectionMatch != null && !trimmed.startsWith('  ')) {
      final key = sectionMatch.group(1)!;
      if (key == 'dependencies' ||
          key == 'dev_dependencies' ||
          key == 'dependency_overrides') {
        currentSection = key;
      } else {
        currentSection = null;
      }
      out.add(line);
      continue;
    }

    if (currentSection == null) {
      out.add(line);
      continue;
    }

    final depMatch =
        RegExp(r'^(\s+)([a-zA-Z0-9_]+):\s*(.+)?$').firstMatch(line);
    if (depMatch == null) {
      out.add(line);
      continue;
    }

    final indent = depMatch.group(1)!;
    final name = depMatch.group(2)!;
    final rawValue = (depMatch.group(3) ?? '').trim();

    if (!internalPackageNames.contains(name)) {
      out.add(line);
      continue;
    }

    // Skip map-style deps like:
    //   foo:
    //     path: ...
    if (rawValue.isEmpty) {
      out.add(line);
      continue;
    }
    if (rawValue.startsWith('{') || rawValue.startsWith('path:')) {
      out.add(line);
      continue;
    }
    if (rawValue.startsWith('git:') || rawValue.startsWith('sdk:')) {
      out.add(line);
      continue;
    }

    out.add('$indent$name: $caretConstraint');
  }

  return out.join('\n');
}

List<_WorkspacePackage> _discoverPackages(Directory rootDir) {
  final packagesDir = Directory('${rootDir.path}/packages');
  if (!packagesDir.existsSync()) return const [];

  final results = <_WorkspacePackage>[];

  for (final entity in packagesDir.listSync(followLinks: false)) {
    if (entity is! Directory) continue;
    final pubspec = File('${entity.path}/pubspec.yaml');
    if (!pubspec.existsSync()) continue;

    final name = _readPackageName(pubspec);
    if (name == null) continue;

    results.add(_WorkspacePackage(name: name, pubspec: pubspec));
  }

  results.sort((a, b) => a.name.compareTo(b.name));
  return results;
}

String? _readPackageName(File pubspec) {
  for (final line in pubspec.readAsLinesSync()) {
    final m = RegExp(r'^\s*name:\s*([^\s#]+)\s*$').firstMatch(line);
    if (m != null) return m.group(1);
  }
  return null;
}

class _WorkspacePackage {
  final String name;
  final File pubspec;

  const _WorkspacePackage({required this.name, required this.pubspec});
}

class _ArgBag {
  final Map<String, String?> _values;
  final Set<String> _bools;

  const _ArgBag(this._values, this._bools);

  String? string(String name) => _values[name];

  bool boolFlag(String name, {required bool defaultValue}) {
    if (_bools.contains(name)) return true;
    if (_bools.contains('no-$name')) return false;
    return defaultValue;
  }
}

_ArgBag _parseArgs(List<String> args) {
  final values = <String, String?>{};
  final bools = <String>{};

  for (var i = 0; i < args.length; i++) {
    final arg = args[i];
    if (!arg.startsWith('--')) continue;

    final raw = arg.substring(2);
    final eq = raw.indexOf('=');
    if (eq >= 0) {
      final key = raw.substring(0, eq);
      final value = raw.substring(eq + 1);
      values[key] = value;
      continue;
    }

    if (raw.startsWith('no-')) {
      bools.add(raw);
      continue;
    }

    // --flag value
    if (i + 1 < args.length && !args[i + 1].startsWith('--')) {
      values[raw] = args[i + 1];
      i++;
      continue;
    }

    // --flag
    bools.add(raw);
  }

  return _ArgBag(values, bools);
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
