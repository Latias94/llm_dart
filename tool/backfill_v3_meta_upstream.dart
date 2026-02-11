import 'dart:convert';
import 'dart:io';

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

void main(List<String> args) {
  final write = args.contains('--write');
  final check = args.contains('--check') || !write;

  if (check && write) {
    stderr.writeln('Pass at most one of --check or --write.');
    exitCode = 2;
    return;
  }

  final upstreamInfo = _readUpstreamInfo();
  if (upstreamInfo == null) {
    stderr.writeln(
      'Missing upstream info: test/fixtures/v3_parts/_upstream.json',
    );
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
      .where((f) => f.path.endsWith('.meta.json'))
      .where((f) =>
          !f.path.endsWith('${Platform.pathSeparator}_template.meta.json'))
      .toList(growable: false)
    ..sort((a, b) => a.path.compareTo(b.path));

  var touched = 0;
  var missing = 0;

  for (final file in metas) {
    final decoded = jsonDecode(file.readAsStringSync());
    if (decoded is! Map) continue;
    final meta = decoded.cast<String, dynamic>();

    final source = meta['source'];
    final sourceType =
        (source is Map) ? (source['type'] as String?)?.trim() ?? '' : '';
    final sourcePaths = <String>[
      if (source is Map && source['paths'] is List)
        ...((source['paths'] as List).map((e) => e.toString())),
    ];

    final repoRefPaths = sourcePaths
        .where((p) => p.replaceAll('\\', '/').startsWith('repo-ref/ai/'))
        .toList(growable: false);

    final isVendored = sourceType == 'vendored-ai-sdk-fixture';
    if (!isVendored && repoRefPaths.isEmpty) {
      // Handcrafted scenarios: do not inject upstream fields automatically.
      continue;
    }

    final upstream = (meta['upstream'] is Map)
        ? (meta['upstream'] as Map).cast<String, dynamic>()
        : <String, dynamic>{};

    upstream['repository'] ??= upstreamInfo['repository'];
    upstream['commit'] ??= upstreamInfo['commit'];
    upstream['license'] ??= upstreamInfo['license'];

    if (repoRefPaths.isNotEmpty) {
      final existing = upstream['paths'];
      if (existing is List) {
        final list = existing.map((e) => e.toString()).toList();
        for (final p in repoRefPaths) {
          if (!list.contains(p)) list.add(p);
        }
        upstream['paths'] = list;
      } else {
        upstream['paths'] = repoRefPaths;
      }
    }

    if (upstream.isEmpty) {
      missing++;
      continue;
    }

    final before = file.readAsStringSync();
    meta['upstream'] = upstream;
    final after = _prettyJson(meta);

    if (before == after) continue;

    if (write) {
      file.writeAsStringSync(after);
      stdout.writeln('Updated meta: ${file.path.replaceAll('\\', '/')}');
    }
    touched++;
  }

  if (missing > 0) {
    stderr.writeln('Metas missing upstream info: $missing');
  }

  if (check) {
    if (touched > 0 || missing > 0) {
      stderr.writeln(
        'Upstream backfill check failed (touched=$touched, missing=$missing). '
        'Run with --write to apply.',
      );
      exitCode = 1;
      return;
    }
    stdout.writeln('Upstream backfill OK.');
    exitCode = 0;
    return;
  }

  stdout.writeln('Done (updated=$touched, missing=$missing).');
  exitCode = 0;
}
