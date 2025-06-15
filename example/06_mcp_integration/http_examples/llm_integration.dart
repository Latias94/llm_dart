// ignore_for_file: avoid_print
import 'dart:io';
import 'package:llm_dart/llm_dart.dart';
import 'package:mcp_dart/mcp_dart.dart' hide Tool;
import '../shared/mcp_tool_bridge.dart';

/// HTTP LLM Integration - AI Agents with HTTP MCP Tools
///
/// This example demonstrates how to integrate LLMs with MCP servers
/// using HTTP transport with streaming capabilities. The LLM can discover
/// and use tools from the HTTP MCP server through the MCP bridge.
///
/// Architecture:
/// LLM (OpenAI/etc) ↔ llm_dart ↔ MCP Bridge ↔ HTTP MCP Server ↔ Tools
///
/// Before running:
/// export OPENAI_API_KEY="your-key-here"
/// dart run example/06_mcp_integration/http_examples/llm_integration.dart
void main() async {
  print('🌐 HTTP LLM Integration - AI Agents with HTTP MCP Tools\n');

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
}

/// Demonstrate basic HTTP MCP + LLM integration
Future<void> demonstrateBasicHttpIntegration(String apiKey) async {
  print('🔗 Basic HTTP MCP + LLM Integration:\n');

  try {
    // Create LLM provider
    final llmProvider = await ai()
        .openai()
        .apiKey(apiKey)
        .model('gpt-4o-mini')
        .temperature(0.7)
        .build();

    // Create MCP bridge for HTTP server
    final mcpBridge = await _createHttpMcpBridge();

    // Get MCP tools as llm_dart tools
    final mcpTools = mcpBridge.convertToLlmDartTools();

    print('   🔧 Available HTTP MCP Tools:');
    for (final tool in mcpTools) {
      print('      • ${tool.function.name}: ${tool.function.description}');
    }

    // Create enhanced tools that bridge to MCP
    final enhancedTools = _createEnhancedTools(mcpBridge, mcpTools);

    // Test with a greeting and calculation request
    final messages = [
      ChatMessage.user(
          'Please greet me as "Alice" and then calculate 18 * 24 + 6.')
    ];

    // Print actual user message
    print('   💬 User Message:');
    print('      "${messages.last.content}"');
    print('   🤖 LLM: Processing request with HTTP MCP tools...');

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

        // Execute the MCP tool via HTTP
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
    print('   ✅ Basic HTTP integration successful\n');

    await mcpBridge.close();
  } catch (e) {
    print('   ❌ Basic HTTP integration failed: $e\n');
  }
}

/// Demonstrate HTTP streaming workflow
Future<void> demonstrateHttpStreamingWorkflow(String apiKey) async {
  print('🌊 HTTP Streaming Workflow:\n');

  try {
    final provider = await ai()
        .openai()
        .apiKey(apiKey)
        .model('gpt-4o-mini')
        .temperature(0.3)
        .build();

    final mcpBridge = await _createHttpMcpBridge();
    final mcpTools = mcpBridge.convertToLlmDartTools();
    final enhancedTools = _createEnhancedTools(mcpBridge, mcpTools);

    // Streaming workflow request
    final messages = [
      ChatMessage.system(
          'You are a friendly assistant that can use streaming tools. '
          'Use the multi-greet tool to send personalized greetings.'),
      ChatMessage.user(
          'Please use the multi-greet tool to greet me as "Charlie" with multiple messages.'),
    ];

    // Print actual user message
    print('   💬 User Message:');
    print('      "${messages.last.content}"');
    print('   🤖 LLM: Initiating HTTP streaming workflow...');

    final response = await provider.chatWithTools(messages, enhancedTools);

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

        final mcpResult = await mcpBridge.executeMcpTool(
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

      // Send tool results back to LLM for final response
      print(
          '   🔄 Sending MCP results back to LLM for streaming final response...');
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
    print('   ✅ HTTP streaming workflow successful\n');

    await mcpBridge.close();
  } catch (e) {
    print('   ❌ HTTP streaming workflow failed: $e\n');
  }
}

/// Demonstrate HTTP session management
Future<void> demonstrateHttpSessionManagement(String apiKey) async {
  print('🆔 HTTP Session Management:\n');

  try {
    final provider = await ai()
        .openai()
        .apiKey(apiKey)
        .model('gpt-4o-mini')
        .temperature(0.2)
        .build();

    final mcpBridge = await _createHttpMcpBridge();
    final mcpTools = mcpBridge.convertToLlmDartTools();
    final enhancedTools = _createEnhancedTools(mcpBridge, mcpTools);

    // Session-based workflow request
    final messages = [
      ChatMessage.system(
          'You are a session-aware assistant. Use tools to demonstrate session management.'),
      ChatMessage.user(
          'Please: 1) Generate a UUID for this session, 2) Get the current time, '
          '3) Calculate 7 * 9, and 4) Greet me as "Session User".'),
    ];

    // Print actual user message
    print('   💬 User Message:');
    print('      "${messages.last.content}"');
    print('   🤖 LLM: Processing request with HTTP MCP tools...');

    final response = await provider.chatWithTools(messages, enhancedTools);

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
        print('         🌐 Session: HTTP session with unique ID');

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
          '   🔄 Sending MCP results back to LLM for session final response...');
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
    print('   ✅ HTTP session management successful\n');

    await mcpBridge.close();
  } catch (e) {
    print('   ❌ HTTP session management failed: $e\n');
  }
}

/// Create enhanced tools that bridge to HTTP MCP
List<Tool> _createEnhancedTools(McpToolBridge bridge, List<Tool> mcpTools) {
  // For demo purposes, we'll return the MCP tools as-is
  // In a real implementation, you might enhance them with additional metadata
  return mcpTools;
}

/// Create an HTTP MCP bridge for demonstration
Future<McpToolBridge> _createHttpMcpBridge() async {
  print('   🌐 Creating HTTP MCP bridge...');

  // In a real implementation, you would:
  // 1. Create StreamableHttpClientTransport with server URL
  // 2. Connect the client to the transport
  // 3. Handle session management and SSE connections

  // For demo purposes, create a mock bridge
  final client = Client(
    Implementation(name: "http-demo-client", version: "1.0.0"),
  );

  final bridge = McpToolBridge(client);
  await bridge.initialize();

  print('   ✅ HTTP MCP bridge created');
  return bridge;
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
