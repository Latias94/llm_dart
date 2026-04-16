# HTTP MCP Examples

This directory contains the HTTP transport examples for MCP integration.

The important boundary is now explicit:

- HTTP transport and session lifecycle stay in `mcp_dart`
- MCP tool schema/result adaptation lives in `../shared/mcp_tool_bridge.dart`
- model orchestration lives on the stable `llm_dart/core.dart` runners

## Files

- `server.dart`
  - real MCP server using `StreamableHTTPServerTransport`
- `client.dart`
  - direct HTTP MCP client for transport-level validation
- `llm_client.dart`
  - stable `core.runTextGeneration(...)` example with HTTP MCP tools
- `simple_stream_client.dart`
  - stable `core.streamTextRun(...)` example showing tool-input and tool-call
    events

## Quick Start

### 1. Start the HTTP MCP server

```bash
cd example/06_mcp_integration
dart run http_examples/server.dart
```

The server listens on `http://localhost:3000/mcp`.

### 2. Validate transport directly

```bash
dart run http_examples/client.dart
```

### 3. Run the non-streaming LLM example

```bash
export OPENAI_API_KEY="your-key-here"
dart run http_examples/llm_client.dart
```

### 4. Run the streaming LLM example

```bash
export OPENAI_API_KEY="your-key-here"
dart run http_examples/simple_stream_client.dart
```

## Stable Runtime Shape

```text
OpenAI chat model
        │
        ▼
runTextGeneration / streamTextRun
        │
        ▼
MCP bridge
        │
        ▼
StreamableHttpClientTransport
        │
        ▼
HTTP MCP server
```

## HTTP-Specific Capabilities

- session IDs stay transport-owned
- SSE notifications stay transport-owned
- tool discovery and execution still happen through MCP protocol calls
- the LLM example no longer hand-builds assistant/tool replay messages

## Available Tools

The HTTP server exposes:

1. `calculate`
2. `random_number`
3. `current_time`
4. `file_info`
5. `system_info`
6. `uuid_generate`
7. `greet`
8. `multi-greet`

`simple_stream_client.dart` intentionally narrows the exposed tool set to
`current_time` so the streaming event flow stays easy to read.

## API Endpoints

### `POST /mcp`

- send JSON-RPC requests
- use `mcp-session-id` after initialization

### `GET /mcp`

- open the SSE notification channel
- optionally pass `Last-Event-ID` for replay

### `DELETE /mcp`

- terminate the current session

## Troubleshooting

### Port already in use

Change the bind port in `server.dart` if `3000` is occupied.

### Session issues

Check the server output for the generated session ID and make sure the client
reuses it consistently across requests.

### Streaming issues

- confirm the SSE channel is connected
- watch the `ToolInputStartEvent` and `ToolCallEvent` logs
- verify the MCP server is still alive while the model is waiting for tool
  results
