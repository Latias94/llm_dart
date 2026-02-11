import 'dart:convert';
import 'dart:io';

class _Issue {
  final String severity; // 'ERROR' | 'WARN'
  final String file;
  final String message;

  const _Issue(this.severity, this.file, this.message);
}

String _prettyJson(Object value) =>
    const JsonEncoder.withIndent('  ').convert(value) + '\n';

Map<String, dynamic>? _readUpstreamInfo() {
  final file = File('test/fixtures/v3_parts/_upstream.json');
  if (!file.existsSync()) return null;

  final decoded = jsonDecode(file.readAsStringSync());
  if (decoded is! Map) return null;
  final map = decoded.cast<String, dynamic>();

  return <String, dynamic>{
    if (map['repository'] is String) 'repository': map['repository'],
    if (map['commit'] is String) 'commit': map['commit'],
    if (map['license'] is String) 'license': map['license'],
  };
}

bool _isMetaFile(File f) =>
    f.path.endsWith('.meta.json') &&
    !f.path.endsWith('${Platform.pathSeparator}_template.meta.json');

String _normalizePath(String p) => p.replaceAll('\\', '/');

void main(List<String> args) {
  final check = args.contains('--check') || !args.contains('--write');
  final write = args.contains('--write');

  if (check && write) {
    stderr.writeln('Pass at most one of --check or --write.');
    exitCode = 2;
    return;
  }

  // This tool is check-only for now.
  if (write) {
    stderr.writeln('This tool is check-only. Use --check.');
    exitCode = 2;
    return;
  }

  final upstreamInfo = _readUpstreamInfo();
  if (upstreamInfo == null) {
    stderr.writeln(
        'Missing upstream info: test/fixtures/v3_parts/_upstream.json');
    exitCode = 2;
    return;
  }

  final root = Directory('test/fixtures/v3_parts');
  if (!root.existsSync()) {
    stderr.writeln('Missing directory: test/fixtures/v3_parts');
    exitCode = 2;
    return;
  }

  final metas = root
      .listSync(recursive: true, followLinks: false)
      .whereType<File>()
      .where(_isMetaFile)
      .toList(growable: false)
    ..sort((a, b) => a.path.compareTo(b.path));

  final issues = <_Issue>[];

  for (final file in metas) {
    final path = _normalizePath(file.path);
    final expectedProvider = path.split('/').reversed.skip(1).first;
    final expectedScenario = path.split('/').last.replaceAll('.meta.json', '');

    Object? decoded;
    try {
      decoded = jsonDecode(file.readAsStringSync());
    } catch (e) {
      issues.add(_Issue('ERROR', path, 'Invalid JSON: $e'));
      continue;
    }

    if (decoded is! Map) {
      issues.add(_Issue('ERROR', path, 'Expected JSON object at root.'));
      continue;
    }

    final meta = decoded.cast<String, dynamic>();

    final provider = (meta['provider'] as String?)?.trim();
    final scenario = (meta['scenario'] as String?)?.trim();
    if (provider == null || provider.isEmpty) {
      issues.add(_Issue('ERROR', path, 'Missing or empty `provider`.'));
    } else if (provider != expectedProvider) {
      issues.add(
        _Issue(
          'ERROR',
          path,
          '`provider` mismatch: meta=$provider path=$expectedProvider',
        ),
      );
    }

    if (scenario == null || scenario.isEmpty) {
      issues.add(_Issue('ERROR', path, 'Missing or empty `scenario`.'));
    } else if (scenario != expectedScenario) {
      issues.add(
        _Issue(
          'ERROR',
          path,
          '`scenario` mismatch: meta=$scenario path=$expectedScenario',
        ),
      );
    }

    final description = (meta['description'] as String?)?.trim() ?? '';
    if (description.isEmpty) {
      issues.add(_Issue('ERROR', path, 'Missing or empty `description`.'));
    }
    if (description.contains('Short human-readable description') ||
        description.contains('Auto-generated meta')) {
      issues.add(
        _Issue(
          'ERROR',
          path,
          '`description` appears to be a placeholder; please replace it.',
        ),
      );
    }

    // Validate `source.paths` contain local + repo-ref paths and exist.
    final source = meta['source'];
    final sourcePaths = <String>[];
    if (source is Map && source['paths'] is List) {
      for (final p in (source['paths'] as List)) {
        final s = p.toString().trim();
        if (s.isNotEmpty) sourcePaths.add(_normalizePath(s));
      }
    }

    final localFixturePaths = sourcePaths
        .where(
            (p) => p.startsWith('test/fixtures/') && p.endsWith('.chunks.txt'))
        .toList(growable: false);
    final repoRefPaths = sourcePaths
        .where((p) => p.startsWith('repo-ref/ai/') && p.endsWith('.chunks.txt'))
        .toList(growable: false);

    if (localFixturePaths.isEmpty) {
      issues.add(
          _Issue('ERROR', path, '`source.paths` missing local fixture path.'));
    }
    if (repoRefPaths.isEmpty) {
      issues.add(_Issue(
          'ERROR', path, '`source.paths` missing repo-ref fixture path.'));
    }

    for (final p in localFixturePaths) {
      if (!File(p).existsSync()) {
        issues.add(_Issue('ERROR', path, 'Local fixture not found: $p'));
      }
    }
    for (final p in repoRefPaths) {
      if (!File(p).existsSync()) {
        issues.add(_Issue('ERROR', path, 'Repo-ref fixture not found: $p'));
      }
    }

    // Validate `upstream` points at the pinned reference and includes repo-ref paths.
    final upstream = meta['upstream'];
    if (upstream is! Map) {
      issues.add(_Issue('ERROR', path, 'Missing `upstream` object.'));
    } else {
      final u = upstream.cast<String, dynamic>();
      final uRepo = (u['repository'] as String?)?.trim();
      final uCommit = (u['commit'] as String?)?.trim();
      final uLicense = (u['license'] as String?)?.trim();

      if (uRepo == null || uRepo.isEmpty) {
        issues.add(_Issue('ERROR', path, 'Missing `upstream.repository`.'));
      } else if (uRepo != upstreamInfo['repository']) {
        issues.add(
          _Issue(
            'ERROR',
            path,
            '`upstream.repository` mismatch: meta=$uRepo expected=${upstreamInfo['repository']}',
          ),
        );
      }

      if (uCommit == null || uCommit.isEmpty) {
        issues.add(_Issue('ERROR', path, 'Missing `upstream.commit`.'));
      } else if (uCommit != upstreamInfo['commit']) {
        issues.add(
          _Issue(
            'ERROR',
            path,
            '`upstream.commit` mismatch: meta=$uCommit expected=${upstreamInfo['commit']}',
          ),
        );
      }

      if (uLicense == null || uLicense.isEmpty) {
        issues.add(
            _Issue('WARN', path, 'Missing `upstream.license` (recommended).'));
      } else if (uLicense != upstreamInfo['license']) {
        issues.add(
          _Issue(
            'WARN',
            path,
            '`upstream.license` mismatch: meta=$uLicense expected=${upstreamInfo['license']}',
          ),
        );
      }

      final uPaths = <String>[];
      if (u['paths'] is List) {
        for (final p in (u['paths'] as List)) {
          final s = p.toString().trim();
          if (s.isNotEmpty) uPaths.add(_normalizePath(s));
        }
      }
      final uRepoRefPaths =
          uPaths.where((p) => p.startsWith('repo-ref/ai/')).toList();
      if (uRepoRefPaths.isEmpty) {
        issues.add(_Issue(
            'ERROR', path, '`upstream.paths` must include repo-ref/ai paths.'));
      }
      for (final p in uRepoRefPaths) {
        if (!File(p).existsSync()) {
          issues.add(_Issue('ERROR', path, 'Upstream path not found: $p'));
        }
      }
    }

    // Validate goldens exist for this scenario.
    if (provider != null &&
        provider.isNotEmpty &&
        scenario != null &&
        scenario.isNotEmpty) {
      final providerDir = Directory('test/fixtures/v3_parts/$provider');
      if (!providerDir.existsSync()) {
        issues.add(_Issue('ERROR', path,
            'Missing provider golden directory: ${providerDir.path}'));
      } else {
        final matches = providerDir
            .listSync(followLinks: false)
            .whereType<File>()
            .map((f) => _normalizePath(f.path))
            .where((p) => p.contains('/$scenario') && p.endsWith('.jsonl'))
            .toList(growable: false);
        if (matches.isEmpty) {
          issues.add(_Issue(
              'ERROR', path, 'Missing golden JSONL for scenario: $scenario'));
        }
      }
    }
  }

  final errors = issues.where((i) => i.severity == 'ERROR').toList();
  final warnings = issues.where((i) => i.severity == 'WARN').toList();

  for (final i in [...errors, ...warnings]) {
    final out = i.severity == 'ERROR' ? stderr : stdout;
    out.writeln('[${i.severity}] ${i.file}: ${i.message}');
  }

  if (errors.isNotEmpty) {
    stderr.writeln(
      '\nFound ${errors.length} error(s) and ${warnings.length} warning(s).',
    );
    exitCode = 1;
    return;
  }

  if (warnings.isNotEmpty) {
    stdout.writeln('\nOK with ${warnings.length} warning(s).');
  } else {
    stdout.writeln('OK.');
  }
  exitCode = 0;
}
