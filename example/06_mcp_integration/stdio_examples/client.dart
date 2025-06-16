// ignore_for_file: avoid_print
import 'dart:io';
import 'package:mcp_dart/mcp_dart.dart';

/// stdio REST Client - Test client for stdio MCP server
///
/// This client demonstrates how to connect to and interact with the
/// stdio MCP server using the mcp_dart Client and StdioClientTransport.
/// This is a "REST" client in the sense that it makes direct calls to
/// test the server's tools without LLM integration.
///
/// Usage:
/// 1. Start the server: dart run stdio_examples/server.dart
/// 2. Run this client: dart run stdio_examples/client.dart
void main() async {
  print('🧪 Testing stdio MCP Server - Real REST Client\n');

  Client? client;

  try {
    // Step 1: Initialize real MCP client and connection
    print('1️⃣ Initializing real MCP connection...');
    client = await _createRealStdioMcpClient();
    print('   ✅ Connection established\n');

    // Step 2: List available tools from real server
    print('2️⃣ Listing available tools from real server...');
    await _listRealTools(client);
    print('');

    // Step 3: Test calculation tool with real server
    print('3️⃣ Testing calculation tool with real server...');
    await _testRealCalculationTool(client);
    print('');

    // Step 4: Test random number generation with real server
    print('4️⃣ Testing random number tool with real server...');
    await _testRealRandomNumberTool(client);
    print('');

    // Step 5: Test time tool with real server
    print('5️⃣ Testing time tool with real server...');
    await _testRealTimeTool(client);
    print('');

    // Step 6: Test file info tool with real server
    print('6️⃣ Testing file info tool with real server...');
    await _testRealFileInfoTool(client);
    print('');

    // Step 7: Test UUID generation with real server
    print('7️⃣ Testing UUID generation with real server...');
    await _testRealUuidTool(client);
    print('');

    print('✅ All real REST client tests completed successfully!');
    print('💡 This demonstrates direct tool testing with real MCP server');
  } catch (e) {
    print('❌ Test failed: $e');
  } finally {
    // Clean up
    if (client != null) {
      try {
        await client.close();
        print('🧹 Connection closed');
      } catch (e) {
        print('⚠️ Error closing connection: $e');
      }
    }
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
  final clientInfo = Implementation(name: 'StdioRestClient', version: '1.0.0');

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

/// List available tools from real server
Future<void> _listRealTools(Client client) async {
  try {
    final toolsResult = await client.listTools();
    print('   📋 Available tools from real server:');

    if (toolsResult.tools.isEmpty) {
      print('      No tools available');
    } else {
      for (final tool in toolsResult.tools) {
        print('      • ${tool.name}: ${tool.description}');
      }
    }
  } catch (error) {
    print('   ❌ Error listing tools: $error');
  }
}

/// Test calculation tool with real server
Future<void> _testRealCalculationTool(Client client) async {
  print('   🧮 Testing calculation: 15 * 23 + 7');

  try {
    final expression = '15 * 23 + 7';

    print('   📤 Request:');
    print('      Tool: calculate');
    print('      Args: {expression: "$expression"}');

    final result = await client.callTool(
      CallToolRequestParams(
        name: 'calculate',
        arguments: {'expression': expression},
      ),
    );

    print('   📥 Response:');
    final resultText = result.content
        .whereType<TextContent>()
        .map((item) => item.text)
        .join('\n');
    print('      $resultText');
  } catch (error) {
    print('   ❌ Error testing calculation tool: $error');
  }
}

/// Test random number tool with real server
Future<void> _testRealRandomNumberTool(Client client) async {
  print('   🎲 Testing random number generation: 3 numbers between 1-100');

  try {
    print('   📤 Request:');
    print('      Tool: random_number');
    print('      Args: {min: 1, max: 100, count: 3}');

    final result = await client.callTool(
      CallToolRequestParams(
        name: 'random_number',
        arguments: {'min': 1, 'max': 100, 'count': 3},
      ),
    );

    print('   📥 Response:');
    final resultText = result.content
        .whereType<TextContent>()
        .map((item) => item.text)
        .join('\n');
    print('      $resultText');
  } catch (error) {
    print('   ❌ Error testing random number tool: $error');
  }
}

/// Test time tool with real server
Future<void> _testRealTimeTool(Client client) async {
  print('   ⏰ Testing current time in ISO format');

  try {
    print('   📤 Request:');
    print('      Tool: current_time');
    print('      Args: {format: "iso"}');

    final result = await client.callTool(
      CallToolRequestParams(
        name: 'current_time',
        arguments: {'format': 'iso'},
      ),
    );

    print('   📥 Response:');
    final resultText = result.content
        .whereType<TextContent>()
        .map((item) => item.text)
        .join('\n');
    print('      $resultText');
  } catch (error) {
    print('   ❌ Error testing time tool: $error');
  }
}

/// Test file info tool with real server
Future<void> _testRealFileInfoTool(Client client) async {
  print('   📁 Testing file info for current directory');

  try {
    print('   📤 Request:');
    print('      Tool: file_info');
    print('      Args: {path: "."}');

    final result = await client.callTool(
      CallToolRequestParams(
        name: 'file_info',
        arguments: {'path': '.'},
      ),
    );

    print('   📥 Response:');
    final resultText = result.content
        .whereType<TextContent>()
        .map((item) => item.text)
        .join('\n');
    print('      $resultText');
  } catch (error) {
    print('   ❌ Error testing file info tool: $error');
  }
}

/// Test UUID generation tool with real server
Future<void> _testRealUuidTool(Client client) async {
  print('   🆔 Testing UUID generation');

  try {
    print('   📤 Request:');
    print('      Tool: uuid_generate');
    print('      Args: {}');

    final result = await client.callTool(
      CallToolRequestParams(
        name: 'uuid_generate',
        arguments: {},
      ),
    );

    print('   📥 Response:');
    final resultText = result.content
        .whereType<TextContent>()
        .map((item) => item.text)
        .join('\n');
    print('      $resultText');
  } catch (error) {
    print('   ❌ Error testing UUID tool: $error');
  }
}

/// 🎯 Key stdio Transport Concepts:
///
/// stdio Benefits:
/// - Simple process-based communication
/// - Easy to debug with standard I/O
/// - Natural fit for command-line tools
/// - Minimal setup required
///
/// stdio Limitations:
/// - One client per server process
/// - No built-in session management
/// - Buffer size limitations
/// - Process lifecycle management needed
///
/// Best Practices:
/// 1. Handle process spawning and cleanup properly
/// 2. Implement proper JSON-RPC message framing
/// 3. Monitor stderr for server errors
/// 4. Implement timeouts for tool execution
/// 5. Handle server process crashes gracefully
///
/// Use Cases:
/// - Local development and testing
/// - Command-line AI tools
/// - Simple automation scripts
/// - Educational examples
///
/// Next Steps:
/// - Try the HTTP examples for web-based scenarios
/// - Implement real stdio transport connection
/// - Add process management utilities
/// - Build CLI tools using this pattern
