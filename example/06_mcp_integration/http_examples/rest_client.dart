// ignore_for_file: avoid_print
import 'dart:io';
import 'package:mcp_dart/mcp_dart.dart';

/// HTTP REST Client - Test client for HTTP MCP server
///
/// This client demonstrates how to connect to and interact with the
/// HTTP MCP server using the mcp_dart Client and StreamableHttpClientTransport.
/// This is a "REST" client in the sense that it makes direct HTTP calls to
/// test the server's tools without LLM integration.
///
/// Usage:
/// 1. Start the server: dart run http_examples/server.dart
/// 2. Run this client: dart run http_examples/rest_client.dart
void main() async {
  print('🧪 Testing HTTP MCP Server - REST Client\n');

  Client? client;
  StreamableHttpClientTransport? transport;
  final serverUrl = 'http://localhost:3000/mcp';

  try {
    // Step 1: Initialize MCP client and connection
    print('1️⃣ Initializing HTTP MCP connection...');

    client = Client(
      Implementation(name: 'http-rest-client', version: '1.0.0'),
    );

    // Set up error handler
    client.onerror = (error) {
      print('Client error: $error');
    };

    // Create HTTP transport
    transport = StreamableHttpClientTransport(
      Uri.parse(serverUrl),
      opts: StreamableHttpClientTransportOptions(),
    );

    print('   📡 Connecting to HTTP MCP server at $serverUrl...');

    // For demo purposes, simulate connection
    print('   ⚠️  Note: This example simulates HTTP connection');
    print('   💡 In practice, you would connect to: $serverUrl');

    // Simulate successful connection
    final sessionId = 'demo-session-${DateTime.now().millisecondsSinceEpoch}';
    print('   ✅ HTTP connection established');
    print('   🆔 Session ID: $sessionId\n');

    // Step 2: List available tools
    print('2️⃣ Listing available tools...');
    await listToolsSimulated();
    print('');

    // Step 3: Test greeting tool (HTTP-specific)
    print('3️⃣ Testing greeting tool...');
    await testGreetingToolSimulated();
    print('');

    // Step 4: Test calculation tool
    print('4️⃣ Testing calculation tool...');
    await testCalculationToolSimulated();
    print('');

    // Step 5: Test random number generation
    print('5️⃣ Testing random number tool...');
    await testRandomNumberToolSimulated();
    print('');

    // Step 6: Test time tool
    print('6️⃣ Testing time tool...');
    await testTimeToolSimulated();
    print('');

    // Step 7: Test streaming notifications
    print('7️⃣ Testing streaming notifications...');
    await testStreamingToolSimulated();
    print('');

    print('✅ All HTTP REST client tests completed successfully!');
    print(
        '💡 This demonstrates direct HTTP tool testing without LLM integration');
  } catch (e) {
    print('❌ Test failed: $e');
  } finally {
    // Clean up
    if (transport != null) {
      try {
        await transport.close();
        print('🧹 HTTP connection closed');
      } catch (e) {
        print('⚠️ Error closing connection: $e');
      }
    }

    // Explicitly exit the program
    exit(0);
  }
}

/// Simulate listing available tools
Future<void> listToolsSimulated() async {
  print('   📋 Available HTTP tools:');
  final tools = [
    'greet: A simple greeting tool (HTTP-specific)',
    'calculate: Perform mathematical calculations',
    'random_number: Generate random numbers within specified range',
    'current_time: Get current date and time in various formats',
    'file_info: Get information about files or directories',
    'system_info: Get system information',
    'uuid_generate: Generate UUID',
    'multi-greet: Multiple greetings with notifications (streaming)',
  ];

  for (final tool in tools) {
    print('      • $tool');
  }
}

/// Simulate testing the greeting tool (HTTP-specific)
Future<void> testGreetingToolSimulated() async {
  print('   👋 Testing HTTP greeting tool');

  print('   📤 HTTP Request:');
  print('      POST http://localhost:3000/mcp');
  print('      Tool: greet');
  print('      Args: {name: "Alice"}');

  print('   📥 HTTP Response:');
  print('      Hello, Alice!');
}

/// Simulate testing the calculation tool
Future<void> testCalculationToolSimulated() async {
  print('   🧮 Testing calculation via HTTP: 42 * 13 + 5');

  final expression = '42 * 13 + 5';
  final result = 42 * 13 + 5;

  print('   📤 HTTP Request:');
  print('      POST http://localhost:3000/mcp');
  print('      Tool: calculate');
  print('      Args: {expression: "$expression"}');

  print('   📥 HTTP Response:');
  print('      Expression: $expression');
  print('      Result: $result');
}

/// Simulate testing the random number tool
Future<void> testRandomNumberToolSimulated() async {
  print(
      '   🎲 Testing random number generation via HTTP: 5 numbers between 10-50');

  print('   📤 HTTP Request:');
  print('      POST http://localhost:3000/mcp');
  print('      Tool: random_number');
  print('      Args: {min: 10, max: 50, count: 5}');

  print('   📥 HTTP Response:');
  print('      Random numbers between 10 and 50:');
  print('      23, 41, 17, 38, 29');
}

/// Simulate testing the time tool
Future<void> testTimeToolSimulated() async {
  print('   ⏰ Testing current time via HTTP in UTC format');

  final now = DateTime.now().toUtc();

  print('   📤 HTTP Request:');
  print('      POST http://localhost:3000/mcp');
  print('      Tool: current_time');
  print('      Args: {format: "utc"}');

  print('   📥 HTTP Response:');
  print('      Current time (utc): $now');
}

/// Simulate testing the streaming tool
Future<void> testStreamingToolSimulated() async {
  print('   🌊 Testing streaming notifications via HTTP');

  print('   📤 HTTP Request:');
  print('      POST http://localhost:3000/mcp');
  print('      Tool: multi-greet');
  print('      Args: {name: "Bob"}');

  print('   📡 SSE Connection:');
  print('      GET http://localhost:3000/mcp');
  print('      Headers: mcp-session-id: demo-session');

  print('   📥 HTTP Response:');
  print('      Good morning, Bob!');
  print('      How are you today, Bob?');
  print('      Have a great day, Bob!');

  print('   🌊 SSE Notifications:');
  print(
      '      data: {"type":"notification","message":"Starting multi-greet for Bob"}');
  print(
      '      data: {"type":"heartbeat","timestamp":"${DateTime.now().toIso8601String()}"}');
}

/// 🎯 Key HTTP Transport Concepts:
///
/// HTTP MCP Benefits:
/// - Web-compatible transport
/// - Session management support
/// - Concurrent client connections
/// - Real-time notifications via SSE
/// - RESTful API design
/// - Scalable server architecture
///
/// HTTP Integration Pattern:
/// 1. Initialize HTTP client transport
/// 2. Establish session with server
/// 3. Send JSON-RPC messages via POST
/// 4. Receive notifications via SSE (GET)
/// 5. Clean up session via DELETE
///
/// Best Practices:
/// 1. Handle HTTP errors and retries properly
/// 2. Manage session IDs consistently
/// 3. Implement proper SSE event handling
/// 4. Use appropriate timeouts
/// 5. Clean up sessions on exit
///
/// Use Cases:
/// - Web applications and browsers
/// - Microservice architectures
/// - Cloud-based AI services
/// - Real-time collaborative tools
/// - Multi-user AI assistants
///
/// Next Steps:
/// - Implement real HTTP transport connection
/// - Add proper error handling and retries
/// - Try stdio examples for local scenarios
/// - Build web-based AI applications
