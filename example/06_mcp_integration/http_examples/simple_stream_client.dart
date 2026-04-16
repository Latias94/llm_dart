// ignore_for_file: avoid_print
import 'dart:io';

import 'package:llm_dart/core.dart' as core;
import 'package:llm_dart/llm_dart.dart' as llm;
import 'package:mcp_dart/mcp_dart.dart';

import '../shared/mcp_tool_bridge.dart';

/// Simple HTTP streaming LLM integration - streaming tool use demo.
///
/// This example focuses on the shared streaming event model:
/// - stream the model response
/// - observe tool input deltas and resolved tool calls
/// - execute MCP tools through the shared executor bridge
/// - continue automatically into the final answer
void main() async {
  print('🌊 Simple HTTP Streaming Tool Use Demo\n');

  final apiKey = Platform.environment['OPENAI_API_KEY'] ?? 'sk-TESTKEY';
  if (apiKey == 'sk-TESTKEY') {
    print(
      '⚠️  Warning: Using test API key. Set OPENAI_API_KEY for real usage.\n',
    );
  }

  await demonstrateStreamingToolUse(apiKey);

  print('\n✅ Streaming tool use demo completed!');
  exit(0);
}

Future<void> demonstrateStreamingToolUse(String apiKey) async {
  print('🌊 Streaming Tool Use with HTTP MCP Tools:\n');

  StreamableHttpClientTransport? transport;

  try {
    final model = _createOpenAIModel(apiKey);
    print('   🤖 Creating LLM provider: OpenAI GPT-4o-mini');

    final mcpConnection = await _createHttpMcpClient();
    final mcpClient = mcpConnection.client;
    transport = mcpConnection.transport;

    final allTools = await discoverMcpFunctionTools(mcpClient);
    final tools = allTools
        .where((tool) => tool.name == 'current_time')
        .toList(growable: false);

    if (tools.isEmpty) {
      throw StateError(
        'The current_time tool was not discovered from the HTTP MCP server.',
      );
    }

    print('   🔧 Exposed HTTP MCP Tool for this demo:');
    for (final tool in tools) {
      print('      • ${tool.name}: ${tool.description}');
    }

    final prompt = <core.PromptMessage>[
      core.SystemPromptMessage.text(
        'You are a helpful assistant. When users ask for time-related '
        'information, use the available tools to get the accurate current time.',
      ),
      core.UserPromptMessage.text(
        'Hi! Can you please tell me what time it is right now?',
      ),
    ];

    print('\n   💬 User Message:');
    print('      "${_lastUserText(prompt)}"');
    print('\n   🤖 LLM Processing...');

    final stream = core.streamTextRun(
      model: model,
      prompt: prompt,
      tools: tools,
      toolChoice: const core.RequiredToolChoice(),
      options: const core.GenerateTextOptions(
        temperature: 0.7,
      ),
      functionToolExecutor: createMcpFunctionToolExecutor(
        mcpClient,
        onExecutionStart: (request, arguments) {
          print(
            '   🛠️  Executing MCP tool: ${request.toolCall.toolName} '
            '(${request.toolCall.toolCallId})',
          );
          _printIndentedValue(
            'Arguments',
            arguments,
            baseIndent: '      ',
          );
        },
        onExecutionFinish: (request, arguments, result, executionResult) {
          _printIndentedValue(
            'Result',
            executionResult.output,
            baseIndent: '      ',
          );
          if (result.isError == true || executionResult.isError) {
            print(
              '      ⚠️ MCP tool ${request.toolCall.toolName} completed with an error state.',
            );
          } else {
            print('      ✅ MCP tool ${request.toolCall.toolName} completed.');
          }
        },
        onExecutionError: (request, arguments, error) {
          print(
            '      ❌ MCP tool ${request.toolCall.toolName} execution error: $error',
          );
        },
      ),
      onStepFinish: (step) {
        print(
          '   📋 Step ${step.stepNumber + 1} finished with ${step.finishReason.name}.',
        );
      },
    );

    await _consumeStreamingEvents(stream);

    final runResult = await stream.result;
    print('\n   📝 Final Response: ${runResult.text}');
    print('\n   ✅ Streaming tool use demonstration successful\n');
  } catch (e) {
    print('   ❌ Streaming tool use failed: $e\n');
  } finally {
    if (transport != null) {
      await _closeHttpTransport(transport);
      print('   🔌 HTTP MCP connection closed');
    }
  }
}

Future<void> _consumeStreamingEvents(core.StreamTextRunResult stream) async {
  var activeText = false;
  var activeReasoning = false;
  final toolNamesByCallId = <String, String>{};

  await for (final event in stream) {
    switch (event) {
      case core.TextStartEvent():
        _flushActiveStreams(
          activeText: activeText,
          activeReasoning: activeReasoning,
        );
        activeText = true;
        activeReasoning = false;
        print('   🤖 Assistant Stream:');
        stdout.write('      ');

      case core.TextDeltaEvent(delta: final delta):
        stdout.write(delta.replaceAll('\n', '\n      '));

      case core.TextEndEvent():
        if (activeText) {
          print('');
        }
        activeText = false;

      case core.ReasoningStartEvent():
        _flushActiveStreams(
          activeText: activeText,
          activeReasoning: activeReasoning,
        );
        activeText = false;
        activeReasoning = true;
        print('   🧠 Reasoning Stream:');
        stdout.write('      ');

      case core.ReasoningDeltaEvent(delta: final delta):
        stdout.write(delta.replaceAll('\n', '\n      '));

      case core.ReasoningEndEvent():
        if (activeReasoning) {
          print('');
        }
        activeReasoning = false;

      case core.ToolInputStartEvent(
          toolCallId: final toolCallId,
          toolName: final toolName,
        ):
        _flushActiveStreams(
          activeText: activeText,
          activeReasoning: activeReasoning,
        );
        activeText = false;
        activeReasoning = false;
        toolNamesByCallId[toolCallId] = toolName;
        print('   🔧 Tool Input Stream: $toolName ($toolCallId)');

      case core.ToolInputDeltaEvent():
        break;

      case core.ToolInputEndEvent(toolCallId: final toolCallId):
        final toolName = toolNamesByCallId[toolCallId];
        if (toolName != null) {
          print('   ✅ Tool Input Ready: $toolName ($toolCallId)');
        }

      case core.ToolInputErrorEvent(
          toolCallId: final toolCallId,
          toolName: final toolName,
          errorText: final errorText,
          input: final input,
        ):
        print('   ❌ Tool Input Error: $toolName ($toolCallId)');
        print('      Reason: $errorText');
        _printIndentedValue(
          'Input',
          input,
          baseIndent: '      ',
        );

      case core.ToolCallEvent(toolCall: final toolCall):
        print('   📞 Tool Call Ready: ${toolCall.toolName}');
        print('      🆔 Call ID: ${toolCall.toolCallId}');
        _printIndentedValue(
          'Input',
          toolCall.input,
          baseIndent: '      ',
        );

      case core.FinishEvent(finishReason: final finishReason):
        _flushActiveStreams(
          activeText: activeText,
          activeReasoning: activeReasoning,
        );
        activeText = false;
        activeReasoning = false;
        print('   ✅ Stream finished with ${finishReason.name}.');

      case core.ErrorEvent(error: final error):
        _flushActiveStreams(
          activeText: activeText,
          activeReasoning: activeReasoning,
        );
        activeText = false;
        activeReasoning = false;
        print('   ❌ Streaming error: ${error.message}');

      case core.StartEvent():
      case core.ResponseMetadataEvent():
      case core.ReasoningFileEvent():
      case core.ToolResultEvent():
      case core.ToolApprovalRequestEvent():
      case core.ToolOutputDeniedEvent():
      case core.SourceEvent():
      case core.FileEvent():
      case core.StepStartEvent():
      case core.StepFinishEvent():
      case core.AbortEvent():
      case core.CustomEvent():
      case core.RawChunkEvent():
        break;
    }
  }
}

void _flushActiveStreams({
  required bool activeText,
  required bool activeReasoning,
}) {
  if (activeText || activeReasoning) {
    print('');
  }
}

core.LanguageModel _createOpenAIModel(String apiKey) {
  return llm.AI.openai(apiKey: apiKey).chatModel('gpt-4o-mini');
}

class McpConnection {
  final Client client;
  final StreamableHttpClientTransport transport;

  McpConnection(this.client, this.transport);
}

Future<McpConnection> _createHttpMcpClient() async {
  print('   🌐 Creating HTTP MCP client connection...');

  final client = Client(
    const Implementation(name: 'simple-stream-client', version: '1.0.0'),
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

Future<void> _closeHttpTransport(StreamableHttpClientTransport transport) async {
  try {
    await transport.close();
  } catch (e) {
    print('   ⚠️ Error closing transport: $e');
  }
}

String _lastUserText(List<core.PromptMessage> prompt) {
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

  return '';
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
