# Builder Web-Search Replacements

## Goal

Document the modern replacements for the deprecated builder-era web-search
helpers.

This covers:

- `LLMBuilder.enableWebSearch()`
- `LLMBuilder.webSearch(...)`
- `LLMBuilder.quickWebSearch(...)`
- `LLMBuilder.newsSearch(...)`
- `LLMBuilder.searchLocation(...)`
- `LLMBuilder.advancedWebSearch(...)`

and the OpenRouter-specific legacy builder helpers in
`lib/providers/openai/compatible/openrouter/builder.dart`.

## Why A Shared Search Toggle Is Not Stable

The old builder API treated "search" as if it were a generic shared capability.

The actual provider contracts are not aligned that way:

- OpenAI uses built-in tools on the Responses-style surface
- Anthropic uses native provider-owned tools
- xAI uses provider-owned live-search request options
- OpenRouter uses online-model shaping / provider-specific settings
- Google exposes provider-owned native search tools

That means the builder helpers are migration rails only.

They should remain soft-deprecated and documentation should point to the
provider-owned APIs instead of reviving a fake shared abstraction.

## Legacy Helper Mapping

| Legacy helper | Why it is not a stable shared contract | Modern replacement direction |
| --- | --- | --- |
| `enableWebSearch()` | A boolean cannot express tool shape, source selection, citations, or provider-specific limits. | Pick the provider-native search/tool option on the modern `AI.*(...).chatModel(...)` flow. |
| `webSearch(...)` | Its mixed field bag (`maxUses`, `maxResults`, domains, dates, location) does not map 1:1 across providers. | Translate only the fields the chosen provider actually owns. |
| `quickWebSearch(...)` | "Quick" is builder ergonomics, not a wire contract. | Use provider-native result caps or prompt shaping. |
| `newsSearch(...)` | News/time-window behavior is provider-specific. | Use provider-native search sources/options or normal prompt shaping. |
| `searchLocation(...)` | Location filters are not universal and are not encoded the same way. | Use provider-owned location/time filters only where supported. |
| `advancedWebSearch(...)` | It merges unrelated semantics into one compatibility bag. | Split intent into provider-specific typed settings/options. |

## Stable App-Facing Flow

The shared app-facing flow is now:

1. create a model with `AI.<provider>(...).chatModel(...)`
2. call `generateTextCall(...)`, `streamTextCall(...)`, `runTextGeneration(...)`,
   or `streamTextRun(...)`
3. pass search behavior through provider-owned typed options/settings

The repository already has a stable example for this in
`example/02_core_features/web_search.dart`.

## Provider-Owned Replacement Paths

### OpenAI Responses web search

Use OpenAI built-in tools instead of a generic search flag.

```dart
final model = AI.openai(apiKey: apiKey).chatModel('gpt-5-mini');

final result = await generateTextCall(
  model: model,
  prompt: [
    UserPromptMessage.text('Search for recent Dart SDK release notes.'),
  ],
  callOptions: const CallOptions(
    providerOptions: OpenAIGenerateTextOptions(
      builtInTools: [OpenAIWebSearchTool()],
    ),
  ),
);
```

Use this when the provider contract is "OpenAI built-in tool invocation", not
"generic search".

### Anthropic native web search

Use Anthropic's native search tool definitions.

```dart
final model = AI.anthropic(apiKey: apiKey).chatModel('claude-sonnet-4-5');

final result = await generateTextCall(
  model: model,
  prompt: [
    UserPromptMessage.text('Find recent Flutter desktop updates.'),
  ],
  callOptions: CallOptions(
    providerOptions: AnthropicGenerateTextOptions(
      tools: [
        AnthropicTools.webSearch20250305(
          maxUses: 3,
          allowedDomains: ['dart.dev', 'docs.flutter.dev'],
        ),
      ],
    ),
  ),
);
```

This is the cleanest replacement for old fields such as `maxUses` and
`allowedDomains`, because Anthropic actually owns those concepts.

### xAI live search

Use xAI's typed live-search options.

```dart
final model = AI.xai(apiKey: apiKey).chatModel('grok-3');

final result = await generateTextCall(
  model: model,
  prompt: [
    UserPromptMessage.text('Find the latest announcements about AI coding tools.'),
  ],
  callOptions: const CallOptions(
    providerOptions: XAIGenerateTextOptions(
      search: XAILiveSearchOptions(
        maxSearchResults: 5,
        sources: [
          XAIWebSearchSource(),
          XAINewsSearchSource(),
        ],
      ),
    ),
  ),
);
```

This is the honest migration target for "news" or "live search" style usage on
xAI.

### OpenRouter online search

Use provider-owned model settings instead of the generic builder search bag.

```dart
final model = AI.openRouter(apiKey: apiKey).chatModel(
  'openai/gpt-4.1-mini',
  settings: const OpenRouterChatModelSettings(
    search: OpenRouterSearchOptions.onlineModel(),
  ),
);
```

Notes:

- This is the stable path for app-facing code.
- If a user is still on the compatibility builder, `onlineSearch()` is the only
  retained OpenRouter helper that maps cleanly to the refactored bridge.
- Deprecated OpenRouter builder helpers such as `searchPrompt(...)`,
  `maxSearchResults(...)`, `forAcademicResearch()`, and `forNewsAndEvents()`
  should migrate to normal prompt shaping plus the stable profile API.

### Google native search tools

Google has provider-owned native search tools on the modern package surface.

```dart
final model = AI.google(apiKey: apiKey).chatModel('gemini-2.5-flash');

final result = await generateTextCall(
  model: model,
  prompt: [
    UserPromptMessage.text('Find recent Android Studio AI announcements.'),
  ],
  callOptions: const CallOptions(
    providerOptions: GoogleGenerateTextOptions(
      tools: [
        GoogleSearchTool(),
      ],
    ),
  ),
);
```

Notes:

- Google search remains provider-owned even on the modern surface.
- The repository already exports `GoogleSearchTool` and `GoogleTools.googleSearch(...)`.
- Until a public example is added, docs should stay conservative and avoid
  claiming richer cross-provider parity than the codebase demonstrates.

## OpenRouter Compatibility Builder Notes

`lib/providers/openai/compatible/openrouter/builder.dart` still contains
deprecated helper ergonomics:

- `webSearch(...)`
- `searchPrompt(...)`
- `useOnlineShortcut(...)`
- `maxSearchResults(...)`
- `forAcademicResearch()`
- `forNewsAndEvents()`
- `forTechnicalQueries()`
- `forGeneralSearch()`
- `forQuickSearch()`

Their practical replacements are:

- `onlineSearch()` for the remaining legacy online intent
- explicit `:online` model IDs where appropriate
- normal prompt shaping instead of `searchPrompt(...)`
- the stable `AI.openRouter(...).chatModel(..., settings: ...)` path for new
  app-facing code

## Practical Policy Outcome

This document closes the "what replaces the deprecated builder web-search
helpers?" blocker.

What follows from that:

- keep the builder helpers deprecated
- do not use them in modern docs or examples
- remove them only in a deliberate breaking window
- treat search as provider-owned capability configuration, not a shared core
  toggle
