// ignore_for_file: avoid_print
import 'dart:io';

import 'package:llm_dart_ai/llm_dart_ai.dart';
import 'package:llm_dart_builder/llm_dart_builder.dart';
import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_anthropic/llm_dart_anthropic.dart';
import 'package:llm_dart_groq/llm_dart_groq.dart';
import 'package:llm_dart_openai/llm_dart_openai.dart';

/// 💻 CLI Tool Integration - Command-line AI Assistant
///
/// This example demonstrates how to integrate LLM Dart into a command-line tool:
/// - Argument parsing and configuration
/// - Interactive prompts and responses
/// - Progress indicators and status updates
/// - Configuration management
///
/// Usage:
/// dart run cli_tool.dart --help
/// dart run cli_tool.dart chat "Hello, how are you?"
/// dart run cli_tool.dart --provider groq --model llama-3.1-8b-instant chat "Explain AI"
///
/// Before running, set your API keys:
/// export OPENAI_API_KEY="your-key"
/// export GROQ_API_KEY="your-key"
void main(List<String> arguments) async {
  final cliTool = AICliTool();
  await cliTool.run(arguments);
}

/// AI-powered command-line tool
class AICliTool {
  // Configuration
  String _provider = 'openai';
  String _model = 'gpt-4o-mini';
  double _temperature = 0.7;
  int _maxTokens = 1000;
  bool _verbose = false;
  bool _streaming = false;

  /// Run the CLI tool with given arguments
  Future<void> run(List<String> arguments) async {
    try {
      // Parse arguments
      final command = parseArguments(arguments);

      if (command == null) {
        return; // Help was shown or invalid arguments
      }

      // Initialize AI provider
      final aiProvider = await initializeProvider();

      // Execute command
      await executeCommand(command, aiProvider);
    } catch (e) {
      printError('Error: $e');
      exit(1);
    }
  }

  /// Parse command-line arguments
  String? parseArguments(List<String> arguments) {
    if (arguments.isEmpty ||
        arguments.contains('--help') ||
        arguments.contains('-h')) {
      showHelp();
      return null;
    }

    // Parse flags
    for (int i = 0; i < arguments.length; i++) {
      switch (arguments[i]) {
        case '--provider':
        case '-p':
          if (i + 1 < arguments.length) {
            _provider = arguments[++i];
          }
          break;
        case '--model':
        case '-m':
          if (i + 1 < arguments.length) {
            _model = arguments[++i];
          }
          break;
        case '--temperature':
        case '-t':
          if (i + 1 < arguments.length) {
            _temperature = double.tryParse(arguments[++i]) ?? 0.7;
          }
          break;
        case '--max-tokens':
          if (i + 1 < arguments.length) {
            _maxTokens = int.tryParse(arguments[++i]) ?? 1000;
          }
          break;
        case '--verbose':
        case '-v':
          _verbose = true;
          break;
        case '--stream':
        case '-s':
          _streaming = true;
          break;
        case 'chat':
        case 'ask':
        case 'generate':
          // Found command, return it with remaining arguments
          if (i + 1 < arguments.length) {
            return '${arguments[i]} ${arguments.sublist(i + 1).join(' ')}';
          } else {
            printError('Error: Command "${arguments[i]}" requires a prompt');
            return null;
          }
      }
    }

    printError(
        'Error: No command specified. Use --help for usage information.');
    return null;
  }

  /// Show help information
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
    -m, --model <name>        Model name [default: gpt-4o-mini]
    -t, --temperature <num>   Temperature 0.0-1.0 [default: 0.7]
    --max-tokens <num>        Maximum tokens [default: 1000]
    -s, --stream              Enable streaming responses
    -v, --verbose             Verbose output
    -h, --help                Show this help

EXAMPLES:
    dart run cli_tool.dart chat "Hello, how are you?"
    dart run cli_tool.dart -p groq -m llama-3.1-8b-instant ask "Explain quantum computing"
    dart run cli_tool.dart --stream generate "Write a short story about AI"

ENVIRONMENT VARIABLES:
    OPENAI_API_KEY      OpenAI API key
    GROQ_API_KEY        Groq API key
    ANTHROPIC_API_KEY   Anthropic API key
''');
  }

  /// Initialize AI provider based on configuration
  Future<ChatCapability> initializeProvider() async {
    if (_verbose) {
      print('🔧 Initializing $_provider provider with model $_model...');
    }
    registerOpenAI();
    registerGroq();
    registerAnthropic();

    switch (_provider.toLowerCase()) {
      case 'openai':
        final apiKey = Platform.environment['OPENAI_API_KEY'];
        if (apiKey == null || apiKey.isEmpty) {
          throw Exception('OPENAI_API_KEY environment variable not set');
        }
        return await LLMBuilder()
            .provider(openaiProviderId)
            .apiKey(apiKey)
            .model(_model)
            .temperature(_temperature)
            .maxTokens(_maxTokens)
            .build();

      case 'groq':
        final apiKey = Platform.environment['GROQ_API_KEY'];
        if (apiKey == null || apiKey.isEmpty) {
          throw Exception('GROQ_API_KEY environment variable not set');
        }
        return await LLMBuilder()
            .provider(groqProviderId)
            .apiKey(apiKey)
            .model(_model)
            .temperature(_temperature)
            .maxTokens(_maxTokens)
            .build();

      case 'anthropic':
        final apiKey = Platform.environment['ANTHROPIC_API_KEY'];
        if (apiKey == null || apiKey.isEmpty) {
          throw Exception('ANTHROPIC_API_KEY environment variable not set');
        }
        return await LLMBuilder()
            .provider(anthropicProviderId)
            .apiKey(apiKey)
            .model(_model)
            .temperature(_temperature)
            .maxTokens(_maxTokens)
            .build();

      default:
        throw Exception(
            'Unknown provider: $_provider. Supported: openai, groq, anthropic');
    }
  }

  /// Execute the parsed command
  Future<void> executeCommand(String command, ChatCapability provider) async {
    final parts = command.split(' ');
    final commandType = parts[0];
    final prompt = parts.sublist(1).join(' ');

    if (prompt.isEmpty) {
      printError('Error: Empty prompt provided');
      return;
    }

    switch (commandType) {
      case 'chat':
        await handleChatCommand(provider, prompt);
        break;
      case 'ask':
        await handleAskCommand(provider, prompt);
        break;
      case 'generate':
        await handleGenerateCommand(provider, prompt);
        break;
      default:
        printError('Unknown command: $commandType');
    }
  }

  /// Handle chat command (interactive conversation)
  Future<void> handleChatCommand(
      ChatCapability provider, String initialPrompt) async {
    print('🤖 Starting chat session. Type "quit" or "exit" to end.\n');

    final conversation = <ChatMessage>[];

    // Add initial prompt
    await processMessage(provider, conversation, initialPrompt);

    // Interactive loop
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

      await processMessage(provider, conversation, input);
    }
  }

  /// Handle ask command (single question)
  Future<void> handleAskCommand(ChatCapability provider, String prompt) async {
    if (_verbose) {
      print('❓ Asking: $prompt\n');
    }

    await processMessage(provider, [], prompt);
  }

  /// Handle generate command (content generation)
  Future<void> handleGenerateCommand(
      ChatCapability provider, String prompt) async {
    if (_verbose) {
      print('✨ Generating: $prompt\n');
    }

    // Add system prompt for generation
    final messages = [
      ChatMessage.system(
          'You are a creative content generator. Provide high-quality, engaging content.'),
      ChatMessage.user(prompt),
    ];

    await processMessages(provider, messages);
  }

  /// Process a single message and add to conversation
  Future<void> processMessage(ChatCapability provider,
      List<ChatMessage> conversation, String prompt) async {
    conversation.add(ChatMessage.user(prompt));
    await processMessages(provider, conversation);
  }

  /// Process messages and get AI response
  Future<void> processMessages(
      ChatCapability provider, List<ChatMessage> messages) async {
    try {
      if (_streaming) {
        await handleStreamingResponse(provider, messages);
      } else {
        await handleRegularResponse(provider, messages);
      }
    } catch (e) {
      printError('AI Error: $e');
    }
  }

  /// Handle regular (non-streaming) response
  Future<void> handleRegularResponse(
      ChatCapability provider, List<ChatMessage> messages) async {
    if (_verbose) {
      stdout.write('🤔 Thinking...');
    }

    final stopwatch = Stopwatch()..start();
    final response = await generateText(model: provider, messages: messages);
    stopwatch.stop();

    if (_verbose) {
      print('\r🤖 Response (${stopwatch.elapsedMilliseconds}ms):');
    } else {
      print('🤖 AI:');
    }

    print(response.text ?? 'No response generated');

    if (_verbose && response.usage != null) {
      final usage = response.usage!;
      print(
          '\n📊 Usage: ${usage.totalTokens} tokens (${usage.promptTokens} prompt + ${usage.completionTokens} completion)');
    }

    // Add response to conversation if it's a list we're maintaining
    if (messages.isNotEmpty && messages.last.role == ChatRole.user) {
      messages.add(ChatMessage.assistant(response.text ?? ''));
    }
  }

  /// Handle streaming response
  Future<void> handleStreamingResponse(
      ChatCapability provider, List<ChatMessage> messages) async {
    print('🤖 AI: ');

    final responseBuffer = StringBuffer();

    await for (final part in streamText(model: provider, messages: messages)) {
      switch (part) {
        case TextDeltaPart(delta: final delta):
          stdout.write(delta);
          responseBuffer.write(delta);
          break;
        case FinishPart(result: final result):
          print('\n');
          if (_verbose && result.usage != null) {
            final usage = result.usage!;
            print('📊 Usage: ${usage.totalTokens} tokens');
          }
          break;
        case ErrorPart(error: final error):
          printError('\nStreaming error: $error');
          break;
        case ThinkingDeltaPart():
        case ToolCallDeltaPart():
          // Ignore for this demo.
          break;
      }
    }

    // Add response to conversation if it's a list we're maintaining
    if (messages.isNotEmpty && messages.last.role == ChatRole.user) {
      messages.add(ChatMessage.assistant(responseBuffer.toString()));
    }
  }

  /// Print error message in red
  void printError(String message) {
    print('\x1B[31m$message\x1B[0m'); // Red text
  }
}

/// 🎯 Key CLI Integration Concepts Summary:
///
/// Argument Parsing:
/// - Command-line flags and options
/// - Subcommands and arguments
/// - Help and usage information
/// - Environment variable support
///
/// User Experience:
/// - Interactive prompts
/// - Progress indicators
/// - Colored output
/// - Error handling
///
/// Configuration:
/// - Provider selection
/// - Model configuration
/// - Runtime options
/// - Environment variables
///
/// Features:
/// - Single-shot questions
/// - Interactive chat sessions
/// - Streaming responses
/// - Verbose output
///
/// Best Practices:
/// 1. Provide clear help and usage information
/// 2. Handle errors gracefully with meaningful messages
/// 3. Support multiple providers and models
/// 4. Use environment variables for API keys
/// 5. Implement streaming for better UX
///
/// Next Steps:
/// - Add configuration file support
/// - Implement conversation history
/// - Add more output formats (JSON, markdown)
/// - Create shell completion scripts
/// - Add batch processing capabilities
