# OpenRouter Search Options Design

## Goal

This note freezes the recommended request-side and result-side design for OpenRouter search in the refactored architecture.

The design goal is not to preserve every legacy builder helper as a stable new API.

The goal is to define the smallest honest provider-owned surface that matches what OpenRouter search actually is in this repository today.

## 1. What OpenRouter Search Really Means In The Current Repository

The old root-package OpenRouter path exposes several search-shaped entries:

- `webSearchEnabled`
- `webSearchConfig`
- `searchPrompt`
- `useOnlineShortcut`
- `maxSearchResults`
- explicit `:online` model suffixes

But the current observable request behavior is narrower than that surface suggests.

The old implementation reliably proves only one stable search behavior:

- search is enabled by shaping the model ID to `:online`

The current code does **not** prove a stable OpenRouter-native request contract for:

- `search_prompt`
- `max_search_results`
- any richer OpenRouter search request body

That means the new primary API should not turn those legacy builder helpers into a fake typed contract.

## 2. Frozen Architecture Decision

OpenRouter search remains provider-owned, but its ownership is **model/profile shaping**, not shared invocation options.

The key rule is:

- shared core owns only common source projection
- OpenRouter search ownership lives in the OpenRouter profile path inside `llm_dart_openai`

This is different from xAI.

For OpenRouter, the current stable search behavior changes routing/model identity rather than adding a clearly proven provider request object.

So the first stable OpenRouter search API should be model-owned.

## 3. Recommended Public Shape

### Stable V1 public contract

The recommended V1 surface is a dedicated OpenRouter-owned settings object:

```dart
final class OpenRouterChatModelSettings implements ProviderModelOptions {
  final OpenAIChatModelSettings common;
  final OpenRouterSearchOptions? search;

  const OpenRouterChatModelSettings({
    this.common = const OpenAIChatModelSettings(),
    this.search,
  });
}

enum OpenRouterSearchMode {
  onlineModel,
}

final class OpenRouterSearchOptions {
  final OpenRouterSearchMode mode;

  const OpenRouterSearchOptions.onlineModel()
      : mode = OpenRouterSearchMode.onlineModel;
}
```

Target usage:

```dart
final model = AI.openRouter(apiKey: apiKey).chatModel(
  'openai/gpt-4o-mini',
  settings: const OpenRouterChatModelSettings(
    search: OpenRouterSearchOptions.onlineModel(),
  ),
);
```

### Why model settings, not invocation options

OpenRouter search currently behaves like:

- model routing
- capability shaping
- cost/latency shaping

That is closer to model selection than to a normal per-call toggle.

If a caller wants both plain and online behavior, it is acceptable to construct two models.

That is more explicit than hiding model shaping behind a per-call shared option.

## 4. Fields That Must Not Enter Stable V1

The following legacy entries should **not** become stable V1 fields on the new primary API yet:

- `searchPrompt`
- `maxSearchResults`
- `useOnlineShortcut`

Reasons:

- `searchPrompt` is not backed by a frozen OpenRouter wire contract in this repository
- `maxSearchResults` is not backed by a frozen OpenRouter wire contract in this repository
- `useOnlineShortcut` is builder ergonomics, not provider semantics

Those fields remain compatibility-only migration inputs until a real OpenRouter request contract is proven and tested.

## 5. Ownership And Module Placement

The owning package remains `llm_dart_openai`.

Recommended placement:

- public export: `packages/llm_dart_openai/lib/src/openrouter_options.dart`
- request shaping: `packages/llm_dart_openai/lib/src/openai_family_profile.dart` or an OpenRouter-owned helper beside it
- compatibility mapping: root compatibility layer only

Important boundary:

- do not add OpenRouter search fields to `OpenAIGenerateTextOptions`
- do not add OpenRouter search fields to shared core option types

If the current `OpenAI.chatModel(... settings: ...)` API is too narrow to accept provider-owned settings, that factory surface should be refactored rather than pushing OpenRouter search back into shared family settings.

## 6. Request Encoding Rule

The first stable request rule is simple:

- `OpenRouterSearchOptions.onlineModel()` shapes the outgoing model ID to `:online`

The codec should **not** synthesize unsupported request fields such as:

- `search_prompt`
- `max_search_results`

The design must stay honest to the repository's currently proven behavior.

## 7. Result Projection Rule

OpenRouter search does not currently justify a provider-specific search result model in the shared architecture.

### Shared projection

If OpenRouter returns citations or source-like annotations through the OpenAI-family path, project them into:

- `SourceReference`
- `SourceContentPart`
- `SourceEvent`
- `SourceUiPart`

### Provider-owned projection

Do **not** add OpenRouter-specific search custom parts/events in V1 unless OpenRouter later exposes explicit search artifacts that are not just citations.

For the current architecture, shared source projection is enough.

## 8. Compatibility Mapping Policy

The next compatibility expansion should remain narrower than the new primary API.

### Bridge-safe candidates after typed settings exist

- explicit legacy `:online` model usage
- `webSearchEnabled == true` when the legacy request does not also depend on richer legacy search helpers
- `webSearchConfig` when compatibility only preserves the legacy observable online-model shaping effect

### Still fallback-only after this design freeze

- `searchPrompt`
- `maxSearchResults`
- `useOnlineShortcut == false`
- any claim that `webSearchConfig.searchPrompt` or `webSearchConfig.maxResults` has a frozen OpenRouter wire meaning
- OpenRouter DeepSeek R1 traffic

The compatibility bridge should expand only when the old request can be represented **exactly enough** by `OpenRouterSearchOptions.onlineModel()`.

## 9. Flutter Guidance

Flutter chat rendering should treat OpenRouter online search as normal assistant output plus shared sources.

That means:

- render citations through `SourceUiPart`
- do not create OpenRouter-specific search cards in the common chat layer
- add provider-specific UI only if OpenRouter later exposes provider-native search artifacts worth rendering

## 10. Follow-Up Implementation Slice

1. Add `OpenRouterChatModelSettings` and `OpenRouterSearchOptions`.
2. Make the OpenAI-family factory/model selection path accept provider-owned settings for OpenRouter profiles.
3. Encode `onlineModel()` by shaping the model ID to `:online`.
4. Keep `searchPrompt` and `maxSearchResults` out of the stable API until a tested wire contract exists.
5. Re-audit compatibility expansion only after the typed settings and tests land.
