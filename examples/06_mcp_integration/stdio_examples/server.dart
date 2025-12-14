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
/// dart run 06_mcp_integration/stdio_examples/server.dart
void main() async {
  // Use stderr for all logging since stdout is reserved for JSON-RPC communication
  stderr.writeln(
      '🛠️ stdio MCP Server - Starting MCP server with stdio transport\n');

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
  stderr.writeln('📋 Registering tools...');
  CommonMcpTools.registerAllCommonTools(server);

  stderr.writeln('📋 Registered Tools:');
  stderr.writeln('   • calculate - Perform mathematical calculations');
  stderr.writeln('   • random_number - Generate random numbers');
  stderr.writeln('   • current_time - Get current date and time');
  stderr.writeln('   • file_info - Get file information');
  stderr.writeln('   • system_info - Get system information');
  stderr.writeln('   • uuid_generate - Generate UUID');

  stderr.writeln('\n🚀 Starting MCP server on stdio...');
  stderr.writeln('💡 Connect with: dart run stdio_examples/client.dart');
  stderr.writeln(
      '🔗 Or integrate with LLM: dart run stdio_examples/llm_client.dart');
  stderr.writeln('⏹️  Press Ctrl+C to stop\n');

  try {
    // Connect using stdio transport
    await server.connect(StdioServerTransport());
  } catch (e) {
    stderr.writeln('❌ Server error: $e');
    exit(1);
  }
}
