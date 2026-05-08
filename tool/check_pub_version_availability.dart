import 'dart:convert';
import 'dart:io';

import 'bootstrap_workspace_pubspec_overrides.dart'
    show publishableWorkspacePackages;

final class PubVersionAvailabilityOptions {
  final String? proxy;
  final bool showHelp;

  const PubVersionAvailabilityOptions({
    this.proxy,
    this.showHelp = false,
  });
}

final class PubPackageApiResult {
  final String packageName;
  final bool packageExists;
  final String? latestVersion;
  final Set<String> publishedVersions;

  const PubPackageApiResult({
    required this.packageName,
    required this.packageExists,
    required this.latestVersion,
    required this.publishedVersions,
  });

  bool containsVersion(String version) => publishedVersions.contains(version);
}

final class PubVersionAvailability {
  final String packageName;
  final String targetVersion;
  final bool packageExists;
  final String? latestVersion;
  final bool targetVersionExists;

  const PubVersionAvailability({
    required this.packageName,
    required this.targetVersion,
    required this.packageExists,
    required this.latestVersion,
    required this.targetVersionExists,
  });

  bool get passed => !targetVersionExists;

  String get status {
    if (targetVersionExists) {
      return 'blocked';
    }
    if (!packageExists) {
      return 'available-new-package';
    }
    return 'available-new-version';
  }
}

Future<void> main(List<String> arguments) async {
  late final PubVersionAvailabilityOptions options;
  try {
    options = parsePubVersionAvailabilityOptions(arguments);
  } on FormatException catch (error) {
    stderr.writeln('pub version availability argument error: ${error.message}');
    stderr.writeln('');
    stderr.write(pubVersionAvailabilityUsage);
    exitCode = 64;
    return;
  }

  if (options.showHelp) {
    stdout.write(pubVersionAvailabilityUsage);
    return;
  }

  final repoRoot = Directory.current.absolute;
  final results = <PubVersionAvailability>[];

  stdout.writeln('pub.dev version availability preflight');
  stdout.writeln('repository: ${repoRoot.path}');
  if (options.proxy != null) {
    stdout.writeln('proxy: ${options.proxy}');
  }

  for (final packageName in publishableWorkspacePackages) {
    final targetVersion = await readPackageVersion(
      repoRoot: repoRoot,
      packageName: packageName,
    );
    final apiResult = await fetchPubPackageApiResult(
      packageName,
      proxy: options.proxy,
    );
    final availability = PubVersionAvailability(
      packageName: packageName,
      targetVersion: targetVersion,
      packageExists: apiResult.packageExists,
      latestVersion: apiResult.latestVersion,
      targetVersionExists: apiResult.containsVersion(targetVersion),
    );
    results.add(availability);

    final latestSuffix = availability.latestVersion == null
        ? ''
        : ' (latest ${availability.latestVersion})';
    stdout.writeln(
      '- $packageName $targetVersion: ${availability.status}$latestSuffix',
    );
  }

  stdout.writeln('');
  stdout.write(buildPubVersionAvailabilityReport(results));

  if (results.any((result) => !result.passed)) {
    stderr.writeln('');
    stderr.writeln(
      'pub.dev version availability failed: at least one target version '
      'already exists.',
    );
    exitCode = 1;
  }
}

PubVersionAvailabilityOptions parsePubVersionAvailabilityOptions(
  List<String> arguments,
) {
  String? proxy;
  var showHelp = false;

  for (final argument in arguments) {
    switch (argument) {
      case '-h' || '--help':
        showHelp = true;
      default:
        if (argument.startsWith('--proxy=')) {
          proxy = _readFlagValue(argument, '--proxy=');
          continue;
        }
        throw FormatException('unknown option `$argument`');
    }
  }

  return PubVersionAvailabilityOptions(
    proxy: proxy,
    showHelp: showHelp,
  );
}

String _readFlagValue(String argument, String prefix) {
  final value = argument.substring(prefix.length).trim();
  if (value.isEmpty) {
    throw FormatException(
        '`${prefix.substring(0, prefix.length - 1)}` needs a value');
  }
  return value;
}

Future<String> readPackageVersion({
  required Directory repoRoot,
  required String packageName,
}) async {
  final packageDirectory = packageName == 'llm_dart'
      ? repoRoot
      : Directory.fromUri(repoRoot.uri.resolve('packages/$packageName/'));
  final pubspec = File.fromUri(packageDirectory.uri.resolve('pubspec.yaml'));
  if (!pubspec.existsSync()) {
    throw StateError('pubspec.yaml not found for `$packageName`.');
  }

  final lines = await pubspec.readAsLines();
  for (final rawLine in lines) {
    final line = rawLine.trim();
    if (line.startsWith('version:')) {
      final version = line.substring('version:'.length).trim();
      if (version.isNotEmpty) {
        return version;
      }
      break;
    }
  }

  throw StateError('pubspec.yaml for `$packageName` is missing a version.');
}

Future<PubPackageApiResult> fetchPubPackageApiResult(
  String packageName, {
  String? proxy,
}) async {
  final client = HttpClient();
  if (proxy != null) {
    client.findProxy = (_) => buildPubProxyRule(proxy);
  }

  try {
    final request = await client.getUrl(
      Uri.https('pub.dev', '/api/packages/$packageName'),
    );
    request.headers.set(HttpHeaders.acceptHeader, 'application/json');
    final response = await request.close();
    final body = await utf8.decoder.bind(response).join();

    if (response.statusCode == HttpStatus.notFound) {
      return PubPackageApiResult(
        packageName: packageName,
        packageExists: false,
        latestVersion: null,
        publishedVersions: const {},
      );
    }

    if (response.statusCode != HttpStatus.ok) {
      throw StateError(
        'pub.dev returned HTTP ${response.statusCode} for `$packageName`.',
      );
    }

    return parsePubPackageApiResult(
      packageName: packageName,
      responseBody: body,
    );
  } finally {
    client.close(force: true);
  }
}

String buildPubProxyRule(String proxy) {
  final proxyUri = Uri.parse(proxy);
  if (proxyUri.host.isEmpty || proxyUri.port == 0) {
    throw FormatException('invalid proxy URI `$proxy`');
  }
  final port = proxyUri.hasPort ? proxyUri.port : 80;
  return 'PROXY ${proxyUri.host}:$port';
}

PubPackageApiResult parsePubPackageApiResult({
  required String packageName,
  required String responseBody,
}) {
  final decoded = jsonDecode(responseBody);
  if (decoded is! Map<String, Object?>) {
    throw FormatException('pub.dev response for `$packageName` is not JSON.');
  }

  final latest = decoded['latest'];
  String? latestVersion;
  if (latest is Map<String, Object?>) {
    final value = latest['version'];
    if (value is String && value.isNotEmpty) {
      latestVersion = value;
    }
  }

  final versions = <String>{};
  final rawVersions = decoded['versions'];
  if (rawVersions is List) {
    for (final item in rawVersions) {
      if (item is! Map<String, Object?>) {
        continue;
      }
      final version = item['version'];
      if (version is String && version.isNotEmpty) {
        versions.add(version);
      }
    }
  }

  return PubPackageApiResult(
    packageName: packageName,
    packageExists: true,
    latestVersion: latestVersion,
    publishedVersions: Set.unmodifiable(versions),
  );
}

String buildPubVersionAvailabilityReport(
  List<PubVersionAvailability> results,
) {
  final buffer = StringBuffer()
    ..writeln('# Pub Version Availability')
    ..writeln()
    ..writeln('| Package | Target | Status | Latest Published |')
    ..writeln('| --- | --- | --- | --- |');

  for (final result in results) {
    buffer.writeln(
      '| ${result.packageName} | '
      '${result.targetVersion} | '
      '${result.status} | '
      '${result.latestVersion ?? '-'} |',
    );
  }

  buffer
    ..writeln()
    ..writeln(
      results.every((result) => result.passed)
          ? 'Result: passed'
          : 'Result: failed',
    );

  return buffer.toString();
}

const pubVersionAvailabilityUsage = '''
Usage: dart run tool/check_pub_version_availability.dart [options]

Checks pub.dev for the target versions of publishable workspace packages.

Options:
  --proxy=<url>  Use an HTTP proxy such as http://127.0.0.1:10809.
  -h, --help     Print this help text.
''';
