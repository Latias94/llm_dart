# Provider Tool Catalogs (ProviderTool)

This doc describes the recommended way to configure **provider-executed** tools
(aka provider-native / built-in tools) in `llm_dart`.

## Why catalogs?

Provider-native tools have provider-specific semantics and request JSON shapes.
To keep the *standard* surface stable, `llm_dart` models them as:

- `Tool` / `FunctionTool`: executed locally by tool loops
- `ProviderTool`: executed by the provider (server-side)

Typed catalogs exist to avoid “stringly-typed” ids/options:

- `OpenAIProviderTools` (Responses API built-ins)
- `AnthropicProviderTools` (Anthropic server tools)
- `GoogleProviderTools` (Gemini built-ins)

## How to use

### Using `providerTools` directly

```dart
registerOpenAI();

final provider = await LLMBuilder()
    .provider(openaiProviderId)
    .apiKey(apiKey)
    .model('gpt-4o')
    .providerTool(OpenAIProviderTools.webSearch(
      contextSize: OpenAIWebSearchContextSize.high,
    ))
    .build();
```

Note: `llm_dart` does not rewrite `model` when enabling provider-native tools. If a
tool requires a specific model family, the provider API should return an error and
the caller can pick an appropriate model.

```dart
registerAnthropic();

final provider = await LLMBuilder()
    .provider(anthropicProviderId)
    .apiKey(apiKey)
    .model('claude-sonnet-4-20250514')
    .providerTool(AnthropicProviderTools.webSearch(
      toolType: 'web_search_20250305',
      options: AnthropicWebSearchToolOptions(
        maxUses: 2,
        userLocation: AnthropicUserLocation(
          city: 'San Francisco',
          region: 'California',
          country: 'US',
          timezone: 'America/Los_Angeles',
        ),
      ),
    ))
    .build();
```

```dart
registerAnthropic();

final provider = await LLMBuilder()
    .provider(anthropicProviderId)
    .apiKey(apiKey)
    .model('claude-sonnet-4-20250514')
    .providerTool(AnthropicProviderTools.webFetch(
      toolType: 'web_fetch_20250910',
      options: AnthropicWebFetchToolOptions(
        maxUses: 1,
        maxContentTokens: 512,
        citations: AnthropicWebFetchCitationsOptions(enabled: true),
      ),
    ))
    .build();
```

```dart
registerGoogle();

final provider = await LLMBuilder()
    .provider(googleProviderId)
    .apiKey(apiKey)
    .model('gemini-1.5-flash')
    .providerTool(GoogleProviderTools.webSearch(
      options: GoogleWebSearchToolOptions(
        mode: GoogleDynamicRetrievalMode.dynamic,
        dynamicThreshold: 0.3,
      ),
    ))
    .build();
```

```dart
registerGoogle();

final provider = await LLMBuilder()
    .provider(googleProviderId)
    .apiKey(apiKey)
    .model('gemini-2.0-flash')
    .providerTools([
      GoogleProviderTools.codeExecution(),
      GoogleProviderTools.urlContext(),
    ])
    .build();
```

## Compatibility notes

- `providerOptions` remains supported as an escape hatch and for gradual migration.
- Providers may bridge `LLMConfig.providerTools` into their native request formats internally.
- `LLMBuilder` web search convenience methods have been removed; use provider-native tools (`providerTools`) and provider-specific `providerOptions` instead.
- Some providers may not implement a given provider-native tool even if they use
  the same wire protocol (e.g. Anthropic-compatible). In those cases, the
  provider API will return an error; use a local `FunctionTool` if you need web
  search/fetch.
