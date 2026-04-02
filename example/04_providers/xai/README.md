# XAI Unique Features

Real-time web search and live information access with Grok.

New code should prefer the stable `AI.xai(...).chatModel(...)` facade plus
typed xAI provider options from `package:llm_dart/openai.dart`.

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
import 'package:llm_dart/ai.dart' as llm;
import 'package:llm_dart/core.dart' as core;
import 'package:llm_dart/openai.dart' as openai;

final model = llm.AI.xai(apiKey: 'your-key').chatModel('grok-3');

final result = await core.generateTextCall(
  model: model,
  prompt: [
    core.UserPromptMessage.text('What are the latest AI developments this week?'),
  ],
  callOptions: const core.CallOptions(
    providerOptions: openai.XAIGenerateTextOptions(
      search: openai.XAILiveSearchOptions.autoWeb(maxSearchResults: 5),
    ),
  ),
);

print(result.text);
```

### Real-time Data Access
```dart
import 'package:llm_dart/ai.dart' as llm;
import 'package:llm_dart/core.dart' as core;
import 'package:llm_dart/openai.dart' as openai;

final model = llm.AI.xai(apiKey: 'your-key').chatModel('grok-3');

final result = await core.generateTextCall(
  model: model,
  prompt: [
    core.UserPromptMessage.text('Current Bitcoin price and market trends'),
  ],
  callOptions: const core.CallOptions(
    providerOptions: openai.XAIGenerateTextOptions(
      search: const openai.XAILiveSearchOptions(
        maxSearchResults: 4,
        sources: [
          openai.XAINewsSearchSource(),
          openai.XAIWebSearchSource(),
        ],
      ),
    ),
  ),
);

print(result.text);
```

## Next Steps

- [Core Features](../../02_core_features/) - Basic chat and streaming
- [Advanced Features](../../03_advanced_features/) - Cross-provider capabilities
