# HTTP MCP Examples

This directory contains examples of MCP integration using HTTP transport with streaming capabilities. HTTP transport provides a modern, web-compatible way of communicating with MCP servers.

## Files in this directory

- **`server.dart`** - MCP server implementation using HTTP transport with streaming
- **`rest_client.dart`** - REST client that tests server tools directly via HTTP
- **`llm_integration.dart`** - Integration example showing how LLMs can use MCP tools via HTTP

## What is HTTP Transport?

HTTP transport uses standard HTTP requests and Server-Sent Events (SSE) for communication:
- **POST /mcp** - Client sends JSON-RPC messages to server
- **GET /mcp** - Client establishes SSE connection for notifications
- **DELETE /mcp** - Client terminates session

## Key Features

### Comparison with stdio Version

| Feature | stdio Version | HTTP Version |
|---------|---------------|--------------|
| Transport | stdin/stdout | HTTP + Server-Sent Events |
| Session Management | None | ✅ Session ID support |
| Resumability | None | ✅ Reconnection support |
| Concurrent Connections | Single | ✅ Multi-client support |
| Real-time Notifications | None | ✅ SSE streaming |
| Web Compatibility | None | ✅ Web application ready |

### Core Capabilities

1. **Session Management** - Each client connection gets a unique session ID
2. **Event Storage** - Supports message replay and reconnection recovery
3. **Streaming Notifications** - Real-time push notifications via SSE
4. **RESTful API** - Standard HTTP endpoint design
5. **Concurrent Support** - Handle multiple clients simultaneously

## Quick Start

### 1. Start the HTTP MCP Server

```bash
dart run example/06_mcp_integration/http_examples/server.dart
```

The server will start at `http://localhost:3000/mcp`.

### 2. Test with REST Client

In another terminal:

```bash
dart run example/06_mcp_integration/http_examples/rest_client.dart
```

This will connect to the server via HTTP and test all available tools.

### 3. Test LLM Integration

```bash
# Set your API key first
export OPENAI_API_KEY="your-key-here"

# Run the LLM integration example
dart run example/06_mcp_integration/http_examples/llm_integration.dart
```

## Available Tools

The HTTP server provides these tools:

1. **calculate** - Perform mathematical calculations
2. **random_number** - Generate random numbers within specified range
3. **current_time** - Get current date and time in various formats
4. **file_info** - Get information about files or directories
5. **system_info** - Get system information
6. **uuid_generate** - Generate UUID
7. **greet** - Simple greeting tool (HTTP-specific)
8. **multi-greet** - Multiple greetings with notifications (streaming demo)

## Architecture

```
┌─────────────────┐    HTTP/SSE    ┌─────────────────┐
│   MCP Client    │◄──────────────►│   HTTP Server   │
│ (rest_client)   │                │   (server.dart) │
└─────────────────┘                └─────────────────┘
                                          │
                                          ▼
                                   ┌─────────────────┐
                                   │  Common Tools   │
                                   │ (shared/common) │
                                   └─────────────────┘
```

## API Endpoints

### POST /mcp
- **Purpose**: Send MCP messages
- **Headers**:
  - `Content-Type: application/json`
  - `mcp-session-id: <session-id>` (after initialization)
- **Body**: JSON-RPC 2.0 message

### GET /mcp
- **Purpose**: Establish SSE connection for notifications
- **Headers**:
  - `mcp-session-id: <session-id>`
  - `Last-Event-ID: <event-id>` (optional, for resumption)

### DELETE /mcp
- **Purpose**: Terminate session
- **Headers**:
  - `mcp-session-id: <session-id>`

## Use Cases

HTTP transport is ideal for:
- **Web applications** - Direct browser integration
- **Microservices** - RESTful service architecture
- **Cloud deployment** - Scalable server infrastructure
- **Real-time applications** - SSE streaming notifications
- **Multi-client scenarios** - Concurrent user support

## Troubleshooting

### Port already in use
If port 3000 is occupied, modify the port in server.dart:
```dart
final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 3001);
```

### Session lost
Check server logs for session initialization messages:
```
Session initialized with ID: abc123-def456-ghi789
```

### Connection issues
Ensure:
1. Server is running
2. Firewall allows port access
3. Client uses correct URL
4. Session headers are properly set

### Streaming not working
- Verify SSE connection is established
- Check for proper event handling
- Monitor network tab in browser dev tools
- Ensure session ID is consistent across requests
