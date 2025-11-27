# Anthropic Unique Features

Claude's advanced reasoning capabilities and safety-focused design.

## Examples

### [extended_thinking.dart](extended_thinking.dart)
Access Claude's step-by-step reasoning process.

### [file_handling.dart](file_handling.dart)
Advanced document processing and analysis.

### [mcp_connector.dart](mcp_connector.dart)
Anthropic's MCP connector for external tool integration.

## Setup

```bash
export ANTHROPIC_API_KEY="your-anthropic-api-key"

# Run Anthropic-specific examples
dart run extended_thinking.dart
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

## Usage Examples (Prompt-first)

### Extended Thinking
```dart
final model = await ai()
    .anthropic()
    .apiKey('your-key')
    .model('claude-sonnet-4-20250514')
    .buildLanguageModel();

final prompt = ChatPromptBuilder.user()
    .text('Solve this logic puzzle step by step')
    .build();

final response = await generateTextWithModel(
  model,
  promptMessages: [prompt],
);

// Access Claude's thinking process
if (response.thinking != null) {
  print('Claude\'s reasoning: ${response.thinking}');
}
```

### File Processing
```dart
final provider = await ai().anthropic().apiKey('your-key')
    .buildFileManagement();

// Upload and analyze document
final fileObject = await provider.uploadFile(FileUploadRequest(
  file: documentBytes,
  purpose: FilePurpose.assistants,
));

final model = await ai()
    .anthropic()
    .apiKey('your-key')
    .model('claude-sonnet-4-20250514')
    .buildLanguageModel();

final prompt = ChatPromptBuilder.user()
    .text('Analyze this document: ${fileObject.id}')
    .build();

final analysis = await generateTextWithModel(
  model,
  promptMessages: [prompt],
);
```

### MCP Connector
```dart
final model = await ai()
    .anthropic((anthropic) => anthropic
        .mcpServers([
          AnthropicMCPServer.url(
            name: 'file-server',
            url: 'https://example.com/mcp',
            authorizationToken: 'your-oauth-token',
          ),
        ]))
    .apiKey('your-key')
    .model('claude-sonnet-4-20250514')
    .buildLanguageModel();

final prompt = ChatPromptBuilder.user()
    .text('Use the file server to read my documents')
    .build();

final response = await generateTextWithModel(
  model,
  promptMessages: [prompt],
);
```

## Next Steps

- [Core Features](../../02_core_features/) - Basic chat and streaming
- [Advanced Features](../../03_advanced_features/) - Cross-provider capabilities
