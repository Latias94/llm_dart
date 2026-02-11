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

String? _repoRefFixturePathFor(String provider, String scenario) {
  final filename = '$scenario.chunks.txt';
  switch (provider) {
    case 'openai':
      return 'repo-ref/ai/packages/openai/src/responses/__fixtures__/$filename';
    case 'openai_chat':
      return 'repo-ref/ai/packages/openai/src/chat/__fixtures__/$filename';
    case 'azure':
      return 'repo-ref/ai/packages/azure/src/__fixtures__/$filename';
    case 'anthropic':
      return 'repo-ref/ai/packages/anthropic/src/__fixtures__/$filename';
    case 'openai_compatible':
      return 'repo-ref/ai/packages/deepseek/src/chat/__fixtures__/$filename';
    case 'xai':
      return 'repo-ref/ai/packages/xai/src/responses/__fixtures__/$filename';
    case 'open_responses':
      return 'repo-ref/ai/packages/open-responses/src/responses/__fixtures__/$filename';
    case 'groq':
      return null; // handcrafted contract fixtures (no upstream chunks).
    case 'ollama':
      return null; // handcrafted contract fixtures (no upstream chunks).
    case 'google':
      return null; // handcrafted contract fixtures (no upstream chunks).
    case 'google_vertex':
      return null; // handcrafted contract fixtures (no upstream chunks).
  }
  return null;
}

String? _localFixturePathFor(String provider, String scenario) {
  final filename = '$scenario.chunks.txt';
  switch (provider) {
    case 'openai':
      return 'test/fixtures/openai/responses/$filename';
    case 'openai_chat':
      return 'test/fixtures/openai/chat/$filename';
    case 'azure':
      return 'test/fixtures/azure/responses/$filename';
    case 'anthropic':
      return 'test/fixtures/anthropic/messages/$filename';
    case 'openai_compatible':
      return 'test/fixtures/openai_compatible/$filename';
    case 'xai':
      return 'test/fixtures/xai/responses/$filename';
    case 'open_responses':
      return 'test/fixtures/open_responses/responses/$filename';
    case 'groq':
      return 'test/fixtures/groq/chat/$filename';
    case 'ollama':
      return 'test/fixtures/ollama/chat/$filename';
    case 'google':
      return 'test/fixtures/google/chat/$filename';
    case 'google_vertex':
      return 'test/fixtures/google_vertex/chat/$filename';
  }
  return null;
}

List<String> _readStringList(Object? value) {
  if (value is! List) return const [];
  return value
      .map((e) => e.toString().trim())
      .where((s) => s.isNotEmpty)
      .toList(growable: false);
}

bool _containsPath(List<String> paths, String path) =>
    paths.map(_normalizePath).contains(_normalizePath(path));

void main(List<String> args) {
  final fix = args.contains('--fix') || args.contains('--write');
  final check = args.contains('--check') || !fix;

  if (check && fix) {
    stderr.writeln('Pass at most one of --check or --fix.');
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
  var fixedFiles = 0;
  var fixedFields = 0;

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
    final before = _prettyJson(meta);

    final provider = (meta['provider'] as String?)?.trim();
    final scenario = (meta['scenario'] as String?)?.trim();

    if (provider == null || provider.isEmpty) {
      issues.add(_Issue('ERROR', path, 'Missing or empty `provider`.'));
      if (fix) {
        meta['provider'] = expectedProvider;
        fixedFields++;
      }
    } else if (provider != expectedProvider) {
      issues.add(
        _Issue(
          'ERROR',
          path,
          '`provider` mismatch: meta=$provider path=$expectedProvider',
        ),
      );
      if (fix) {
        meta['provider'] = expectedProvider;
        fixedFields++;
      }
    }

    if (scenario == null || scenario.isEmpty) {
      issues.add(_Issue('ERROR', path, 'Missing or empty `scenario`.'));
      if (fix) {
        meta['scenario'] = expectedScenario;
        fixedFields++;
      }
    } else if (scenario != expectedScenario) {
      issues.add(
        _Issue(
          'ERROR',
          path,
          '`scenario` mismatch: meta=$scenario path=$expectedScenario',
        ),
      );
      if (fix) {
        meta['scenario'] = expectedScenario;
        fixedFields++;
      }
    }

    final effectiveProvider =
        (meta['provider'] as String?)?.trim() ?? expectedProvider;
    final effectiveScenario =
        (meta['scenario'] as String?)?.trim() ?? expectedScenario;

    final description = (meta['description'] as String?)?.trim() ?? '';
    if (description.isEmpty) {
      issues.add(_Issue('ERROR', path, 'Missing or empty `description`.'));
    } else if (description.contains('Short human-readable description') ||
        description.contains('Auto-generated meta')) {
      issues.add(
        _Issue(
          'WARN',
          path,
          '`description` appears to be a placeholder; please replace it.',
        ),
      );
    }

    final source = (meta['source'] is Map)
        ? (meta['source'] as Map).cast<String, dynamic>()
        : null;
    final sourceType = (source?['type'] as String?)?.trim() ?? '';
    final sourcePaths =
        _readStringList(source?['paths']).map(_normalizePath).toList();
    final isVendored = sourceType == 'vendored-ai-sdk-fixture';

    final expectedLocalFixturePath =
        _localFixturePathFor(effectiveProvider, effectiveScenario);
    final expectedRepoRefFixturePath =
        _repoRefFixturePathFor(effectiveProvider, effectiveScenario);

    final hasLocal = expectedLocalFixturePath != null &&
        _containsPath(sourcePaths, expectedLocalFixturePath);
    final hasRepoRef = expectedRepoRefFixturePath != null &&
        _containsPath(sourcePaths, expectedRepoRefFixturePath);

    if (!hasLocal) {
      issues.add(
        _Issue(
          isVendored ? 'ERROR' : 'WARN',
          path,
          '`source.paths` missing local fixture path.',
        ),
      );
      if (fix &&
          expectedLocalFixturePath != null &&
          File(expectedLocalFixturePath).existsSync()) {
        final updated = List<String>.from(sourcePaths);
        updated.insert(0, expectedLocalFixturePath);
        source?['paths'] = updated;
        meta['source'] = source;
        fixedFields++;
      }
    } else {
      for (final p
          in sourcePaths.where((p) => p.startsWith('test/fixtures/'))) {
        if (!File(p).existsSync()) {
          issues.add(_Issue('ERROR', path, 'Local fixture not found: $p'));
        }
      }
    }

    if (isVendored) {
      if (!hasRepoRef) {
        issues.add(
          _Issue(
            'ERROR',
            path,
            '`source.paths` missing repo-ref fixture path.',
          ),
        );
        if (fix &&
            expectedRepoRefFixturePath != null &&
            File(expectedRepoRefFixturePath).existsSync()) {
          final updated = List<String>.from(sourcePaths);
          updated.add(expectedRepoRefFixturePath);
          source?['paths'] = updated;
          meta['source'] = source;
          fixedFields++;
        }
      } else {
        for (final p
            in sourcePaths.where((p) => p.startsWith('repo-ref/ai/'))) {
          if (!File(p).existsSync()) {
            issues.add(_Issue('ERROR', path, 'Repo-ref fixture not found: $p'));
          }
        }
      }
    }

    // Upstream provenance checks:
    // - required for vendored fixtures
    // - optional for hand-constructed scenarios
    final upstream = (meta['upstream'] is Map)
        ? (meta['upstream'] as Map).cast<String, dynamic>()
        : null;

    if (isVendored && upstream == null) {
      issues.add(_Issue('ERROR', path, 'Missing `upstream` object.'));
      if (fix) {
        meta['upstream'] = <String, dynamic>{
          'repository': upstreamInfo['repository'],
          'commit': upstreamInfo['commit'],
          'license': upstreamInfo['license'],
          if (expectedRepoRefFixturePath != null)
            'paths': [expectedRepoRefFixturePath],
        };
        fixedFields++;
      }
    } else if (upstream != null) {
      final uRepo = (upstream['repository'] as String?)?.trim();
      final uCommit = (upstream['commit'] as String?)?.trim();
      final uLicense = (upstream['license'] as String?)?.trim();

      if (isVendored) {
        if (uRepo == null || uRepo.isEmpty) {
          issues.add(_Issue('ERROR', path, 'Missing `upstream.repository`.'));
          if (fix) {
            upstream['repository'] = upstreamInfo['repository'];
            fixedFields++;
          }
        } else if (uRepo != upstreamInfo['repository']) {
          issues.add(
            _Issue(
              'ERROR',
              path,
              '`upstream.repository` mismatch: meta=$uRepo expected=${upstreamInfo['repository']}',
            ),
          );
          if (fix) {
            upstream['repository'] = upstreamInfo['repository'];
            fixedFields++;
          }
        }

        if (uCommit == null || uCommit.isEmpty) {
          issues.add(_Issue('ERROR', path, 'Missing `upstream.commit`.'));
          if (fix) {
            upstream['commit'] = upstreamInfo['commit'];
            fixedFields++;
          }
        } else if (uCommit != upstreamInfo['commit']) {
          issues.add(
            _Issue(
              'ERROR',
              path,
              '`upstream.commit` mismatch: meta=$uCommit expected=${upstreamInfo['commit']}',
            ),
          );
          if (fix) {
            upstream['commit'] = upstreamInfo['commit'];
            fixedFields++;
          }
        }

        if (uLicense == null || uLicense.isEmpty) {
          issues.add(_Issue(
              'WARN', path, 'Missing `upstream.license` (recommended).'));
          if (fix) {
            upstream['license'] = upstreamInfo['license'];
            fixedFields++;
          }
        } else if (uLicense != upstreamInfo['license']) {
          issues.add(
            _Issue(
              'WARN',
              path,
              '`upstream.license` mismatch: meta=$uLicense expected=${upstreamInfo['license']}',
            ),
          );
          if (fix) {
            upstream['license'] = upstreamInfo['license'];
            fixedFields++;
          }
        }

        final upstreamPaths = _readStringList(upstream['paths']);
        final needsRepoRefPath = expectedRepoRefFixturePath != null &&
            !_containsPath(upstreamPaths, expectedRepoRefFixturePath);
        if (upstreamPaths
            .where((p) => _normalizePath(p).startsWith('repo-ref/ai/'))
            .isEmpty) {
          issues.add(_Issue('ERROR', path,
              '`upstream.paths` must include repo-ref/ai paths.'));
        }

        if (needsRepoRefPath) {
          issues.add(
            _Issue(
              'ERROR',
              path,
              '`upstream.paths` missing repo-ref fixture path.',
            ),
          );
          if (fix &&
              expectedRepoRefFixturePath != null &&
              File(expectedRepoRefFixturePath).existsSync()) {
            upstream['paths'] = [...upstreamPaths, expectedRepoRefFixturePath];
            fixedFields++;
          }
        }
      }

      final uRepoRefPaths = _readStringList(upstream['paths'])
          .map(_normalizePath)
          .where((p) => p.startsWith('repo-ref/ai/'))
          .toList(growable: false);
      for (final p in uRepoRefPaths) {
        if (!File(p).existsSync()) {
          issues.add(_Issue('ERROR', path, 'Upstream path not found: $p'));
        }
      }
    }

    // Golden existence check (must exist for any scenario).
    final providerDir = Directory('test/fixtures/v3_parts/$expectedProvider');
    if (!providerDir.existsSync()) {
      issues.add(
        _Issue(
          'ERROR',
          path,
          'Missing provider golden directory: ${_normalizePath(providerDir.path)}',
        ),
      );
    } else {
      final matches = providerDir
          .listSync(followLinks: false)
          .whereType<File>()
          .map((f) => _normalizePath(f.path))
          .where(
              (p) => p.contains('/$expectedScenario') && p.endsWith('.jsonl'))
          .toList(growable: false);
      if (matches.isEmpty) {
        issues.add(_Issue('ERROR', path,
            'Missing golden JSONL for scenario: $expectedScenario'));
      }
    }

    final after = _prettyJson(meta);
    if (fix && after != before) {
      file.writeAsStringSync(after);
      fixedFiles++;
      stdout.writeln('Fixed meta: $path');
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

  if (fix) {
    stdout.writeln('Fixed files: $fixedFiles (fields updated: $fixedFields).');
  }

  exitCode = 0;
}
