// ignore_for_file: avoid_print
import 'dart:convert';
import 'dart:io';
import 'package:llm_dart/llm_dart.dart';
import 'package:llm_dart_core/llm_dart_core.dart'
    show
        ChatContentPart,
        TextContentPart,
        ToolCallContentPart,
        ToolResultContentPart,
        ToolResultTextPayload;
import 'package:mcp_dart/mcp_dart.dart' hide Tool;

/// HTTP LLM Integration - Real AI Agents with HTTP MCP Tools
///
/// This example demonstrates how to integrate LLMs with MCP servers
/// using HTTP transport with streaming capabilities. The LLM can discover
/// and use tools from the HTTP MCP server through real MCP protocol.
///
/// Architecture:
/// LLM (OpenAI/etc) ↔ llm_dart ↔ Real MCP Client ↔ HTTP MCP Server ↔ Tools
///
/// Before running:
/// 1. Start the server: dart run http_examples/server.dart
/// 2. Set API key: export OPENAI_API_KEY="your-key-here"
/// 3. Run this: dart run 06_mcp_integration/http_examples/llm_client.dart
void main() async {
  print('🌐 HTTP LLM Integration - Real AI Agents with HTTP MCP Tools\n');

  // Get API key
  final apiKey = Platform.environment['OPENAI_API_KEY'] ?? 'sk-TESTKEY';
  if (apiKey == 'sk-TESTKEY') {
    print(
        '⚠️  Warning: Using test API key. Set OPENAI_API_KEY for real usage.\n');
  }

  await demonstrateBasicHttpIntegration(apiKey);
  await demonstrateHttpStreamingWorkflow(apiKey);
  await demonstrateHttpSessionManagement(apiKey);

  print('\n✅ HTTP LLM integration examples completed!');
  print('🚀 You can now build web-based AI agents that use HTTP MCP tools!');

  // Ensure the program exits cleanly
  exit(0);
}

/// Helper to build an assistant message that includes tool call parts.
ModelMessage _assistantWithToolCalls(String? text, List<ToolCall> toolCalls) {
  final parts = <ChatContentPart>[];
  if (text != null && text.isNotEmpty) {
    parts.add(TextContentPart(text));
  }
  for (final call in toolCalls) {
    parts.add(
      ToolCallContentPart(
        toolName: call.function.name,
        argumentsJson: call.function.arguments,
        toolCallId: call.id,
      ),
    );
  }
  return ModelMessage(role: ChatRole.assistant, parts: parts);
}

/// Helper to build a tool result message from a tool call and text result.
ModelMessage _toolResultMessage(ToolCall toolCall, String result) {
  return ModelMessage(
    role: ChatRole.assistant,
    parts: [
      ToolResultContentPart(
        toolCallId: toolCall.id,
        toolName: toolCall.function.name,
        payload: ToolResultTextPayload(result),
      ),
    ],
  );
}

/// Demonstrate basic HTTP MCP + LLM integration
Future<void> demonstrateBasicHttpIntegration(String apiKey) async {
  print('🔗 Basic HTTP MCP + LLM Integration:\n');

  Client? mcpClient;
  StreamableHttpClientTransport? transport;

  try {
    // Create high-level language model (prompt-first, Vercel-style)
    final model = await ai()
        .openai()
        .apiKey(apiKey)
        .model('gpt-4o-mini')
        .temperature(0.7)
        .buildLanguageModel();

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

    // Test with a greeting and calculation request
    const userMessage =
        'Please greet me as "Alice" and then calculate 18 * 24 + 6.';
    final prompt = ChatPromptBuilder.user().text(userMessage).build();

    // Print actual user message
    print('   💬 User Message:');
    print('      "$userMessage"');
    print('   🤖 LLM: Processing request with HTTP MCP tools...');

    // First pass: let the model plan and emit tool calls.
    final result = await generateTextWithModel(
      model,
      promptMessages: [prompt],
      options: LanguageModelCallOptions(tools: mcpTools),
    );

    final toolCalls = result.toolCalls ?? const <ToolCall>[];

    if (toolCalls.isNotEmpty) {
      print('   🤖 LLM: Requested ${toolCalls.length} tool call(s):');

      // Execute MCP tools and collect results
      final toolResultCalls = <ToolCall>[];
      for (int i = 0; i < toolCalls.length; i++) {
        final toolCall = toolCalls[i];
        print('      ${i + 1}. 🛠️  Tool Call:');
        print('         📞 Function: ${toolCall.function.name}');
        print('         📋 Arguments: ${toolCall.function.arguments}');
        print('         🆔 Call ID: ${toolCall.id}');

        // Execute the MCP tool via HTTP
        final mcpResult = await _executeMcpTool(
          mcpClient,
          toolCall.function.name,
          toolCall.function.arguments,
        );

        // Create tool result call
        toolResultCalls.add(ToolCall(
          id: toolCall.id,
          callType: 'function',
          function: FunctionCall(
            name: toolCall.function.name,
            arguments: mcpResult,
          ),
        ));
      }

      // Build prompt-first conversation with tool calls and results.
      final conversation = <ModelMessage>[
        prompt,
        _assistantWithToolCalls(result.text, toolCalls),
      ];

      for (final toolCall in toolResultCalls) {
        conversation
            .add(_toolResultMessage(toolCall, toolCall.function.arguments));
      }

      // Send tool results back to LLM for final response using ModelMessage
      print('   🔄 Sending MCP results back to LLM for final response...');
      final finalResult = await generateTextWithModel(
        model,
        promptMessages: conversation,
      );

      print('   📝 LLM Final Response: ${finalResult.text}');
    } else {
      print('   📝 LLM Response: ${result.text}');
    }
    print('   ✅ Basic HTTP integration successful\n');
  } catch (e) {
    print('   ❌ Basic HTTP integration failed: $e\n');
  } finally {
    // Clean up
    if (transport != null) {
      try {
        await transport.close();
      } catch (e) {
        print('   ⚠️ Error closing transport: $e');
      }
    }
  }
}

/// Demonstrate HTTP streaming workflow
Future<void> demonstrateHttpStreamingWorkflow(String apiKey) async {
  print('🌊 HTTP Streaming Workflow:\n');

  Client? mcpClient;
  StreamableHttpClientTransport? transport;

  try {
    final model = await ai()
        .openai()
        .apiKey(apiKey)
        .model('gpt-4o-mini')
        .temperature(0.3)
        .buildLanguageModel();

    // Create MCP client for HTTP server
    final mcpConnection = await _createHttpMcpClient();
    mcpClient = mcpConnection.client;
    transport = mcpConnection.transport;

    // Get MCP tools and convert to llm_dart tools
    final mcpTools = await _getMcpToolsAsLlmDartTools(mcpClient);

    // Set up notification handler to capture streaming notifications
    int notificationCount = 0;
    mcpClient.setNotificationHandler("notifications/message",
        (notification) async {
      notificationCount++;
      final params = notification.logParams;
      print(
          '   📡 Streaming Notification #$notificationCount: ${params.level} - ${params.data}');
      return Future.value();
    },
        (params, meta) => JsonRpcLoggingMessageNotification.fromJson({
              'params': params,
              if (meta != null) '_meta': meta,
            }));

    // Streaming workflow request (prompt-first)
    const systemPrompt =
        'You are a friendly assistant that can use streaming tools. '
        'Use the multi-greet tool to send personalized greetings.';
    const userPrompt =
        'Please use the multi-greet tool to greet me as "Charlie" with multiple messages.';

    final prompts = <ModelMessage>[
      ChatPromptBuilder.system().text(systemPrompt).build(),
      ChatPromptBuilder.user().text(userPrompt).build(),
    ];

    // Print actual user message
    print('   💬 User Message:');
    print('      "$userPrompt"');
    print('   🤖 LLM: Initiating HTTP streaming workflow...');

    final response = await generateTextWithModel(
      model,
      promptMessages: prompts,
      options: LanguageModelCallOptions(tools: mcpTools),
    );

    print('   📋 HTTP streaming execution:');
    if (response.toolCalls != null && response.toolCalls!.isNotEmpty) {
      // Execute MCP tools and collect results
      final toolResultCalls = <ToolCall>[];
      for (int i = 0; i < response.toolCalls!.length; i++) {
        final toolCall = response.toolCalls![i];
        print('      Step ${i + 1}: 🛠️  Tool Call:');
        print('         📞 Function: ${toolCall.function.name}');
        print('         📋 Arguments: ${toolCall.function.arguments}');
        print('         🆔 Call ID: ${toolCall.id}');

        final mcpResult = await _executeMcpTool(
          mcpClient,
          toolCall.function.name,
          toolCall.function.arguments,
        );
        print(
            '         📡 SSE: Real-time notifications received during execution');

        // Create tool result call
        toolResultCalls.add(ToolCall(
          id: toolCall.id,
          callType: 'function',
          function: FunctionCall(
            name: toolCall.function.name,
            arguments: mcpResult,
          ),
        ));
      }

      // Send tool results back to LLM for final response (prompt-first)
      print(
          '   🔄 Sending MCP results back to LLM for streaming final response...');
      final conversation = <ModelMessage>[
        ...prompts,
        _assistantWithToolCalls(response.text, response.toolCalls!),
      ];

      for (final toolCall in toolResultCalls) {
        conversation
            .add(_toolResultMessage(toolCall, toolCall.function.arguments));
      }

      final finalResult = await generateTextWithModel(
        model,
        promptMessages: conversation,
      );
      print('   📝 Final Response: ${finalResult.text}');
    } else {
      print('   📝 Final Response: ${response.text}');
    }
    print(
        '   ✅ HTTP streaming workflow successful with $notificationCount notifications\n');
  } catch (e) {
    print('   ❌ HTTP streaming workflow failed: $e\n');
  } finally {
    // Clean up
    if (transport != null) {
      try {
        await transport.close();
      } catch (e) {
        print('   ⚠️ Error closing transport: $e');
      }
    }
  }
}

/// Demonstrate HTTP session management
Future<void> demonstrateHttpSessionManagement(String apiKey) async {
  print('🆔 HTTP Session Management:\n');

  Client? mcpClient;
  StreamableHttpClientTransport? transport;

  try {
    final model = await ai()
        .openai()
        .apiKey(apiKey)
        .model('gpt-4o-mini')
        .temperature(0.2)
        .buildLanguageModel();

    // Create MCP client for HTTP server
    final mcpConnection = await _createHttpMcpClient();
    mcpClient = mcpConnection.client;
    transport = mcpConnection.transport;

    // Get MCP tools and convert to llm_dart tools
    final mcpTools = await _getMcpToolsAsLlmDartTools(mcpClient);

    // Session-based workflow request (prompt-first)
    const systemPrompt =
        'You are a session-aware assistant. Use tools to demonstrate session management.';
    const userPrompt =
        'Please: 1) Generate a UUID for this session, 2) Get the current time, '
        '3) Calculate 7 * 9, and 4) Greet me as "Session User".';

    final prompts = <ModelMessage>[
      ChatPromptBuilder.system().text(systemPrompt).build(),
      ChatPromptBuilder.user().text(userPrompt).build(),
    ];

    // Print actual user message
    print('   💬 User Message:');
    print('      "$userPrompt"');
    print('   🤖 LLM: Processing request with HTTP MCP tools...');
    print('   🆔 Session ID: ${transport.sessionId}');

    final response = await generateTextWithModel(
      model,
      promptMessages: prompts,
      options: LanguageModelCallOptions(tools: mcpTools),
    );

    print('   📋 Session-managed workflow via HTTP:');
    if (response.toolCalls != null && response.toolCalls!.isNotEmpty) {
      // Execute MCP tools and collect results
      final toolResultCalls = <ToolCall>[];
      for (int i = 0; i < response.toolCalls!.length; i++) {
        final toolCall = response.toolCalls![i];
        print('      Step ${i + 1}: 🛠️  Tool Call:');
        print('         📞 Function: ${toolCall.function.name}');
        print('         📋 Arguments: ${toolCall.function.arguments}');
        print('         🆔 Call ID: ${toolCall.id}');
        print('         🌐 Session: HTTP session ${transport.sessionId}');

        final mcpResult = await _executeMcpTool(
          mcpClient,
          toolCall.function.name,
          toolCall.function.arguments,
        );

        // Create tool result call
        toolResultCalls.add(ToolCall(
          id: toolCall.id,
          callType: 'function',
          function: FunctionCall(
            name: toolCall.function.name,
            arguments: mcpResult,
          ),
        ));
      }

      // Send tool results back to LLM for final response (prompt-first)
      print(
          '   🔄 Sending MCP results back to LLM for session final response...');
      final conversation = <ModelMessage>[
        ...prompts,
        _assistantWithToolCalls(response.text, response.toolCalls!),
      ];

      for (final toolCall in toolResultCalls) {
        conversation
            .add(_toolResultMessage(toolCall, toolCall.function.arguments));
      }

      final finalResult = await generateTextWithModel(
        model,
        promptMessages: conversation,
      );
      print('   📝 Final Response: ${finalResult.text}');
    } else {
      print('   📝 Final Response: ${response.text}');
    }
    print('   ✅ HTTP session management successful\n');
  } catch (e) {
    print('   ❌ HTTP session management failed: $e\n');
  } finally {
    // Clean up
    if (transport != null) {
      try {
        await transport.close();
      } catch (e) {
        print('   ⚠️ Error closing transport: $e');
      }
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
    Implementation(name: "http-llm-client", version: "1.0.0"),
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
    if (argumentsJson.isNotEmpty && argumentsJson != '{}') {
      try {
        // Use proper JSON parsing
        arguments = jsonDecode(argumentsJson) as Map<String, dynamic>;
      } catch (e) {
        print('   ⚠️ Error parsing JSON arguments: $e, using empty args');
        print('   📋 Raw arguments: $argumentsJson');
      }
    }

    print('         📡 Executing MCP tool: $toolName with args: $arguments');

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

/// 🎯 Key HTTP Integration Concepts:
///
/// HTTP MCP Benefits:
/// - Web-compatible transport protocol
/// - Session management with unique IDs
/// - Real-time notifications via SSE
/// - Concurrent multi-client support
/// - RESTful API design patterns
/// - Scalable cloud deployment
///
/// HTTP Integration Pattern:
/// 1. Create HTTP client transport with server URL
/// 2. Initialize session with unique session ID
/// 3. Send JSON-RPC messages via POST requests
/// 4. Receive real-time notifications via SSE
/// 5. Discover and convert tools to llm_dart format
/// 6. Integrate with LLM tool calling system
/// 7. Clean up session when done
///
/// Best Practices:
/// 1. Handle HTTP errors and implement retries
/// 2. Manage session IDs consistently across requests
/// 3. Implement proper SSE event handling
/// 4. Use appropriate request timeouts
/// 5. Clean up sessions and connections properly
/// 6. Monitor server health and connectivity
///
/// Use Cases:
/// - Web-based AI assistants
/// - Browser-integrated AI tools
/// - Microservice AI architectures
/// - Cloud-deployed AI services
/// - Real-time collaborative AI applications
/// - Multi-user AI platforms
///
/// Next Steps:
/// - Implement real HTTP transport connection
/// - Add proper session management
/// - Build web frontend integration
/// - Deploy to cloud infrastructure
/// - Add authentication and security
/// - Monitor performance and scaling
