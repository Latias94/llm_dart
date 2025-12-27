// ignore_for_file: avoid_print
import 'dart:convert';
import 'dart:io';

import 'package:llm_dart_ai/llm_dart_ai.dart';
import 'package:llm_dart_builder/llm_dart_builder.dart';
import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_openai/llm_dart_openai.dart';
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

  registerOpenAI();

  final apiKey = Platform.environment['OPENAI_API_KEY'];
  if (apiKey == null || apiKey.isEmpty) {
    print('⚠️  Skipped: Please set OPENAI_API_KEY environment variable');
    return;
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
    final provider = await LLMBuilder()
        .provider(openaiProviderId)
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
  final conversation = List<ChatMessage>.from(messages);
  final toolSet = ToolSet(
    tools.map(
      (tool) => LocalTool(
        tool: tool,
        handler: (toolCall, {cancelToken}) async {
          return _executeMcpTool(
            mcpClient,
            toolCall.function.name,
            toolCall.function.arguments,
          );
        },
      ),
    ),
  );

  print('   📡 Starting streaming request to LLM...');
  print('   🤖 LLM Response:');
  stdout.write('      ');

  // Recommended: stream a tool loop as Vercel-style stream parts.
  await for (final part in streamToolLoopPartsWithToolSet(
    model: provider,
    messages: conversation,
    toolSet: toolSet,
  )) {
    switch (part) {
      case LLMTextDeltaPart(:final delta):
        stdout.write(delta.replaceAll('\n', '\n      '));
        break;

      case LLMToolCallStartPart(:final toolCall):
        stdout.writeln('\n\n   🔧 LLM requested tool call:');
        stdout.writeln('      📞 Function: ${toolCall.function.name}');
        stdout.writeln('      🆔 Call ID: ${toolCall.id}');
        break;

      case LLMToolCallDeltaPart(:final toolCall):
        if (toolCall.function.arguments.isNotEmpty) {
          stdout.writeln(
            '      📋 Arguments (delta): ${toolCall.function.arguments}',
          );
        }
        break;

      case LLMToolResultPart(:final result):
        stdout.writeln('\n   🛠️  MCP tool result:');
        stdout.writeln('      • toolCallId: ${result.toolCallId}');
        stdout.writeln('      • ok: ${!result.isError}');
        stdout.writeln('      • content: ${result.content}');
        stdout.writeln('\n   🤖 Continuing...\n');
        stdout.write('      ');
        break;

      case LLMFinishPart(:final response):
        stdout.writeln('\n\n✅ Done');
        final usage = response.usage;
        if (usage != null) {
          stdout.writeln('   📊 Usage: ${usage.totalTokens} tokens');
        }
        break;

      case LLMErrorPart(:final error):
        stdout.writeln('\n   ❌ Streaming error: $error');
        break;

      case LLMReasoningDeltaPart():
      case LLMTextStartPart():
      case LLMTextEndPart():
      case LLMReasoningStartPart():
      case LLMReasoningEndPart():
      case LLMToolCallEndPart():
      case LLMProviderMetadataPart():
        // Ignore for this demo.
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
