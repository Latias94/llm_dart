import 'dart:io';

/// Runs a focused subset of tests that validate `providerMetadata` conventions.
///
/// This keeps CI/local loops fast when iterating on provider metadata or alias
/// behavior, without running the full suite.
Future<void> main(List<String> args) async {
  final testFiles = _discoverMetadataTests(
    Directory('test'),
  );

  if (testFiles.isEmpty) {
    stderr.writeln('No providerMetadata tests found under `test/`.');
    exitCode = 2;
    return;
  }

  final dartArgs = <String>[
    'test',
    '-j',
    '1',
    ...testFiles,
  ];

  final proc = await Process.start(
    'dart',
    dartArgs,
    mode: ProcessStartMode.inheritStdio,
  );

  exitCode = await proc.exitCode;
}

List<String> _discoverMetadataTests(Directory root) {
  if (!root.existsSync()) return const [];

  final results = <String>[];

  for (final entity in root.listSync(recursive: true, followLinks: false)) {
    if (entity is! File) continue;
    final path = entity.path.replaceAll('\\', '/');
    if (!path.endsWith('_test.dart')) continue;

    // Include providerMetadata coverage tests.
    final isMetadataTest = path.endsWith('_provider_metadata_test.dart') ||
        path.endsWith('_provider_metadata_alias_test.dart') ||
        path.contains('provider_metadata_') ||
        path.contains('provider_metadata');

    if (!isMetadataTest) continue;
    results.add(path);
  }

  results.sort();
  return results;
}
