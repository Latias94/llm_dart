// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';

import 'package:llm_dart/llm_dart.dart';

/// Miniagent-style single-agent REPL demo.
///
/// Features:
/// - Multi-turn conversation with a single LanguageModel
/// - Tool loop based on [ToolLoopAgent] + [ExecutableTool]
/// - Simple workspace tools:
///   - `read_file(path)`  : read a UTF-8 text file
///   - `write_file(path, content)` : write a UTF-8 text file
///   - `run_shell(command)`       : run a shell command in the workspace
///
/// Before running:
///   export OPENAI_API_KEY="your-key"
///
/// Then:
///   dart run example/05_use_cases/miniagent.dart
///
/// Commands inside REPL:
///   /exit   - quit
///   /help   - show help
///   /tools  - list available tools
///   /clear  - clear conversation history
Future<void> main() async {
  final apiKey = Platform.environment['OPENAI_API_KEY'];
  if (apiKey == null || apiKey.isEmpty) {
    print('OPENAI_API_KEY is not set. Skipping miniagent example.');
    return;
  }

  final workspace = Directory.current;
  print('Miniagent workspace: ${workspace.path}');

  // 1. Define tools (schema + executor).
  final tools = <String, ExecutableTool>{
    'read_file': ExecutableTool(
      schema: Tool.function(
        name: 'read_file',
        description: 'Read a UTF-8 text file from the workspace.',
        parameters: ParametersSchema(
          schemaType: 'object',
          properties: {
            'path': ParameterProperty(
              propertyType: 'string',
              description: 'Relative path to the file within the workspace.',
            ),
          },
          required: const ['path'],
        ),
      ),
      execute: (args) async {
        final rawPath = args['path'] as String?;
        if (rawPath == null || rawPath.isEmpty) {
          return {
            'ok': false,
            'error': 'Missing "path" argument for read_file.',
          };
        }

        final file = File(
          File(rawPath).isAbsolute
              ? rawPath
              : workspace.uri.resolveUri(Uri.file(rawPath)).toFilePath(),
        );

        if (!await file.exists()) {
          return {
            'ok': false,
            'error': 'File does not exist: ${file.path}',
          };
        }

        try {
          final content = await file.readAsString();
          return {
            'ok': true,
            'path': file.path,
            'content': content,
          };
        } catch (e) {
          return {
            'ok': false,
            'error': 'Failed to read file: $e',
          };
        }
      },
    ),
    'write_file': ExecutableTool(
      schema: Tool.function(
        name: 'write_file',
        description: 'Write a UTF-8 text file in the workspace.',
        parameters: ParametersSchema(
          schemaType: 'object',
          properties: {
            'path': ParameterProperty(
              propertyType: 'string',
              description: 'Relative path to the file within the workspace.',
            ),
            'content': ParameterProperty(
              propertyType: 'string',
              description: 'Text content to write to the file.',
            ),
          },
          required: const ['path', 'content'],
        ),
      ),
      execute: (args) async {
        final rawPath = args['path'] as String?;
        final content = args['content'] as String?;

        if (rawPath == null || content == null) {
          return {
            'ok': false,
            'error': 'Missing "path" or "content" argument for write_file.',
          };
        }

        final file = File(
          File(rawPath).isAbsolute
              ? rawPath
              : workspace.uri.resolveUri(Uri.file(rawPath)).toFilePath(),
        );

        try {
          await file.parent.create(recursive: true);
          await file.writeAsString(content);
          return {
            'ok': true,
            'path': file.path,
            'bytesWritten': content.length,
          };
        } catch (e) {
          return {
            'ok': false,
            'error': 'Failed to write file: $e',
          };
        }
      },
    ),
    'run_shell': ExecutableTool(
      schema: Tool.function(
        name: 'run_shell',
        description:
            'Run a shell command in the workspace and return its output.',
        parameters: ParametersSchema(
          schemaType: 'object',
          properties: {
            'command': ParameterProperty(
              propertyType: 'string',
              description: 'Shell command to execute.',
            ),
          },
          required: const ['command'],
        ),
      ),
      execute: (args) async {
        final command = args['command'] as String?;
        if (command == null || command.isEmpty) {
          return {
            'ok': false,
            'error': 'Missing "command" argument for run_shell.',
          };
        }

        try {
          final result = await _runShellCommand(
            command,
            workingDirectory: workspace.path,
          );
          return {
            'ok': true,
            'command': command,
            'exitCode': result.exitCode,
            'stdout': result.stdout,
            'stderr': result.stderr,
          };
        } catch (e) {
          return {
            'ok': false,
            'error': 'Failed to run shell command: $e',
          };
        }
      },
    ),
  };

  final toolSchemas =
      tools.values.map((tool) => tool.schema).toList(growable: false);

  // 2. Build a LanguageModel with tool schemas attached.
  //
  // This mirrors the idea of:
  //   model: openai('gpt-4o').withTools([...])
  //
  final model = await ai()
      .use('openai:gpt-4o-mini')
      .apiKey(apiKey)
      // Avoid hanging forever when network/API is unavailable.
      .timeout(const Duration(seconds: 30))
      .tools(toolSchemas)
      .buildLanguageModel();

  // 3. Start REPL with a system prompt and ToolLoopAgent.
  final history = <ModelMessage>[
    ModelMessage(
      role: ChatRole.system,
      parts: [
        TextContentPart(
          'You are a helpful coding and file assistant. '
          'You are running in a workspace at "${workspace.path}". '
          'Use the provided tools (read_file, write_file, run_shell) '
          'to inspect and edit files, and to run commands when helpful. '
          'Always explain what you did and show important outputs.',
        ),
      ],
    ),
  ];

  const agent = ToolLoopAgent();

  print('\nMiniagent (ToolLoopAgent + OpenAI gpt-4o-mini)');
  print('Type your questions. Commands: /help, /tools, /clear, /exit\n');

  while (true) {
    stdout.write('You > ');
    String? line;
    try {
      line = stdin.readLineSync();
    } on FormatException catch (e) {
      // Handle non-UTF8 input sequences gracefully instead of crashing.
      print('Input decoding error: $e');
      continue;
    }
    if (line == null) break;

    final input = line.trim();
    if (input.isEmpty) continue;

    if (input == '/exit') {
      print('Bye!');
      break;
    }
    if (input == '/help') {
      print('Commands:');
      print('  /help  - show this help');
      print('  /tools - list available tools');
      print('  /clear - clear conversation history');
      print('  /exit  - quit');
      continue;
    }
    if (input == '/tools') {
      print('Available tools:');
      for (final entry in tools.entries) {
        print(
          '  - ${entry.key}: '
          '${entry.value.schema.function.description}',
        );
      }
      continue;
    }
    if (input == '/clear') {
      history
        ..clear()
        ..add(
          ModelMessage(
            role: ChatRole.system,
            parts: [
              TextContentPart(
                'You are a helpful coding and file assistant. '
                'Conversation history was cleared. '
                'Workspace: "${workspace.path}".',
              ),
            ],
          ),
        );
      print('History cleared.\n');
      continue;
    }

    // Append user message to conversation.
    history.add(
      ModelMessage(
        role: ChatRole.user,
        parts: [TextContentPart(input)],
      ),
    );

    final agentInput = AgentInput(
      model: model,
      messages: List<ModelMessage>.from(history),
      tools: tools,
      loopConfig: const ToolLoopConfig(
        maxIterations: 8,
        runToolsInParallel: false,
        maxToolRetries: 0,
      ),
    );

    print('\n[agent] Running tool loop...\n');

    try {
      final traced = await agent.runTextWithSteps(agentInput);

      // Print a per-step summary.
      for (final step in traced.steps) {
        print('--- Step ${step.iteration} ---');
        final result = step.modelResult;
        if (result.thinking != null && result.thinking!.trim().isNotEmpty) {
          print('Thinking:\n${result.thinking}\n');
        }

        if (step.toolCalls.isNotEmpty) {
          print('Tools:');
          for (final call in step.toolCalls) {
            final name = call.call.function.name;
            final argsJson = call.call.function.arguments;
            final truncatedArgs = _truncate(argsJson, 200);
            if (call.isSuccess) {
              final resultJson = jsonEncode(call.result);
              final truncatedResult = _truncate(resultJson, 200);
              print('  - $name(args: $truncatedArgs) => $truncatedResult');
            } else {
              print(
                '  - $name(args: $truncatedArgs) => ERROR: ${call.error}',
              );
            }
          }
          print('');
        }
      }

      final finalText = traced.result.text ?? '(no text)';
      print('Assistant > $finalText\n');

      // Append final assistant message to history for next turn.
      if (traced.result.text != null && traced.result.text!.trim().isNotEmpty) {
        history.add(
          ModelMessage(
            role: ChatRole.assistant,
            parts: [TextContentPart(traced.result.text!)],
          ),
        );
      }
    } on LLMError catch (e) {
      print('LLM error: $e\n');
    } catch (e, st) {
      print('Unexpected error: $e');
      print(st);
    }
  }
}

String _truncate(String value, int max) {
  if (value.length <= max) return value;
  return '${value.substring(0, max)}...';
}

Future<_ShellResult> _runShellCommand(
  String command, {
  required String workingDirectory,
}) async {
  ProcessResult result;
  if (Platform.isWindows) {
    result = await Process.run(
      'cmd.exe',
      ['/C', command],
      workingDirectory: workingDirectory,
    );
  } else {
    result = await Process.run(
      '/bin/sh',
      ['-lc', command],
      workingDirectory: workingDirectory,
    );
  }

  String trimOutput(String s) =>
      s.length > 4000 ? '${s.substring(0, 4000)}...' : s;

  return _ShellResult(
    exitCode: result.exitCode,
    stdout: trimOutput(result.stdout.toString()),
    stderr: trimOutput(result.stderr.toString()),
  );
}

class _ShellResult {
  final int exitCode;
  final String stdout;
  final String stderr;

  const _ShellResult({
    required this.exitCode,
    required this.stdout,
    required this.stderr,
  });
}
