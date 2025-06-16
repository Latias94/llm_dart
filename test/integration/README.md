# Anthropic Integration Tests

This directory contains comprehensive integration tests for the Anthropic provider with real API key testing, focusing on the message builder system and advanced features.

## 🚀 Quick Start

### Prerequisites

1. **API Key**: Set your Anthropic API key as an environment variable:
   ```bash
   export ANTHROPIC_API_KEY="your-api-key-here"
   ```

2. **Dependencies**: Ensure all project dependencies are installed:
   ```bash
   dart pub get
   ```

### Running the Tests

#### Run All Integration Tests
```bash
dart test test/integration/
```

#### Run Specific Test Files
```bash
# Basic message builder integration tests
dart test test/integration/anthropic_message_builder_integration_test.dart

# Advanced scenarios and edge cases
dart test test/integration/anthropic_advanced_scenarios_test.dart
```

#### Run with Verbose Output
```bash
dart test test/integration/ --reporter=expanded
```

## 📋 Test Coverage

### Core Message Builder Features
- ✅ **Cached System Messages**: One-hour and five-minute TTL testing
- ✅ **Multiple Cached Groups**: Different cache contexts and TTLs
- ✅ **Complex Content Blocks**: Mixed content with cache controls
- ✅ **Universal + Provider Content**: Combining universal and Anthropic-specific blocks

### Tool Usage Scenarios
- ✅ **Web Search Tool**: Information retrieval and result processing
- ✅ **Calculator Tool**: Mathematical operations with error handling
- ✅ **Multi-Tool Workflows**: Sequential and parallel tool execution
- ✅ **Tool Error Recovery**: Graceful handling of tool failures
- ✅ **Complex Orchestration**: Multi-step workflows with tool dependencies

### Performance & Scalability
- ✅ **Caching Benefits**: Performance comparison with/without caching
- ✅ **Sequential Requests**: Rapid successive requests with shared cache
- ✅ **Concurrent Requests**: Parallel request handling
- ✅ **Cache Warming**: Pre-loading and reusing cached content
- ✅ **Streaming Performance**: Real-time response streaming with caching

### Edge Cases & Error Handling
- ✅ **Long Cached Content**: Large system messages and caching limits
- ✅ **Malformed Responses**: Invalid tool responses and recovery
- ✅ **Empty Cache Controls**: Missing TTL and malformed cache settings
- ✅ **Network Issues**: Timeout and retry scenarios

## 🏗️ Test Structure

### Files Overview

| File | Purpose | Key Features |
|------|---------|--------------|
| `anthropic_message_builder_integration_test.dart` | Core integration tests | Basic caching, tool usage, streaming |
| `anthropic_advanced_scenarios_test.dart` | Advanced scenarios | Edge cases, performance, complex workflows |
| `anthropic_test_helpers.dart` | Test utilities | Helper functions, mock data, test tools |

### Test Categories

#### 1. Cached System Message Tests
```dart
test('should handle cached system message with one-hour TTL', () async {
  final systemMessage = MessageBuilder.system()
      .anthropic((anthropic) => anthropic.cachedText(
            'You are a helpful AI assistant...',
            ttl: AnthropicCacheTtl.oneHour,
          ))
      .build();
  // ... test implementation
});
```

#### 2. Tool Usage Tests
```dart
test('should handle web search tool usage', () async {
  final response = await provider.chatWithTools(messages, [webSearchTool]);
  
  if (response.toolCalls?.isNotEmpty == true) {
    final toolResultMessage = MessageBuilder.user()
        .anthropic((anthropic) => anthropic.toolResult(
              toolUseId: toolCall.id,
              content: 'Search results...',
            ))
        .build();
    // ... continue workflow
  }
});
```

#### 3. Performance Tests
```dart
test('should demonstrate caching benefits', () async {
  final cachedSystem = AnthropicTestHelpers.createCachedSystemMessage(
    content: 'System instructions...',
    ttl: AnthropicCacheTtl.oneHour,
  );

  // Measure first request
  final response1 = await AnthropicTestHelpers.measureExecutionTime(
    () => provider.chat([cachedSystem, userMessage1]),
  );

  // Measure second request (should benefit from caching)
  final response2 = await AnthropicTestHelpers.measureExecutionTime(
    () => provider.chat([cachedSystem, userMessage2]),
  );
});
```

## 🛠️ Helper Utilities

### AnthropicTestHelpers
- `canRunIntegrationTests`: Check if API key is available
- `createTestProvider()`: Standard test provider configuration
- `createCachedSystemMessage()`: Create cached system messages
- `measureExecutionTime()`: Performance measurement wrapper
- `assertResponseQuality()`: Response validation

### TestTools
- `webSearchTool`: Web search tool definition
- `calculatorTool`: Mathematical calculation tool
- `dataAnalysisTool`: Data analysis and insights tool
- `fileOperationsTool`: File operations tool
- `allTools`: Complete tool set for comprehensive testing

### TestScenarios
- **System Messages**: Pre-defined system prompts for different roles
- **User Prompts**: Various user inputs for testing different capabilities
- **Test Conversations**: Ready-to-use conversation pairs

## 📊 Expected Results

### Successful Test Run
```
✅ Cached system message test passed
📊 Input tokens: 245
📊 Output tokens: 156
⏱️  First request: 1250ms
⏱️  Second request: 890ms
🔧 Tool: web_search
📝 Query: latest AI developments
📄 Final response preview: Recent developments in AI include...
```

### Performance Metrics
- **Response Quality**: Non-empty, meaningful responses (>= 10 chars)
- **Token Usage**: Positive input/output token counts
- **Execution Time**: Reasonable response times (< 30s for most tests)
- **Cache Effectiveness**: Potential performance improvements with cached content

## 🚨 Troubleshooting

### Common Issues

#### API Key Not Set
```
⚠️  ANTHROPIC_API_KEY not found. Skipping integration tests.
   Set ANTHROPIC_API_KEY environment variable to run these tests.
```
**Solution**: Export your API key as an environment variable.

#### Network Timeouts
**Solution**: Tests have built-in timeouts (30-180s). Check your internet connection.

#### Rate Limiting
**Solution**: Tests are designed to respect rate limits. If issues persist, add delays between test groups.

#### Tool Call Variations
**Note**: Tool calling behavior may vary. Tests are designed to handle cases where tools are not called.

## 🔧 Customization

### Adding New Test Scenarios
1. Add new system messages to `TestScenarios.systemMessages`
2. Add corresponding user prompts to `TestScenarios.userPrompts`
3. Create test cases using helper functions

### Custom Tool Testing
```dart
final customTool = Tool(
  function: FunctionDefinition(
    name: 'custom_operation',
    description: 'Perform custom operation',
    parameters: ParameterDefinition(/* ... */),
  ),
);

// Add to TestTools or use directly in tests
```

### Performance Benchmarking
```dart
final benchmark = await AnthropicTestHelpers.measureExecutionTime(
  () => provider.chat(messages),
  operationName: 'Custom benchmark',
);
```

## 📈 Monitoring and Metrics

The tests automatically collect and display:
- **Response Times**: API call duration
- **Token Usage**: Input/output token counts
- **Response Quality**: Content length and relevance
- **Tool Usage**: Tool call frequency and success rates
- **Caching Effectiveness**: Performance comparisons

## 🤝 Contributing

When adding new integration tests:
1. Use the helper utilities for consistency
2. Include proper timeout handling
3. Add meaningful assertions and logging
4. Test both success and failure scenarios
5. Document any new helper functions

## 📝 Notes

- Tests require real API calls and will consume Anthropic API credits
- Some tests may take 30-180 seconds due to complex multi-turn conversations
- Tool calling behavior may vary based on model and prompt variations
- Caching benefits depend on Anthropic's implementation and may not always be measurable