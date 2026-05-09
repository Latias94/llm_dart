# Anthropic Provider Features

Anthropic already has a stable chat facade plus typed Anthropic-owned
invocation options for extended thinking, MCP servers, and native tools.

For new code, prefer:

- `anthropic(...).chatModel(...)`
- `AnthropicGenerateTextOptions` for extended-thinking and MCP controls
- `anthropic(...).files()` for stable file upload, listing, metadata,
  download, and deletion

## Example Status

### Stable or Mostly Stable

- [extended_thinking.dart](extended_thinking.dart)
- [streaming_tool_calling.dart](streaming_tool_calling.dart)
- [mcp_connector.dart](mcp_connector.dart)

### Transitional or Compatibility-Oriented

- [file_handling.dart](file_handling.dart)

## Setup

```bash
export ANTHROPIC_API_KEY="your-anthropic-api-key"

dart run extended_thinking.dart
dart run streaming_tool_calling.dart
dart run mcp_connector.dart
```

Run the legacy file-handling appendix only when checking old provider-shell
integration code:

```bash
dart run file_handling.dart
```

## Stable Usage Examples

### Extended Thinking

```dart
import 'package:llm_dart/anthropic.dart' as anthropic;
import 'package:llm_dart/core.dart' as core;
import 'package:llm_dart/llm_dart.dart' as llm;

final model = llm.anthropic(apiKey: 'your-key').chatModel('claude-sonnet-4-5');

final result = await core.generateTextCall(
  model: model,
  prompt: [
    core.UserPromptMessage.text('Solve this logic puzzle step by step.'),
  ],
  callOptions: const core.CallOptions(
    providerOptions: anthropic.AnthropicGenerateTextOptions(
      extendedThinking: true,
      thinkingBudgetTokens: 2048,
    ),
  ),
);

print(result.reasoningText);
print(result.text);
```

### MCP Server Integration

```dart
import 'package:llm_dart/anthropic.dart' as anthropic;
import 'package:llm_dart/core.dart' as core;
import 'package:llm_dart/llm_dart.dart' as llm;

final model = llm.anthropic(apiKey: 'your-key').chatModel('claude-sonnet-4-5');

final result = await core.generateTextCall(
  model: model,
  prompt: [
    core.UserPromptMessage.text('Use the file server to read my documents.'),
  ],
  callOptions: const core.CallOptions(
    providerOptions: anthropic.AnthropicGenerateTextOptions(
      mcpServers: [
        anthropic.AnthropicMcpServer.url(
          name: 'file-server',
          url: 'https://example.com/mcp',
          authorizationToken: 'your-oauth-token',
        ),
      ],
    ),
  ),
);

print(result.text);
```

### Streaming Tool Tracing

```dart
import 'package:llm_dart/core.dart' as core;
import 'package:llm_dart/llm_dart.dart' as llm;

final model = llm.anthropic(apiKey: 'your-key').chatModel('claude-sonnet-4-5');

final stream = core.streamTextCall(
  model: model,
  prompt: [
    core.UserPromptMessage.text('Find the weather in Tokyo.'),
  ],
  tools: [
    core.FunctionToolDefinition(
      name: 'get_weather',
      inputSchema: core.ToolJsonSchema.object(
        properties: {
          'location': {'type': 'string'},
        },
        required: ['location'],
      ),
    ),
  ],
  toolChoice: const core.RequiredToolChoice(),
);

await for (final event in stream) {
  switch (event) {
    case core.ToolInputStartEvent(:final toolName):
      print('tool input started: $toolName');
    case core.ToolCallEvent(:final toolCall):
      print('tool call: ${toolCall.toolName} ${toolCall.input}');
    case core.TextDeltaEvent(:final delta):
      stdout.write(delta);
    default:
      break;
  }
}
```

### Stable Files Client

```dart
import 'package:llm_dart/llm_dart.dart' as llm;

final files = llm.anthropic(apiKey: 'your-key').files();

final uploaded = await files.uploadBytes(
  [72, 101, 108, 108, 111],
  filename: 'hello.txt',
  mediaType: 'text/plain',
);
final page = await files.listFiles(limit: 20);
final metadata = await files.getFile(uploaded.id);
final download = await files.downloadFile(uploaded.id);
final deleted = await files.deleteFile(uploaded.id);

print(page.data.length);
print(metadata.filename);
print(download.sizeBytes);
print(deleted.deleted);
```

## Boundary Notes

- Extended thinking must stay provider owned. Do not move `extendedThinking` or
  `thinkingBudgetTokens` into shared `GenerateTextOptions`.
- Anthropic's stable files client now covers upload, list, metadata, download,
  and delete through `anthropic(...).files()`.
  `file_handling.dart` remains a compatibility appendix; the modern end-to-end
  files example lives in `example/02_core_features/file_management.dart`.
- Anthropic streaming tool activity should stay on shared `TextStreamEvent`
  surfaces. Do not introduce Anthropic-only stream contracts for ordinary tool
  tracing.
- MCP server declarations already have a typed stable surface through
  `AnthropicGenerateTextOptions.mcpServers`, and `mcp_connector.dart` now stays
  on stable call results instead of compatibility response casts.

## Next Steps

- [Core Features](../../02_core_features/) - Stable chat and tool patterns
- [Advanced Features](../../03_advanced_features/) - Shared reasoning examples
- [Use Cases](../../05_use_cases/) - Flutter-facing integration patterns
