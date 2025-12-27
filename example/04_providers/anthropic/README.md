# Anthropic Unique Features

Claude's advanced reasoning capabilities and safety-focused design.

## Examples

### [extended_thinking.dart](extended_thinking.dart)
Access Claude's step-by-step reasoning process.

### [tool_use_interleaved_thinking_stream.dart](tool_use_interleaved_thinking_stream.dart)
Prompt IR + local tool loop, streamed as `LLMStreamPart`s.

### [file_handling.dart](file_handling.dart)
Advanced document processing and analysis.

### [mcp_connector.dart](mcp_connector.dart)
Anthropic's MCP connector for external tool integration.

## Setup

```bash
export ANTHROPIC_API_KEY="your-anthropic-api-key"

# Run Anthropic-specific examples
dart run extended_thinking.dart
dart run tool_use_interleaved_thinking_stream.dart
dart run file_handling.dart
dart run mcp_connector.dart
```

## Unique Capabilities

### Extended Thinking
- **Reasoning Process**: Access Claude's step-by-step thinking
- **Problem Solving**: Complex logical analysis and decomposition
- **Transparency**: See how Claude arrives at conclusions

### Advanced File Processing
- **Document Analysis**: Deep understanding of complex documents
- **Content Extraction**: Intelligent text and data extraction
- **Summarization**: Comprehensive document summarization

### MCP Connector
- **Direct Integration**: Connect to MCP servers without separate client
- **OAuth Support**: Secure authentication with external services
- **Tool Filtering**: Control which tools are available to Claude

## Usage Examples

### Extended Thinking
```dart
registerAnthropic();

final model = await LLMBuilder()
    .provider(anthropicProviderId)
    .apiKey('your-key')
    .model('claude-sonnet-4-20250514')
    .providerOptions(anthropicProviderId, const {
      'reasoning': true,
      'thinkingBudgetTokens': 1024,
    })
    .build();

final result = await generateText(
  model: model,
  promptIr: Prompt(messages: [PromptMessage.user('Solve this logic puzzle step by step')]),
);

if (result.thinking != null) {
  print("Claude's reasoning: ${result.thinking}");
}
```

### File Processing
```dart
final provider = createAnthropicProvider(
  apiKey: 'your-key',
  model: 'claude-sonnet-4-20250514',
);

// Upload and analyze document
final fileObject = await provider.uploadFile(FileUploadRequest(
  file: documentBytes,
  purpose: FilePurpose.assistants,
));

final analysis = await generateText(
  model: provider,
  promptIr: Prompt(
    messages: [
      PromptMessage(
        role: ChatRole.user,
        parts: [
          const TextPart('Analyze this document:'),
          FilePart(mime: FileMime.pdf, data: documentBytes),
        ],
      ),
    ],
  ),
);
```

### MCP Connector
```dart
registerAnthropic();

final model = await LLMBuilder()
    .provider(anthropicProviderId)
    .apiKey('your-key')
    .model('claude-sonnet-4-20250514')
    .providerOptions(anthropicProviderId, {
      'mcpServers': [
        AnthropicMCPServer.url(
          name: 'file-server',
          url: 'https://example.com/mcp',
          authorizationToken: 'your-oauth-token',
        ).toJson(),
      ],
    })
    .build();

final response = await generateText(
  model: model,
  promptIr: Prompt(messages: [PromptMessage.user('Use the file server to read my documents')]),
);
```

## Next Steps

- [Core Features](../../02_core_features/) - Basic chat and streaming
- [Advanced Features](../../03_advanced_features/) - Cross-provider capabilities
