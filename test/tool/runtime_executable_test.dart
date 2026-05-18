import 'dart:io';

import 'package:test/test.dart';

import '../../tool/runtime_executable.dart';

void main() {
  group('resolveToolArguments', () {
    test('adds suppress analytics to Dart tool commands', () {
      expect(
        resolveToolArguments('dart', const ['test']),
        ['--suppress-analytics', 'test'],
      );
    });

    test('runs direct Dart scripts through dart run', () {
      expect(
        resolveToolArguments('dart', const ['tool/example.dart']),
        ['--suppress-analytics', 'run', 'tool/example.dart'],
      );
    });

    test('does not add duplicate suppress analytics arguments', () {
      expect(
        resolveToolArguments(
          'dart',
          const ['--suppress-analytics', 'test'],
        ),
        ['--suppress-analytics', 'test'],
      );
    });

    test('leaves Flutter commands unchanged', () {
      expect(
        resolveToolArguments('flutter', const ['test']),
        ['test'],
      );
    });

    test('leaves VM-only package config invocations unchanged', () {
      expect(
        resolveToolArguments(
          Platform.resolvedExecutable,
          const ['--packages=.dart_tool/package_config.json', 'bin/smoke.dart'],
        ),
        ['--packages=.dart_tool/package_config.json', 'bin/smoke.dart'],
      );
    });
  });

  group('buildToolProcessEnvironment', () {
    test('suppresses Dart and Flutter analytics by default', () {
      final environment = buildToolProcessEnvironment();

      expect(environment['DART_SUPPRESS_ANALYTICS'], 'true');
      expect(environment['FLUTTER_SUPPRESS_ANALYTICS'], 'true');
    });

    test('keeps caller overrides', () {
      final environment = buildToolProcessEnvironment({
        'HTTP_PROXY': 'http://127.0.0.1:10809',
      });

      expect(environment['HTTP_PROXY'], 'http://127.0.0.1:10809');
      expect(environment['DART_SUPPRESS_ANALYTICS'], 'true');
    });
  });
}
