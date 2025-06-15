// ignore_for_file: avoid_print
import 'dart:io';
import 'package:mcp_dart/mcp_dart.dart';
import '../shared/common_tools.dart';

/// stdio MCP Server - MCP server using stdio transport
///
/// This example demonstrates how to create an MCP server that communicates
/// through standard input/output streams. This is the traditional MCP transport
/// method and is ideal for command-line tools and process spawning.
///
/// Features:
/// - Uses stdio transport (stdin/stdout communication)
/// - Provides mathematical, utility, file, and system tools
/// - Shared tool implementations from common_tools.dart
/// - Simple process-based communication
///
/// To run this server:
/// dart run example/06_mcp_integration/stdio_examples/server.dart
void main() async {
  print('🛠️ stdio MCP Server - Starting MCP server with stdio transport\n');

  // Create MCP server with capabilities
  final server = McpServer(
    Implementation(name: "llm-dart-stdio-server", version: "1.0.0"),
    options: ServerOptions(
      capabilities: ServerCapabilities(
        tools: ServerCapabilitiesTools(),
        resources: ServerCapabilitiesResources(),
        prompts: ServerCapabilitiesPrompts(),
      ),
    ),
  );

  // Register all common tools using shared implementations
  print('📋 Registering tools...');
  CommonMcpTools.registerAllCommonTools(server);

  print('📋 Registered Tools:');
  print('   • calculate - Perform mathematical calculations');
  print('   • random_number - Generate random numbers');
  print('   • current_time - Get current date and time');
  print('   • file_info - Get file information');
  print('   • system_info - Get system information');
  print('   • uuid_generate - Generate UUID');

  print('\n🚀 Starting MCP server on stdio...');
  print('💡 Connect with: dart run stdio_examples/rest_client.dart');
  print(
      '🔗 Or integrate with LLM: dart run stdio_examples/llm_integration.dart');
  print('⏹️  Press Ctrl+C to stop\n');

  try {
    // Connect using stdio transport
    await server.connect(StdioServerTransport());
  } catch (e) {
    print('❌ Server error: $e');
    exit(1);
  }
}
