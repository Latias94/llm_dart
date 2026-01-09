import 'dart:io';

/// Syncs Vercel AI SDK test fixtures from `repo-ref/ai` into `test/fixtures`.
///
/// This tool is intentionally conservative:
/// - It never deletes files from `test/fixtures`.
/// - By default it runs in `--check` mode and exits with code 1 if diffs exist.
///
/// Usage:
///   dart run tool/sync_vercel_fixtures.dart --check
///   dart run tool/sync_vercel_fixtures.dart --write
///   dart run tool/sync_vercel_fixtures.dart --write --only=openai,anthropic
void main(List<String> args) {
  final flags = _parseArgs(args);

  final mappings = <_Mapping>[
    _Mapping(
      id: 'openai-responses',
      sourceDir:
          Directory('repo-ref/ai/packages/openai/src/responses/__fixtures__'),
      targetDir: Directory('test/fixtures/openai/responses'),
    ),
    _Mapping(
      id: 'openai-chat',
      sourceDir: Directory('repo-ref/ai/packages/openai/src/chat/__fixtures__'),
      targetDir: Directory('test/fixtures/openai/chat'),
    ),
    _Mapping(
      id: 'anthropic-messages',
      sourceDir: Directory('repo-ref/ai/packages/anthropic/src/__fixtures__'),
      targetDir: Directory('test/fixtures/anthropic/messages'),
    ),
    _Mapping(
      id: 'deepseek-chat',
      sourceDir:
          Directory('repo-ref/ai/packages/deepseek/src/chat/__fixtures__'),
      targetDir: Directory('test/fixtures/openai_compatible'),
    ),
    _Mapping(
      id: 'xai-responses',
      sourceDir:
          Directory('repo-ref/ai/packages/xai/src/responses/__fixtures__'),
      targetDir: Directory('test/fixtures/xai/responses'),
    ),
  ];

  final selected = flags.only.isEmpty
      ? mappings
      : mappings.where((m) => flags.only.contains(m.id)).toList();

  if (selected.isEmpty) {
    stderr.writeln(
      'No mappings selected. Valid ids: ${mappings.map((m) => m.id).join(', ')}',
    );
    exitCode = 2;
    return;
  }

  var hasDiffs = false;

  for (final m in selected) {
    if (!m.sourceDir.existsSync()) {
      stderr.writeln('Missing source: ${m.sourceDir.path} (skip ${m.id})');
      continue;
    }

    if (!m.targetDir.existsSync()) {
      if (flags.write) {
        m.targetDir.createSync(recursive: true);
      } else {
        stderr.writeln('Missing target: ${m.targetDir.path} (needs sync)');
        hasDiffs = true;
        continue;
      }
    }

    final sourceFiles = _listFiles(m.sourceDir);
    final targetFiles = _listFiles(m.targetDir);
    final targetByName = {for (final f in targetFiles) _basename(f.path): f};

    var copied = 0;
    var updated = 0;
    var unchanged = 0;
    final missingInTarget = <String>[];
    final different = <String>[];

    for (final src in sourceFiles) {
      final name = _basename(src.path);
      final dst = targetByName[name];
      if (dst == null) {
        missingInTarget.add(name);
        continue;
      }
      if (_bytesEqual(src, dst)) {
        unchanged++;
        continue;
      }
      different.add(name);
    }

    final sourceNames = sourceFiles.map((f) => _basename(f.path)).toSet();
    final extrasInTarget = targetFiles
        .map((f) => _basename(f.path))
        .where((n) => !sourceNames.contains(n))
        .toList()
      ..sort();

    if (missingInTarget.isNotEmpty || different.isNotEmpty) {
      hasDiffs = true;
    }

    if (flags.write) {
      for (final name in missingInTarget) {
        final src = File('${m.sourceDir.path}${Platform.pathSeparator}$name');
        final dst = File('${m.targetDir.path}${Platform.pathSeparator}$name');
        src.copySync(dst.path);
        copied++;
      }
      for (final name in different) {
        final src = File('${m.sourceDir.path}${Platform.pathSeparator}$name');
        final dst = File('${m.targetDir.path}${Platform.pathSeparator}$name');
        src.copySync(dst.path);
        updated++;
      }
    }

    stdout.writeln('[${m.id}]');
    stdout.writeln(
      flags.write
          ? 'copied=$copied updated=$updated unchanged=$unchanged'
          : 'missing=${missingInTarget.length} changed=${different.length} unchanged=$unchanged',
    );

    if (flags.verbose) {
      if (missingInTarget.isNotEmpty) {
        stdout.writeln('  missing: ${missingInTarget..sort()}');
      }
      if (different.isNotEmpty) {
        stdout.writeln('  changed: ${different..sort()}');
      }
      if (extrasInTarget.isNotEmpty) {
        stdout.writeln('  extra (kept): $extrasInTarget');
      }
    }
  }

  if (flags.check && hasDiffs) {
    exitCode = 1;
    return;
  }

  exitCode = 0;
}

class _Mapping {
  final String id;
  final Directory sourceDir;
  final Directory targetDir;

  const _Mapping({
    required this.id,
    required this.sourceDir,
    required this.targetDir,
  });
}

class _Flags {
  final bool check;
  final bool write;
  final bool verbose;
  final Set<String> only;

  const _Flags({
    required this.check,
    required this.write,
    required this.verbose,
    required this.only,
  });
}

_Flags _parseArgs(List<String> args) {
  var check = true;
  var write = false;
  var verbose = false;
  final only = <String>{};

  for (final a in args) {
    if (a == '--check') {
      check = true;
      continue;
    }
    if (a == '--write') {
      write = true;
      check = false;
      continue;
    }
    if (a == '--verbose') {
      verbose = true;
      continue;
    }
    if (a.startsWith('--only=')) {
      final raw = a.substring('--only='.length).trim();
      if (raw.isNotEmpty) {
        only.addAll(
          raw.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty),
        );
      }
      continue;
    }
  }

  return _Flags(check: check, write: write, verbose: verbose, only: only);
}

List<File> _listFiles(Directory dir) {
  return dir
      .listSync(followLinks: false)
      .whereType<File>()
      .toList(growable: false)
    ..sort((a, b) => a.path.compareTo(b.path));
}

String _basename(String path) {
  final sep = Platform.pathSeparator;
  final idx = path.lastIndexOf(sep);
  if (idx < 0) return path;
  return path.substring(idx + 1);
}

bool _bytesEqual(File a, File b) {
  if (!b.existsSync()) return false;
  if (a.lengthSync() != b.lengthSync()) return false;
  final aBytes = a.readAsBytesSync();
  final bBytes = b.readAsBytesSync();
  if (aBytes.length != bBytes.length) return false;
  for (var i = 0; i < aBytes.length; i++) {
    if (aBytes[i] != bBytes[i]) return false;
  }
  return true;
}
