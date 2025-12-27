# XAI Unique Features

Real-time web search and live information access with Grok.

## Examples

### [live_search.dart](live_search.dart)
Live web search integration and real-time information access.

## Setup

```bash
export XAI_API_KEY="your-xai-api-key"

# Run XAI live search example
dart run live_search.dart
```

## Unique Capabilities

### Live Search Integration
- **Real-time Web Access**: Current information and breaking news
- **Fact Checking**: Verify claims with live sources
- **Trending Analysis**: Social media and news trend analysis

### Current Information Access
- **Live Data**: Real-time cryptocurrency, weather, sports scores
- **News Integration**: Latest developments and current events
- **Search Enhancement**: Automatic web search for current topics

## Usage Examples

### Live Search Query
```dart
import 'package:llm_dart_ai/llm_dart_ai.dart';
import 'package:llm_dart_builder/llm_dart_builder.dart';
import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_xai/llm_dart_xai.dart';

registerXAI();

final provider = await LLMBuilder()
    .provider(xaiProviderId)
    .apiKey('your-key')
    .model('grok-3')
    .option('liveSearch', true)
    .build();

final result = await generateText(
  model: provider,
  messages: [ChatMessage.user('What are the latest AI developments this week?')],
);

// Grok automatically includes live search results
print('Current info: ${result.text}');
print(result.providerMetadata);
```

### Real-time Data Access
```dart
final provider = await LLMBuilder()
    .provider(xaiProviderId)
    .apiKey('your-key')
    .model('grok-3')
    .option('liveSearch', true)
    .build();

final result = await generateText(
  model: provider,
  messages: [ChatMessage.user('Current Bitcoin price and market trends')],
);

// Live financial data integrated automatically
print('Live data: ${result.text}');
print(result.providerMetadata);
```

## Next Steps

- [Core Features](../../02_core_features/) - Basic chat and streaming
- [Advanced Features](../../03_advanced_features/) - Cross-provider capabilities
