# MCP Integration Examples

MCP (Model Context Protocol) examples for `llm_dart`.

This standalone example package now follows a stable-first integration shape:

1. create a model with `openai(...).chatModel(...)`
2. discover MCP tools through `mcp_dart`
3. convert them into shared `FunctionToolDefinition`s
4. let `core.runTextGeneration(...)` or `core.streamTextRun(...)` handle the
   tool continuation loop

MCP-specific schema conversion and result normalization now live in a dedicated
bridge instead of being reimplemented inside every example.

## Quick Start

```bash
# Enter the standalone example package
cd example/06_mcp_integration

# Install dependencies
dart pub get

# Start with the concept walkthrough
dart run mcp_concept_demo.dart

# stdio MCP. The client examples spawn the stdio server process.
dart run stdio_examples/client.dart
dart run stdio_examples/llm_client.dart

# HTTP MCP. Start the server in one terminal, then run clients separately.
dart run http_examples/server.dart
dart run http_examples/client.dart
dart run http_examples/llm_client.dart
dart run http_examples/simple_stream_client.dart
```

## Examples

| File | Description | API Key Required |
|------|-------------|------------------|
| `mcp_concept_demo.dart` | Concept walkthrough and architecture notes | ❌ |
| `shared/mcp_tool_bridge.dart` | Shared bridge from MCP tools/results to `llm_dart/core.dart` | ❌ |
| `stdio_examples/client.dart` | Direct stdio MCP client without an LLM | ❌ |
| `stdio_examples/llm_client.dart` | Stable `runTextGeneration(...)` + MCP stdio tools | ✅ |
| `http_examples/client.dart` | Direct HTTP MCP client without an LLM | ❌ |
| `http_examples/llm_client.dart` | Stable `runTextGeneration(...)` + HTTP MCP tools | ✅ |
| `http_examples/simple_stream_client.dart` | Stable `streamTextRun(...)` with MCP tool events | ✅ |

## Stable Integration Shape

```text
provider factory / LanguageModel
        │
        ▼
llm_dart core runners
runTextGeneration / streamTextRun
        │
        ▼
shared/mcp_tool_bridge.dart
schema bridge + function tool executor
        │
        ▼
mcp_dart client / transport
        │
        ▼
MCP server tools
```

## Key Files

- `shared/mcp_tool_bridge.dart`
  - converts `mcp_dart` tool definitions to shared tool schemas
  - parses model-emitted tool input into MCP call arguments
  - normalizes `CallToolResult` into shared tool outputs
- `stdio_examples/llm_client.dart`
  - shows non-streaming tool continuation on `core.runTextGeneration(...)`
- `http_examples/llm_client.dart`
  - keeps HTTP session handling and SSE notifications transport-owned
- `http_examples/simple_stream_client.dart`
  - shows the shared streaming event model:
    `TextDeltaEvent`, `ToolInputStartEvent`, `ToolCallEvent`, `FinishEvent`

## API Key Setup

```bash
export OPENAI_API_KEY="your-key-here"
```

The direct MCP client examples do not need an API key.

## Troubleshooting

- **Package not found**: Run `dart pub get` inside `example/06_mcp_integration`
- **LLM request failed**: Set a valid `OPENAI_API_KEY`
- **stdio connection failed**: Run the client from `example/06_mcp_integration`
  so its spawned Dart process can resolve `stdio_examples/server.dart`
- **HTTP connection failed**: Check whether `http_examples/server.dart` is
  already running
- **No tool call happened**: Use prompts that explicitly require tool usage
- **Streaming output looks incomplete**: Check the tool-call event log before
  assuming the model failed

## Debug Mode

```dart
import 'package:llm_dart/transport.dart' show Level, Logger;

Logger.root.level = Level.ALL;
Logger.root.onRecord.listen((record) {
  print('${record.level.name}: ${record.time}: ${record.message}');
});
```

The MCP examples call `silenceMcpLogs()` so transport internals do not obscure
the walkthrough output. Remove that call or use `resetMcpLogHandler()` when you
need raw `mcp_dart` protocol and transport diagnostics.

## Resources

- [MCP Examples](https://modelcontextprotocol.io/examples)
- [MCP Specification](https://modelcontextprotocol.io/specification)
- [MCP Community](https://github.com/modelcontextprotocol)
