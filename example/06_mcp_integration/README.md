# MCP Integration Examples

MCP (Model Context Protocol) integration examples for llm_dart. MCP enables LLMs to interact with external tools through standardized protocols.

## Quick Start

```bash
# Install dependencies
dart pub get

# Start with core concepts
dart run example/06_mcp_integration/mcp_concept_demo.dart

# Test stdio integration
dart run example/06_mcp_integration/stdio_examples/server.dart  # Terminal 1
dart run example/06_mcp_integration/stdio_examples/llm_client.dart  # Terminal 2

# Test HTTP integration
dart run example/06_mcp_integration/http_examples/server.dart  # Terminal 1
dart run example/06_mcp_integration/http_examples/llm_client.dart  # Terminal 2
```

## Examples

| File | Description | API Key Required |
|------|-------------|------------------|
| `mcp_concept_demo.dart` | Core MCP concepts | ❌ |
| `stdio_examples/server.dart` | stdio MCP server | ❌ |
| `stdio_examples/llm_client.dart` | LLM + stdio MCP | ⚠️ Optional |
| `http_examples/server.dart` | HTTP MCP server | ❌ |
| `http_examples/llm_client.dart` | LLM + HTTP MCP | ⚠️ Optional |
| `test_all_examples.dart` | Automated tests | ❌ |

## API Key Setup (Optional)

```bash
# For real LLM integration (optional - examples work without API keys)
export OPENAI_API_KEY="your-key-here"
export ANTHROPIC_API_KEY="sk-ant-your-key-here"
```

## Architecture

```
LLM Provider ◄──► llm_dart Tool System ◄──► MCP Client ◄──► MCP Server
(OpenAI, etc)                                (mcp_dart)      (Tools/Data)
```

## Key Files

- `shared/mcp_tool_bridge.dart` - Converts MCP tools to llm_dart format
- `stdio_examples/` - stdio transport examples
- `http_examples/` - HTTP transport examples

## Troubleshooting

### Common Issues

- **Package not found**: Run `dart pub get`
- **API key errors**: Examples work without API keys (test mode)
- **Connection failed**: Check if MCP server is running
- **No tool calls**: Try more explicit requests like "Use the calculate tool to compute 15 * 23"

### Debug Mode

```dart
import 'package:llm_dart/llm_dart.dart';

final model = await ai()
    .openai()
    .apiKey('YOUR_API_KEY')
    .model('gpt-4o-mini')
    .extension(
      LLMConfigKeys.logger,
      const ConsoleLLMLogger(name: 'llm_dart.mcp', includeTimestamp: true),
    )
    .buildLanguageModel();
```

## Use Cases

- **File Operations**: Read, write, search files through MCP filesystem servers
- **Database Access**: Query databases through MCP database servers
- **API Integration**: Call external APIs through MCP API servers
- **System Tools**: Execute system commands through MCP system servers
- **Custom Tools**: Create domain-specific tools with MCP servers

## Resources

- [MCP Examples](https://modelcontextprotocol.io/examples)
- [MCP Specification](https://modelcontextprotocol.io/specification)
- [MCP Community](https://github.com/modelcontextprotocol)
