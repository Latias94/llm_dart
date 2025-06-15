// ignore_for_file: avoid_print
import 'dart:io';
import 'package:llm_dart/llm_dart.dart';
import 'package:mcp_dart/mcp_dart.dart' hide Tool;
import '../shared/mcp_tool_bridge.dart';

/// stdio LLM Integration - AI Agents with stdio MCP Tools
///
/// This example demonstrates how to integrate LLMs with MCP servers
/// using stdio transport. The LLM can discover and use tools from
/// the stdio MCP server through the MCP bridge.
///
/// Architecture:
/// LLM (OpenAI/etc) ↔ llm_dart ↔ MCP Bridge ↔ stdio MCP Server ↔ Tools
///
/// Before running:
/// export OPENAI_API_KEY="your-key-here"
/// dart run example/06_mcp_integration/stdio_examples/llm_integration.dart
void main() async {
  print('🤖 stdio LLM Integration - AI Agents with stdio MCP Tools\n');

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
  print('🚀 You can now build AI agents that use stdio MCP tools!');
}

/// Demonstrate basic stdio MCP + LLM integration
Future<void> demonstrateBasicStdioIntegration(String apiKey) async {
  print('🔗 Basic stdio MCP + LLM Integration:\n');

  try {
    // Create LLM provider
    final llmProvider = await ai()
        .openai()
        .apiKey(apiKey)
        .model('gpt-4o-mini')
        .temperature(0.7)
        .build();

    // Create MCP bridge for stdio server
    final mcpBridge = await _createStdioMcpBridge();

    // Get MCP tools as llm_dart tools
    final mcpTools = mcpBridge.convertToLlmDartTools();

    print('   🔧 Available stdio MCP Tools:');
    for (final tool in mcpTools) {
      print('      • ${tool.function.name}: ${tool.function.description}');
    }

    // Create enhanced tools that bridge to MCP
    final enhancedTools = _createEnhancedTools(mcpBridge, mcpTools);

    // Test with a simple calculation request
    final messages = [
      ChatMessage.user('Calculate 25 * 8 + 12 using the available tools.')
    ];

    // Print actual user message
    print('   💬 User Message:');
    print('      "${messages.last.content}"');
    print('   🤖 LLM: Analyzing request and selecting appropriate tools...');

    final response = await llmProvider.chatWithTools(messages, enhancedTools);

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

        // Execute the MCP tool via stdio
        final mcpResult = await mcpBridge.executeMcpTool(
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

    await mcpBridge.close();
  } catch (e) {
    print('   ❌ Basic stdio integration failed: $e\n');
  }
}

/// Demonstrate stdio calculation workflow
Future<void> demonstrateStdioCalculationWorkflow(String apiKey) async {
  print('🧮 stdio Calculation Workflow:\n');

  try {
    final provider = await ai()
        .openai()
        .apiKey(apiKey)
        .model('gpt-4o-mini')
        .temperature(0.3)
        .build();

    final mcpBridge = await _createStdioMcpBridge();
    final mcpTools = mcpBridge.convertToLlmDartTools();
    final enhancedTools = _createEnhancedTools(mcpBridge, mcpTools);

    // Mathematical workflow request
    final messages = [
      ChatMessage.system(
          'You are a math assistant that can use calculation tools. '
          'Break down complex problems into steps and use tools for each calculation.'),
      ChatMessage.user(
          'I need to calculate the area of a circle with radius 7, '
          'then find what percentage that area is of a square with side length 20.'),
    ];

    // Print actual user message
    print('   💬 User Message:');
    print('      "${messages.last.content}"');
    print('   🤖 LLM: Breaking down the mathematical workflow...');

    final response = await provider.chatWithTools(messages, enhancedTools);

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

        final mcpResult = await mcpBridge.executeMcpTool(
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

    await mcpBridge.close();
  } catch (e) {
    print('   ❌ stdio calculation workflow failed: $e\n');
  }
}

/// Demonstrate multi-tool workflow with stdio
Future<void> demonstrateStdioMultiToolWorkflow(String apiKey) async {
  print('⚡ stdio Multi-Tool Workflow:\n');

  try {
    final provider = await ai()
        .openai()
        .apiKey(apiKey)
        .model('gpt-4o-mini')
        .temperature(0.2)
        .build();

    final mcpBridge = await _createStdioMcpBridge();
    final mcpTools = mcpBridge.convertToLlmDartTools();
    final enhancedTools = _createEnhancedTools(mcpBridge, mcpTools);

    // Multi-tool request
    final messages = [
      ChatMessage.system(
          'You are a helpful assistant that can use various tools. '
          'Use multiple tools to gather information and provide comprehensive answers.'),
      ChatMessage.user(
          'Please: 1) Get the current time, 2) Generate a random number between 1-10, '
          '3) Calculate that number squared, and 4) Generate a UUID for this session.'),
    ];

    // Print actual user message
    print('   💬 User Message:');
    print('      "${messages.last.content}"');
    print('   🤖 LLM: Planning multi-tool workflow via stdio...');

    final response = await provider.chatWithTools(messages, enhancedTools);

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

        final mcpResult = await mcpBridge.executeMcpTool(
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

    await mcpBridge.close();
  } catch (e) {
    print('   ❌ stdio multi-tool workflow failed: $e\n');
  }
}

/// Create enhanced tools that bridge to stdio MCP
List<Tool> _createEnhancedTools(McpToolBridge bridge, List<Tool> mcpTools) {
  // For demo purposes, we'll return the MCP tools as-is
  // In a real implementation, you might enhance them with additional metadata
  return mcpTools;
}

/// Create a stdio MCP bridge for demonstration
Future<McpToolBridge> _createStdioMcpBridge() async {
  print('   🔌 Creating stdio MCP bridge...');

  // In a real implementation, you would:
  // 1. Spawn the stdio server process
  // 2. Create StdioClientTransport with the process
  // 3. Connect the client to the transport

  // For demo purposes, create a mock bridge
  final client = Client(
    Implementation(name: "stdio-demo-client", version: "1.0.0"),
  );

  final bridge = McpToolBridge(client);
  await bridge.initialize();

  print('   ✅ stdio MCP bridge created');
  return bridge;
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
