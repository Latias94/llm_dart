// ignore_for_file: avoid_print
import 'dart:convert';
import 'dart:io';
import 'package:llm_dart/llm_dart.dart';
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
/// 3. Run this: dart run example/06_mcp_integration/http_examples/simple_stream_client.dart
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
    // Create streaming LLM provider
    final provider = await ai()
        .openai()
        .apiKey(apiKey)
        .model('gpt-4o-mini')
        .temperature(0.7)
        .build();

    print('   🤖 Creating LLM provider: OpenAI GPT-4o-mini');

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

    // Streaming conversation requesting current time
    final messages = [
      ChatMessage.system(
          'You are a helpful assistant. When users ask for time-related information, use the available tools to get accurate current time.'),
      ChatMessage.user('Hi! Can you please tell me what time it is right now?'),
    ];

    print('\n   💬 User Message:');
    print('      "${messages.last.content}"');
    print('\n   🤖 LLM Processing...');

    // Process the streaming response with detailed logging
    await _processStreamingToolUse(provider, messages, mcpTools, mcpClient);

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
  ChatCapability provider,
  List<ChatMessage> messages,
  List<Tool> tools,
  Client mcpClient,
) async {
  var conversation = List<ChatMessage>.from(messages);
  var toolCallsCollected = <ToolCall>[];
  var hasToolCalls = false;
  var initialResponseText = '';

  print('   📡 Starting streaming request to LLM...');

  // First stream - get initial response and tool calls
  await for (final event in provider.chatStream(conversation, tools: tools)) {
    switch (event) {
      case TextDeltaEvent(delta: final delta):
        initialResponseText += delta;
        // Don't print yet, wait to see if there are tool calls
        break;

      case ToolCallDeltaEvent(toolCall: final toolCall):
        if (!hasToolCalls) {
          // If we have initial text, print it first
          if (initialResponseText.isNotEmpty) {
            print('   🤖 LLM Initial Response: $initialResponseText');
          }
          print('\n   🔧 LLM requested tool calls:');
          hasToolCalls = true;
        }
        print('      📞 Function: ${toolCall.function.name}');
        print('      📋 Arguments: ${toolCall.function.arguments}');
        print('      🆔 Call ID: ${toolCall.id}');
        toolCallsCollected.add(toolCall);
        break;

      case CompletionEvent():
        if (hasToolCalls) {
          print('\n   🛠️  Executing MCP tools via HTTP...');

          // Execute tools with detailed logging
          final toolResults = <ToolCall>[];
          for (int i = 0; i < toolCallsCollected.length; i++) {
            final toolCall = toolCallsCollected[i];
            print('      Step ${i + 1}: Executing ${toolCall.function.name}');

            final result = await _executeMcpTool(
              mcpClient,
              toolCall.function.name,
              toolCall.function.arguments,
            );

            toolResults.add(ToolCall(
              id: toolCall.id,
              callType: 'function',
              function: FunctionCall(
                name: toolCall.function.name,
                arguments: result,
              ),
            ));
          }

          // Add tool results to conversation
          conversation.addAll([
            ChatMessage.toolUse(toolCalls: toolCallsCollected),
            ChatMessage.toolResult(results: toolResults),
          ]);

          print('\n   🔄 Sending tool results back to LLM for final response...');
          print('   🤖 LLM Final Response:');
          stdout.write('      '); // Initial indentation for streaming text

          // Second stream - get final response with streaming output
          await for (final finalEvent in provider.chatStream(conversation)) {
            switch (finalEvent) {
              case TextDeltaEvent(delta: final delta):
                // Replace newlines with indented newlines to maintain formatting
                final indentedDelta = delta.replaceAll('\n', '\n      ');
                stdout.write(indentedDelta);
                break;
              case CompletionEvent():
                print(''); // New line after streaming
                break;
              case ErrorEvent(error: final error):
                print('\n   ❌ Final response error: $error');
                break;
              case ToolCallDeltaEvent():
              case ThinkingDeltaEvent():
                // Handle other events if needed
                break;
            }
          }
        } else {
          // No tool calls, just print the response
          if (initialResponseText.isNotEmpty) {
            print('   🤖 LLM Response: $initialResponseText');
          }
        }
        break;

      case ErrorEvent(error: final error):
        print('\n   ❌ Streaming error: $error');
        break;

      case ThinkingDeltaEvent(delta: final delta):
        print('   🧠 Thinking: $delta');
        break;
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
    if (argumentsJson.isNotEmpty && argumentsJson != '{}' && argumentsJson.trim().isNotEmpty) {
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
