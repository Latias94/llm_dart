# HTTP MCP Examples - Real Implementation

This directory contains **real** MCP integration examples using HTTP transport with streaming capabilities. These examples use the actual MCP protocol implementation from `mcp_dart` library, not simulated versions.

## Files in this directory

- **`server.dart`** - **Real** MCP server using `StreamableHTTPServerTransport`
- **`client.dart`** - **Real** MCP client using `StreamableHttpClientTransport` for direct tool testing
- **`llm_client.dart`** - **Real** LLM integration showing how AI agents can use MCP tools via HTTP
- **`simple_stream_client.dart`** - **Simple** streaming example focusing on basic streaming + tools

## What is HTTP Transport?

HTTP transport uses standard HTTP requests and Server-Sent Events (SSE) for communication:
- **POST /mcp** - Client sends JSON-RPC messages to server
- **GET /mcp** - Client establishes SSE connection for notifications
- **DELETE /mcp** - Client terminates session

## Key Features - Real MCP Implementation

### Core Capabilities

1. **Real MCP Protocol** - Uses actual `mcp_dart` library implementation
2. **Session Management** - Each client connection gets a unique session ID
3. **Event Storage** - Supports message replay and reconnection recovery
4. **Streaming Notifications** - Real-time push notifications via SSE
5. **RESTful API** - Standard HTTP endpoint design
6. **Concurrent Support** - Handle multiple clients simultaneously
7. **Streaming Integration** - Real-time LLM responses with tool execution

## Quick Start

### 1. Start the HTTP MCP Server

```bash
dart run example/06_mcp_integration/http_examples/server.dart
```

The server will start at `http://localhost:3000/mcp`.

### 2. Test with REST Client

In another terminal:

```bash
dart run example/06_mcp_integration/http_examples/client.dart
```

This will connect to the server via HTTP and test all available tools.

### 3. Test LLM Integration

```bash
# Set your API key first
export OPENAI_API_KEY="your-key-here"

# Run the LLM integration example
dart run example/06_mcp_integration/http_examples/llm_client.dart
```

### 4. Test Streaming LLM Integration

```bash
# Set your API key first
export OPENAI_API_KEY="your-key-here"

dart run example/06_mcp_integration/http_examples/simple_stream_client.dart
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

## Real MCP Architecture

```text
┌─────────────────────┐    Real HTTP/SSE    ┌─────────────────────┐
│   Real MCP Client   │◄──────────────────►│   Real MCP Server   │
│ StreamableHttpClient│                    │StreamableHTTPServer │
│   Transport         │                    │   Transport         │
└─────────────────────┘                    └─────────────────────┘
         │                                            │
         ▼                                            ▼
┌─────────────────────┐                    ┌─────────────────────┐
│   llm_dart Tools    │                    │   Real MCP Tools    │
│   Integration       │                    │  (shared/common)    │
└─────────────────────┘                    └─────────────────────┘
         │
         ▼
┌─────────────────────┐
│   OpenAI/LLM        │
│   Provider          │
└─────────────────────┘
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
- **Streaming AI chat** - Real-time LLM responses with tool execution
- **Interactive AI assistants** - Progressive tool chain execution

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
