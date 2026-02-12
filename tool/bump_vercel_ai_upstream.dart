import 'dart:convert';
import 'dart:io';

Future<int> _run(List<String> args) async {
  final p = await Process.start(
    args.first,
    args.sublist(1),
    mode: ProcessStartMode.inheritStdio,
  );
  return p.exitCode;
}

String _requireArgValue(List<String> args, String name) {
  final prefix = '$name=';
  for (final a in args) {
    if (a.startsWith(prefix)) {
      final v = a.substring(prefix.length).trim();
      if (v.isNotEmpty) return v;
    }
  }
  throw ArgumentError('Missing required arg: $name=<value>');
}

bool _hasFlag(List<String> args, String flag) => args.contains(flag);

bool _looksLikeCommitSha(String value) =>
    RegExp(r'^[a-fA-F0-9]{7,40}$').hasMatch(value);

Future<void> main(List<String> args) async {
  final write = _hasFlag(args, '--write');
  final check = _hasFlag(args, '--check') || !write;

  if (write && check) {
    stderr.writeln('Pass at most one of --write or --check.');
    exitCode = 2;
    return;
  }

  final commit = _requireArgValue(args, '--commit');
  if (!_looksLikeCommitSha(commit)) {
    stderr.writeln('Invalid commit sha: $commit');
    exitCode = 2;
    return;
  }

  final upstreamPath = 'test/fixtures/v3_parts/_upstream.json';
  final upstreamFile = File(upstreamPath);
  if (!upstreamFile.existsSync()) {
    stderr.writeln('Missing file: $upstreamPath');
    exitCode = 2;
    return;
  }

  final decoded = jsonDecode(upstreamFile.readAsStringSync());
  if (decoded is! Map) {
    stderr.writeln('Invalid JSON: $upstreamPath');
    exitCode = 2;
    return;
  }

  final obj = decoded.cast<String, dynamic>();
  final current = obj['commit'] as String?;

  if (check) {
    if (current != commit) {
      stderr.writeln(
        'Upstream commit mismatch. '
        'Expected $commit, got ${current ?? '(missing)'}',
      );
      exitCode = 1;
      return;
    }
    stdout.writeln('Upstream commit OK: $commit');
    return;
  }

  obj['commit'] = commit;
  upstreamFile.writeAsStringSync(
    '${const JsonEncoder.withIndent('  ').convert(obj)}\n',
  );

  final shouldCheckout = _hasFlag(args, '--checkout');
  if (shouldCheckout) {
    final dir = Directory('repo-ref/ai');
    if (!dir.existsSync()) dir.createSync(recursive: true);

    final gitDir = Directory('repo-ref/ai/.git');
    if (!gitDir.existsSync()) {
      final code = await _run([
        'git',
        'clone',
        '--filter=blob:none',
        '--no-checkout',
        'https://github.com/vercel/ai.git',
        'repo-ref/ai',
      ]);
      if (code != 0) {
        exitCode = code;
        return;
      }
    }

    final fetch = await _run(
        ['git', '-C', 'repo-ref/ai', 'fetch', '--depth=1', 'origin', commit]);
    if (fetch != 0) {
      exitCode = fetch;
      return;
    }

    final checkout =
        await _run(['git', '-C', 'repo-ref/ai', 'checkout', '--force', commit]);
    if (checkout != 0) {
      exitCode = checkout;
      return;
    }
  }

  // Bring fixtures/meta/goldens back to green in one pass.
  final parity =
      await _run(['dart', 'run', 'tool/parity_check.dart', '--write']);
  if (parity != 0) {
    exitCode = parity;
    return;
  }
}
