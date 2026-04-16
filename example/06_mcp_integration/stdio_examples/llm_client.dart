// ignore_for_file: avoid_print
import 'dart:io';

import 'package:llm_dart/core.dart' as core;
import 'package:llm_dart/llm_dart.dart' as llm;
import 'package:mcp_dart/mcp_dart.dart';

import '../shared/mcp_tool_bridge.dart';

/// stdio LLM Integration - AI agents with real stdio MCP tools.
///
/// This example demonstrates the stable llm_dart tool-running flow:
/// - discover MCP tools
/// - expose them as shared `FunctionToolDefinition`s
/// - let `core.runTextGeneration(...)` orchestrate tool continuation
/// - keep MCP-specific schema/result handling inside the bridge layer
void main() async {
  print('🤖 stdio LLM Integration - AI Agents with Real stdio MCP Tools\n');

  final apiKey = Platform.environment['OPENAI_API_KEY'] ?? 'sk-TESTKEY';
  if (apiKey == 'sk-TESTKEY') {
    print(
      '⚠️  Warning: Using test API key. Set OPENAI_API_KEY for real usage.\n',
    );
  }

  await demonstrateBasicStdioIntegration(apiKey);
  await demonstrateStdioCalculationWorkflow(apiKey);
  await demonstrateStdioMultiToolWorkflow(apiKey);

  print('\n✅ stdio LLM integration examples completed!');
  print('🚀 You can now build AI agents that use real stdio MCP tools!');
}

Future<void> demonstrateBasicStdioIntegration(String apiKey) async {
  print('🔗 Basic stdio MCP + LLM Integration:\n');

  Client? mcpClient;
  try {
    final model = _createOpenAIModel(apiKey);
    mcpClient = await _createRealStdioMcpClient();
    final tools = await discoverMcpFunctionTools(mcpClient);

    _printAvailableTools('stdio', tools);

    final prompt = <core.PromptMessage>[
      core.UserPromptMessage.text(
        'Calculate 25 * 8 + 12 using the available tools.',
      ),
    ];

    _printUserMessage(prompt);
    print('   🤖 LLM: Analyzing request and selecting appropriate tools...');

    final result = await _runToolEnabledPrompt(
      model: model,
      prompt: prompt,
      tools: tools,
      mcpClient: mcpClient,
      options: const core.GenerateTextOptions(
        temperature: 0.7,
      ),
    );

    print('   📝 LLM Final Response: ${result.text}');
    print('   ✅ Basic stdio integration successful\n');
  } catch (e) {
    print('   ❌ Basic stdio integration failed: $e\n');
  } finally {
    await mcpClient?.close();
  }
}

Future<void> demonstrateStdioCalculationWorkflow(String apiKey) async {
  print('🧮 stdio Calculation Workflow:\n');

  Client? mcpClient;
  try {
    final model = _createOpenAIModel(apiKey);
    mcpClient = await _createRealStdioMcpClient();
    final tools = await discoverMcpFunctionTools(mcpClient);

    _printAvailableTools('stdio', tools);

    final prompt = <core.PromptMessage>[
      core.SystemPromptMessage.text(
        'You are a math assistant that can use calculation tools. '
        'The calculation tool supports basic operations: +, -, *, /. '
        'It does NOT support ^ (power), pi, sqrt, or other advanced functions. '
        'Use only basic arithmetic operations and break down complex '
        'calculations into simple steps.',
      ),
      core.UserPromptMessage.text(
        'I need to calculate the area of a circle with radius 7 '
        '(use 3.14159 for pi), then find what percentage that area is of a '
        'square with side length 20. Please use only basic arithmetic '
        'operations (+, -, *, /) in your calculations.',
      ),
    ];

    _printUserMessage(prompt);
    print('   🤖 LLM: Breaking down the mathematical workflow...');

    final result = await _runToolEnabledPrompt(
      model: model,
      prompt: prompt,
      tools: tools,
      mcpClient: mcpClient,
      options: const core.GenerateTextOptions(
        temperature: 0.3,
      ),
    );

    print('   📝 Final Response: ${result.text}');
    print('   ✅ stdio calculation workflow successful\n');
  } catch (e) {
    print('   ❌ stdio calculation workflow failed: $e\n');
  } finally {
    await mcpClient?.close();
  }
}

Future<void> demonstrateStdioMultiToolWorkflow(String apiKey) async {
  print('⚡ stdio Multi-Tool Workflow:\n');

  Client? mcpClient;
  try {
    final model = _createOpenAIModel(apiKey);
    mcpClient = await _createRealStdioMcpClient();
    final tools = await discoverMcpFunctionTools(mcpClient);

    _printAvailableTools('stdio', tools);

    final prompt = <core.PromptMessage>[
      core.SystemPromptMessage.text(
        'You are a helpful assistant that can use various tools. '
        'The calculation tool supports basic operations: +, -, *, /. '
        'Use multiple tools to gather information and provide comprehensive '
        'answers. Always use the calculation tool for mathematical operations.',
      ),
      core.UserPromptMessage.text(
        'Please: 1) Get the current time, 2) Generate a random number between '
        '1-10, 3) Use the calculation tool to calculate that number squared '
        '(multiply the number by itself), and 4) Generate a UUID for this '
        'session.',
      ),
    ];

    _printUserMessage(prompt);
    print('   🤖 LLM: Planning multi-tool workflow via stdio...');

    final result = await _runToolEnabledPrompt(
      model: model,
      prompt: prompt,
      tools: tools,
      mcpClient: mcpClient,
      options: const core.GenerateTextOptions(
        temperature: 0.2,
      ),
    );

    print('   📝 Final Response: ${result.text}');
    print('   ✅ stdio multi-tool workflow successful\n');
  } catch (e) {
    print('   ❌ stdio multi-tool workflow failed: $e\n');
  } finally {
    await mcpClient?.close();
  }
}

Future<core.GenerateTextRunResult> _runToolEnabledPrompt({
  required core.LanguageModel model,
  required List<core.PromptMessage> prompt,
  required List<core.FunctionToolDefinition> tools,
  required Client mcpClient,
  required core.GenerateTextOptions options,
}) {
  return core.runTextGeneration(
    model: model,
    prompt: prompt,
    tools: tools,
    toolChoice: const core.RequiredToolChoice(),
    options: options,
    functionToolExecutor: createMcpFunctionToolExecutor(
      mcpClient,
      onExecutionStart: (request, arguments) {
        print('      🛠️  Executing MCP tool: ${request.toolCall.toolName}');
        print('         🆔 Call ID: ${request.toolCall.toolCallId}');
        _printIndentedValue(
          'Arguments',
          arguments,
          baseIndent: '         ',
        );
      },
      onExecutionFinish: (request, arguments, result, executionResult) {
        _printIndentedValue(
          'Result',
          executionResult.output,
          baseIndent: '         ',
        );
        if (result.isError == true || executionResult.isError) {
          print(
            '         ⚠️ MCP tool ${request.toolCall.toolName} completed with an error state.',
          );
        } else {
          print('         ✅ MCP tool ${request.toolCall.toolName} completed.');
        }
      },
      onExecutionError: (request, arguments, error) {
        print(
          '         ❌ MCP tool ${request.toolCall.toolName} execution error: $error',
        );
      },
    ),
    onStepFinish: (step) {
      _printStepSummary(step);
    },
  );
}

core.LanguageModel _createOpenAIModel(String apiKey) {
  return llm.AI.openai(apiKey: apiKey).chatModel('gpt-4o-mini');
}

Future<Client> _createRealStdioMcpClient() async {
  print('   🔌 Creating real stdio MCP client...');

  const serverCommand = 'dart';
  const serverArgs = <String>[
    'run',
    'example/06_mcp_integration/stdio_examples/server.dart',
  ];

  final serverParams = StdioServerParameters(
    command: serverCommand,
    args: serverArgs,
    stderrMode: ProcessStartMode.normal,
  );

  final transport = StdioClientTransport(serverParams);
  final clientInfo = Implementation(
    name: 'LlmDartStdioClient',
    version: '1.0.0',
  );
  final client = Client(clientInfo);

  transport.onerror = (error) {
    print('   ❌ MCP Transport error: $error');
  };

  transport.onclose = () {
    print('   🔌 MCP Transport closed');
  };

  print('   🔗 Connecting to stdio MCP server...');
  await client.connect(transport);
  print('   ✅ Connected to stdio MCP server');

  return client;
}

void _printAvailableTools(
  String transportName,
  List<core.FunctionToolDefinition> tools,
) {
  print('   🔧 Available $transportName MCP Tools:');
  for (final tool in tools) {
    print('      • ${tool.name}: ${tool.description}');
  }
}

void _printUserMessage(List<core.PromptMessage> prompt) {
  final userText = _lastUserText(prompt);
  if (userText == null) {
    return;
  }

  print('   💬 User Message:');
  print('      "$userText"');
}

String? _lastUserText(List<core.PromptMessage> prompt) {
  for (var index = prompt.length - 1; index >= 0; index--) {
    final message = prompt[index];
    if (message is! core.UserPromptMessage) {
      continue;
    }

    final text = message.parts.whereType<core.TextPromptPart>().map((part) {
      return part.text;
    }).join('\n');
    if (text.trim().isNotEmpty) {
      return text;
    }
  }

  return null;
}

void _printStepSummary(core.GenerateTextStepResult step) {
  print(
    '   📋 Step ${step.stepNumber + 1} finished with ${step.finishReason.name}.',
  );

  if (step.toolCalls.isEmpty) {
    return;
  }

  for (final toolCall in step.toolCalls) {
    print('      📞 Tool Request: ${toolCall.toolName}');
    print('         🆔 Call ID: ${toolCall.toolCallId}');
    _printIndentedValue(
      'Input',
      toolCall.input,
      baseIndent: '         ',
    );
  }
}

void _printIndentedValue(
  String label,
  Object? value, {
  String baseIndent = '      ',
}) {
  final formatted = formatMcpValue(value);
  final lines = formatted.split('\n');
  if (lines.length == 1) {
    print('$baseIndent$label: ${lines.first}');
    return;
  }

  print('$baseIndent$label:');
  final childIndent = '$baseIndent   ';
  for (final line in lines) {
    print('$childIndent$line');
  }
}
