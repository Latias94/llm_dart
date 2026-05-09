import 'dart:io';

import 'package:test/test.dart';

import '../../tool/run_consumer_smoke.dart';

void main() {
  group('parseConsumerSmokeOptions', () {
    test('parses proxy flag', () {
      final options = parseConsumerSmokeOptions([
        '--proxy=http://127.0.0.1:10809',
      ]);

      expect(options.proxy, 'http://127.0.0.1:10809');
      expect(options.showHelp, isFalse);
    });

    test('rejects unknown flags', () {
      expect(
        () => parseConsumerSmokeOptions(['--unknown']),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('consumer pubspec builders', () {
    test('builds Dart consumer pubspec with path overrides', () {
      final paths = ConsumerSmokePaths(
        repoRoot: 'F:/repo/llm_dart',
        packagePaths: {
          for (final packageName in const [
            'llm_dart_ai',
            'llm_dart_anthropic',
            'llm_dart_chat',
            'llm_dart_community',
            'llm_dart_core',
            'llm_dart_google',
            'llm_dart_openai',
            'llm_dart_provider',
            'llm_dart_transport',
          ])
            packageName: 'F:/repo/llm_dart/packages/$packageName',
        },
      );

      final pubspec = buildDartConsumerPubspec(paths);

      expect(pubspec, contains('llm_dart:\n    path: F:/repo/llm_dart'));
      expect(pubspec, contains('dependency_overrides:'));
      expect(pubspec, contains('llm_dart_provider:'));
      expect(
        pubspec,
        contains('path: F:/repo/llm_dart/packages/llm_dart_transport'),
      );
    });

    test('builds Flutter consumer pubspec with Flutter SDK dependency', () {
      final paths = ConsumerSmokePaths(
        repoRoot: 'F:/repo/llm_dart',
        packagePaths: {
          for (final packageName in const [
            'llm_dart_ai',
            'llm_dart_chat',
            'llm_dart_community',
            'llm_dart_flutter',
            'llm_dart_openai',
            'llm_dart_provider',
            'llm_dart_transport',
          ])
            packageName: 'F:/repo/llm_dart/packages/$packageName',
        },
      );

      final pubspec = buildFlutterConsumerPubspec(paths);

      expect(pubspec, contains('flutter:\n    sdk: flutter'));
      expect(pubspec, contains('llm_dart_flutter:'));
      expect(
        pubspec,
        contains('path: F:/repo/llm_dart/packages/llm_dart_flutter'),
      );
      expect(pubspec, contains('dev_dependencies:'));
    });

    test('builds OpenAI-only consumer pubspec without root package', () {
      final paths = ConsumerSmokePaths(
        repoRoot: 'F:/repo/llm_dart',
        packagePaths: {
          for (final packageName in const [
            'llm_dart_openai',
            'llm_dart_provider',
            'llm_dart_transport',
          ])
            packageName: 'F:/repo/llm_dart/packages/$packageName',
        },
      );

      final pubspec = buildOpenAIOnlyConsumerPubspec(paths);

      expect(pubspec, isNot(contains('llm_dart:\n')));
      expect(pubspec, contains('llm_dart_openai:'));
      expect(
        pubspec,
        contains('path: F:/repo/llm_dart/packages/llm_dart_openai'),
      );
      expect(pubspec, contains('dependency_overrides:'));
      expect(pubspec, contains('llm_dart_provider:'));
      expect(pubspec, contains('llm_dart_transport:'));
    });

    test('builds Google-only consumer pubspec without root package', () {
      final paths = ConsumerSmokePaths(
        repoRoot: 'F:/repo/llm_dart',
        packagePaths: {
          for (final packageName in const [
            'llm_dart_google',
            'llm_dart_provider',
            'llm_dart_transport',
          ])
            packageName: 'F:/repo/llm_dart/packages/$packageName',
        },
      );

      final pubspec = buildGoogleOnlyConsumerPubspec(paths);

      expect(pubspec, isNot(contains('llm_dart:\n')));
      expect(pubspec, contains('llm_dart_google:'));
      expect(
        pubspec,
        contains('path: F:/repo/llm_dart/packages/llm_dart_google'),
      );
      expect(pubspec, contains('dependency_overrides:'));
      expect(pubspec, contains('llm_dart_provider:'));
      expect(pubspec, contains('llm_dart_transport:'));
    });

    test('builds Anthropic-only consumer pubspec without root package', () {
      final paths = ConsumerSmokePaths(
        repoRoot: 'F:/repo/llm_dart',
        packagePaths: {
          for (final packageName in const [
            'llm_dart_anthropic',
            'llm_dart_provider',
            'llm_dart_transport',
          ])
            packageName: 'F:/repo/llm_dart/packages/$packageName',
        },
      );

      final pubspec = buildAnthropicOnlyConsumerPubspec(paths);

      expect(pubspec, isNot(contains('llm_dart:\n')));
      expect(pubspec, contains('llm_dart_anthropic:'));
      expect(
        pubspec,
        contains('path: F:/repo/llm_dart/packages/llm_dart_anthropic'),
      );
      expect(pubspec, contains('dependency_overrides:'));
      expect(pubspec, contains('llm_dart_provider:'));
      expect(pubspec, contains('llm_dart_transport:'));
    });

    test('builds Community-only consumer pubspec without root package', () {
      final paths = ConsumerSmokePaths(
        repoRoot: 'F:/repo/llm_dart',
        packagePaths: {
          for (final packageName in const [
            'llm_dart_community',
            'llm_dart_provider',
            'llm_dart_transport',
          ])
            packageName: 'F:/repo/llm_dart/packages/$packageName',
        },
      );

      final pubspec = buildCommunityOnlyConsumerPubspec(paths);

      expect(pubspec, isNot(contains('llm_dart:\n')));
      expect(pubspec, contains('llm_dart_community:'));
      expect(
        pubspec,
        contains('path: F:/repo/llm_dart/packages/llm_dart_community'),
      );
      expect(pubspec, contains('dependency_overrides:'));
      expect(pubspec, contains('llm_dart_provider:'));
      expect(pubspec, contains('llm_dart_transport:'));
    });

    test('builds split package consumer pubspec without root package', () {
      final paths = ConsumerSmokePaths(
        repoRoot: 'F:/repo/llm_dart',
        packagePaths: {
          for (final packageName in const [
            'llm_dart_ai',
            'llm_dart_anthropic',
            'llm_dart_chat',
            'llm_dart_community',
            'llm_dart_google',
            'llm_dart_openai',
            'llm_dart_provider',
            'llm_dart_transport',
          ])
            packageName: 'F:/repo/llm_dart/packages/$packageName',
        },
      );

      final pubspec = buildSplitPackageConsumerPubspec(paths);

      expect(pubspec, isNot(contains('llm_dart:\n')));
      expect(pubspec, contains('llm_dart_ai:'));
      expect(pubspec, contains('llm_dart_openai:'));
      expect(pubspec, contains('llm_dart_anthropic:'));
      expect(pubspec, contains('llm_dart_google:'));
      expect(pubspec, contains('llm_dart_chat:'));
      expect(pubspec, contains('llm_dart_community:'));
    });
  });

  test('buildConsumerSmokeEnvironment returns proxy overrides', () {
    final environment = buildConsumerSmokeEnvironment(
      const ConsumerSmokeOptions(proxy: 'http://127.0.0.1:10809'),
    );

    expect(environment, isNotNull);
    expect(environment!['HTTP_PROXY'], 'http://127.0.0.1:10809');
    expect(environment['HTTPS_PROXY'], 'http://127.0.0.1:10809');
  });

  test('pathForPubspec normalizes Windows separators', () {
    final path = pathForPubspec(Directory(r'F:\repo\llm_dart'));

    expect(path, contains('/'));
    expect(path, isNot(contains(r'\')));
  });

  test('executableForCurrentPlatform resolves Flutter on Windows', () {
    final executable = executableForCurrentPlatform('flutter');

    if (Platform.isWindows) {
      expect(executable, 'flutter.bat');
    } else {
      expect(executable, 'flutter');
    }
  });
}
