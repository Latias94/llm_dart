import 'dart:io';

import 'package:test/test.dart';

import '../../tool/check_pub_version_availability.dart';

void main() {
  group('parsePubVersionAvailabilityOptions', () {
    test('parses proxy flag', () {
      final options = parsePubVersionAvailabilityOptions([
        '--proxy=http://127.0.0.1:10809',
      ]);

      expect(options.proxy, 'http://127.0.0.1:10809');
      expect(options.showHelp, isFalse);
    });

    test('parses help flag', () {
      final options = parsePubVersionAvailabilityOptions(['--help']);

      expect(options.showHelp, isTrue);
    });

    test('rejects unknown flags', () {
      expect(
        () => parsePubVersionAvailabilityOptions(['--unknown']),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('buildPubProxyRule', () {
    test('builds an HttpClient proxy rule', () {
      expect(
        buildPubProxyRule('http://127.0.0.1:10809'),
        'PROXY 127.0.0.1:10809',
      );
    });
  });

  group('buildPubVersionAvailabilityNetworkFailureMessage', () {
    test('summarizes package and retry action', () {
      final message = buildPubVersionAvailabilityNetworkFailureMessage(
        packageName: 'llm_dart',
        error: const SocketException('connection reset'),
      );

      expect(message, contains('llm_dart'));
      expect(message, contains('SocketException'));
      expect(message, contains('--proxy=http://127.0.0.1:10809'));
      expect(message, contains('pub.dev is reachable'));
    });
  });

  group('parsePubPackageApiResult', () {
    test('extracts latest and published versions', () {
      final result = parsePubPackageApiResult(
        packageName: 'llm_dart',
        responseBody: '''
{
  "name": "llm_dart",
  "latest": {"version": "0.10.7"},
  "versions": [
    {"version": "0.10.6"},
    {"version": "0.10.7"}
  ]
}
''',
      );

      expect(result.packageExists, isTrue);
      expect(result.latestVersion, '0.10.7');
      expect(result.containsVersion('0.10.7'), isTrue);
      expect(result.containsVersion('0.11.0-alpha.1'), isFalse);
    });
  });

  group('readPackageVersion', () {
    test('reads a package pubspec version', () async {
      final directory = await Directory.systemTemp.createTemp(
        'llm_dart_pub_version_',
      );
      addTearDown(() async {
        if (directory.existsSync()) {
          await directory.delete(recursive: true);
        }
      });

      final packageDirectory =
          Directory.fromUri(directory.uri.resolve('packages/example_pkg/'));
      await packageDirectory.create(recursive: true);
      await File.fromUri(packageDirectory.uri.resolve('pubspec.yaml'))
          .writeAsString(
        '''
name: example_pkg
version: 0.11.0-alpha.1
''',
      );

      expect(
        await readPackageVersion(
          repoRoot: directory,
          packageName: 'example_pkg',
        ),
        '0.11.0-alpha.1',
      );
    });
  });

  group('buildPubVersionAvailabilityReport', () {
    test('summarizes available and blocked packages', () {
      final report = buildPubVersionAvailabilityReport(
        const [
          PubVersionAvailability(
            packageName: 'llm_dart_provider',
            targetVersion: '0.11.0-alpha.1',
            packageExists: false,
            latestVersion: null,
            targetVersionExists: false,
          ),
          PubVersionAvailability(
            packageName: 'llm_dart',
            targetVersion: '0.11.0-alpha.1',
            packageExists: true,
            latestVersion: '0.10.7',
            targetVersionExists: false,
          ),
          PubVersionAvailability(
            packageName: 'example_blocked',
            targetVersion: '1.0.0',
            packageExists: true,
            latestVersion: '1.0.0',
            targetVersionExists: true,
          ),
        ],
      );

      expect(report, contains('available-new-package'));
      expect(report, contains('available-new-version'));
      expect(report, contains('blocked'));
      expect(report, contains('Result: failed'));
    });
  });
}
