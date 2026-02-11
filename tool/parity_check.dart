import 'dart:io';

Future<int> _run(List<String> args) async {
  final p = await Process.start(
    args.first,
    args.sublist(1),
    mode: ProcessStartMode.inheritStdio,
  );
  return p.exitCode;
}

void main(List<String> args) async {
  final write = args.contains('--write');
  final check = args.contains('--check') || !write;

  if (write && check) {
    stderr.writeln('Pass at most one of --check or --write.');
    exitCode = 2;
    return;
  }

  final sync = ['dart', 'run', 'tool/sync_vercel_fixtures.dart'];
  final meta = ['dart', 'run', 'tool/check_v3_meta.dart'];
  final upstream = ['dart', 'run', 'tool/backfill_v3_meta_upstream.dart'];
  final goldens = ['dart', 'run', 'tool/update_v3_goldens.dart'];

  final modeFlag = write ? '--write' : '--check';

  final steps = <List<String>>[
    [...sync, modeFlag],
    [...meta, modeFlag],
    [...upstream, modeFlag],
    [...goldens, modeFlag],
  ];

  for (final cmd in steps) {
    final code = await _run(cmd);
    if (code != 0) {
      exitCode = code;
      return;
    }
  }
}
