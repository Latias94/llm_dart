// ignore_for_file: avoid_print
import 'dart:io';
import 'package:mcp_dart/mcp_dart.dart';

/// HTTP REST Client - Real test client for HTTP MCP server
///
/// This client demonstrates how to connect to and interact with the
/// HTTP MCP server using the mcp_dart Client and StreamableHttpClientTransport.
/// This is a "REST" client in the sense that it makes direct HTTP calls to
/// test the server's tools without LLM integration.
///
/// Usage:
/// 1. Start the server: dart run http_examples/server.dart
/// 2. Run this client: dart run http_examples/client.dart
void main() async {
  print('🧪 Testing HTTP MCP Server - Real REST Client\n');

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
      print('   ❌ Client error: $error');
    };

    // Create HTTP transport
    transport = StreamableHttpClientTransport(
      Uri.parse(serverUrl),
      opts: StreamableHttpClientTransportOptions(),
    );

    print('   📡 Connecting to HTTP MCP server at $serverUrl...');

    // Connect the client to the transport
    await client.connect(transport);
    final sessionId = transport.sessionId;
    print('   ✅ HTTP connection established');
    print('   🆔 Session ID: $sessionId\n');

    // Step 2: List available tools
    print('2️⃣ Listing available tools...');
    await listTools(client);
    print('');

    // Step 3: Test greeting tool (HTTP-specific)
    print('3️⃣ Testing greeting tool...');
    await testGreetingTool(client);
    print('');

    // Step 4: Test calculation tool
    print('4️⃣ Testing calculation tool...');
    await testCalculationTool(client);
    print('');

    // Step 5: Test random number generation
    print('5️⃣ Testing random number tool...');
    await testRandomNumberTool(client);
    print('');

    // Step 6: Test time tool
    print('6️⃣ Testing time tool...');
    await testTimeTool(client);
    print('');

    // Step 7: Test streaming notifications
    print('7️⃣ Testing streaming notifications...');
    await testStreamingTool(client);
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

/// List available tools using real MCP client
Future<void> listTools(Client client) async {
  try {
    final toolsResult = await client.listTools();
    print('   📋 Available HTTP tools:');

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

/// Test the greeting tool using real MCP client
Future<void> testGreetingTool(Client client) async {
  print('   👋 Testing HTTP greeting tool');

  try {
    print('   📤 Calling tool: greet');
    print('      Args: {name: "Alice"}');

    final result = await client.callTool(
      CallToolRequestParams(
        name: 'greet',
        arguments: {'name': 'Alice'},
      ),
    );

    print('   📥 Tool result:');
    for (final item in result.content) {
      if (item is TextContent) {
        print('      ${item.text}');
      } else {
        print('      ${item.runtimeType} content: $item');
      }
    }
  } catch (error) {
    print('   ❌ Error calling greet tool: $error');
  }
}

/// Test the calculation tool using real MCP client
Future<void> testCalculationTool(Client client) async {
  print('   🧮 Testing calculation via HTTP: 42 * 13 + 5');

  try {
    final expression = '42 * 13 + 5';
    print('   📤 Calling tool: calculate');
    print('      Args: {expression: "$expression"}');

    final result = await client.callTool(
      CallToolRequestParams(
        name: 'calculate',
        arguments: {'expression': expression},
      ),
    );

    print('   📥 Tool result:');
    for (final item in result.content) {
      if (item is TextContent) {
        print('      ${item.text}');
      } else {
        print('      ${item.runtimeType} content: $item');
      }
    }
  } catch (error) {
    print('   ❌ Error calling calculate tool: $error');
  }
}

/// Test the random number tool using real MCP client
Future<void> testRandomNumberTool(Client client) async {
  print(
      '   🎲 Testing random number generation via HTTP: 5 numbers between 10-50');

  try {
    print('   📤 Calling tool: random_number');
    print('      Args: {min: 10, max: 50, count: 5}');

    final result = await client.callTool(
      CallToolRequestParams(
        name: 'random_number',
        arguments: {'min': 10, 'max': 50, 'count': 5},
      ),
    );

    print('   📥 Tool result:');
    for (final item in result.content) {
      if (item is TextContent) {
        print('      ${item.text}');
      } else {
        print('      ${item.runtimeType} content: $item');
      }
    }
  } catch (error) {
    print('   ❌ Error calling random_number tool: $error');
  }
}

/// Test the time tool using real MCP client
Future<void> testTimeTool(Client client) async {
  print('   ⏰ Testing current time via HTTP in UTC format');

  try {
    print('   📤 Calling tool: current_time');
    print('      Args: {format: "utc"}');

    final result = await client.callTool(
      CallToolRequestParams(
        name: 'current_time',
        arguments: {'format': 'utc'},
      ),
    );

    print('   📥 Tool result:');
    for (final item in result.content) {
      if (item is TextContent) {
        print('      ${item.text}');
      } else {
        print('      ${item.runtimeType} content: $item');
      }
    }
  } catch (error) {
    print('   ❌ Error calling current_time tool: $error');
  }
}

/// Test the streaming tool using real MCP client
Future<void> testStreamingTool(Client client) async {
  print('   🌊 Testing streaming notifications via HTTP');

  try {
    // Set up notification handler to capture streaming notifications
    int notificationCount = 0;
    client.setNotificationHandler("notifications/message",
        (notification) async {
      notificationCount++;
      final params = notification.logParams;
      print(
          '   📡 Notification #$notificationCount: ${params.level} - ${params.data}');
      return Future.value();
    },
        (params, meta) => JsonRpcLoggingMessageNotification.fromJson({
              'params': params,
              if (meta != null) '_meta': meta,
            }));

    print('   📤 Calling tool: multi-greet');
    print('      Args: {name: "Bob"}');

    final result = await client.callTool(
      CallToolRequestParams(
        name: 'multi-greet',
        arguments: {'name': 'Bob'},
      ),
    );

    print('   📥 Tool result:');
    for (final item in result.content) {
      if (item is TextContent) {
        print('      ${item.text}');
      } else {
        print('      ${item.runtimeType} content: $item');
      }
    }

    // Wait a bit to see if more notifications come in
    await Future.delayed(Duration(milliseconds: 500));
    print(
        '   ✅ Streaming test completed with $notificationCount notifications');
  } catch (error) {
    print('   ❌ Error calling multi-greet tool: $error');
  }
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
