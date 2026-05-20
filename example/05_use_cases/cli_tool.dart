// ignore_for_file: avoid_print

import 'dart:io';

import 'package:llm_dart/core.dart' as core;
import 'package:llm_dart_anthropic/llm_dart_anthropic.dart' as anthropic;
import 'package:llm_dart_openai/llm_dart_openai.dart' as openai;

/// CLI example using the stable model API.
Future<void> main(List<String> arguments) async {
  final cliTool = AICliTool();
  await cliTool.run(arguments);
}

class AICliTool {
  String _provider = 'openai';
  String _model = 'gpt-4.1-mini';
  double _temperature = 0.7;
  int _maxTokens = 1000;
  bool _verbose = false;
  bool _streaming = false;

  Future<void> run(List<String> arguments) async {
    try {
      final command = parseArguments(arguments);
      if (command == null) {
        return;
      }

      final model = initializeProvider();
      await executeCommand(command, model);
    } catch (error) {
      printError('Error: $error');
      exit(1);
    }
  }

  String? parseArguments(List<String> arguments) {
    if (arguments.isEmpty ||
        arguments.contains('--help') ||
        arguments.contains('-h')) {
      showHelp();
      return null;
    }

    for (var i = 0; i < arguments.length; i++) {
      switch (arguments[i]) {
        case '--provider':
        case '-p':
          if (i + 1 < arguments.length) {
            _provider = arguments[++i];
          }
        case '--model':
        case '-m':
          if (i + 1 < arguments.length) {
            _model = arguments[++i];
          }
        case '--temperature':
        case '-t':
          if (i + 1 < arguments.length) {
            _temperature = double.tryParse(arguments[++i]) ?? 0.7;
          }
        case '--max-tokens':
          if (i + 1 < arguments.length) {
            _maxTokens = int.tryParse(arguments[++i]) ?? 1000;
          }
        case '--verbose':
        case '-v':
          _verbose = true;
        case '--stream':
        case '-s':
          _streaming = true;
        case 'chat':
        case 'ask':
        case 'generate':
          if (i + 1 < arguments.length) {
            return '${arguments[i]} ${arguments.sublist(i + 1).join(' ')}';
          }

          printError('Error: Command "${arguments[i]}" requires a prompt');
          return null;
      }
    }

    printError(
        'Error: No command specified. Use --help for usage information.');
    return null;
  }

  void showHelp() {
    print('''
🤖 AI CLI Tool - Command-line AI Assistant

USAGE:
    dart run cli_tool.dart [OPTIONS] COMMAND PROMPT

COMMANDS:
    chat <prompt>      Start a chat conversation
    ask <prompt>       Ask a single question
    generate <prompt>  Generate content

OPTIONS:
    -p, --provider <name>     AI provider (openai, groq, anthropic) [default: openai]
    -m, --model <name>        Model name [default: gpt-4.1-mini]
    -t, --temperature <num>   Temperature 0.0-1.0 [default: 0.7]
    --max-tokens <num>        Maximum output tokens [default: 1000]
    -s, --stream              Enable streaming responses
    -v, --verbose             Verbose output
    -h, --help                Show this help

EXAMPLES:
    dart run cli_tool.dart chat "Hello, how are you?"
    dart run cli_tool.dart -p groq -m llama-3.3-70b-versatile ask "Explain quantum computing"
    dart run cli_tool.dart --stream generate "Write a short story about AI"

ENVIRONMENT VARIABLES:
    OPENAI_API_KEY      OpenAI API key
    GROQ_API_KEY        Groq API key
    ANTHROPIC_API_KEY   Anthropic API key
''');
  }

  core.LanguageModel initializeProvider() {
    if (_verbose) {
      print('🔧 Initializing $_provider provider with model $_model...');
    }

    switch (_provider.toLowerCase()) {
      case 'openai':
        final apiKey = Platform.environment['OPENAI_API_KEY'];
        if (apiKey == null || apiKey.isEmpty) {
          throw Exception('OPENAI_API_KEY environment variable not set');
        }
        return openai.openai(apiKey: apiKey).chatModel(_model);
      case 'groq':
        final apiKey = Platform.environment['GROQ_API_KEY'];
        if (apiKey == null || apiKey.isEmpty) {
          throw Exception('GROQ_API_KEY environment variable not set');
        }
        return openai.groq(apiKey: apiKey).chatModel(_model);
      case 'anthropic':
        final apiKey = Platform.environment['ANTHROPIC_API_KEY'];
        if (apiKey == null || apiKey.isEmpty) {
          throw Exception('ANTHROPIC_API_KEY environment variable not set');
        }
        return anthropic.anthropic(apiKey: apiKey).chatModel(_model);
      default:
        throw Exception(
          'Unknown provider: $_provider. Supported: openai, groq, anthropic',
        );
    }
  }

  Future<void> executeCommand(String command, core.LanguageModel model) async {
    final parts = command.split(' ');
    final commandType = parts[0];
    final prompt = parts.sublist(1).join(' ');

    if (prompt.isEmpty) {
      printError('Error: Empty prompt provided');
      return;
    }

    switch (commandType) {
      case 'chat':
        await handleChatCommand(model, prompt);
      case 'ask':
        await handleAskCommand(model, prompt);
      case 'generate':
        await handleGenerateCommand(model, prompt);
      default:
        printError('Unknown command: $commandType');
    }
  }

  Future<void> handleChatCommand(
    core.LanguageModel model,
    String initialPrompt,
  ) async {
    print('🤖 Starting chat session. Type "quit" or "exit" to end.\n');

    final conversation = <core.ModelMessage>[];
    await processMessage(model, conversation, initialPrompt);

    while (true) {
      stdout.write('\n💬 You: ');
      final input = stdin.readLineSync();

      if (input == null ||
          input.toLowerCase() == 'quit' ||
          input.toLowerCase() == 'exit') {
        print('\n👋 Goodbye!');
        break;
      }

      if (input.trim().isEmpty) {
        continue;
      }

      await processMessage(model, conversation, input);
    }
  }

  Future<void> handleAskCommand(core.LanguageModel model, String prompt) async {
    if (_verbose) {
      print('❓ Asking: $prompt\n');
    }

    await processMessage(model, <core.ModelMessage>[], prompt);
  }

  Future<void> handleGenerateCommand(
    core.LanguageModel model,
    String prompt,
  ) async {
    if (_verbose) {
      print('✨ Generating: $prompt\n');
    }

    await processMessages(model, [
      core.SystemModelMessage.text(
        'You are a creative content generator. Provide high-quality, engaging content.',
      ),
      core.UserModelMessage.text(prompt),
    ]);
  }

  Future<void> processMessage(
    core.LanguageModel model,
    List<core.ModelMessage> conversation,
    String prompt,
  ) async {
    conversation.add(core.UserModelMessage.text(prompt));
    await processMessages(model, conversation);
  }

  Future<void> processMessages(
    core.LanguageModel model,
    List<core.ModelMessage> messages,
  ) async {
    try {
      if (_streaming) {
        await handleStreamingResponse(model, messages);
      } else {
        await handleRegularResponse(model, messages);
      }
    } catch (error) {
      printError('AI Error: $error');
    }
  }

  Future<void> handleRegularResponse(
    core.LanguageModel model,
    List<core.ModelMessage> messages,
  ) async {
    if (_verbose) {
      stdout.write('🤔 Thinking...');
    }

    final stopwatch = Stopwatch()..start();
    final result = await core.generateTextCall(
      model: model,
      messages: messages,
      options: _buildOptions(),
    );
    stopwatch.stop();

    if (_verbose) {
      print('\r🤖 Response (${stopwatch.elapsedMilliseconds}ms):');
    } else {
      print('🤖 AI:');
    }

    print(result.text);

    if (_verbose && result.usage != null) {
      final usage = result.usage!;
      print(
        '\n📊 Usage: ${usage.totalTokens} tokens (${usage.inputTokens} input + ${usage.outputTokens} output)',
      );
    }

    if (messages.isNotEmpty &&
        messages.last.role == core.ModelMessageRole.user &&
        result.text.isNotEmpty) {
      messages.add(core.AssistantModelMessage.text(result.text));
    }
  }

  Future<void> handleStreamingResponse(
    core.LanguageModel model,
    List<core.ModelMessage> messages,
  ) async {
    print('🤖 AI: ');

    final stream = core.streamTextCall(
      model: model,
      messages: messages,
      options: _buildOptions(),
    );

    await for (final event in stream) {
      switch (event) {
        case core.TextDeltaEvent(:final delta):
          stdout.write(delta);
        case core.FinishEvent(:final usage):
          print('\n');
          if (_verbose && usage != null) {
            print('📊 Usage: ${usage.totalTokens} tokens');
          }
        case core.ErrorEvent(:final error):
          printError('\nStreaming error: $error');
        case core.ReasoningDeltaEvent():
        case core.RunStartEvent():
        case core.RunFinishEvent():
        case core.StepStartEvent():
        case core.StepFinishEvent():
        case core.StartEvent():
        case core.ResponseMetadataEvent():
        case core.TextStartEvent():
        case core.TextEndEvent():
        case core.ReasoningStartEvent():
        case core.ReasoningEndEvent():
        case core.ReasoningFileEvent():
        case core.ToolInputStartEvent():
        case core.ToolInputDeltaEvent():
        case core.ToolInputEndEvent():
        case core.ToolInputErrorEvent():
        case core.ToolCallEvent():
        case core.ToolResultEvent():
        case core.ToolApprovalRequestEvent():
        case core.ToolOutputDeniedEvent():
        case core.SourceEvent():
        case core.FileEvent():
        case core.CustomEvent():
        case core.AbortEvent():
        case core.RawChunkEvent():
          break;
      }
    }

    final finalText = (await stream.text).trim();
    if (messages.isNotEmpty &&
        messages.last.role == core.ModelMessageRole.user &&
        finalText.isNotEmpty) {
      messages.add(core.AssistantModelMessage.text(finalText));
    }
  }

  core.GenerateTextOptions _buildOptions() {
    return core.GenerateTextOptions(
      temperature: _temperature,
      maxOutputTokens: _maxTokens,
    );
  }

  void printError(String message) {
    print('\x1B[31m$message\x1B[0m');
  }
}
