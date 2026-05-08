import 'dart:async';
import 'dart:convert';
import 'dart:io';

final class ConsumerSmokeOptions {
  final String? proxy;
  final bool showHelp;

  const ConsumerSmokeOptions({
    this.proxy,
    this.showHelp = false,
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

  const ConsumerSmokePaths({
    required this.repoRoot,
    required this.packagePaths,
  });
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

  return ConsumerSmokeOptions(
    proxy: proxy,
    showHelp: showHelp,
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
    final dartConsumer = Directory.fromUri(tempRoot.uri.resolve(
      'dart_consumer/',
    ));
    final openAIOnlyConsumer = Directory.fromUri(tempRoot.uri.resolve(
      'openai_only_consumer/',
    ));
    final splitPackageConsumer = Directory.fromUri(tempRoot.uri.resolve(
      'split_package_consumer/',
    ));
    final flutterConsumer = Directory.fromUri(tempRoot.uri.resolve(
      'flutter_consumer/',
    ));

    await writeDartConsumer(
      repoRoot: repoRoot,
      consumerDirectory: dartConsumer,
    );
    await writeOpenAIOnlyConsumer(
      repoRoot: repoRoot,
      consumerDirectory: openAIOnlyConsumer,
    );
    await writeSplitPackageConsumer(
      repoRoot: repoRoot,
      consumerDirectory: splitPackageConsumer,
    );
    await writeFlutterConsumer(
      repoRoot: repoRoot,
      consumerDirectory: flutterConsumer,
    );

    final commands = buildConsumerSmokeCommands(
      dartConsumer: dartConsumer,
      openAIOnlyConsumer: openAIOnlyConsumer,
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
  final processExitCode = await process.exitCode;
  await Future.wait([stdoutDone, stderrDone]);
  stopwatch.stop();

  return ConsumerSmokeCommandResult(
    command: command,
    exitCode: processExitCode,
    elapsed: stopwatch.elapsed,
  );
}

Future<void> writeDartConsumer({
  required Directory repoRoot,
  required Directory consumerDirectory,
}) async {
  final paths = buildConsumerSmokePaths(repoRoot);
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
  required Directory repoRoot,
  required Directory consumerDirectory,
}) async {
  final paths = buildConsumerSmokePaths(repoRoot);
  await writeTextFile(
    File.fromUri(consumerDirectory.uri.resolve('pubspec.yaml')),
    buildOpenAIOnlyConsumerPubspec(paths),
  );
  await writeTextFile(
    File.fromUri(consumerDirectory.uri.resolve('bin/smoke.dart')),
    openAIOnlyConsumerSmokeProgram,
  );
}

Future<void> writeSplitPackageConsumer({
  required Directory repoRoot,
  required Directory consumerDirectory,
}) async {
  final paths = buildConsumerSmokePaths(repoRoot);
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
  required Directory repoRoot,
  required Directory consumerDirectory,
}) async {
  final paths = buildConsumerSmokePaths(repoRoot);
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
        'llm_dart_community',
        'llm_dart_core',
        'llm_dart_flutter',
        'llm_dart_google',
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

String buildDartConsumerPubspec(ConsumerSmokePaths paths) {
  return '''
name: llm_dart_dart_consumer_smoke
publish_to: none

environment:
  sdk: '>=3.5.0 <4.0.0'

dependencies:
  llm_dart:
    path: ${paths.repoRoot}
${_pathEntries([
        'llm_dart_ai',
        'llm_dart_anthropic',
        'llm_dart_chat',
        'llm_dart_community',
        'llm_dart_core',
        'llm_dart_google',
        'llm_dart_openai',
        'llm_dart_provider',
        'llm_dart_transport',
      ], paths.packagePaths)}
dependency_overrides:
${_pathEntries([
        'llm_dart_ai',
        'llm_dart_anthropic',
        'llm_dart_chat',
        'llm_dart_community',
        'llm_dart_core',
        'llm_dart_google',
        'llm_dart_openai',
        'llm_dart_provider',
        'llm_dart_transport',
      ], paths.packagePaths)}
''';
}

String buildOpenAIOnlyConsumerPubspec(ConsumerSmokePaths paths) {
  return '''
name: llm_dart_openai_only_consumer_smoke
publish_to: none

environment:
  sdk: '>=3.5.0 <4.0.0'

dependencies:
  llm_dart_openai:
    path: ${paths.packagePaths['llm_dart_openai']}

dependency_overrides:
${_pathEntries([
        'llm_dart_provider',
        'llm_dart_transport',
      ], paths.packagePaths)}
''';
}

String buildSplitPackageConsumerPubspec(ConsumerSmokePaths paths) {
  return '''
name: llm_dart_split_package_consumer_smoke
publish_to: none

environment:
  sdk: '>=3.5.0 <4.0.0'

dependencies:
${_pathEntries([
        'llm_dart_ai',
        'llm_dart_anthropic',
        'llm_dart_chat',
        'llm_dart_community',
        'llm_dart_google',
        'llm_dart_openai',
        'llm_dart_provider',
        'llm_dart_transport',
      ], paths.packagePaths)}
dependency_overrides:
${_pathEntries([
        'llm_dart_ai',
        'llm_dart_anthropic',
        'llm_dart_chat',
        'llm_dart_community',
        'llm_dart_google',
        'llm_dart_openai',
        'llm_dart_provider',
        'llm_dart_transport',
      ], paths.packagePaths)}
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
  llm_dart_flutter:
    path: ${paths.packagePaths['llm_dart_flutter']}
  llm_dart_openai:
    path: ${paths.packagePaths['llm_dart_openai']}

dependency_overrides:
${_pathEntries([
        'llm_dart_ai',
        'llm_dart_chat',
        'llm_dart_community',
        'llm_dart_openai',
        'llm_dart_provider',
        'llm_dart_transport',
      ], paths.packagePaths)}
dev_dependencies:
  flutter_test:
    sdk: flutter
''';
}

String _pathEntries(List<String> packageNames, Map<String, String> paths) {
  final buffer = StringBuffer();
  for (final packageName in packageNames) {
    buffer
      ..writeln('  $packageName:')
      ..writeln('    path: ${paths[packageName]}');
  }
  return buffer.toString();
}

Future<void> writeTextFile(File file, String contents) async {
  await file.parent.create(recursive: true);
  await file.writeAsString(contents);
}

Map<String, String>? buildConsumerSmokeEnvironment(
  ConsumerSmokeOptions options,
) {
  final proxy = options.proxy;
  if (proxy == null) {
    return null;
  }

  return {
    'HTTP_PROXY': proxy,
    'HTTPS_PROXY': proxy,
  };
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
  if (!Platform.isWindows) {
    return executable;
  }

  return switch (executable) {
    'flutter' => 'flutter.bat',
    _ => executable,
  };
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
import 'package:llm_dart/legacy.dart' as legacy;
import 'package:llm_dart/llm_dart.dart' as llm;
import 'package:llm_dart_ai/llm_dart_ai.dart' as ai;
import 'package:llm_dart_anthropic/llm_dart_anthropic.dart' as anthropic;
import 'package:llm_dart_chat/llm_dart_chat.dart' as chat;
import 'package:llm_dart_community/llm_dart_community.dart' as community;
import 'package:llm_dart_core/llm_dart_core.dart' as compat_core;
import 'package:llm_dart/deepseek.dart' as deepseek;
import 'package:llm_dart/groq.dart' as groq;
import 'package:llm_dart_google/llm_dart_google.dart' as google;
import 'package:llm_dart_openai/llm_dart_openai.dart' as openai;
import 'package:llm_dart/openrouter.dart' as openrouter;
import 'package:llm_dart/phind.dart' as phind;
import 'package:llm_dart_provider/llm_dart_provider.dart' as provider;
import 'package:llm_dart_transport/llm_dart_transport.dart' as transport;
import 'package:llm_dart/xai.dart' as xai;

void main() {
  final prompts = <provider.PromptMessage>[
    core.SystemPromptMessage.text('You are concise.'),
    ai.UserPromptMessage.text('Say hello.'),
  ];

  final models = [
    llm.openai(apiKey: 'test').chatModel('gpt-4.1-mini'),
    openai.OpenAI(apiKey: 'test').chatModel('gpt-4.1-mini'),
    google.Google(apiKey: 'test').chatModel('gemini-2.0-flash'),
    anthropic.Anthropic(apiKey: 'test').chatModel('claude-3-5-haiku-latest'),
    community.Ollama().chatModel('llama3.2'),
    xai.xai(apiKey: 'test').chatModel('grok-3'),
    deepseek.deepSeek(apiKey: 'test').chatModel('deepseek-chat'),
    openrouter.openRouter(apiKey: 'test').chatModel('openai/gpt-4o-mini'),
    groq.groq(apiKey: 'test').chatModel('llama-3.3-70b-versatile'),
    phind.phind(apiKey: 'test').chatModel('Phind-70B'),
  ];

  final speechModel =
      community.ElevenLabs(apiKey: 'test').speechModel('eleven_multilingual_v2');
  final chatInput = chat.ChatInput.text('hello');
  final cancellation = transport.TransportCancellation()..cancel('smoke');
  final legacyBuilder = legacy.LLMBuilder();
  final mapped = const compat_core.ChatMessageMapper();
  final callOptions = const provider.CallOptions();

  if (prompts.length != 2 ||
      models.length != 10 ||
      chatInput.message.role != provider.PromptRole.user ||
      !cancellation.isCancelled ||
      callOptions.timeout != null) {
    throw StateError('consumer smoke failed');
  }

  print([
    speechModel.runtimeType,
    legacyBuilder.runtimeType,
    mapped.runtimeType,
    'ok',
  ].join(' '));
}
''';

const openAIOnlyConsumerSmokeProgram = r'''
import 'package:llm_dart_openai/llm_dart_openai.dart' as openai;

void main() {
  final openAIProvider = openai.OpenAI(apiKey: 'test');
  final openAIModel = openAIProvider.chatModel('gpt-4.1-mini');
  final xaiModel = openai.OpenAI(
    apiKey: 'test',
    profile: const openai.XAIProfile(),
  ).chatModel('grok-3');
  const xaiOptions = openai.XAIGenerateTextOptions(
    search: openai.XAILiveSearchOptions.autoWeb(maxSearchResults: 3),
  );
  final openRouterModel = openai.OpenAI(
    apiKey: 'test',
    profile: const openai.OpenRouterProfile(),
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

const splitPackageConsumerSmokeProgram = r'''
import 'package:llm_dart_ai/llm_dart_ai.dart' as ai;
import 'package:llm_dart_anthropic/llm_dart_anthropic.dart' as anthropic;
import 'package:llm_dart_chat/llm_dart_chat.dart' as chat;
import 'package:llm_dart_community/llm_dart_community.dart' as community;
import 'package:llm_dart_google/llm_dart_google.dart' as google;
import 'package:llm_dart_openai/llm_dart_openai.dart' as openai;
import 'package:llm_dart_provider/llm_dart_provider.dart' as provider;
import 'package:llm_dart_transport/llm_dart_transport.dart' as transport;

Future<void> main() async {
  final prompt = ai.UserPromptMessage.text('Say hello.');
  final openAIModel = openai.OpenAI(apiKey: 'test').chatModel('gpt-4.1-mini');
  final anthropicModel =
      anthropic.Anthropic(apiKey: 'test').chatModel('claude-3-5-haiku-latest');
  final googleModel =
      google.Google(apiKey: 'test').chatModel('gemini-2.0-flash');
  final ollamaModel = community.Ollama().chatModel('llama3.2');
  final speechModel =
      community.ElevenLabs(apiKey: 'test').speechModel('eleven_multilingual_v2');
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

    if (prompt.role != provider.PromptRole.user ||
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
          model: openai.OpenAI(apiKey: 'test').chatModel('gpt-4.1-mini'),
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
Usage: dart run tool/run_consumer_smoke.dart [options]

Creates clean temporary Dart, split-package, and Flutter consumers, validates
local path dependency resolution, analyzes them, and runs no-key smoke tests.

Options:
  --proxy=<url>  Set HTTP_PROXY and HTTPS_PROXY for child commands.
  -h, --help     Print this help text.
''';
