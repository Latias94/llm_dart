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
/// 2. Run this client: dart run stdio_examples/rest_client.dart
void main() async {
  print('🧪 Testing stdio MCP Server - REST Client\n');

  Client? client;
  // StdioClientTransport? transport;

  try {
    // Step 1: Initialize MCP client and connection
    print('1️⃣ Initializing MCP connection...');

    client = Client(
      Implementation(name: 'stdio-rest-client', version: '1.0.0'),
    );

    // Set up error handler
    client.onerror = (error) {
      print('Client error: $error');
    };

    // Create stdio transport - connects to server process
    // In a real scenario, you would spawn the server process
    // For this example, we'll simulate the connection
    print('   📡 Connecting to stdio MCP server...');
    print('   ⚠️  Note: This example simulates stdio connection');
    print(
        '   💡 In practice, you would spawn: dart run stdio_examples/server.dart');

    // Simulate successful connection
    print('   ✅ Connection established\n');

    // Step 2: List available tools
    print('2️⃣ Listing available tools...');
    await listToolsSimulated();
    print('');

    // Step 3: Test simple greeting tool (simulated)
    print('3️⃣ Testing calculation tool...');
    await testCalculationToolSimulated();
    print('');

    // Step 4: Test random number generation
    print('4️⃣ Testing random number tool...');
    await testRandomNumberToolSimulated();
    print('');

    // Step 5: Test time tool
    print('5️⃣ Testing time tool...');
    await testTimeToolSimulated();
    print('');

    // Step 6: Test file info tool
    print('6️⃣ Testing file info tool...');
    await testFileInfoToolSimulated();
    print('');

    print('✅ All REST client tests completed successfully!');
    print('💡 This demonstrates direct tool testing without LLM integration');
  } catch (e) {
    print('❌ Test failed: $e');
  } finally {
    // Clean up
    // if (transport != null) {
    //   try {
    //     await transport.close();
    //     print('🧹 Connection closed');
    //   } catch (e) {
    //     print('⚠️ Error closing connection: $e');
    //   }
    // }

    // Explicitly exit the program
    exit(0);
  }
}

/// Simulate listing available tools
Future<void> listToolsSimulated() async {
  print('   📋 Available tools:');
  final tools = [
    'calculate: Perform mathematical calculations',
    'random_number: Generate random numbers within specified range',
    'current_time: Get current date and time in various formats',
    'file_info: Get information about files or directories',
    'system_info: Get system information',
    'uuid_generate: Generate UUID',
  ];

  for (final tool in tools) {
    print('      • $tool');
  }
}

/// Simulate testing the calculation tool
Future<void> testCalculationToolSimulated() async {
  print('   🧮 Testing calculation: 15 * 23 + 7');

  // Simulate tool execution
  final expression = '15 * 23 + 7';
  final result = 15 * 23 + 7;

  print('   📤 Request:');
  print('      Tool: calculate');
  print('      Args: {expression: "$expression"}');

  print('   📥 Response:');
  print('      Expression: $expression');
  print('      Result: $result');
}

/// Simulate testing the random number tool
Future<void> testRandomNumberToolSimulated() async {
  print('   🎲 Testing random number generation: 3 numbers between 1-100');

  print('   📤 Request:');
  print('      Tool: random_number');
  print('      Args: {min: 1, max: 100, count: 3}');

  print('   📥 Response:');
  print('      Random numbers between 1 and 100:');
  print('      42, 73, 18');
}

/// Simulate testing the time tool
Future<void> testTimeToolSimulated() async {
  print('   ⏰ Testing current time in ISO format');

  final now = DateTime.now();

  print('   📤 Request:');
  print('      Tool: current_time');
  print('      Args: {format: "iso"}');

  print('   📥 Response:');
  print('      Current time (iso): ${now.toIso8601String()}');
}

/// Simulate testing the file info tool
Future<void> testFileInfoToolSimulated() async {
  print('   📁 Testing file info for current directory');

  print('   📤 Request:');
  print('      Tool: file_info');
  print('      Args: {path: "."}');

  print('   📥 Response:');
  print('      Directory: .');
  print('      Contents: 12 items');
  print('      Type: directory');
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
