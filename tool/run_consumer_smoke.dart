import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'runtime_executable.dart';

enum ConsumerSmokeDependencySource {
  localPath,
  published,
}

const consumerSmokeCommandTimeout = Duration(minutes: 5);
const consumerSmokeTerminationTimeout = Duration(seconds: 5);

final class ConsumerSmokeOptions {
  final String? proxy;
  final bool showHelp;
  final bool directPackageConfig;
  final ConsumerSmokeDependencySource dependencySource;
  final String? packageVersion;

  const ConsumerSmokeOptions({
    this.proxy,
    this.showHelp = false,
    this.directPackageConfig = false,
    this.dependencySource = ConsumerSmokeDependencySource.localPath,
    this.packageVersion,
  });
}

final class ConsumerSmokeCommand {
  final String name;
  final String executable;
  final List<String> arguments;
  final Directory workingDirectory;

  const ConsumerSmokeCommand({
    required this.name,
    required this.executable,
    required this.arguments,
    required this.workingDirectory,
  });

  String get commandText => [
        executable,
        ...arguments,
      ].map(quoteCommandPart).join(' ');
}

final class ConsumerSmokeCommandResult {
  final ConsumerSmokeCommand command;
  final int exitCode;
  final Duration elapsed;

  const ConsumerSmokeCommandResult({
    required this.command,
    required this.exitCode,
    required this.elapsed,
  });

  bool get passed => exitCode == 0;
}

final class ConsumerSmokeRunResult {
  final List<ConsumerSmokeCommandResult> commands;

  const ConsumerSmokeRunResult(this.commands);

  bool get passed => commands.every((command) => command.passed);
}

final class ConsumerSmokePaths {
  final String repoRoot;
  final Map<String, String> packagePaths;
  final ConsumerSmokeDependencySource source;
  final String packageVersion;

  const ConsumerSmokePaths({
    required this.repoRoot,
    required this.packagePaths,
    this.source = ConsumerSmokeDependencySource.localPath,
    this.packageVersion = '',
  });

  const ConsumerSmokePaths.published({
    required this.packageVersion,
  })  : repoRoot = '',
        packagePaths = const {},
        source = ConsumerSmokeDependencySource.published;

  bool get usesPublishedPackages =>
      source == ConsumerSmokeDependencySource.published;
}

Future<void> main(List<String> arguments) async {
  late final ConsumerSmokeOptions options;
  try {
    options = parseConsumerSmokeOptions(arguments);
  } on FormatException catch (error) {
    stderr.writeln('consumer smoke argument error: ${error.message}');
    stderr.writeln('');
    stderr.write(consumerSmokeUsage);
    exitCode = 64;
    return;
  }

  if (options.showHelp) {
    stdout.write(consumerSmokeUsage);
    return;
  }

  final result = await runConsumerSmoke(
    repoRoot: Directory.current.absolute,
    options: options,
  );

  if (!result.passed) {
    final failed = result.commands.firstWhere((command) => !command.passed);
    stderr.writeln('');
    stderr.writeln('consumer smoke failed at: ${failed.command.name}');
    exitCode = failed.exitCode == 0 ? 1 : failed.exitCode;
  }
}

ConsumerSmokeOptions parseConsumerSmokeOptions(List<String> arguments) {
  var showHelp = false;
  String? proxy;
  var dependencySource = ConsumerSmokeDependencySource.localPath;
  String? packageVersion;
  var directPackageConfig = false;

  for (final argument in arguments) {
    switch (argument) {
      case '-h' || '--help':
        showHelp = true;
      case '--direct-package-config':
        directPackageConfig = true;
      case '--published':
        dependencySource = ConsumerSmokeDependencySource.published;
      default:
        if (argument.startsWith('--proxy=')) {
          proxy = _readFlagValue(argument, '--proxy=');
          continue;
        }
        if (argument.startsWith('--version=')) {
          packageVersion = _readFlagValue(argument, '--version=');
          continue;
        }
        throw FormatException('unknown option `$argument`');
    }
  }

  if (packageVersion != null &&
      dependencySource != ConsumerSmokeDependencySource.published) {
    throw const FormatException('`--version` requires `--published`.');
  }
  if (directPackageConfig &&
      dependencySource == ConsumerSmokeDependencySource.published) {
    throw const FormatException(
      '`--direct-package-config` uses the local workspace package_config and '
      'cannot be combined with `--published`.',
    );
  }

  return ConsumerSmokeOptions(
    proxy: proxy,
    showHelp: showHelp,
    directPackageConfig: directPackageConfig,
    dependencySource: dependencySource,
    packageVersion: packageVersion,
  );
}

Future<ConsumerSmokeRunResult> runConsumerSmoke({
  required Directory repoRoot,
  required ConsumerSmokeOptions options,
}) async {
  final tempRoot = await Directory.systemTemp.createTemp(
    'llm_dart_consumer_smoke_',
  );

  stdout.writeln('consumer smoke validation');
  stdout.writeln('repository: ${repoRoot.path}');
  stdout.writeln('workspace: ${tempRoot.path}');
  if (options.proxy != null) {
    stdout.writeln('proxy: ${options.proxy}');
  }

  try {
    final paths = await resolveConsumerSmokePaths(
      repoRoot: repoRoot,
      options: options,
    );
    stdout.writeln(
      paths.usesPublishedPackages
          ? 'dependency source: pub.dev ${paths.packageVersion}'
          : 'dependency source: local path workspace',
    );
    if (options.directPackageConfig) {
      stdout.writeln(
        'consumer mode: direct package_config import/runtime smoke',
      );
    }

    final dartConsumer = Directory.fromUri(tempRoot.uri.resolve(
      'dart_consumer/',
    ));
    final openAIOnlyConsumer = Directory.fromUri(tempRoot.uri.resolve(
      'openai_only_consumer/',
    ));
    final googleOnlyConsumer = Directory.fromUri(tempRoot.uri.resolve(
      'google_only_consumer/',
    ));
    final anthropicOnlyConsumer = Directory.fromUri(tempRoot.uri.resolve(
      'anthropic_only_consumer/',
    ));
    final ollamaOnlyConsumer = Directory.fromUri(tempRoot.uri.resolve(
      'ollama_only_consumer/',
    ));
    final elevenLabsOnlyConsumer = Directory.fromUri(tempRoot.uri.resolve(
      'elevenlabs_only_consumer/',
    ));
    final splitPackageConsumer = Directory.fromUri(tempRoot.uri.resolve(
      'split_package_consumer/',
    ));
    final flutterConsumer = Directory.fromUri(tempRoot.uri.resolve(
      'flutter_consumer/',
    ));

    await writeDartConsumer(
      paths: paths,
      consumerDirectory: dartConsumer,
    );
    await writeOpenAIOnlyConsumer(
      paths: paths,
      consumerDirectory: openAIOnlyConsumer,
    );
    await writeGoogleOnlyConsumer(
      paths: paths,
      consumerDirectory: googleOnlyConsumer,
    );
    await writeAnthropicOnlyConsumer(
      paths: paths,
      consumerDirectory: anthropicOnlyConsumer,
    );
    await writeOllamaOnlyConsumer(
      paths: paths,
      consumerDirectory: ollamaOnlyConsumer,
    );
    await writeElevenLabsOnlyConsumer(
      paths: paths,
      consumerDirectory: elevenLabsOnlyConsumer,
    );
    await writeSplitPackageConsumer(
      paths: paths,
      consumerDirectory: splitPackageConsumer,
    );
    await writeFlutterConsumer(
      paths: paths,
      consumerDirectory: flutterConsumer,
    );

    final commands = options.directPackageConfig
        ? buildDirectPackageConfigConsumerSmokeCommands(
            repoRoot: repoRoot,
            dartConsumer: dartConsumer,
            openAIOnlyConsumer: openAIOnlyConsumer,
            googleOnlyConsumer: googleOnlyConsumer,
            anthropicOnlyConsumer: anthropicOnlyConsumer,
            ollamaOnlyConsumer: ollamaOnlyConsumer,
            elevenLabsOnlyConsumer: elevenLabsOnlyConsumer,
            splitPackageConsumer: splitPackageConsumer,
          )
        : buildConsumerSmokeCommands(
            dartConsumer: dartConsumer,
            openAIOnlyConsumer: openAIOnlyConsumer,
            googleOnlyConsumer: googleOnlyConsumer,
            anthropicOnlyConsumer: anthropicOnlyConsumer,
            ollamaOnlyConsumer: ollamaOnlyConsumer,
            elevenLabsOnlyConsumer: elevenLabsOnlyConsumer,
            splitPackageConsumer: splitPackageConsumer,
            flutterConsumer: flutterConsumer,
          );
    final environment = buildConsumerSmokeEnvironment(options);
    final results = <ConsumerSmokeCommandResult>[];

    for (var index = 0; index < commands.length; index++) {
      final command = commands[index];
      stdout.writeln('');
      stdout.writeln('==> ${index + 1}/${commands.length}: ${command.name}');
      stdout.writeln(r'$ ' + command.commandText);

      final result = await runConsumerSmokeCommand(
        command,
        environment: environment,
      );
      results.add(result);

      stdout.writeln(
        result.passed
            ? 'passed in ${formatDuration(result.elapsed)}'
            : 'failed with exit code ${result.exitCode} '
                'after ${formatDuration(result.elapsed)}',
      );

      if (!result.passed) {
        return ConsumerSmokeRunResult(List.unmodifiable(results));
      }
    }

    stdout.writeln('');
    stdout.writeln('consumer smoke validation passed.');
    return ConsumerSmokeRunResult(List.unmodifiable(results));
  } finally {
    if (tempRoot.existsSync()) {
      await tempRoot.delete(recursive: true);
    }
  }
}

List<ConsumerSmokeCommand> buildConsumerSmokeCommands({
  required Directory dartConsumer,
  required Directory openAIOnlyConsumer,
  required Directory googleOnlyConsumer,
  required Directory anthropicOnlyConsumer,
  required Directory ollamaOnlyConsumer,
  required Directory elevenLabsOnlyConsumer,
  required Directory splitPackageConsumer,
  required Directory flutterConsumer,
}) {
  return [
    ConsumerSmokeCommand(
      name: 'Dart consumer pub get',
      executable: 'dart',
      arguments: const ['pub', 'get'],
      workingDirectory: dartConsumer,
    ),
    ConsumerSmokeCommand(
      name: 'Dart consumer analysis',
      executable: 'dart',
      arguments: const ['analyze'],
      workingDirectory: dartConsumer,
    ),
    ConsumerSmokeCommand(
      name: 'Dart consumer no-key run',
      executable: 'dart',
      arguments: const ['run', 'bin/smoke.dart'],
      workingDirectory: dartConsumer,
    ),
    ConsumerSmokeCommand(
      name: 'OpenAI-only consumer pub get',
      executable: 'dart',
      arguments: const ['pub', 'get'],
      workingDirectory: openAIOnlyConsumer,
    ),
    ConsumerSmokeCommand(
      name: 'OpenAI-only consumer analysis',
      executable: 'dart',
      arguments: const ['analyze'],
      workingDirectory: openAIOnlyConsumer,
    ),
    ConsumerSmokeCommand(
      name: 'OpenAI-only consumer no-key run',
      executable: 'dart',
      arguments: const ['run', 'bin/smoke.dart'],
      workingDirectory: openAIOnlyConsumer,
    ),
    ConsumerSmokeCommand(
      name: 'Google-only consumer pub get',
      executable: 'dart',
      arguments: const ['pub', 'get'],
      workingDirectory: googleOnlyConsumer,
    ),
    ConsumerSmokeCommand(
      name: 'Google-only consumer analysis',
      executable: 'dart',
      arguments: const ['analyze'],
      workingDirectory: googleOnlyConsumer,
    ),
    ConsumerSmokeCommand(
      name: 'Google-only consumer no-key run',
      executable: 'dart',
      arguments: const ['run', 'bin/smoke.dart'],
      workingDirectory: googleOnlyConsumer,
    ),
    ConsumerSmokeCommand(
      name: 'Anthropic-only consumer pub get',
      executable: 'dart',
      arguments: const ['pub', 'get'],
      workingDirectory: anthropicOnlyConsumer,
    ),
    ConsumerSmokeCommand(
      name: 'Anthropic-only consumer analysis',
      executable: 'dart',
      arguments: const ['analyze'],
      workingDirectory: anthropicOnlyConsumer,
    ),
    ConsumerSmokeCommand(
      name: 'Anthropic-only consumer no-key run',
      executable: 'dart',
      arguments: const ['run', 'bin/smoke.dart'],
      workingDirectory: anthropicOnlyConsumer,
    ),
    ConsumerSmokeCommand(
      name: 'Ollama-only consumer pub get',
      executable: 'dart',
      arguments: const ['pub', 'get'],
      workingDirectory: ollamaOnlyConsumer,
    ),
    ConsumerSmokeCommand(
      name: 'Ollama-only consumer analysis',
      executable: 'dart',
      arguments: const ['analyze'],
      workingDirectory: ollamaOnlyConsumer,
    ),
    ConsumerSmokeCommand(
      name: 'Ollama-only consumer no-key run',
      executable: 'dart',
      arguments: const ['run', 'bin/smoke.dart'],
      workingDirectory: ollamaOnlyConsumer,
    ),
    ConsumerSmokeCommand(
      name: 'ElevenLabs-only consumer pub get',
      executable: 'dart',
      arguments: const ['pub', 'get'],
      workingDirectory: elevenLabsOnlyConsumer,
    ),
    ConsumerSmokeCommand(
      name: 'ElevenLabs-only consumer analysis',
      executable: 'dart',
      arguments: const ['analyze'],
      workingDirectory: elevenLabsOnlyConsumer,
    ),
    ConsumerSmokeCommand(
      name: 'ElevenLabs-only consumer no-key run',
      executable: 'dart',
      arguments: const ['run', 'bin/smoke.dart'],
      workingDirectory: elevenLabsOnlyConsumer,
    ),
    ConsumerSmokeCommand(
      name: 'Split package consumer pub get',
      executable: 'dart',
      arguments: const ['pub', 'get'],
      workingDirectory: splitPackageConsumer,
    ),
    ConsumerSmokeCommand(
      name: 'Split package consumer analysis',
      executable: 'dart',
      arguments: const ['analyze'],
      workingDirectory: splitPackageConsumer,
    ),
    ConsumerSmokeCommand(
      name: 'Split package consumer no-key run',
      executable: 'dart',
      arguments: const ['run', 'bin/smoke.dart'],
      workingDirectory: splitPackageConsumer,
    ),
    ConsumerSmokeCommand(
      name: 'Flutter consumer pub get',
      executable: 'flutter',
      arguments: const ['pub', 'get'],
      workingDirectory: flutterConsumer,
    ),
    ConsumerSmokeCommand(
      name: 'Flutter consumer analysis',
      executable: 'flutter',
      arguments: const ['analyze'],
      workingDirectory: flutterConsumer,
    ),
    ConsumerSmokeCommand(
      name: 'Flutter consumer tests',
      executable: 'flutter',
      arguments: const ['test'],
      workingDirectory: flutterConsumer,
    ),
  ];
}

Future<ConsumerSmokeCommandResult> runConsumerSmokeCommand(
  ConsumerSmokeCommand command, {
  required Map<String, String>? environment,
  Duration commandTimeout = consumerSmokeCommandTimeout,
  Duration terminationTimeout = consumerSmokeTerminationTimeout,
}) async {
  final stopwatch = Stopwatch()..start();
  final process = await Process.start(
    executableForCurrentPlatform(command.executable),
    command.arguments,
    workingDirectory: command.workingDirectory.path,
    environment: environment,
  );

  final stdoutDone = pipeProcessOutput(process.stdout, stdout);
  final stderrDone = pipeProcessOutput(process.stderr, stderr);
  try {
    final processExitCode = await process.exitCode.timeout(
      commandTimeout,
    );
    await Future.wait([stdoutDone, stderrDone]);
    stopwatch.stop();

    return ConsumerSmokeCommandResult(
      command: command,
      exitCode: processExitCode,
      elapsed: stopwatch.elapsed,
    );
  } on TimeoutException {
    process.kill();
    await process.exitCode.timeout(
      terminationTimeout,
      onTimeout: () => -1,
    );
    await Future.wait([stdoutDone, stderrDone]).timeout(
      terminationTimeout,
      onTimeout: () => const <void>[],
    );
    stopwatch.stop();

    return ConsumerSmokeCommandResult(
      command: command,
      exitCode: 124,
      elapsed: stopwatch.elapsed,
    );
  }
}

List<ConsumerSmokeCommand> buildDirectPackageConfigConsumerSmokeCommands({
  required Directory repoRoot,
  required Directory dartConsumer,
  required Directory openAIOnlyConsumer,
  required Directory googleOnlyConsumer,
  required Directory anthropicOnlyConsumer,
  required Directory ollamaOnlyConsumer,
  required Directory elevenLabsOnlyConsumer,
  required Directory splitPackageConsumer,
}) {
  final packageConfig = File.fromUri(
    repoRoot.uri.resolve('.dart_tool/package_config.json'),
  );
  if (!packageConfig.existsSync()) {
    throw StateError(
      'direct package_config consumer smoke requires '
      '${packageConfig.path}. Run dependency bootstrap first.',
    );
  }
  final packageConfigPath = pathForPubspec(packageConfig);

  return [
    directPackageConfigConsumerSmokeCommand(
      name: 'Dart consumer direct run',
      consumerDirectory: dartConsumer,
      packageConfigPath: packageConfigPath,
    ),
    directPackageConfigConsumerSmokeCommand(
      name: 'OpenAI-only consumer direct run',
      consumerDirectory: openAIOnlyConsumer,
      packageConfigPath: packageConfigPath,
    ),
    directPackageConfigConsumerSmokeCommand(
      name: 'Google-only consumer direct run',
      consumerDirectory: googleOnlyConsumer,
      packageConfigPath: packageConfigPath,
    ),
    directPackageConfigConsumerSmokeCommand(
      name: 'Anthropic-only consumer direct run',
      consumerDirectory: anthropicOnlyConsumer,
      packageConfigPath: packageConfigPath,
    ),
    directPackageConfigConsumerSmokeCommand(
      name: 'Ollama-only consumer direct run',
      consumerDirectory: ollamaOnlyConsumer,
      packageConfigPath: packageConfigPath,
    ),
    directPackageConfigConsumerSmokeCommand(
      name: 'ElevenLabs-only consumer direct run',
      consumerDirectory: elevenLabsOnlyConsumer,
      packageConfigPath: packageConfigPath,
    ),
    directPackageConfigConsumerSmokeCommand(
      name: 'Split package consumer direct run',
      consumerDirectory: splitPackageConsumer,
      packageConfigPath: packageConfigPath,
    ),
  ];
}

ConsumerSmokeCommand directPackageConfigConsumerSmokeCommand({
  required String name,
  required Directory consumerDirectory,
  required String packageConfigPath,
}) {
  return ConsumerSmokeCommand(
    name: name,
    executable: Platform.resolvedExecutable,
    arguments: [
      '--packages=$packageConfigPath',
      'bin/smoke.dart',
    ],
    workingDirectory: consumerDirectory,
  );
}

Future<void> writeDartConsumer({
  required ConsumerSmokePaths paths,
  required Directory consumerDirectory,
}) async {
  await writeTextFile(
    File.fromUri(consumerDirectory.uri.resolve('pubspec.yaml')),
    buildDartConsumerPubspec(paths),
  );
  await writeTextFile(
    File.fromUri(consumerDirectory.uri.resolve('bin/smoke.dart')),
    dartConsumerSmokeProgram,
  );
}

Future<void> writeOpenAIOnlyConsumer({
  required ConsumerSmokePaths paths,
  required Directory consumerDirectory,
}) async {
  await writeTextFile(
    File.fromUri(consumerDirectory.uri.resolve('pubspec.yaml')),
    buildOpenAIOnlyConsumerPubspec(paths),
  );
  await writeTextFile(
    File.fromUri(consumerDirectory.uri.resolve('bin/smoke.dart')),
    openAIOnlyConsumerSmokeProgram,
  );
}

Future<void> writeGoogleOnlyConsumer({
  required ConsumerSmokePaths paths,
  required Directory consumerDirectory,
}) async {
  await writeTextFile(
    File.fromUri(consumerDirectory.uri.resolve('pubspec.yaml')),
    buildGoogleOnlyConsumerPubspec(paths),
  );
  await writeTextFile(
    File.fromUri(consumerDirectory.uri.resolve('bin/smoke.dart')),
    googleOnlyConsumerSmokeProgram,
  );
}

Future<void> writeAnthropicOnlyConsumer({
  required ConsumerSmokePaths paths,
  required Directory consumerDirectory,
}) async {
  await writeTextFile(
    File.fromUri(consumerDirectory.uri.resolve('pubspec.yaml')),
    buildAnthropicOnlyConsumerPubspec(paths),
  );
  await writeTextFile(
    File.fromUri(consumerDirectory.uri.resolve('bin/smoke.dart')),
    anthropicOnlyConsumerSmokeProgram,
  );
}

Future<void> writeOllamaOnlyConsumer({
  required ConsumerSmokePaths paths,
  required Directory consumerDirectory,
}) async {
  await writeTextFile(
    File.fromUri(consumerDirectory.uri.resolve('pubspec.yaml')),
    buildOllamaOnlyConsumerPubspec(paths),
  );
  await writeTextFile(
    File.fromUri(consumerDirectory.uri.resolve('bin/smoke.dart')),
    ollamaOnlyConsumerSmokeProgram,
  );
}

Future<void> writeElevenLabsOnlyConsumer({
  required ConsumerSmokePaths paths,
  required Directory consumerDirectory,
}) async {
  await writeTextFile(
    File.fromUri(consumerDirectory.uri.resolve('pubspec.yaml')),
    buildElevenLabsOnlyConsumerPubspec(paths),
  );
  await writeTextFile(
    File.fromUri(consumerDirectory.uri.resolve('bin/smoke.dart')),
    elevenLabsOnlyConsumerSmokeProgram,
  );
}

Future<void> writeSplitPackageConsumer({
  required ConsumerSmokePaths paths,
  required Directory consumerDirectory,
}) async {
  await writeTextFile(
    File.fromUri(consumerDirectory.uri.resolve('pubspec.yaml')),
    buildSplitPackageConsumerPubspec(paths),
  );
  await writeTextFile(
    File.fromUri(consumerDirectory.uri.resolve('bin/smoke.dart')),
    splitPackageConsumerSmokeProgram,
  );
}

Future<void> writeFlutterConsumer({
  required ConsumerSmokePaths paths,
  required Directory consumerDirectory,
}) async {
  await writeTextFile(
    File.fromUri(consumerDirectory.uri.resolve('pubspec.yaml')),
    buildFlutterConsumerPubspec(paths),
  );
  await writeTextFile(
    File.fromUri(consumerDirectory.uri.resolve('test/import_smoke_test.dart')),
    flutterConsumerSmokeTest,
  );
}

ConsumerSmokePaths buildConsumerSmokePaths(Directory repoRoot) {
  return ConsumerSmokePaths(
    repoRoot: pathForPubspec(repoRoot),
    packagePaths: {
      for (final packageName in const [
        'llm_dart_ai',
        'llm_dart_anthropic',
        'llm_dart_chat',
        'llm_dart_core',
        'llm_dart_elevenlabs',
        'llm_dart_flutter',
        'llm_dart_google',
        'llm_dart_ollama',
        'llm_dart_openai',
        'llm_dart_provider',
        'llm_dart_transport',
      ])
        packageName: pathForPubspec(
          Directory.fromUri(repoRoot.uri.resolve('packages/$packageName/')),
        ),
    },
  );
}

Future<ConsumerSmokePaths> resolveConsumerSmokePaths({
  required Directory repoRoot,
  required ConsumerSmokeOptions options,
}) async {
  switch (options.dependencySource) {
    case ConsumerSmokeDependencySource.localPath:
      return buildConsumerSmokePaths(repoRoot);
    case ConsumerSmokeDependencySource.published:
      return ConsumerSmokePaths.published(
        packageVersion:
            options.packageVersion ?? await readRootPackageVersion(repoRoot),
      );
  }
}

Future<String> readRootPackageVersion(Directory repoRoot) async {
  final pubspec = File.fromUri(repoRoot.uri.resolve('pubspec.yaml'));
  if (!pubspec.existsSync()) {
    throw StateError('pubspec.yaml not found at ${pubspec.path}');
  }

  final lines = await pubspec.readAsLines();
  for (final rawLine in lines) {
    final line = rawLine.trim();
    if (line.startsWith('version:')) {
      final version = line.substring('version:'.length).trim();
      if (version.isEmpty) {
        break;
      }
      return version;
    }
  }

  throw StateError('pubspec.yaml is missing a top-level version.');
}

String buildDartConsumerPubspec(ConsumerSmokePaths paths) {
  return '''
name: llm_dart_dart_consumer_smoke
publish_to: none

environment:
  sdk: '>=3.5.0 <4.0.0'

dependencies:
${_dependencyEntries([
        'llm_dart',
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
      ], paths)}${_dependencyOverrides([
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
      ], paths)}
''';
}

String buildOpenAIOnlyConsumerPubspec(ConsumerSmokePaths paths) {
  return '''
name: llm_dart_openai_only_consumer_smoke
publish_to: none

environment:
  sdk: '>=3.5.0 <4.0.0'

dependencies:
${_dependencyEntries(['llm_dart_openai'], paths)}${_dependencyOverrides([
        'llm_dart_ai',
        'llm_dart_provider',
        'llm_dart_transport',
      ], paths)}
''';
}

String buildGoogleOnlyConsumerPubspec(ConsumerSmokePaths paths) {
  return '''
name: llm_dart_google_only_consumer_smoke
publish_to: none

environment:
  sdk: '>=3.5.0 <4.0.0'

dependencies:
${_dependencyEntries(['llm_dart_google'], paths)}${_dependencyOverrides([
        'llm_dart_ai',
        'llm_dart_provider',
        'llm_dart_transport',
      ], paths)}
''';
}

String buildAnthropicOnlyConsumerPubspec(ConsumerSmokePaths paths) {
  return '''
name: llm_dart_anthropic_only_consumer_smoke
publish_to: none

environment:
  sdk: '>=3.5.0 <4.0.0'

dependencies:
${_dependencyEntries(['llm_dart_anthropic'], paths)}${_dependencyOverrides([
        'llm_dart_ai',
        'llm_dart_provider',
        'llm_dart_transport',
      ], paths)}
''';
}

String buildOllamaOnlyConsumerPubspec(ConsumerSmokePaths paths) {
  return '''
name: llm_dart_ollama_only_consumer_smoke
publish_to: none

environment:
  sdk: '>=3.5.0 <4.0.0'

dependencies:
${_dependencyEntries(['llm_dart_ollama'], paths)}${_dependencyOverrides([
        'llm_dart_provider',
        'llm_dart_transport',
      ], paths)}
''';
}

String buildElevenLabsOnlyConsumerPubspec(ConsumerSmokePaths paths) {
  return '''
name: llm_dart_elevenlabs_only_consumer_smoke
publish_to: none

environment:
  sdk: '>=3.5.0 <4.0.0'

dependencies:
${_dependencyEntries(['llm_dart_elevenlabs'], paths)}${_dependencyOverrides([
        'llm_dart_provider',
        'llm_dart_transport',
      ], paths)}
''';
}

String buildSplitPackageConsumerPubspec(ConsumerSmokePaths paths) {
  return '''
name: llm_dart_split_package_consumer_smoke
publish_to: none

environment:
  sdk: '>=3.5.0 <4.0.0'

dependencies:
${_dependencyEntries([
        'llm_dart_ai',
        'llm_dart_anthropic',
        'llm_dart_chat',
        'llm_dart_elevenlabs',
        'llm_dart_google',
        'llm_dart_ollama',
        'llm_dart_openai',
        'llm_dart_provider',
        'llm_dart_transport',
      ], paths)}${_dependencyOverrides([
        'llm_dart_ai',
        'llm_dart_anthropic',
        'llm_dart_chat',
        'llm_dart_elevenlabs',
        'llm_dart_google',
        'llm_dart_ollama',
        'llm_dart_openai',
        'llm_dart_provider',
        'llm_dart_transport',
      ], paths)}
''';
}

String buildFlutterConsumerPubspec(ConsumerSmokePaths paths) {
  return '''
name: llm_dart_flutter_consumer_smoke
publish_to: none

environment:
  sdk: '>=3.5.0 <4.0.0'
  flutter: '>=3.24.0'

dependencies:
  flutter:
    sdk: flutter
${_dependencyEntries([
        'llm_dart_flutter',
        'llm_dart_openai',
      ], paths)}${_dependencyOverrides([
        'llm_dart_ai',
        'llm_dart_chat',
        'llm_dart_openai',
        'llm_dart_provider',
        'llm_dart_transport',
      ], paths)}
dev_dependencies:
  flutter_test:
    sdk: flutter
''';
}

String _dependencyEntries(
  List<String> packageNames,
  ConsumerSmokePaths paths,
) {
  final buffer = StringBuffer();
  for (final packageName in packageNames) {
    buffer.write(_dependencyEntry(packageName, paths));
  }
  return buffer.toString();
}

String _dependencyOverrides(
  List<String> packageNames,
  ConsumerSmokePaths paths,
) {
  if (paths.usesPublishedPackages) {
    return '';
  }

  return '\ndependency_overrides:\n${_dependencyEntries(packageNames, paths)}';
}

String _dependencyEntry(String packageName, ConsumerSmokePaths paths) {
  if (paths.usesPublishedPackages) {
    return '  $packageName: ${paths.packageVersion}\n';
  }

  final packagePath = packageName == 'llm_dart'
      ? paths.repoRoot
      : paths.packagePaths[packageName];
  if (packagePath == null) {
    throw StateError('missing local path for `$packageName`.');
  }

  return '  $packageName:\n    path: $packagePath\n';
}

Future<void> writeTextFile(File file, String contents) async {
  await file.parent.create(recursive: true);
  await file.writeAsString(contents);
}

Map<String, String> buildConsumerSmokeEnvironment(
  ConsumerSmokeOptions options,
) {
  final environment = {
    'DART_SUPPRESS_ANALYTICS': 'true',
    'FLUTTER_SUPPRESS_ANALYTICS': 'true',
  };
  final proxy = options.proxy;
  if (proxy != null) {
    environment['HTTP_PROXY'] = proxy;
    environment['HTTPS_PROXY'] = proxy;
  }

  return Map.unmodifiable(environment);
}

String pathForPubspec(FileSystemEntity entity) {
  return entity.absolute.path.replaceAll('\\', '/');
}

Future<void> pipeProcessOutput(
  Stream<List<int>> source,
  IOSink destination,
) async {
  await for (final chunk in source.transform(utf8.decoder)) {
    destination.write(chunk);
  }
}

String formatDuration(Duration duration) {
  final minutes = duration.inMinutes;
  final seconds = duration.inSeconds.remainder(60);
  final milliseconds = duration.inMilliseconds.remainder(1000);
  if (minutes > 0) {
    return '${minutes}m ${seconds}s';
  }
  if (seconds > 0) {
    return '$seconds.${milliseconds.toString().padLeft(3, '0')}s';
  }
  return '${milliseconds}ms';
}

String quoteCommandPart(String value) {
  if (!value.contains(RegExp(r'\s'))) {
    return value;
  }
  return '"${value.replaceAll('"', r'\"')}"';
}

String executableForCurrentPlatform(String executable) {
  return resolveToolExecutable(executable);
}

String _readFlagValue(String argument, String prefix) {
  final value = argument.substring(prefix.length).trim();
  if (value.isEmpty) {
    throw FormatException(
        '`${prefix.substring(0, prefix.length - 1)}` needs a value');
  }
  return value;
}

const dartConsumerSmokeProgram = r'''
import 'package:llm_dart/core.dart' as core;
import 'package:llm_dart/llm_dart.dart' as llm;
import 'package:llm_dart_ai/llm_dart_ai.dart' as ai;
import 'package:llm_dart_anthropic/llm_dart_anthropic.dart' as anthropic;
import 'package:llm_dart_chat/llm_dart_chat.dart' as chat;
import 'package:llm_dart_core/llm_dart_core.dart' as compat_core;
import 'package:llm_dart/deepseek.dart' as deepseek;
import 'package:llm_dart/elevenlabs.dart' as elevenlabs;
import 'package:llm_dart/groq.dart' as groq;
import 'package:llm_dart_google/llm_dart_google.dart' as google;
import 'package:llm_dart/ollama.dart' as ollama;
import 'package:llm_dart_openai/llm_dart_openai.dart' as openai;
import 'package:llm_dart/openrouter.dart' as openrouter;
import 'package:llm_dart/phind.dart' as phind;
import 'package:llm_dart_provider/llm_dart_provider.dart' as provider;
import 'package:llm_dart_transport/llm_dart_transport.dart' as transport;
import 'package:llm_dart/xai.dart' as xai;

void main() {
  final prompts = <ai.ModelMessage>[
    const core.SystemModelMessage.text('You are concise.'),
    ai.UserModelMessage.text('Say hello.'),
  ];

  final models = [
    llm.openai(apiKey: 'test').chatModel('gpt-4.1-mini'),
    openai.openai(apiKey: 'test').chatModel('gpt-4.1-mini'),
    google.google(apiKey: 'test').chatModel('gemini-2.0-flash'),
    anthropic
        .anthropic(apiKey: 'test')
        .chatModel('claude-3-5-haiku-latest'),
    ollama.ollama().chatModel('llama3.2'),
    xai.xai(apiKey: 'test').chatModel('grok-3'),
    deepseek.deepSeek(apiKey: 'test').chatModel('deepseek-chat'),
    openrouter.openRouter(apiKey: 'test').chatModel('openai/gpt-4o-mini'),
    groq.groq(apiKey: 'test').chatModel('llama-3.3-70b-versatile'),
    phind.phind(apiKey: 'test').chatModel('Phind-70B'),
  ];

  final speechModel =
      elevenlabs.elevenLabs(apiKey: 'test').speechModel('eleven_multilingual_v2');
  final chatInput = chat.ChatInput.text('hello');
  final cancellation = transport.TransportCancellation()..cancel('smoke');
  final mapped = const compat_core.ChatMessageMapper();
  final callOptions = const provider.CallOptions();

  if (prompts.length != 2 ||
      models.length != 10 ||
      chatInput.message.role != ai.ModelMessageRole.user ||
      !cancellation.isCancelled ||
      callOptions.timeout != null) {
    throw StateError('consumer smoke failed');
  }

  print([
    speechModel.runtimeType,
    mapped.runtimeType,
    'ok',
  ].join(' '));
}
''';

const openAIOnlyConsumerSmokeProgram = r'''
import 'package:llm_dart_openai/llm_dart_openai.dart' as openai;

void main() {
  final openAIProvider = openai.openai(apiKey: 'test');
  final openAIModel = openAIProvider.chatModel('gpt-4.1-mini');
  final xaiModel = openai.xai(apiKey: 'test').chatModel('grok-3');
  const xaiOptions = openai.XAIGenerateTextOptions(
    search: openai.XAILiveSearchOptions.autoWeb(maxSearchResults: 3),
  );
  final openRouterModel = openai.openRouter(
    apiKey: 'test',
  ).chatModel(
    'openai/gpt-4o-mini',
    settings: const openai.OpenRouterChatModelSettings(
      search: openai.OpenRouterSearchOptions.onlineModel(),
    ),
  );

  if (openAIModel.providerId != 'openai' ||
      xaiModel.providerId != 'xai' ||
      openRouterModel.providerId != 'openrouter' ||
      xaiOptions.search?.maxSearchResults != 3) {
    throw StateError('OpenAI-only consumer smoke failed');
  }

  print('openai-only ok');
}
''';

const googleOnlyConsumerSmokeProgram = r'''
import 'package:llm_dart_google/llm_dart_google.dart' as google;

void main() {
  final provider = google.google(apiKey: 'test');
  final chatModel = provider.chatModel(
    'gemini-2.0-flash',
    settings: const google.GoogleChatModelSettings(
      safetySettings: [
        google.GoogleSafetySetting(
          category: google.GoogleHarmCategory.harassment,
          threshold: google.GoogleHarmBlockThreshold.blockOnlyHigh,
        ),
      ],
    ),
  );
  final embeddingModel = provider.embeddingModel('text-embedding-004');
  final imageModel = provider.imageModel('gemini-2.5-flash-image');
  final speechModel = provider.speechModel('gemini-2.5-flash-preview-tts');
  const textOptions = google.GoogleGenerateTextOptions(
    thinkingLevel: google.GoogleThinkingLevel.low,
    includeThoughts: true,
  );
  const imageOptions = google.GoogleImageOptions(
    aspectRatio: google.GoogleImageAspectRatio.landscape16x9,
  );

  if (chatModel.providerId != 'google' ||
      embeddingModel.providerId != 'google' ||
      imageModel.providerId != 'google' ||
      speechModel.providerId != 'google' ||
      textOptions.thinkingLevel != google.GoogleThinkingLevel.low ||
      imageOptions.aspectRatio != google.GoogleImageAspectRatio.landscape16x9) {
    throw StateError('Google-only consumer smoke failed');
  }

  print('google-only ok');
}
''';

const anthropicOnlyConsumerSmokeProgram = r'''
import 'package:llm_dart_anthropic/llm_dart_anthropic.dart' as anthropic;

void main() {
  final provider = anthropic.anthropic(apiKey: 'test');
  final model = provider.chatModel(
    'claude-3-5-haiku-latest',
    settings: const anthropic.AnthropicChatModelSettings(
      betaFeatures: ['files-api-2025-04-14'],
    ),
  );
  final files = provider.files(
    settings: const anthropic.AnthropicFilesSettings(
      betaFeatures: ['files-api-2025-04-14'],
    ),
  );
  const options = anthropic.AnthropicGenerateTextOptions(
    extendedThinking: true,
    thinkingBudgetTokens: 1024,
  );

  if (model.providerId != 'anthropic' ||
      files.runtimeType.toString().isEmpty ||
      options.extendedThinking != true ||
      options.thinkingBudgetTokens != 1024) {
    throw StateError('Anthropic-only consumer smoke failed');
  }

  print('anthropic-only ok');
}
''';

const ollamaOnlyConsumerSmokeProgram = r'''
import 'package:llm_dart_ollama/llm_dart_ollama.dart' as ollama;

void main() {
  final provider = ollama.ollama(baseUrl: 'http://localhost:11434');
  final chatModel = provider.chatModel('llama3.2');
  final embeddingModel = provider.embeddingModel('nomic-embed-text');
  final catalog = provider.catalog();
  const options = ollama.OllamaGenerateTextOptions(
    numCtx: 4096,
    keepAlive: '10m',
  );

  if (chatModel.providerId != 'ollama' ||
      embeddingModel.providerId != 'ollama' ||
      catalog.runtimeType.toString().isEmpty ||
      options.numCtx != 4096) {
    throw StateError('Ollama-only consumer smoke failed');
  }

  print('ollama-only ok');
}
''';

const elevenLabsOnlyConsumerSmokeProgram = r'''
import 'package:llm_dart_elevenlabs/llm_dart_elevenlabs.dart' as elevenlabs;

void main() {
  final provider = elevenlabs.elevenLabs(apiKey: 'test');
  final speechModel = provider.speechModel('eleven_multilingual_v2');
  final transcriptionModel = provider.transcriptionModel('scribe_v1');
  final voices = provider.voices();
  const speechOptions = elevenlabs.ElevenLabsSpeechOptions(
    outputFormat: 'mp3_44100_128',
    speed: 1.0,
  );

  if (speechModel.providerId != 'elevenlabs' ||
      transcriptionModel.providerId != 'elevenlabs' ||
      voices.runtimeType.toString().isEmpty ||
      speechOptions.outputFormat != 'mp3_44100_128') {
    throw StateError('ElevenLabs-only consumer smoke failed');
  }

  print('elevenlabs-only ok');
}
''';

const splitPackageConsumerSmokeProgram = r'''
import 'package:llm_dart_ai/llm_dart_ai.dart' as ai;
import 'package:llm_dart_anthropic/llm_dart_anthropic.dart' as anthropic;
import 'package:llm_dart_chat/llm_dart_chat.dart' as chat;
import 'package:llm_dart_elevenlabs/llm_dart_elevenlabs.dart' as elevenlabs;
import 'package:llm_dart_google/llm_dart_google.dart' as google;
import 'package:llm_dart_ollama/llm_dart_ollama.dart' as ollama;
import 'package:llm_dart_openai/llm_dart_openai.dart' as openai;
import 'package:llm_dart_provider/llm_dart_provider.dart' as provider;
import 'package:llm_dart_transport/llm_dart_transport.dart' as transport;

Future<void> main() async {
  final message = ai.UserModelMessage.text('Say hello.');
  final openAIModel = openai.openai(apiKey: 'test').chatModel('gpt-4.1-mini');
  final anthropicModel =
      anthropic.anthropic(apiKey: 'test').chatModel('claude-3-5-haiku-latest');
  final googleModel =
      google.google(apiKey: 'test').chatModel('gemini-2.0-flash');
  final ollamaModel = ollama.ollama().chatModel('llama3.2');
  final speechModel =
      elevenlabs.elevenLabs(apiKey: 'test').speechModel('eleven_multilingual_v2');
  final cancellation = transport.TransportCancellation()..cancel('smoke');
  final session = chat.DefaultChatSession(
    transport: chat.DirectChatTransport(model: openAIModel),
  );

  try {
    final models = <provider.LanguageModel>[
      openAIModel,
      anthropicModel,
      googleModel,
      ollamaModel,
    ];
    const options = provider.GenerateTextOptions(maxOutputTokens: 16);

    if (message.role != ai.ModelMessageRole.user ||
        models.map((model) => model.providerId).join(',') !=
            'openai,anthropic,google,ollama' ||
        speechModel.providerId != 'elevenlabs' ||
        !cancellation.isCancelled ||
        options.maxOutputTokens != 16) {
      throw StateError('split package consumer smoke failed');
    }

    print('split-package ok');
  } finally {
    await session.dispose();
  }
}
''';

const flutterConsumerSmokeTest = r'''
import 'package:flutter_test/flutter_test.dart';
import 'package:llm_dart_flutter/llm_dart_flutter.dart';
import 'package:llm_dart_openai/llm_dart_openai.dart' as openai;

void main() {
  test('imports and constructs a Flutter chat controller', () async {
    final controller = ChatController(
      session: DefaultChatSession(
        transport: DirectChatTransport(
          model: openai.openai(apiKey: 'test').chatModel('gpt-4.1-mini'),
        ),
      ),
    );

    try {
      expect(controller.state.messages, isEmpty);
      expect(controller.state.status, ChatStatus.ready);
    } finally {
      await controller.close();
    }
  });
}
''';

const consumerSmokeUsage = '''
Usage: dart tool/run_consumer_smoke.dart [options]

Creates clean temporary Dart, provider-only, split-package, and Flutter
consumers, validates dependency resolution, analyzes them, and runs no-key
smoke tests. The default mode uses local path dependencies; --published uses
pub.dev packages.

Options:
  --published          Resolve llm_dart packages from pub.dev instead of local
                       path dependencies. Defaults to the root pubspec version.
  --version=<version>  Package version to use with --published.
  --proxy=<url>        Set HTTP_PROXY and HTTPS_PROXY for child commands.
  --direct-package-config
                       Run Dart import/runtime smoke programs with the current
                       workspace package_config. Skips pub get, analysis, and
                       Flutter smoke.
  -h, --help           Print this help text.
''';
