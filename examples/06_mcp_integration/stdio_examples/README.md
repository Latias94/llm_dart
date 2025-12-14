# stdio MCP Examples

This directory contains examples of MCP integration using stdio transport. stdio transport is the traditional way of communicating with MCP servers through standard input/output streams.

## Files in this directory

- **`server.dart`** - Real MCP server implementation using stdio transport
- **`client.dart`** - Real REST client that tests server tools directly via stdio (no LLM)
- **`llm_client.dart`** - Real LLM integration example showing how LLMs can use MCP tools via stdio

## What is stdio Transport?

stdio transport uses standard input/output streams for communication between MCP client and server:
- **stdin** - Client sends JSON-RPC messages to server
- **stdout** - Server sends JSON-RPC responses back to client
- **stderr** - Server can send debug/error messages

## Quick Start

### 1. Start the stdio MCP Server

```bash
cd examples
dart pub get
dart run 06_mcp_integration/stdio_examples/server.dart
```

The server will start and wait for JSON-RPC messages on stdin.

### 2. Test with Real REST Client

In another terminal:

```bash
dart run 06_mcp_integration/stdio_examples/client.dart
```

This will spawn a real MCP client, connect to the server process, and test all available tools directly.

### 3. Test Real LLM Integration

```bash
# Set your API key first
export OPENAI_API_KEY="your-key-here"

# Run the real LLM integration example
dart run 06_mcp_integration/stdio_examples/llm_client.dart
```

This will create a real MCP client, connect to the server, discover tools, and use them with LLM tool calling.

## Available Tools

The stdio server provides these tools:

1. **calculate** - Perform mathematical calculations
2. **random_number** - Generate random numbers within specified range
3. **current_time** - Get current date and time in various formats
4. **file_info** - Get information about files or directories
5. **system_info** - Get system information
6. **uuid_generate** - Generate UUID

## Architecture

### Real stdio MCP Integration

```text
┌─────────────────┐    stdin/stdout    ┌─────────────────┐
│   Real MCP      │◄─────────────────►│   Real MCP      │
│   Client        │                    │   Server        │
│ (client.dart)   │                    │ (server.dart)   │
└─────────────────┘                    └─────────────────┘
                                              │
                                              ▼
                                       ┌─────────────────┐
                                       │  Common Tools   │
                                       │ (shared/common) │
                                       └─────────────────┘

┌─────────────────┐    Tool Calls      ┌─────────────────┐    stdin/stdout    ┌─────────────────┐
│      LLM        │◄─────────────────►│   Real MCP      │◄─────────────────►│   Real MCP      │
│   (OpenAI)      │                    │   Client        │                    │   Server        │
│                 │                    │(llm_client.dart)│                    │ (server.dart)   │
└─────────────────┘                    └─────────────────┘                    └─────────────────┘
```

## Use Cases

stdio transport is ideal for:
- **Local development** - Easy to debug with simple I/O
- **Command-line tools** - Natural fit for CLI applications
- **Process spawning** - Easy to start as child processes
- **Simple integration** - Minimal setup required

## Troubleshooting

### Server not responding
- Check if server process is running
- Verify JSON-RPC message format
- Check stderr for error messages

### Tool execution errors
- Verify tool parameters match schema
- Check server logs for detailed error messages
- Ensure required dependencies are available

### Connection issues
- Make sure only one client connects at a time (stdio limitation)
- Verify process communication is working
- Check for buffer overflow issues with large messages
