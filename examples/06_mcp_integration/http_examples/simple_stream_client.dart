// ignore_for_file: avoid_print
import 'dart:convert';
import 'dart:io';
import 'package:llm_dart/llm_dart.dart';
import 'package:llm_dart_core/llm_dart_core.dart' show ToolResultTextPayload;
import 'package:mcp_dart/mcp_dart.dart' hide Tool;

/// Simple HTTP Streaming LLM Integration - Streaming Tool Use Demo
///
/// This example demonstrates streaming conversation with tool use functionality.
/// It shows the complete flow: user request → LLM tool call → tool execution → LLM response.
/// Features a simple "get current time" tool to demonstrate the streaming tool use process.
///
/// Before running:
/// 1. Start the server: dart run http_examples/server.dart
/// 2. Set API key: export OPENAI_API_KEY="your-key-here"
/// 3. Run this: dart run 06_mcp_integration/http_examples/simple_stream_client.dart
void main() async {
  print('🌊 Simple HTTP Streaming Tool Use Demo\n');

  // Get API key
  final apiKey = Platform.environment['OPENAI_API_KEY'] ?? 'sk-TESTKEY';
  if (apiKey == 'sk-TESTKEY') {
    print(
        '⚠️  Warning: Using test API key. Set OPENAI_API_KEY for real usage.\n');
  }

  await demonstrateStreamingToolUse(apiKey);

  print('\n✅ Streaming tool use demo completed!');
  exit(0);
}

/// Demonstrate streaming tool use with HTTP MCP tools
Future<void> demonstrateStreamingToolUse(String apiKey) async {
  print('🌊 Streaming Tool Use with HTTP MCP Tools:\n');

  Client? mcpClient;
  StreamableHttpClientTransport? transport;

  try {
    // Create MCP client for HTTP server
    final mcpConnection = await _createHttpMcpClient();
    mcpClient = mcpConnection.client;
    transport = mcpConnection.transport;

    // Get MCP tools and convert to llm_dart tools
    final mcpTools = await _getMcpToolsAsLlmDartTools(mcpClient);

    print('   🔧 Available HTTP MCP Tools:');
    for (final tool in mcpTools) {
      print('      • ${tool.function.name}: ${tool.function.description}');
    }

    // Create high-level language model with tools configured
    final model = await ai()
        .openai()
        .apiKey(apiKey)
        .model('gpt-4o-mini')
        .temperature(0.7)
        .tools(mcpTools)
        .buildLanguageModel();

    print('   🤖 Creating LLM model: OpenAI GPT-4o-mini');

    // Streaming conversation requesting current time
    final messages = <ModelMessage>[
      ModelMessage.systemText(
        'You are a helpful assistant. When users ask for time-related '
        'information, use the available tools to get accurate current time.',
      ),
      ModelMessage.userText(
        'Hi! Can you please tell me what time it is right now?',
      ),
    ];

    print('\n   💬 User Message:');
    print('      "Hi! Can you please tell me what time it is right now?"');
    print('\n   🤖 LLM Processing...');

    // Process the streaming response with detailed logging
    await _processStreamingToolUse(model, messages, mcpTools, mcpClient);

    print('\n   ✅ Streaming tool use demonstration successful\n');
  } catch (e) {
    print('   ❌ Streaming tool use failed: $e\n');
  } finally {
    // Clean up
    if (transport != null) {
      try {
        await transport.close();
        print('   🔌 HTTP MCP connection closed');
      } catch (e) {
        print('   ⚠️ Error closing transport: $e');
      }
    }
  }
}

/// Process streaming response with detailed tool use logging
Future<void> _processStreamingToolUse(
  LanguageModel model,
  List<ModelMessage> messages,
  List<Tool> tools,
  Client mcpClient,
) async {
  var conversation = List<ModelMessage>.from(messages);
  var initialResponseText = '';
  var hasToolCalls = false;
  final toolCalls = <ToolCall>[];

  print('   📡 Starting streaming request to LLM...');

  // First stream - get initial response and tool calls
  final initialPrompt = List<ModelMessage>.from(conversation);

  await for (final part in model.streamTextPartsWithOptions(
    initialPrompt,
    options: LanguageModelCallOptions(tools: tools),
  )) {
    switch (part) {
      case StreamTextStart():
        break;
      case StreamTextDelta(delta: final delta):
        initialResponseText += delta;
        break;
      case StreamThinkingDelta(delta: final delta):
        print('   🧠 Thinking: $delta');
        break;
      case StreamToolInputStart(
          toolCallId: final toolCallId,
          toolName: final toolName
        ):
        if (!hasToolCalls) {
          if (initialResponseText.isNotEmpty) {
            print('   🤖 LLM Initial Response: $initialResponseText');
          }
          print('\n   🔧 LLM requested tool calls:');
          hasToolCalls = true;
        }
        print('      📞 Function: $toolName');
        print('      🆔 Call ID: $toolCallId');
        break;
      case StreamToolInputDelta():
        // Skip detailed argument deltas for brevity
        break;
      case StreamToolInputEnd():
        break;
      case StreamToolCall(toolCall: final toolCall):
        print('      📋 Arguments: ${toolCall.function.arguments}');
        toolCalls.add(toolCall);
        break;
      case StreamTextEnd():
        break;
      case StreamFinish():
        break;
    }
  }

  if (hasToolCalls) {
    print('\n   🛠️  Executing MCP tools via HTTP...');

    // Execute tools with detailed logging and build structured tool messages
    final toolCallParts = <ChatContentPart>[];
    final toolResultParts = <ChatContentPart>[];

    for (int i = 0; i < toolCalls.length; i++) {
      final toolCall = toolCalls[i];
      print('      Step ${i + 1}: Executing ${toolCall.function.name}');

      // Append tool call content for the assistant message
      toolCallParts.add(
        ToolCallContentPart(
          toolName: toolCall.function.name,
          argumentsJson: toolCall.function.arguments,
          toolCallId: toolCall.id,
        ),
      );

      final result = await _executeMcpTool(
        mcpClient,
        toolCall.function.name,
        toolCall.function.arguments,
      );

      // Append tool result content for the user/tool result message
      toolResultParts.add(
        ToolResultContentPart(
          toolCallId: toolCall.id,
          toolName: toolCall.function.name,
          payload: ToolResultTextPayload(result),
        ),
      );
    }

    // Add tool calls and results to the conversation as structured messages
    conversation.addAll([
      ModelMessage(
        role: ChatRole.assistant,
        parts: toolCallParts,
      ),
      ModelMessage(
        role: ChatRole.user,
        parts: toolResultParts,
      ),
    ]);

    print('\n   🔄 Sending tool results back to LLM for final response...');
    print('   🤖 LLM Final Response:');
    stdout.write('      '); // Initial indentation for streaming text

    // Second stream - get final response with streaming output
    final finalPrompt = List<ModelMessage>.from(conversation);

    await for (final finalPart in model.streamTextPartsWithOptions(
      finalPrompt,
      options: LanguageModelCallOptions(tools: tools),
    )) {
      switch (finalPart) {
        case StreamTextDelta(delta: final delta):
          final indentedDelta = delta.replaceAll('\n', '\n      ');
          stdout.write(indentedDelta);
          break;
        case StreamFinish():
          print(''); // New line after streaming
          break;
        default:
          break;
      }
    }
  } else {
    // No tool calls, just print the response
    if (initialResponseText.isNotEmpty) {
      print('   🤖 LLM Response: $initialResponseText');
    }
  }
}

/// Connection result for MCP client
class McpConnection {
  final Client client;
  final StreamableHttpClientTransport transport;

  McpConnection(this.client, this.transport);
}

/// Create an HTTP MCP client connection
Future<McpConnection> _createHttpMcpClient() async {
  print('   🌐 Creating HTTP MCP client connection...');

  final client = Client(
    Implementation(name: "simple-stream-client", version: "1.0.0"),
  );

  // Set up error handler
  client.onerror = (error) {
    print('   ❌ MCP Client error: $error');
  };

  // Create HTTP transport
  final transport = StreamableHttpClientTransport(
    Uri.parse('http://localhost:3000/mcp'),
    opts: StreamableHttpClientTransportOptions(),
  );

  // Connect the client to the transport
  await client.connect(transport);
  print('   ✅ HTTP MCP client connected with session: ${transport.sessionId}');

  return McpConnection(client, transport);
}

/// Get MCP tools and convert them to llm_dart tools
Future<List<Tool>> _getMcpToolsAsLlmDartTools(Client mcpClient) async {
  try {
    final toolsResult = await mcpClient.listTools();
    final llmDartTools = <Tool>[];

    for (final mcpTool in toolsResult.tools) {
      // Convert MCP tool schema to ParametersSchema
      final parametersSchema =
          _convertMcpSchemaToParametersSchema(mcpTool.inputSchema.toJson());

      // Convert MCP tool to llm_dart tool
      final llmDartTool = Tool.function(
        name: mcpTool.name,
        description: mcpTool.description ?? 'MCP tool: ${mcpTool.name}',
        parameters: parametersSchema,
      );
      llmDartTools.add(llmDartTool);
    }

    return llmDartTools;
  } catch (error) {
    print('   ❌ Error getting MCP tools: $error');
    return [];
  }
}

/// Convert MCP input schema to llm_dart ParametersSchema
ParametersSchema _convertMcpSchemaToParametersSchema(
    Map<String, dynamic>? mcpSchema) {
  if (mcpSchema == null || mcpSchema.isEmpty) {
    return ParametersSchema(
      schemaType: 'object',
      properties: {},
      required: [],
    );
  }

  final properties = <String, ParameterProperty>{};
  final mcpProperties = mcpSchema['properties'] as Map<String, dynamic>? ?? {};

  for (final entry in mcpProperties.entries) {
    final propName = entry.key;
    final propDef = entry.value as Map<String, dynamic>;

    properties[propName] = ParameterProperty(
      propertyType: propDef['type'] as String? ?? 'string',
      description: propDef['description'] as String? ?? '',
    );
  }

  return ParametersSchema(
    schemaType: mcpSchema['type'] as String? ?? 'object',
    properties: properties,
    required: (mcpSchema['required'] as List<dynamic>?)?.cast<String>() ?? [],
  );
}

/// Execute an MCP tool and return the result as a string
Future<String> _executeMcpTool(
  Client mcpClient,
  String toolName,
  String argumentsJson,
) async {
  try {
    // Parse arguments from JSON string
    Map<String, dynamic> arguments = {};
    if (argumentsJson.isNotEmpty &&
        argumentsJson != '{}' &&
        argumentsJson.trim().isNotEmpty) {
      try {
        arguments = jsonDecode(argumentsJson) as Map<String, dynamic>;
      } catch (e) {
        print('         ⚠️ Error parsing JSON arguments: $e');
        print('         📋 Raw arguments: "$argumentsJson"');
      }
    }

    print('         📡 Executing MCP tool: $toolName');
    print('         📋 Arguments: $arguments');

    final result = await mcpClient.callTool(
      CallToolRequestParams(
        name: toolName,
        arguments: arguments,
      ),
    );

    // Convert result to string
    final resultText = result.content
        .whereType<TextContent>()
        .map((item) => item.text)
        .join('\n');

    print('         ✅ MCP tool result: $resultText');
    return resultText;
  } catch (error) {
    print('         ❌ Error executing MCP tool $toolName: $error');
    return 'Error: $error';
  }
}
