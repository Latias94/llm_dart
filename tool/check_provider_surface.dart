import 'dart:io';

import 'package:yaml/yaml.dart';

/// Guard rail for Tier 2 provider public surfaces.
///
/// Provider classes should stay "capability-first" and must not expose
/// protocol/transport/endpoint wrappers as public members.
///
/// This script enforces that `*Provider` classes inside provider packages do
/// not expose Tier 3 members like:
/// - `client` / `responses`
/// - `*Api` getters (e.g. `modelsApi`, `filesApi`)
/// - endpoint-style helper methods (e.g. `uploadFile`, `models`, `complete`)
///
/// Rationale: keep Tier 2 stable; require explicit opt-in via subpath libraries.
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

    if (!_isProviderPackage(packageName)) continue;

    errors.addAll(_checkProviderPackageSurface(packageName, packageDir));
  }

  if (errors.isNotEmpty) {
    stderr.writeln('Provider surface violations:\n');
    for (final e in errors) {
      stderr.writeln('- $e');
    }
    stderr.writeln(
      '\nRule (summary): provider `*Provider` classes must not expose Tier 3 '
      'transport/endpoint APIs (use opt-in subpath libraries instead).',
    );
    exitCode = 1;
    return;
  }

  stdout.writeln('Provider surface: OK');
}

List<String> _checkProviderPackageSurface(
    String packageName, Directory packageDir) {
  final errors = <String>[];
  final libDir = Directory('${packageDir.path}/lib');
  if (!libDir.existsSync()) {
    errors.add('$packageName missing lib/: ${_relPath(libDir.path)}');
    return errors;
  }

  final providerFiles = <File>[];
  for (final entity in libDir.listSync(recursive: true, followLinks: false)) {
    if (entity is! File) {
      continue;
    }
    if (!entity.path.endsWith('${Platform.pathSeparator}provider.dart')) {
      continue;
    }
    providerFiles.add(entity);
  }

  for (final file in providerFiles) {
    final content = file.readAsStringSync();
    if (!content.contains('class')) {
      continue;
    }
    if (!RegExp(r'\bclass\s+\w+Provider\b').hasMatch(content)) {
      continue;
    }

    final violations = _scanProviderFileForTier3Surface(content);
    if (violations.isEmpty) {
      continue;
    }

    for (final v in violations) {
      errors.add('${_relPath(file.path)}:${v.line}: ${v.message}');
    }
  }

  return errors;
}

class _Violation {
  final int line;
  final String message;

  const _Violation(this.line, this.message);
}

List<_Violation> _scanProviderFileForTier3Surface(String source) {
  final violations = <_Violation>[];

  final forbiddenGetters = {'client', 'responses'};

  final forbiddenMethodNames = {
    // Generic endpoint-style helpers.
    'uploadFile',
    'uploadFileFromBytes',
    'listFiles',
    'retrieveFile',
    'deleteFile',
    'deleteFiles',
    'getFileContent',
    'getFileContentAsString',
    'fileExists',
    'models',
    'listModels',
    'getModel',
    'moderate',
    'complete',
    // Assistants-style helpers.
    'createAssistant',
    'listAssistants',
    'retrieveAssistant',
    'modifyAssistant',
    'deleteAssistant',
    // Responses-style helpers (Tier 3).
    'getResponse',
    'deleteResponse',
    'cancelResponse',
    'listInputItems',
    'continueConversation',
    'forkConversation',
    'chatWithToolsBackground',
    // ElevenLabs extras.
    'convertSpeechToSpeech',
    'convertSpeechToSpeechStream',
    'createForcedAlignment',
  };

  final getterRegex = RegExp(r'\bget\s+([A-Za-z_]\w*)\b');
  final apiNameRegex = RegExp(r'^([A-Za-z]\w*Api)$');
  final methodDeclRegex = RegExp(
    r'^\s*(?:Future|Stream|void|int|double|num|bool|String|List|Map|Set|[A-Z]\w*)'
    r'(?:<[^;>{}]*>)?\s+([A-Za-z_]\w*)\s*\(',
  );

  var inBlockComment = false;
  var braceDepth = 0;
  var pendingProviderClass = false;
  var inProviderClass = false;
  var providerClassDepth = -1;

  final lines = source.split('\n');

  for (var index = 0; index < lines.length; index++) {
    final originalLine = lines[index];
    final lineNumber = index + 1;

    final sanitized = _stripComments(
      originalLine,
      inBlockComment: inBlockComment,
    );
    inBlockComment = sanitized.inBlockComment;
    final line = sanitized.text;

    final preDepth = braceDepth;

    if (!inProviderClass && !pendingProviderClass) {
      if (RegExp(r'\bclass\s+\w+Provider\b').hasMatch(line)) {
        pendingProviderClass = true;
      }
    }

    if (inProviderClass && preDepth == providerClassDepth) {
      final getterMatch = getterRegex.firstMatch(line);
      if (getterMatch != null) {
        final name = getterMatch.group(1);
        if (name != null && forbiddenGetters.contains(name)) {
          violations.add(
            _Violation(
              lineNumber,
              'Public getter "$name" is Tier 3 and must be opt-in.',
            ),
          );
        }
        if (name != null && apiNameRegex.hasMatch(name)) {
          violations.add(
            _Violation(
              lineNumber,
              'Public getter "$name" is Tier 3 and must be opt-in.',
            ),
          );
        }
      }

      // Detect public fields named `client`/`responses` or ending with `Api`.
      final fieldMatch = RegExp(
        r'^\s*(?:final|late\s+final)\s+[^;=]+?\s+([A-Za-z]\w*)\b',
      ).firstMatch(line);
      if (fieldMatch != null) {
        final name = fieldMatch.group(1);
        if (name != null && forbiddenGetters.contains(name)) {
          violations.add(
            _Violation(
              lineNumber,
              'Public field "$name" is Tier 3 and must be opt-in.',
            ),
          );
        }
        if (name != null && apiNameRegex.hasMatch(name)) {
          violations.add(
            _Violation(
              lineNumber,
              'Public field "$name" is Tier 3 and must be opt-in.',
            ),
          );
        }
      }

      final methodMatch = methodDeclRegex.firstMatch(line);
      if (methodMatch != null) {
        final name = methodMatch.group(1);
        if (name != null && forbiddenMethodNames.contains(name)) {
          violations.add(
            _Violation(
              lineNumber,
              'Public method "$name" is Tier 3 and must be opt-in.',
            ),
          );
        }
      }
    }

    // Update brace depth and provider class state by scanning the sanitized line.
    for (var i = 0; i < line.length; i++) {
      final ch = line[i];
      if (ch == '{') {
        braceDepth += 1;
        if (pendingProviderClass) {
          pendingProviderClass = false;
          inProviderClass = true;
          providerClassDepth = braceDepth;
        }
      } else if (ch == '}') {
        braceDepth -= 1;
      }
    }

    if (inProviderClass && braceDepth < providerClassDepth) {
      inProviderClass = false;
      providerClassDepth = -1;
    }
  }

  return violations;
}

class _SanitizedLine {
  final String text;
  final bool inBlockComment;

  const _SanitizedLine(this.text, this.inBlockComment);
}

_SanitizedLine _stripComments(
  String line, {
  required bool inBlockComment,
}) {
  final buffer = StringBuffer();
  var i = 0;
  var inBlock = inBlockComment;

  while (i < line.length) {
    if (!inBlock &&
        i + 1 < line.length &&
        line[i] == '/' &&
        line[i + 1] == '/') {
      break; // line comment
    }
    if (!inBlock &&
        i + 1 < line.length &&
        line[i] == '/' &&
        line[i + 1] == '*') {
      inBlock = true;
      i += 2;
      continue;
    }
    if (inBlock &&
        i + 1 < line.length &&
        line[i] == '*' &&
        line[i + 1] == '/') {
      inBlock = false;
      i += 2;
      continue;
    }
    if (!inBlock) buffer.writeCharCode(line.codeUnitAt(i));
    i += 1;
  }

  return _SanitizedLine(buffer.toString(), inBlock);
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

String _relPath(String path) {
  final cwd = Directory.current.path;
  if (path.startsWith(cwd)) {
    return path.substring(cwd.length + 1);
  }
  return path;
}
