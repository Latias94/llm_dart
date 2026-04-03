// ignore_for_file: avoid_print
import 'dart:io';
import 'dart:convert';
import 'package:llm_dart/legacy.dart';
import 'package:mcp_dart/mcp_dart.dart' hide Tool;

/// stdio LLM Integration - AI Agents with stdio MCP Tools
///
/// This example demonstrates how to integrate LLMs with MCP servers
/// using stdio transport. The LLM can discover and use tools from
/// the stdio MCP server through real MCP client-server communication.
///
/// Architecture:
/// LLM (OpenAI/etc) ↔ llm_dart ↔ Real MCP Client ↔ stdio MCP Server ↔ Tools
///
/// Before running:
/// 1. Start the MCP server: dart run example/06_mcp_integration/stdio_examples/server.dart
/// 2. Set API key: export OPENAI_API_KEY="your-key-here"
/// 3. Run this client: dart run example/06_mcp_integration/stdio_examples/llm_client.dart
void main() async {
  print('🤖 stdio LLM Integration - AI Agents with Real stdio MCP Tools\n');

  // Get API key
  final apiKey = Platform.environment['OPENAI_API_KEY'] ?? 'sk-TESTKEY';
  if (apiKey == 'sk-TESTKEY') {
    print(
        '⚠️  Warning: Using test API key. Set OPENAI_API_KEY for real usage.\n');
  }

  await demonstrateBasicStdioIntegration(apiKey);
  await demonstrateStdioCalculationWorkflow(apiKey);
  await demonstrateStdioMultiToolWorkflow(apiKey);

  print('\n✅ stdio LLM integration examples completed!');
  print('🚀 You can now build AI agents that use real stdio MCP tools!');
}

/// Demonstrate basic stdio MCP + LLM integration
Future<void> demonstrateBasicStdioIntegration(String apiKey) async {
  print('🔗 Basic stdio MCP + LLM Integration:\n');

  Client? mcpClient;
  try {
    // Create LLM provider
    final llmProvider = await ai()
        .openai()
        .apiKey(apiKey)
        .model('gpt-4o-mini')
        .temperature(0.7)
        .build();

    // Create real MCP client connected to stdio server
    mcpClient = await _createRealStdioMcpClient();

    // Get MCP tools from real server
    final mcpTools = await _getMcpToolsAsLlmDartTools(mcpClient);

    print('   🔧 Available stdio MCP Tools:');
    for (final tool in mcpTools) {
      print('      • ${tool.function.name}: ${tool.function.description}');
    }

    // Test with a simple calculation request
    final messages = [
      ChatMessage.user('Calculate 25 * 8 + 12 using the available tools.')
    ];

    // Print actual user message
    print('   💬 User Message:');
    print('      "${messages.last.content}"');
    print('   🤖 LLM: Analyzing request and selecting appropriate tools...');

    final response = await llmProvider.chatWithTools(messages, mcpTools);

    if (response.toolCalls != null && response.toolCalls!.isNotEmpty) {
      print('   🤖 LLM: Requested ${response.toolCalls!.length} tool call(s):');

      // Execute MCP tools and collect results
      final toolResultCalls = <ToolCall>[];
      for (int i = 0; i < response.toolCalls!.length; i++) {
        final toolCall = response.toolCalls![i];
        print('      ${i + 1}. 🛠️  Tool Call:');
        print('         📞 Function: ${toolCall.function.name}');
        print('         📋 Arguments: ${toolCall.function.arguments}');
        print('         🆔 Call ID: ${toolCall.id}');

        // Execute the MCP tool via real stdio client
        final mcpResult = await _executeRealMcpTool(
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

      // Send tool results back to LLM for final response
      print('   🔄 Sending MCP results back to LLM for final response...');
      final finalMessages = [
        ...messages,
        ChatMessage.toolUse(toolCalls: response.toolCalls!),
        ChatMessage.toolResult(results: toolResultCalls),
      ];

      final finalResponse = await llmProvider.chat(finalMessages);
      print('   📝 LLM Final Response: ${finalResponse.text}');
    } else {
      print('   📝 LLM Response: ${response.text}');
    }
    print('   ✅ Basic stdio integration successful\n');
  } catch (e) {
    print('   ❌ Basic stdio integration failed: $e\n');
  } finally {
    await mcpClient?.close();
  }
}

/// Demonstrate stdio calculation workflow
Future<void> demonstrateStdioCalculationWorkflow(String apiKey) async {
  print('🧮 stdio Calculation Workflow:\n');

  Client? mcpClient;
  try {
    final provider = await ai()
        .openai()
        .apiKey(apiKey)
        .model('gpt-4o-mini')
        .temperature(0.3)
        .build();

    // Create real MCP client connected to stdio server
    mcpClient = await _createRealStdioMcpClient();
    final mcpTools = await _getMcpToolsAsLlmDartTools(mcpClient);

    // Mathematical workflow request
    final messages = [
      ChatMessage.system(
          'You are a math assistant that can use calculation tools. '
          'The calculation tool supports basic operations: +, -, *, /. '
          'It does NOT support ^ (power), pi, sqrt, or other advanced functions. '
          'Use only basic arithmetic operations and break down complex calculations into simple steps.'),
      ChatMessage.user(
          'I need to calculate the area of a circle with radius 7 (use 3.14159 for pi), '
          'then find what percentage that area is of a square with side length 20. '
          'Please use only basic arithmetic operations (+, -, *, /) in your calculations.'),
    ];

    // Print actual user message
    print('   💬 User Message:');
    print('      "${messages.last.content}"');
    print('   🤖 LLM: Breaking down the mathematical workflow...');

    final response = await provider.chatWithTools(messages, mcpTools);

    print('   📋 stdio calculation workflow execution:');
    if (response.toolCalls != null && response.toolCalls!.isNotEmpty) {
      // Execute MCP tools and collect results
      final toolResultCalls = <ToolCall>[];
      for (int i = 0; i < response.toolCalls!.length; i++) {
        final toolCall = response.toolCalls![i];
        print('      Step ${i + 1}: 🛠️  Tool Call:');
        print('         📞 Function: ${toolCall.function.name}');
        print('         📋 Arguments: ${toolCall.function.arguments}');
        print('         🆔 Call ID: ${toolCall.id}');

        final mcpResult = await _executeRealMcpTool(
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

      // Send tool results back to LLM for final response
      print(
          '   🔄 Sending MCP results back to LLM for calculation final response...');
      final finalMessages = [
        ...messages,
        ChatMessage.toolUse(toolCalls: response.toolCalls!),
        ChatMessage.toolResult(results: toolResultCalls),
      ];

      final finalResponse = await provider.chat(finalMessages);
      print('   📝 Final Response: ${finalResponse.text}');
    } else {
      print('   📝 Final Response: ${response.text}');
    }
    print('   ✅ stdio calculation workflow successful\n');
  } catch (e) {
    print('   ❌ stdio calculation workflow failed: $e\n');
  } finally {
    await mcpClient?.close();
  }
}

/// Demonstrate multi-tool workflow with stdio
Future<void> demonstrateStdioMultiToolWorkflow(String apiKey) async {
  print('⚡ stdio Multi-Tool Workflow:\n');

  Client? mcpClient;
  try {
    final provider = await ai()
        .openai()
        .apiKey(apiKey)
        .model('gpt-4o-mini')
        .temperature(0.2)
        .build();

    // Create real MCP client connected to stdio server
    mcpClient = await _createRealStdioMcpClient();
    final mcpTools = await _getMcpToolsAsLlmDartTools(mcpClient);

    // Multi-tool request
    final messages = [
      ChatMessage.system(
          'You are a helpful assistant that can use various tools. '
          'The calculation tool supports basic operations: +, -, *, /. '
          'Use multiple tools to gather information and provide comprehensive answers. '
          'Always use the calculation tool for mathematical operations.'),
      ChatMessage.user(
          'Please: 1) Get the current time, 2) Generate a random number between 1-10, '
          '3) Use the calculation tool to calculate that number squared (multiply the number by itself), and 4) Generate a UUID for this session.'),
    ];

    // Print actual user message
    print('   💬 User Message:');
    print('      "${messages.last.content}"');
    print('   🤖 LLM: Planning multi-tool workflow via stdio...');

    final response = await provider.chatWithTools(messages, mcpTools);

    print('   📋 Multi-tool workflow execution via stdio:');
    if (response.toolCalls != null && response.toolCalls!.isNotEmpty) {
      // Execute MCP tools and collect results
      final toolResultCalls = <ToolCall>[];
      for (int i = 0; i < response.toolCalls!.length; i++) {
        final toolCall = response.toolCalls![i];
        print('      Step ${i + 1}: 🛠️  Tool Call:');
        print('         📞 Function: ${toolCall.function.name}');
        print('         📋 Arguments: ${toolCall.function.arguments}');
        print('         🆔 Call ID: ${toolCall.id}');

        final mcpResult = await _executeRealMcpTool(
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

      // Send tool results back to LLM for final response
      print(
          '   🔄 Sending MCP results back to LLM for multi-tool final response...');
      final finalMessages = [
        ...messages,
        ChatMessage.toolUse(toolCalls: response.toolCalls!),
        ChatMessage.toolResult(results: toolResultCalls),
      ];

      final finalResponse = await provider.chat(finalMessages);
      print('   📝 Final Response: ${finalResponse.text}');
    } else {
      print('   📝 Final Response: ${response.text}');
    }
    print('   ✅ stdio multi-tool workflow successful\n');
  } catch (e) {
    print('   ❌ stdio multi-tool workflow failed: $e\n');
  } finally {
    await mcpClient?.close();
  }
}

/// Create real MCP client connected to stdio server
Future<Client> _createRealStdioMcpClient() async {
  print('   🔌 Creating real stdio MCP client...');

  // Define the server executable and arguments
  const serverCommand = 'dart';
  const serverArgs = <String>[
    'run',
    'example/06_mcp_integration/stdio_examples/server.dart'
  ];

  // Create StdioServerParameters
  final serverParams = StdioServerParameters(
    command: serverCommand,
    args: serverArgs,
    stderrMode: ProcessStartMode.normal,
  );

  // Create the StdioClientTransport
  final transport = StdioClientTransport(serverParams);

  // Define client information
  final clientInfo =
      Implementation(name: 'LlmDartStdioClient', version: '1.0.0');

  // Create the MCP client
  final client = Client(clientInfo);

  // Set up error and close handlers
  transport.onerror = (error) {
    print('   ❌ MCP Transport error: $error');
  };

  transport.onclose = () {
    print('   🔌 MCP Transport closed');
  };

  // Connect to the server
  print('   🔗 Connecting to stdio MCP server...');
  await client.connect(transport);
  print('   ✅ Connected to stdio MCP server');

  return client;
}

/// Get MCP tools from real server and convert to llm_dart tools
Future<List<Tool>> _getMcpToolsAsLlmDartTools(Client mcpClient) async {
  print('   🔍 Discovering MCP tools from real server...');

  try {
    // Get tools from real MCP server
    final toolsResponse = await mcpClient.listTools();
    final mcpTools = toolsResponse.tools;

    print('   ✅ Discovered ${mcpTools.length} MCP tools');

    // Convert MCP tools to llm_dart tools
    final llmDartTools = <Tool>[];

    for (final mcpTool in mcpTools) {
      try {
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
      } catch (e) {
        print('   ⚠️ Failed to convert tool ${mcpTool.name}: $e');
      }
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

/// Execute MCP tool via real client and return result
Future<String> _executeRealMcpTool(
    Client mcpClient, String toolName, dynamic arguments) async {
  try {
    print('      🔧 MCP: Executing real tool "$toolName"');
    print('         📥 MCP Args: ${jsonEncode(arguments)}');

    // Parse arguments from JSON string
    Map<String, dynamic> parsedArguments = {};
    if (arguments is String && arguments.isNotEmpty && arguments != '{}') {
      try {
        parsedArguments = jsonDecode(arguments) as Map<String, dynamic>;
      } catch (e) {
        print('         ⚠️ Error parsing JSON arguments: $e, using empty args');
        print('         📋 Raw arguments: $arguments');
      }
    } else if (arguments is Map<String, dynamic>) {
      parsedArguments = arguments;
    }

    print(
        '         📡 Executing MCP tool: $toolName with args: $parsedArguments');

    // Execute real MCP tool
    final result = await mcpClient.callTool(
      CallToolRequestParams(
        name: toolName,
        arguments: parsedArguments,
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

/// 🎯 Key stdio Integration Concepts:
///
/// stdio MCP Benefits:
/// - Simple process-based architecture
/// - Easy to debug and monitor
/// - Natural fit for local AI tools
/// - Minimal network overhead
///
/// stdio Integration Pattern:
/// 1. Spawn MCP server process
/// 2. Create stdio transport connection
/// 3. Initialize MCP client with transport
/// 4. Discover and convert tools
/// 5. Integrate with LLM tool calling
///
/// Best Practices:
/// 1. Handle server process lifecycle properly
/// 2. Implement proper error handling and recovery
/// 3. Monitor server stderr for debugging
/// 4. Use timeouts for tool execution
/// 5. Clean up processes on exit
///
/// Use Cases:
/// - Local AI assistants
/// - Development and testing tools
/// - Command-line AI applications
/// - Educational examples
/// - Simple automation scripts
///
/// Next Steps:
/// - Implement real stdio transport connection
/// - Add process management utilities
/// - Try HTTP examples for web scenarios
/// - Build production CLI tools
