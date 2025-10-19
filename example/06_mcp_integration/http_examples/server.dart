// ignore_for_file: avoid_print
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:mcp_dart/mcp_dart.dart';
import '../shared/common_tools.dart';

/// HTTP MCP Server - Real MCP server using HTTP transport with streaming
///
/// This example demonstrates how to create a real MCP server that communicates
/// through HTTP requests and Server-Sent Events (SSE). This provides a modern,
/// web-compatible transport method with session management and streaming support.
///
/// Features:
/// - Real MCP protocol implementation using StreamableHTTPServerTransport
/// - Session management with unique session IDs
/// - Event storage for reconnection recovery
/// - Real-time notifications via SSE
/// - Concurrent client support
/// - Shared tool implementations from common_tools.dart
///
/// To run this server:
/// dart run example/06_mcp_integration/http_examples/server.dart
void main() async {
  print('🌐 HTTP MCP Server - Starting real MCP server with HTTP transport\n');

  // Map to store transports by session ID
  final transports = <String, StreamableHTTPServerTransport>{};

  // Create HTTP server
  final httpServer = await HttpServer.bind(InternetAddress.loopbackIPv4, 3000);
  print('🌐 HTTP MCP Server listening on port 3000');
  print('🔗 Connect to: http://localhost:3000/mcp');
  print('💡 Test with: dart run http_examples/client.dart');
  print('🤖 Or integrate with LLM: dart run http_examples/llm_client.dart');
  print('⏹️  Press Ctrl+C to stop\n');

  // Handle HTTP requests
  await for (final request in httpServer) {
    try {
      if (request.uri.path == '/mcp') {
        await _handleMcpRequest(request, transports);
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

// Simple in-memory event store for resumability
class InMemoryEventStore implements EventStore {
  final Map<String, List<({EventId id, JsonRpcMessage message})>> _events = {};
  int _eventCounter = 0;

  @override
  Future<EventId> storeEvent(StreamId streamId, JsonRpcMessage message) async {
    final eventId = (++_eventCounter).toString();
    _events.putIfAbsent(streamId, () => []);
    _events[streamId]!.add((id: eventId, message: message));
    return eventId;
  }

  @override
  Future<StreamId> replayEventsAfter(
    EventId lastEventId, {
    required Future<void> Function(EventId eventId, JsonRpcMessage message)
        send,
  }) async {
    // Find the stream containing this event ID
    String? streamId;
    int fromIndex = -1;

    for (final entry in _events.entries) {
      final idx = entry.value.indexWhere((event) => event.id == lastEventId);
      if (idx >= 0) {
        streamId = entry.key;
        fromIndex = idx;
        break;
      }
    }

    if (streamId == null) {
      throw StateError('Event ID not found: $lastEventId');
    }

    // Replay all events after the lastEventId
    for (int i = fromIndex + 1; i < _events[streamId]!.length; i++) {
      final event = _events[streamId]![i];
      await send(event.id, event.message);
    }

    return streamId;
  }
}

/// Create an MCP server with implementation details
McpServer _getServer() {
  // Create the McpServer with the implementation details and options
  final server = McpServer(
    Implementation(name: 'llm-dart-http-server', version: '1.0.0'),
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

  return server;
}

/// Handle MCP requests based on HTTP method
Future<void> _handleMcpRequest(
  HttpRequest request,
  Map<String, StreamableHTTPServerTransport> transports,
) async {
  switch (request.method) {
    case 'POST':
      await _handlePostRequest(request, transports);
      break;
    case 'GET':
      await _handleGetRequest(request, transports);
      break;
    case 'DELETE':
      await _handleDeleteRequest(request, transports);
      break;
    default:
      request.response.statusCode = HttpStatus.methodNotAllowed;
      request.response.headers
          .set(HttpHeaders.allowHeader, 'GET, POST, DELETE');
      request.response.write('Method Not Allowed');
      await request.response.close();
  }
}

// Function to check if a request is an initialization request
bool _isInitializeRequest(dynamic body) {
  if (body is Map<String, dynamic> &&
      body.containsKey('method') &&
      body['method'] == 'initialize') {
    return true;
  }
  return false;
}

/// Handle POST requests (JSON-RPC messages)
Future<void> _handlePostRequest(
  HttpRequest request,
  Map<String, StreamableHTTPServerTransport> transports,
) async {
  print('📨 Received MCP POST request');

  try {
    // Parse the body
    final bodyBytes = await _collectBytes(request);
    final bodyString = utf8.decode(bodyBytes);
    final body = jsonDecode(bodyString);

    // Check for existing session ID
    final sessionId = request.headers.value('mcp-session-id');
    StreamableHTTPServerTransport? transport;

    if (sessionId != null && transports.containsKey(sessionId)) {
      // Reuse existing transport
      transport = transports[sessionId]!;
      print('   🔄 Using existing session: $sessionId');
    } else if (sessionId == null && _isInitializeRequest(body)) {
      // New initialization request
      print('   🆕 Creating new session for initialization request');
      final eventStore = InMemoryEventStore();
      transport = StreamableHTTPServerTransport(
        options: StreamableHTTPServerTransportOptions(
          sessionIdGenerator: () => generateUUID(),
          eventStore: eventStore, // Enable resumability
          onsessioninitialized: (sessionId) {
            // Store the transport by session ID when session is initialized
            print('   ✅ Session initialized with ID: $sessionId');
            transports[sessionId] = transport!;
          },
        ),
      );

      // Set up onclose handler to clean up transport when closed
      transport.onclose = () {
        final sid = transport!.sessionId;
        if (sid != null && transports.containsKey(sid)) {
          print(
              '   🧹 Transport closed for session $sid, removing from transports map');
          transports.remove(sid);
        }
      };

      // Connect the transport to the MCP server BEFORE handling the request
      final server = _getServer();
      await server.connect(transport);

      await transport.handleRequest(request, body);
      return; // Already handled
    } else {
      // Invalid request - no session ID or not initialization request
      print(
          '   ❌ Invalid request: no session ID or not initialization request');
      request.response
        ..statusCode = HttpStatus.badRequest
        ..headers.set(HttpHeaders.contentTypeHeader, 'application/json')
        ..write(jsonEncode({
          'jsonrpc': '2.0',
          'error': {
            'code': -32000,
            'message': 'Bad Request: No valid session ID provided',
          },
          'id': null,
        }))
        ..close();
      return;
    }

    // Handle the request with existing transport
    await transport.handleRequest(request, body);
    print('   ✅ POST request handled for session: $sessionId');
  } catch (error) {
    print('   ❌ Error handling MCP request: $error');
    // Check if headers are already sent
    bool headersSent = false;
    try {
      headersSent = request.response.headers.contentType
          .toString()
          .startsWith('text/event-stream');
    } catch (_) {
      // Ignore errors when checking headers
    }

    if (!headersSent) {
      request.response
        ..statusCode = HttpStatus.internalServerError
        ..headers.set(HttpHeaders.contentTypeHeader, 'application/json')
        ..write(jsonEncode({
          'jsonrpc': '2.0',
          'error': {
            'code': -32603,
            'message': 'Internal server error',
          },
          'id': null,
        }))
        ..close();
    }
  }
}

/// Handle GET requests for SSE streams
Future<void> _handleGetRequest(
  HttpRequest request,
  Map<String, StreamableHTTPServerTransport> transports,
) async {
  print('📡 Received MCP GET request (SSE)');

  final sessionId = request.headers.value('mcp-session-id');
  if (sessionId == null || !transports.containsKey(sessionId)) {
    print('   ❌ Invalid or missing session ID');
    request.response
      ..statusCode = HttpStatus.badRequest
      ..write('Invalid or missing session ID')
      ..close();
    return;
  }

  // Check for Last-Event-ID header for resumability
  final lastEventId = request.headers.value('Last-Event-ID');
  if (lastEventId != null) {
    print('   🔄 Client reconnecting with Last-Event-ID: $lastEventId');
  } else {
    print('   📡 Establishing new SSE stream for session $sessionId');
  }

  final transport = transports[sessionId]!;
  await transport.handleRequest(request);
  print('   ✅ SSE connection handled for session: $sessionId');
}

/// Handle DELETE requests for session termination
Future<void> _handleDeleteRequest(
  HttpRequest request,
  Map<String, StreamableHTTPServerTransport> transports,
) async {
  print('🗑️ Received MCP DELETE request (session termination)');

  final sessionId = request.headers.value('mcp-session-id');
  if (sessionId == null || !transports.containsKey(sessionId)) {
    print('   ❌ Invalid or missing session ID');
    request.response
      ..statusCode = HttpStatus.badRequest
      ..write('Invalid or missing session ID')
      ..close();
    return;
  }

  print('   🗑️ Processing session termination request for session $sessionId');

  try {
    final transport = transports[sessionId]!;
    await transport.handleRequest(request);
    print('   ✅ Session termination handled for session: $sessionId');
  } catch (error) {
    print('   ❌ Error handling session termination: $error');
    // Check if headers are already sent
    bool headersSent = false;
    try {
      headersSent = request.response.headers.contentType
          .toString()
          .startsWith('text/event-stream');
    } catch (_) {
      // Ignore errors when checking headers
    }

    if (!headersSent) {
      request.response
        ..statusCode = HttpStatus.internalServerError
        ..write('Error processing session termination')
        ..close();
    }
  }
}

/// Helper function to collect bytes from an HTTP request
Future<List<int>> _collectBytes(HttpRequest request) {
  final completer = Completer<List<int>>();
  final bytes = <int>[];

  request.listen(
    bytes.addAll,
    onDone: () => completer.complete(bytes),
    onError: completer.completeError,
    cancelOnError: true,
  );

  return completer.future;
}

/// Register HTTP-specific tools
void _registerHttpSpecificTools(McpServer server) {
  // Simple greeting tool
  server.tool(
    'greet',
    description: 'A simple greeting tool',
    toolInputSchema: ToolInputSchema(
      properties: {
        'name': {'type': 'string', 'description': 'Name to greet'},
      },
    ),
    callback: ({args, extra}) async {
      final name = args?['name'] as String? ?? 'world';
      return CallToolResult.fromContent(
        content: [
          TextContent(text: 'Hello, $name!'),
        ],
      );
    },
  );

  // Multi-greeting tool with notifications
  server.tool(
    'multi-greet',
    description:
        'A tool that sends different greetings with delays between them',
    toolInputSchema: ToolInputSchema(
      properties: {
        'name': {'type': 'string', 'description': 'Name to greet'},
      },
    ),
    annotations: ToolAnnotations(
      title: 'Multiple Greeting Tool',
      readOnlyHint: true,
      openWorldHint: false,
    ),
    callback: ({args, extra}) async {
      final name = args?['name'] as String? ?? 'world';

      // Helper function for sleeping
      Future<void> sleep(int ms) => Future.delayed(Duration(milliseconds: ms));

      // Send debug notification
      await extra?.sendNotification(JsonRpcLoggingMessageNotification(
          logParams: LoggingMessageNotificationParams(
        level: LoggingLevel.debug,
        data: 'Starting multi-greet for $name',
      )));

      await sleep(1000); // Wait 1 second before first greeting

      // Send first info notification
      await extra?.sendNotification(JsonRpcLoggingMessageNotification(
          logParams: LoggingMessageNotificationParams(
        level: LoggingLevel.info,
        data: 'Sending first greeting to $name',
      )));

      await sleep(1000); // Wait another second before second greeting

      // Send second info notification
      await extra?.sendNotification(JsonRpcLoggingMessageNotification(
          logParams: LoggingMessageNotificationParams(
        level: LoggingLevel.info,
        data: 'Sending second greeting to $name',
      )));

      return CallToolResult.fromContent(
        content: [
          TextContent(text: 'Good morning, $name!'),
        ],
      );
    },
  );

  // Register a tool specifically for testing resumability
  server.tool(
    'start-notification-stream',
    description:
        'Starts sending periodic notifications for testing resumability',
    toolInputSchema: ToolInputSchema(
      properties: {
        'interval': {
          'type': 'number',
          'description': 'Interval in milliseconds between notifications',
          'default': 100,
        },
        'count': {
          'type': 'number',
          'description': 'Number of notifications to send (0 for 100)',
          'default': 50,
        },
      },
    ),
    callback: ({args, extra}) async {
      final interval = args?['interval'] as num? ?? 100;
      final count = args?['count'] as num? ?? 50;

      // Helper function for sleeping
      Future<void> sleep(int ms) => Future.delayed(Duration(milliseconds: ms));

      var counter = 0;

      while (count == 0 || counter < count) {
        counter++;
        try {
          await extra?.sendNotification(JsonRpcLoggingMessageNotification(
              logParams: LoggingMessageNotificationParams(
            level: LoggingLevel.info,
            data:
                'Periodic notification #$counter at ${DateTime.now().toIso8601String()}',
          )));
        } catch (error) {
          print('Error sending notification: $error');
        }

        // Wait for the specified interval
        await sleep(interval.toInt());
      }

      return CallToolResult.fromContent(
        content: [
          TextContent(
            text: 'Started sending periodic notifications every ${interval}ms',
          ),
        ],
      );
    },
  );
}
