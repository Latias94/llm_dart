import 'dart:io';

import 'package:yaml/yaml.dart';

final _providerToProviderExceptions = <String, Set<String>>{
  // AI SDK parity: `@ai-sdk/google-vertex` reuses `@ai-sdk/google/internal`.
  // We allow `llm_dart_google_vertex` to reuse `llm_dart_google` internals until
  // we have a dedicated shared Google Generative AI protocol package.
  'llm_dart_google_vertex': {'llm_dart_google'},
};

void main(List<String> args) {
  final rootDir = Directory.current;
  final packagesDir = Directory('${rootDir.path}/packages');

  if (!packagesDir.existsSync()) {
    stderr.writeln('Missing `packages/` directory at: ${packagesDir.path}');
    exitCode = 2;
    return;
  }

  final workspace = _discoverWorkspacePackages(rootDir, packagesDir);

  final protocolPackages =
      workspace.keys.where((name) => name.endsWith('_compatible')).toSet();

  final errors = <String>[];

  for (final entry in workspace.entries) {
    final packageName = entry.key;
    final pubspecFile = entry.value;

    final internalDeps = _readInternalDependencies(
      pubspecFile,
      workspacePackageNames: workspace.keys.toSet(),
    );

    final allowedInternalDeps = _allowedInternalDepsFor(
      packageName: packageName,
      protocolPackages: protocolPackages,
    );

    if (allowedInternalDeps == null) {
      continue; // umbrella package (or future free-form package)
    }

    final violations = internalDeps.difference(allowedInternalDeps).toList()
      ..sort();

    if (violations.isNotEmpty) {
      errors.add(
        '$packageName depends on disallowed workspace packages: ${violations.join(', ')} '
        '(pubspec: ${_relPath(pubspecFile.path)})',
      );
    }
  }

  if (errors.isNotEmpty) {
    stderr.writeln('Monorepo dependency rule violations:\n');
    for (final e in errors) {
      stderr.writeln('- $e');
    }
    stderr.writeln('\nRules (summary):');
    stderr.writeln(
      '- `llm_dart_core`: no workspace deps\n'
      '- `llm_dart_provider_utils`: only `llm_dart_core`\n'
      '- `llm_dart_ai`: only `llm_dart_core`\n'
      '- `llm_dart_builder`: only `llm_dart_core`\n'
      '- `*_compatible` protocol packages: only `llm_dart_core`, `llm_dart_provider_utils`\n'
      '- Provider packages: only `llm_dart_core`, `llm_dart_provider_utils`, and protocol packages\n'
      '- Umbrella `llm_dart`: unrestricted',
    );
    exitCode = 1;
    return;
  }

  stdout.writeln('Monorepo dependency rules: OK');
}

Map<String, File> _discoverWorkspacePackages(
  Directory rootDir,
  Directory packagesDir,
) {
  final workspace = <String, File>{};

  final rootPubspec = File('${rootDir.path}/pubspec.yaml');
  if (rootPubspec.existsSync()) {
    final name = _readPackageName(rootPubspec);
    if (name != null) {
      workspace[name] = rootPubspec;
    }
  }

  for (final entity in packagesDir.listSync(followLinks: false)) {
    if (entity is! Directory) continue;
    final pubspec = File('${entity.path}/pubspec.yaml');
    if (!pubspec.existsSync()) continue;
    final name = _readPackageName(pubspec);
    if (name == null) continue;
    workspace[name] = pubspec;
  }

  return workspace;
}

String? _readPackageName(File pubspecFile) {
  try {
    final doc = loadYaml(pubspecFile.readAsStringSync());
    if (doc is! YamlMap) return null;
    final name = doc['name'];
    if (name is String && name.trim().isNotEmpty) return name.trim();
    return null;
  } catch (_) {
    return null;
  }
}

Set<String> _readInternalDependencies(
  File pubspecFile, {
  required Set<String> workspacePackageNames,
}) {
  final text = pubspecFile.readAsStringSync();
  final doc = loadYaml(text);
  if (doc is! YamlMap) return {};

  final deps = <String>{};

  deps.addAll(_keysFromMap(doc['dependencies']));
  deps.addAll(_keysFromMap(doc['dev_dependencies']));
  deps.addAll(_keysFromMap(doc['dependency_overrides']));

  return deps.intersection(workspacePackageNames);
}

Set<String> _keysFromMap(Object? node) {
  if (node is! YamlMap) return const {};
  return node.keys.whereType<String>().toSet();
}

Set<String>? _allowedInternalDepsFor({
  required String packageName,
  required Set<String> protocolPackages,
}) {
  if (packageName == 'llm_dart_workspace') {
    return null; // workspace root (tooling only)
  }
  if (packageName == 'llm_dart') {
    return null; // unrestricted umbrella
  }

  if (packageName == 'llm_dart_core') {
    return const {};
  }

  if (packageName == 'llm_dart_provider_utils') {
    return const {'llm_dart_core'};
  }

  if (packageName == 'llm_dart_ai') {
    return const {'llm_dart_core'};
  }

  if (packageName == 'llm_dart_builder') {
    return const {'llm_dart_core'};
  }

  if (packageName.endsWith('_compatible')) {
    return const {'llm_dart_core', 'llm_dart_provider_utils'};
  }

  final extraAllowed = _providerToProviderExceptions[packageName] ?? const {};

  // Provider packages: allow core + provider_utils + protocol reuse packages.
  return {
    'llm_dart_core',
    'llm_dart_provider_utils',
    ...protocolPackages,
    ...extraAllowed,
  };
}

String _relPath(String path) {
  final cwd = Directory.current.path;
  if (path.startsWith(cwd)) {
    return path.substring(cwd.length + 1);
  }
  return path;
}
