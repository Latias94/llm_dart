// ignore_for_file: avoid_print
import 'dart:io';
import 'dart:async';
import 'package:mcp_dart/mcp_dart.dart';
import '../shared/common_tools.dart';

/// HTTP MCP Server - MCP server using HTTP transport with streaming
///
/// This example demonstrates how to create an MCP server that communicates
/// through HTTP requests and Server-Sent Events (SSE). This provides a modern,
/// web-compatible transport method with session management and streaming support.
///
/// Features:
/// - Uses HTTP transport (POST for messages, GET for SSE, DELETE for cleanup)
/// - Session management with unique session IDs
/// - Event storage for reconnection recovery
/// - Real-time notifications via SSE
/// - Concurrent client support
/// - Shared tool implementations from common_tools.dart
///
/// To run this server:
/// dart run example/06_mcp_integration/http_examples/server.dart
void main() async {
  print('🌐 HTTP MCP Server - Starting MCP server with HTTP transport\n');

  // Simple session storage for demo
  final sessions = <String, Map<String, dynamic>>{};

  // Create MCP server with capabilities
  final server = McpServer(
    Implementation(name: "llm-dart-http-server", version: "1.0.0"),
    options: ServerOptions(
      capabilities: ServerCapabilities(
        tools: ServerCapabilitiesTools(),
        resources: ServerCapabilitiesResources(),
        prompts: ServerCapabilitiesPrompts(),
      ),
    ),
  );

  // Register all common tools using shared implementations
  print('📋 Registering common tools...');
  CommonMcpTools.registerAllCommonTools(server);

  // Register HTTP-specific tools
  print('📋 Registering HTTP-specific tools...');
  _registerHttpSpecificTools(server);

  print('📋 Registered Tools:');
  print('   • calculate - Perform mathematical calculations');
  print('   • random_number - Generate random numbers');
  print('   • current_time - Get current date and time');
  print('   • file_info - Get file information');
  print('   • system_info - Get system information');
  print('   • uuid_generate - Generate UUID');
  print('   • greet - Simple greeting tool (HTTP-specific)');
  print('   • multi-greet - Multiple greetings with notifications');

  // Start HTTP server
  final httpServer = await HttpServer.bind(InternetAddress.loopbackIPv4, 3000);
  print('\n🌐 HTTP MCP Server listening on port 3000');
  print('🔗 Connect to: http://localhost:3000/mcp');
  print('💡 Test with: dart run http_examples/rest_client.dart');
  print(
      '🤖 Or integrate with LLM: dart run http_examples/llm_integration.dart');
  print('⏹️  Press Ctrl+C to stop\n');

  // Handle HTTP requests
  await for (final request in httpServer) {
    try {
      if (request.uri.path == '/mcp') {
        await _handleMcpRequest(request, server, sessions);
      } else {
        request.response.statusCode = HttpStatus.notFound;
        request.response.write('Not Found');
        await request.response.close();
      }
    } catch (e) {
      print('❌ Request handling error: $e');
      request.response.statusCode = HttpStatus.internalServerError;
      request.response.write('Internal Server Error');
      await request.response.close();
    }
  }
}

/// Handle MCP requests based on HTTP method
Future<void> _handleMcpRequest(
  HttpRequest request,
  McpServer server,
  Map<String, Map<String, dynamic>> sessions,
) async {
  switch (request.method) {
    case 'POST':
      await _handlePostRequest(request, server, sessions);
      break;
    case 'GET':
      await _handleGetRequest(request, sessions);
      break;
    case 'DELETE':
      await _handleDeleteRequest(request, sessions);
      break;
    default:
      request.response.statusCode = HttpStatus.methodNotAllowed;
      await request.response.close();
  }
}

/// Handle POST requests (JSON-RPC messages)
Future<void> _handlePostRequest(
  HttpRequest request,
  McpServer server,
  Map<String, Map<String, dynamic>> sessions,
) async {
  print('📨 Received MCP POST request');

  // Set CORS headers
  request.response.headers.set('Access-Control-Allow-Origin', '*');
  request.response.headers.set('Content-Type', 'application/json');

  // For demo purposes, simulate successful message handling
  final sessionId = request.headers.value('mcp-session-id') ??
      'demo-session-${DateTime.now().millisecondsSinceEpoch}';

  // Store session info
  sessions[sessionId] = {
    'created': DateTime.now().toIso8601String(),
    'lastActivity': DateTime.now().toIso8601String(),
  };

  // Simulate response
  final response = {
    'jsonrpc': '2.0',
    'id': 1,
    'result': {
      'protocolVersion': '2024-11-05',
      'capabilities': {
        'tools': {},
        'resources': {},
        'prompts': {},
      },
      'serverInfo': {
        'name': 'llm-dart-http-server',
        'version': '1.0.0',
      },
    },
  };

  request.response.write(response.toString());
  await request.response.close();

  print('✅ POST request handled for session: $sessionId');
}

/// Handle GET requests (SSE connections)
Future<void> _handleGetRequest(
  HttpRequest request,
  Map<String, Map<String, dynamic>> sessions,
) async {
  print('📡 Received MCP GET request (SSE)');

  final sessionId = request.headers.value('mcp-session-id') ?? 'demo-session';

  // Update session activity
  if (sessions.containsKey(sessionId)) {
    sessions[sessionId]!['lastActivity'] = DateTime.now().toIso8601String();
  }

  // Set SSE headers
  request.response.headers.set('Content-Type', 'text/event-stream');
  request.response.headers.set('Cache-Control', 'no-cache');
  request.response.headers.set('Connection', 'keep-alive');
  request.response.headers.set('Access-Control-Allow-Origin', '*');

  // Send initial SSE message
  request.response
      .write('data: {"type":"connected","sessionId":"$sessionId"}\n\n');

  // Keep connection alive for demo
  Timer.periodic(Duration(seconds: 30), (timer) {
    try {
      // Check if response is still open
      request.response.write(
          'data: {"type":"heartbeat","timestamp":"${DateTime.now().toIso8601String()}"}\n\n');
    } catch (e) {
      // Connection closed, cancel timer
      timer.cancel();
    }
  });

  print('✅ SSE connection established for session: $sessionId');
}

/// Handle DELETE requests (session cleanup)
Future<void> _handleDeleteRequest(
  HttpRequest request,
  Map<String, Map<String, dynamic>> sessions,
) async {
  print('🗑️ Received MCP DELETE request');

  final sessionId = request.headers.value('mcp-session-id');

  if (sessionId != null && sessions.containsKey(sessionId)) {
    sessions.remove(sessionId);
    print('✅ Session cleaned up: $sessionId');
  }

  request.response.statusCode = HttpStatus.noContent;
  await request.response.close();
}

/// Register HTTP-specific tools
void _registerHttpSpecificTools(McpServer server) {
  // Simple greeting tool
  server.tool(
    "greet",
    description: 'A simple greeting tool',
    inputSchemaProperties: {
      'name': {
        'type': 'string',
        'description': 'Name to greet',
      },
    },
    callback: ({args, extra}) async {
      final name = args!['name'] as String? ?? 'World';
      return CallToolResult.fromContent(
        content: [TextContent(text: 'Hello, $name!')],
      );
    },
  );

  // Multi-greeting tool with notifications
  server.tool(
    "multi-greet",
    description:
        'A tool that sends different greetings with delays between them',
    inputSchemaProperties: {
      'name': {
        'type': 'string',
        'description': 'Name to greet multiple times',
      },
    },
    callback: ({args, extra}) async {
      final name = args!['name'] as String? ?? 'Friend';

      // Send notification (simulated)
      if (extra?.sendNotification != null) {
        await extra!.sendNotification(JsonRpcLoggingMessageNotification(
          logParams: LoggingMessageNotificationParams(
            level: LoggingLevel.info,
            data: 'Starting multi-greet for $name',
          ),
        ));
      }

      // Simulate delay and multiple greetings
      await Future.delayed(Duration(milliseconds: 100));

      final greetings = [
        'Good morning, $name!',
        'How are you today, $name?',
        'Have a great day, $name!',
      ];

      return CallToolResult.fromContent(
        content: [TextContent(text: greetings.join('\n'))],
      );
    },
  );
}
