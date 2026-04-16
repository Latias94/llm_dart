# stdio MCP Examples

This directory contains the stdio transport examples for MCP integration.

The examples now keep a clean separation between:

- stdio process transport in `mcp_dart`
- MCP schema/result adaptation in `../shared/mcp_tool_bridge.dart`
- shared tool continuation in `core.runTextGeneration(...)`

## Files

- `server.dart`
  - real MCP server using stdio transport
- `client.dart`
  - direct stdio MCP client without an LLM
- `llm_client.dart`
  - stable `runTextGeneration(...)` example with automatic MCP tool
    continuation

## Quick Start

### 1. Start the stdio MCP server

```bash
cd example/06_mcp_integration
dart run stdio_examples/server.dart
```

### 2. Validate transport directly

```bash
dart run stdio_examples/client.dart
```

### 3. Run the LLM integration example

```bash
export OPENAI_API_KEY="your-key-here"
dart run stdio_examples/llm_client.dart
```

## Stable Runtime Shape

```text
OpenAI chat model
        │
        ▼
runTextGeneration
        │
        ▼
MCP bridge
        │
        ▼
StdioClientTransport
        │
        ▼
stdio MCP server
```

## Available Tools

The stdio server exposes:

1. `calculate`
2. `random_number`
3. `current_time`
4. `file_info`
5. `system_info`
6. `uuid_generate`

## Why This Example Changed

The old version hand-built a local tool loop with legacy chat/tool messages.

The current version instead:

- discovers MCP tools once
- exposes them as shared `FunctionToolDefinition`s
- lets `GenerateTextFunctionToolExecutor` call back into MCP
- lets `runTextGeneration(...)` own the replay/continuation flow

That keeps the example closer to the real stable library boundary and avoids
duplicating orchestration logic in every transport sample.

## Troubleshooting

### Server not responding

- confirm the server process started successfully
- check stderr output from the child process
- make sure no other process is intercepting stdio

### Tool execution errors

- verify that the generated tool arguments match the MCP input schema
- inspect the logged MCP tool result payload
- check the server implementation in `server.dart`

### Connection issues

- keep the client and server on the same machine for this example
- make sure the spawned Dart process can resolve the example package path
