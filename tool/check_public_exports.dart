import 'dart:io';

import 'package:yaml/yaml.dart';

void main(List<String> args) {
  final rootDir = Directory.current;
  final packagesDir = Directory('${rootDir.path}/packages');

  if (!packagesDir.existsSync()) {
    stderr.writeln('Missing `packages/` directory at: ${packagesDir.path}');
    exitCode = 2;
    return;
  }

  final workspace = _discoverWorkspacePackages(rootDir, packagesDir);
  final errors = <String>[];

  for (final entry in workspace.entries) {
    final packageName = entry.key;
    final pubspecFile = entry.value;
    final packageDir = pubspecFile.parent;

    if (packageName == 'llm_dart_core') {
      errors.addAll(_checkCorePublicSurface(packageDir));
      continue;
    }

    if (packageName == 'llm_dart_openai_compatible') {
      errors.addAll(_checkOpenAICompatiblePublicSurface(packageDir));
      continue;
    }

    if (_isProviderPackage(packageName)) {
      errors.addAll(_checkProviderEntrypoints(packageName, packageDir));
    }
  }

  if (errors.isNotEmpty) {
    stderr.writeln('Public export boundary violations:\n');
    for (final e in errors) {
      stderr.writeln('- $e');
    }
    stderr.writeln('\nRules (summary):');
    stderr.writeln(
      '- `llm_dart_core` must not export OpenAI-only models.\n'
      '- Provider entrypoints must not re-export `*_compatible` protocol layers.\n'
      '- Provider entrypoints must keep low-level HTTP utilities opt-in '
      '(no `client.dart` / `dio_strategy.dart` exports).',
    );
    exitCode = 1;
    return;
  }

  stdout.writeln('Public export boundaries: OK');
}

bool _isProviderPackage(String packageName) {
  if (!packageName.startsWith('llm_dart_')) return false;
  if (packageName == 'llm_dart_workspace') return false;
  if (packageName == 'llm_dart') return false;
  if (packageName == 'llm_dart_core') return false;
  if (packageName == 'llm_dart_ai') return false;
  if (packageName == 'llm_dart_builder') return false;
  if (packageName == 'llm_dart_provider_utils') return false;
  if (packageName.endsWith('_compatible')) return false;
  return true;
}

List<String> _checkCorePublicSurface(Directory packageDir) {
  final errors = <String>[];

  final entrypoint = File('${packageDir.path}/lib/llm_dart_core.dart');
  if (!entrypoint.existsSync()) {
    errors.add(
      'llm_dart_core missing entrypoint: ${_relPath(entrypoint.path)}',
    );
    return errors;
  }

  final exports = _extractExports(entrypoint.readAsStringSync());

  const forbiddenExports = {
    'models/assistant_models.dart',
    'models/responses_models.dart',
  };

  for (final target in exports) {
    final normalized = target.replaceAll('\\', '/');
    if (forbiddenExports.contains(normalized)) {
      errors.add(
        'llm_dart_core must not export OpenAI-only model: '
        '$normalized (entrypoint: ${_relPath(entrypoint.path)})',
      );
    }
  }

  for (final forbidden in forbiddenExports) {
    final file = File('${packageDir.path}/lib/$forbidden');
    if (file.existsSync()) {
      errors.add(
        'llm_dart_core must not ship OpenAI-only model file: '
        '${_relPath(file.path)}',
      );
    }
  }

  return errors;
}

List<String> _checkProviderEntrypoints(
    String packageName, Directory packageDir) {
  final errors = <String>[];

  final shortName = packageName.substring('llm_dart_'.length);
  final candidates = <File>[
    File('${packageDir.path}/lib/$shortName.dart'),
    File('${packageDir.path}/lib/llm_dart_$shortName.dart'),
  ];

  for (final file in candidates) {
    if (!file.existsSync()) continue;

    final exports = _extractExports(file.readAsStringSync());

    final forbiddenEntrypointExports = _forbiddenEntrypointExportsFor(
      packageName,
    );

    for (final target in exports) {
      final normalized = target.replaceAll('\\', '/');

      if (forbiddenEntrypointExports.contains(normalized)) {
        errors.add(
          '$packageName must not export "$normalized" from its entrypoints '
          '(found in ${_relPath(file.path)})',
        );
      }

      if (_isLowLevelHttpExport(normalized)) {
        errors.add(
          '$packageName must keep low-level HTTP utilities opt-in: '
          'export "$normalized" found in ${_relPath(file.path)}',
        );
      }

      if (_isProtocolReuseExport(normalized)) {
        errors.add(
          '$packageName must not re-export protocol reuse layers: '
          'export "$normalized" found in ${_relPath(file.path)}',
        );
      }
    }
  }

  return errors;
}

List<String> _checkOpenAICompatiblePublicSurface(Directory packageDir) {
  final errors = <String>[];

  final entrypoint = File(
    '${packageDir.path}/lib/llm_dart_openai_compatible.dart',
  );
  if (!entrypoint.existsSync()) {
    errors.add(
      'llm_dart_openai_compatible missing entrypoint: ${_relPath(entrypoint.path)}',
    );
    return errors;
  }

  final exports = _extractExports(entrypoint.readAsStringSync());
  const forbidden = {'client.dart', 'dio_strategy.dart'};

  for (final target in exports) {
    final normalized = target.replaceAll('\\', '/');
    if (forbidden.contains(normalized)) {
      errors.add(
        'llm_dart_openai_compatible must keep low-level HTTP utilities opt-in: '
        'export "$normalized" found in ${_relPath(entrypoint.path)}',
      );
    }
  }

  return errors;
}

Set<String> _forbiddenEntrypointExportsFor(String packageName) {
  if (packageName == 'llm_dart_openai') {
    // Keep OpenAI's main entrypoints task-first and push advanced endpoint
    // wrappers to opt-in imports.
    return const {
      'assistants.dart',
      'responses.dart',
      'responses_capability.dart',
      'responses_message_converter.dart',
      'builtin_tools.dart',
      'provider_tools.dart',
      'web_search_context_size.dart',
      'files.dart',
      'models.dart',
      'moderation.dart',
      'completion.dart',
    };
  }
  if (packageName == 'llm_dart_google') {
    // Keep Google entrypoints task-first; provider-native tool helpers are opt-in.
    return const {
      'provider_tools.dart',
      'web_search_tool_options.dart',
    };
  }
  if (packageName == 'llm_dart_anthropic') {
    return const {'files.dart', 'models.dart'};
  }
  if (packageName == 'llm_dart_deepseek') {
    return const {'models.dart'};
  }
  if (packageName == 'llm_dart_ollama') {
    return const {'completion.dart', 'models.dart'};
  }
  if (packageName == 'llm_dart_elevenlabs') {
    return const {'forced_alignment.dart', 'speech_to_speech.dart'};
  }
  if (packageName == 'llm_dart_xai') {
    // Keep xAI's main entrypoints task-first and require explicit opt-in for
    // the provider-native `/responses` adapter.
    return const {'responses.dart', 'responses_provider.dart'};
  }
  return const {};
}

bool _isLowLevelHttpExport(String normalizedTarget) {
  return normalizedTarget == 'client.dart' ||
      normalizedTarget.endsWith('/client.dart') ||
      normalizedTarget == 'dio_strategy.dart' ||
      normalizedTarget.endsWith('/dio_strategy.dart');
}

bool _isProtocolReuseExport(String normalizedTarget) {
  if (!normalizedTarget.startsWith('package:llm_dart_')) return false;
  return normalizedTarget.contains('_compatible/');
}

List<String> _extractExports(String fileText) {
  final exports = <String>[];
  final exportRe = RegExp(
    r'''^\s*export\s+['"]([^'"]+)['"]''',
    multiLine: true,
  );

  for (final match in exportRe.allMatches(fileText)) {
    final target = match.group(1);
    if (target == null) continue;
    exports.add(target.trim());
  }

  return exports;
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

String _relPath(String path) {
  final cwd = Directory.current.path;
  if (path.startsWith(cwd)) {
    return path.substring(cwd.length + 1);
  }
  return path;
}
