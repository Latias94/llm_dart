// ignore_for_file: avoid_print
import 'dart:io';

import 'package:llm_dart/core.dart' as core;
import 'package:llm_dart/llm_dart.dart' as llm;
import 'package:mcp_dart/mcp_dart.dart';

import '../shared/mcp_tool_bridge.dart';

/// HTTP LLM Integration - real AI agents with HTTP MCP tools.
///
/// This example demonstrates the stable llm_dart flow for MCP tool use over
/// HTTP transport, while preserving HTTP-specific concerns such as session IDs
/// and server-sent notifications.
void main() async {
  silenceMcpLogs();

  print('🌐 HTTP LLM Integration - Real AI Agents with HTTP MCP Tools\n');

  final apiKey = Platform.environment['OPENAI_API_KEY'] ?? 'sk-TESTKEY';
  if (apiKey == 'sk-TESTKEY') {
    print(
      '⚠️  Warning: Using test API key. Set OPENAI_API_KEY for real usage.\n',
    );
  }

  await demonstrateBasicHttpIntegration(apiKey);
  await demonstrateHttpStreamingWorkflow(apiKey);
  await demonstrateHttpSessionManagement(apiKey);

  print('\n✅ HTTP LLM integration examples completed!');
  print('🚀 You can now build web-based AI agents that use HTTP MCP tools!');

  exit(0);
}

Future<void> demonstrateBasicHttpIntegration(String apiKey) async {
  print('🔗 Basic HTTP MCP + LLM Integration:\n');

  StreamableHttpClientTransport? transport;

  try {
    final model = _createOpenAIModel(apiKey);
    final mcpConnection = await _createHttpMcpClient();
    final mcpClient = mcpConnection.client;
    transport = mcpConnection.transport;
    final tools = await discoverMcpFunctionTools(mcpClient);

    _printAvailableTools('HTTP', tools);

    final prompt = <core.PromptMessage>[
      core.UserPromptMessage.text(
        'Please greet me as "Alice" and then calculate 18 * 24 + 6.',
      ),
    ];

    _printUserMessage(prompt);
    print('   🤖 LLM: Processing request with HTTP MCP tools...');

    final result = await _runToolEnabledPrompt(
      model: model,
      prompt: prompt,
      tools: tools,
      mcpClient: mcpClient,
      options: const core.GenerateTextOptions(
        temperature: 0.7,
      ),
      sessionId: transport.sessionId,
    );

    print('   📝 LLM Final Response: ${result.text}');
    print('   ✅ Basic HTTP integration successful\n');
  } catch (e) {
    print('   ❌ Basic HTTP integration failed: $e\n');
  } finally {
    if (transport != null) {
      await _closeHttpTransport(transport);
    }
  }
}

Future<void> demonstrateHttpStreamingWorkflow(String apiKey) async {
  print('🌊 HTTP Streaming Workflow:\n');

  StreamableHttpClientTransport? transport;

  try {
    final model = _createOpenAIModel(apiKey);
    final mcpConnection = await _createHttpMcpClient();
    final mcpClient = mcpConnection.client;
    transport = mcpConnection.transport;
    final tools = await discoverMcpFunctionTools(mcpClient);

    _printAvailableTools('HTTP', tools);

    var notificationCount = 0;
    mcpClient.setNotificationHandler(
      'notifications/message',
      (notification) async {
        notificationCount++;
        final params = notification.logParams;
        print(
          '   📡 Streaming Notification #$notificationCount: '
          '${params.level} - ${params.data}',
        );
      },
      (params, meta) => JsonRpcLoggingMessageNotification.fromJson({
        'params': params,
        if (meta != null) '_meta': meta,
      }),
    );

    final prompt = <core.PromptMessage>[
      core.SystemPromptMessage.text(
        'You are a friendly assistant that can use streaming tools. '
        'Use the multi-greet tool to send personalized greetings.',
      ),
      core.UserPromptMessage.text(
        'Please use the multi-greet tool to greet me as "Charlie" '
        'with multiple messages.',
      ),
    ];

    _printUserMessage(prompt);
    print('   🤖 LLM: Initiating HTTP streaming workflow...');

    final result = await _runToolEnabledPrompt(
      model: model,
      prompt: prompt,
      tools: tools,
      mcpClient: mcpClient,
      options: const core.GenerateTextOptions(
        temperature: 0.3,
      ),
      sessionId: transport.sessionId,
    );

    print('   📝 Final Response: ${result.text}');
    print(
      '   ✅ HTTP streaming workflow successful with $notificationCount notifications\n',
    );
  } catch (e) {
    print('   ❌ HTTP streaming workflow failed: $e\n');
  } finally {
    if (transport != null) {
      await _closeHttpTransport(transport);
    }
  }
}

Future<void> demonstrateHttpSessionManagement(String apiKey) async {
  print('🆔 HTTP Session Management:\n');

  StreamableHttpClientTransport? transport;

  try {
    final model = _createOpenAIModel(apiKey);
    final mcpConnection = await _createHttpMcpClient();
    final mcpClient = mcpConnection.client;
    transport = mcpConnection.transport;
    final tools = await discoverMcpFunctionTools(mcpClient);

    _printAvailableTools('HTTP', tools);

    final prompt = <core.PromptMessage>[
      core.SystemPromptMessage.text(
        'You are a session-aware assistant. '
        'Use tools to demonstrate session management.',
      ),
      core.UserPromptMessage.text(
        'Please: 1) Generate a UUID for this session, '
        '2) Get the current time, 3) Calculate 7 * 9, '
        'and 4) Greet me as "Session User".',
      ),
    ];

    _printUserMessage(prompt);
    print('   🤖 LLM: Processing request with HTTP MCP tools...');
    print('   🆔 Session ID: ${transport.sessionId}');

    final result = await _runToolEnabledPrompt(
      model: model,
      prompt: prompt,
      tools: tools,
      mcpClient: mcpClient,
      options: const core.GenerateTextOptions(
        temperature: 0.2,
      ),
      sessionId: transport.sessionId,
    );

    print('   📝 Final Response: ${result.text}');
    print('   ✅ HTTP session management successful\n');
  } catch (e) {
    print('   ❌ HTTP session management failed: $e\n');
  } finally {
    if (transport != null) {
      await _closeHttpTransport(transport);
    }
  }
}

Future<core.GenerateTextRunResult> _runToolEnabledPrompt({
  required core.LanguageModel model,
  required List<core.PromptMessage> prompt,
  required List<core.FunctionToolDefinition> tools,
  required McpClient mcpClient,
  required core.GenerateTextOptions options,
  required String? sessionId,
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
        print(
            '      🛠️  Executing HTTP MCP tool: ${request.toolCall.toolName}');
        print('         🆔 Call ID: ${request.toolCall.toolCallId}');
        if (sessionId != null) {
          print('         🌐 Session: HTTP session $sessionId');
        }
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
            '         ⚠️ HTTP MCP tool ${request.toolCall.toolName} completed with an error state.',
          );
        } else {
          print(
            '         ✅ HTTP MCP tool ${request.toolCall.toolName} completed.',
          );
        }
      },
      onExecutionError: (request, arguments, error) {
        print(
          '         ❌ HTTP MCP tool ${request.toolCall.toolName} execution error: $error',
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

class McpConnection {
  final McpClient client;
  final StreamableHttpClientTransport transport;

  McpConnection(this.client, this.transport);
}

Future<McpConnection> _createHttpMcpClient() async {
  print('   🌐 Creating HTTP MCP client connection...');

  final client = McpClient(
    const Implementation(name: 'http-llm-client', version: '1.0.0'),
  );

  client.onerror = (error) {
    print('   ❌ MCP Client error: $error');
  };

  final transport = StreamableHttpClientTransport(
    Uri.parse('http://localhost:3000/mcp'),
    opts: StreamableHttpClientTransportOptions(),
  );

  await client.connect(transport);
  print('   ✅ HTTP MCP client connected with session: ${transport.sessionId}');

  return McpConnection(client, transport);
}

Future<void> _closeHttpTransport(
    StreamableHttpClientTransport transport) async {
  try {
    await transport.close();
  } catch (e) {
    print('   ⚠️ Error closing transport: $e');
  }
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
