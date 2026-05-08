# XAI Unique Features

Real-time web search and live information access with Grok.

New code should prefer the stable `xai(...).chatModel(...)` facade plus typed
xAI provider options from `package:llm_dart/xai.dart`.

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

## Boundary Notes

- The stable xAI surface in `llm_dart` is the audited live-search path through
  `XAIGenerateTextOptions` and `XAILiveSearchOptions`.
- Broader tool-based search or richer replay-oriented xAI behavior remains
  deferred provider-owned policy work until a narrower stable contract is
  justified.

## Usage Examples

### Live Search Query
```dart
import 'package:llm_dart/core.dart' as core;
import 'package:llm_dart/xai.dart' as xai;

final model = xai.xai(apiKey: 'your-key').chatModel('grok-3');

final result = await core.generateTextCall(
  model: model,
  prompt: [
    core.UserPromptMessage.text('What are the latest AI developments this week?'),
  ],
  callOptions: const core.CallOptions(
    providerOptions: xai.XAIGenerateTextOptions(
      search: xai.XAILiveSearchOptions.autoWeb(maxSearchResults: 5),
    ),
  ),
);

print(result.text);
```

### Real-time Data Access
```dart
import 'package:llm_dart/core.dart' as core;
import 'package:llm_dart/xai.dart' as xai;

final model = xai.xai(apiKey: 'your-key').chatModel('grok-3');

final result = await core.generateTextCall(
  model: model,
  prompt: [
    core.UserPromptMessage.text('Current Bitcoin price and market trends'),
  ],
  callOptions: const core.CallOptions(
    providerOptions: xai.XAIGenerateTextOptions(
      search: const xai.XAILiveSearchOptions(
        maxSearchResults: 4,
        sources: [
          xai.XAINewsSearchSource(),
          xai.XAIWebSearchSource(),
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
