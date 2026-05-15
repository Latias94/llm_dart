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

    test('parses published package flags', () {
      final options = parseConsumerSmokeOptions([
        '--published',
        '--version=0.11.0-alpha.1',
      ]);

      expect(options.dependencySource, ConsumerSmokeDependencySource.published);
      expect(options.packageVersion, '0.11.0-alpha.1');
    });

    test('parses direct package_config flag', () {
      final options = parseConsumerSmokeOptions([
        '--direct-package-config',
      ]);

      expect(options.directPackageConfig, isTrue);
      expect(options.dependencySource, ConsumerSmokeDependencySource.localPath);
    });

    test('rejects unknown flags', () {
      expect(
        () => parseConsumerSmokeOptions(['--unknown']),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects version without published mode', () {
      expect(
        () => parseConsumerSmokeOptions(['--version=0.11.0-alpha.1']),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects direct package_config with published mode', () {
      expect(
        () => parseConsumerSmokeOptions([
          '--direct-package-config',
          '--published',
        ]),
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
            'llm_dart_core',
            'llm_dart_elevenlabs',
            'llm_dart_google',
            'llm_dart_ollama',
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

    test('builds Dart consumer pubspec with published package versions', () {
      const paths = ConsumerSmokePaths.published(
        packageVersion: '0.11.0-alpha.1',
      );

      final pubspec = buildDartConsumerPubspec(paths);

      expect(pubspec, contains('llm_dart: 0.11.0-alpha.1'));
      expect(pubspec, contains('llm_dart_provider: 0.11.0-alpha.1'));
      expect(pubspec, isNot(contains('path:')));
      expect(pubspec, isNot(contains('dependency_overrides:')));
    });

    test('builds Flutter consumer pubspec with published package versions', () {
      const paths = ConsumerSmokePaths.published(
        packageVersion: '0.11.0-alpha.1',
      );

      final pubspec = buildFlutterConsumerPubspec(paths);

      expect(pubspec, contains('flutter:\n    sdk: flutter'));
      expect(pubspec, contains('llm_dart_flutter: 0.11.0-alpha.1'));
      expect(pubspec, contains('llm_dart_openai: 0.11.0-alpha.1'));
      expect(pubspec, isNot(contains('path:')));
      expect(pubspec, isNot(contains('dependency_overrides:')));
    });

    test('builds OpenAI-only consumer pubspec without root package', () {
      final paths = ConsumerSmokePaths(
        repoRoot: 'F:/repo/llm_dart',
        packagePaths: {
          for (final packageName in const [
            'llm_dart_ai',
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
            'llm_dart_ai',
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
            'llm_dart_ai',
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

    test('builds Ollama-only consumer pubspec without root package', () {
      final paths = ConsumerSmokePaths(
        repoRoot: 'F:/repo/llm_dart',
        packagePaths: {
          for (final packageName in const [
            'llm_dart_ollama',
            'llm_dart_provider',
            'llm_dart_transport',
          ])
            packageName: 'F:/repo/llm_dart/packages/$packageName',
        },
      );

      final pubspec = buildOllamaOnlyConsumerPubspec(paths);

      expect(pubspec, isNot(contains('llm_dart:\n')));
      expect(pubspec, contains('llm_dart_ollama:'));
      expect(
        pubspec,
        contains('path: F:/repo/llm_dart/packages/llm_dart_ollama'),
      );
      expect(pubspec, contains('dependency_overrides:'));
      expect(pubspec, contains('llm_dart_provider:'));
      expect(pubspec, contains('llm_dart_transport:'));
    });

    test('builds ElevenLabs-only consumer pubspec without root package', () {
      final paths = ConsumerSmokePaths(
        repoRoot: 'F:/repo/llm_dart',
        packagePaths: {
          for (final packageName in const [
            'llm_dart_elevenlabs',
            'llm_dart_provider',
            'llm_dart_transport',
          ])
            packageName: 'F:/repo/llm_dart/packages/$packageName',
        },
      );

      final pubspec = buildElevenLabsOnlyConsumerPubspec(paths);

      expect(pubspec, isNot(contains('llm_dart:\n')));
      expect(pubspec, contains('llm_dart_elevenlabs:'));
      expect(
        pubspec,
        contains('path: F:/repo/llm_dart/packages/llm_dart_elevenlabs'),
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
            'llm_dart_elevenlabs',
            'llm_dart_google',
            'llm_dart_ollama',
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
      expect(pubspec, contains('llm_dart_ollama:'));
      expect(pubspec, contains('llm_dart_elevenlabs:'));
    });
  });

  group('consumer smoke programs', () {
    test('Dart root smoke uses modern prompt and avoids legacy root API', () {
      expect(
        dartConsumerSmokeProgram,
        isNot(contains("package:llm_dart/legacy.dart")),
      );
      expect(dartConsumerSmokeProgram, isNot(contains('LLMBuilder')));
      expect(dartConsumerSmokeProgram, isNot(contains('PromptMessage')));
      expect(dartConsumerSmokeProgram, contains('ModelMessage'));
      expect(dartConsumerSmokeProgram, contains('SystemModelMessage'));
      expect(dartConsumerSmokeProgram, contains('UserModelMessage'));
      expect(
        dartConsumerSmokeProgram,
        contains('chatInput.message.role != ai.ModelMessageRole.user'),
      );
      expect(
        dartConsumerSmokeProgram,
        isNot(contains('chatInput.message.role != provider.PromptRole.user')),
      );
    });
  });

  group('resolveConsumerSmokePaths', () {
    test('defaults published mode to the root pubspec version', () async {
      final directory = await Directory.systemTemp.createTemp(
        'llm_dart_consumer_smoke_version_',
      );
      addTearDown(() async {
        if (directory.existsSync()) {
          await directory.delete(recursive: true);
        }
      });

      await File.fromUri(directory.uri.resolve('pubspec.yaml')).writeAsString(
        '''
name: llm_dart
version: 0.11.0-alpha.1
''',
      );

      final paths = await resolveConsumerSmokePaths(
        repoRoot: directory,
        options: const ConsumerSmokeOptions(
          dependencySource: ConsumerSmokeDependencySource.published,
        ),
      );

      expect(paths.usesPublishedPackages, isTrue);
      expect(paths.packageVersion, '0.11.0-alpha.1');
    });
  });

  test('buildConsumerSmokeEnvironment returns proxy overrides', () {
    final environment = buildConsumerSmokeEnvironment(
      const ConsumerSmokeOptions(proxy: 'http://127.0.0.1:10809'),
    );

    expect(environment, isNotNull);
    expect(environment['HTTP_PROXY'], 'http://127.0.0.1:10809');
    expect(environment['HTTPS_PROXY'], 'http://127.0.0.1:10809');
    expect(environment['DART_SUPPRESS_ANALYTICS'], 'true');
    expect(environment['FLUTTER_SUPPRESS_ANALYTICS'], 'true');
  });

  test('buildConsumerSmokeEnvironment suppresses analytics by default', () {
    final environment = buildConsumerSmokeEnvironment(
      const ConsumerSmokeOptions(),
    );

    expect(environment['DART_SUPPRESS_ANALYTICS'], 'true');
    expect(environment['FLUTTER_SUPPRESS_ANALYTICS'], 'true');
    expect(environment, isNot(containsPair('HTTP_PROXY', anything)));
  });

  test('runConsumerSmokeCommand terminates timed-out commands', () async {
    final directory = await Directory.systemTemp.createTemp(
      'llm_dart_consumer_smoke_timeout_',
    );
    addTearDown(() async {
      if (directory.existsSync()) {
        await directory.delete(recursive: true);
      }
    });

    final slowScript = File.fromUri(directory.uri.resolve('slow.dart'));
    await slowScript.writeAsString('''
import 'dart:async';

Future<void> main() {
  return Future<void>.delayed(const Duration(seconds: 30));
}
''');

    final result = await runConsumerSmokeCommand(
      ConsumerSmokeCommand(
        name: 'slow command',
        executable: Platform.resolvedExecutable,
        arguments: [slowScript.path],
        workingDirectory: directory,
      ),
      environment: null,
      commandTimeout: const Duration(milliseconds: 100),
      terminationTimeout: const Duration(seconds: 2),
    );

    expect(result.exitCode, 124);
  });

  test('buildDirectPackageConfigConsumerSmokeCommands uses current SDK',
      () async {
    final repoRoot = await Directory.systemTemp.createTemp(
      'llm_dart_direct_consumer_repo_',
    );
    addTearDown(() async {
      if (repoRoot.existsSync()) {
        await repoRoot.delete(recursive: true);
      }
    });

    final packageConfig = File.fromUri(
      repoRoot.uri.resolve('.dart_tool/package_config.json'),
    );
    await packageConfig.parent.create(recursive: true);
    await packageConfig.writeAsString('{"configVersion":2,"packages":[]}');

    final consumers = [
      for (final name in const [
        'dart',
        'openai',
        'google',
        'anthropic',
        'ollama',
        'elevenlabs',
        'split',
      ])
        Directory.fromUri(repoRoot.uri.resolve('$name/'))..createSync(),
    ];

    final commands = buildDirectPackageConfigConsumerSmokeCommands(
      repoRoot: repoRoot,
      dartConsumer: consumers[0],
      openAIOnlyConsumer: consumers[1],
      googleOnlyConsumer: consumers[2],
      anthropicOnlyConsumer: consumers[3],
      ollamaOnlyConsumer: consumers[4],
      elevenLabsOnlyConsumer: consumers[5],
      splitPackageConsumer: consumers[6],
    );

    expect(commands, hasLength(7));
    expect(commands.first.executable, Platform.resolvedExecutable);
    expect(commands.first.arguments.last, 'bin/smoke.dart');
    expect(commands.first.arguments.first, contains('package_config.json'));
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

  test('executableForCurrentPlatform resolves Dart to the current runtime', () {
    final executable = executableForCurrentPlatform('dart');

    if (Platform.isWindows) {
      expect(executable, Platform.resolvedExecutable);
    } else {
      expect(executable, 'dart');
    }
  });
}
