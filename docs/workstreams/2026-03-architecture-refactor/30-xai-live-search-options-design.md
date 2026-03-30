# xAI Live Search Options Design

## Goal

This note freezes the recommended typed API and projection boundary for xAI search in the refactored architecture.

The main constraint is:

- xAI search must stay provider-owned
- but xAI does not have only one search surface

So the design must separate:

- xAI chat live-search request parameters
- future xAI provider-defined search tools

## 1. xAI Has Two Distinct Search Surfaces

### A. Chat live-search through request parameters

The current repository and the current `llm_dart_openai` xAI profile are aligned on the chat-completions path:

- endpoint: `chat/completions`
- request field: `search_parameters`
- output: assistant text plus citations

This is the phase-1 path that matters for the current migration.

### B. Provider-defined search tools

The local `repo-ref/ai` also shows a second xAI search surface:

- provider-defined tools such as `webSearch` and `xSearch`
- tool-call / tool-result style interaction
- this lives alongside xAI responses and broader provider-native tooling

That second surface is real, but it is **not** the same contract as chat live-search parameters.

So one typed Dart options bag must not try to represent both.

## 2. Frozen Architecture Decision

The new primary xAI search API should first model only the chat-completions `search_parameters` path.

That means:

- xAI live search is a provider-owned invocation option
- it stays outside `OpenAIGenerateTextOptions`
- future xAI provider-defined search tools must use a separate provider-native tool API

This keeps the architecture honest:

- chat search parameters remain a request-option concern
- provider-defined tools remain a provider-native tool concern

## 3. Recommended Public Shape

### Provider-owned invocation options

Recommended V1 public types:

```dart
enum XAISearchMode {
  off,
  auto,
  on,
}

sealed class XAISearchSource {
  const XAISearchSource();

  Map<String, Object?> toJson();
}

final class XAIWebSearchSource extends XAISearchSource {
  final String? countryCode;
  final List<String> allowedWebsites;
  final List<String> excludedWebsites;
  final bool? safeSearch;

  const XAIWebSearchSource({
    this.countryCode,
    this.allowedWebsites = const [],
    this.excludedWebsites = const [],
    this.safeSearch,
  });
}

final class XAINewsSearchSource extends XAISearchSource {
  final String? countryCode;
  final List<String> excludedWebsites;
  final bool? safeSearch;

  const XAINewsSearchSource({
    this.countryCode,
    this.excludedWebsites = const [],
    this.safeSearch,
  });
}

final class XAIXSearchSource extends XAISearchSource {
  final List<String> includedHandles;
  final List<String> excludedHandles;
  final int? minFavoriteCount;
  final int? minViewCount;

  const XAIXSearchSource({
    this.includedHandles = const [],
    this.excludedHandles = const [],
    this.minFavoriteCount,
    this.minViewCount,
  });
}

final class XAIRssSearchSource extends XAISearchSource {
  final List<Uri> feeds;

  const XAIRssSearchSource(this.feeds);
}

final class XAILiveSearchOptions {
  final XAISearchMode mode;
  final bool returnCitations;
  final DateTime? fromDate;
  final DateTime? toDate;
  final int? maxSearchResults;
  final List<XAISearchSource> sources;

  const XAILiveSearchOptions({
    this.mode = XAISearchMode.auto,
    this.returnCitations = true,
    this.fromDate,
    this.toDate,
    this.maxSearchResults,
    this.sources = const [],
  });

  const XAILiveSearchOptions.autoWeb({
    this.returnCitations = true,
    this.maxSearchResults,
  })  : mode = XAISearchMode.auto,
        fromDate = null,
        toDate = null,
        sources = const [XAIWebSearchSource()];
}

final class XAIGenerateTextOptions implements ProviderInvocationOptions {
  final OpenAIGenerateTextOptions common;
  final XAILiveSearchOptions? search;

  const XAIGenerateTextOptions({
    this.common = const OpenAIGenerateTextOptions(),
    this.search,
  });
}
```

Target usage:

```dart
final model = AI.xai(apiKey: apiKey).chatModel('grok-3');

final result = await generateText(
  model: model,
  prompt: [
    UserPromptMessage.text('Summarize recent AI chip announcements.'),
  ],
  callOptions: CallOptions(
    providerOptions: XAIGenerateTextOptions(
      search: XAILiveSearchOptions(
        mode: XAISearchMode.auto,
        maxSearchResults: 8,
        sources: const [
          XAIWebSearchSource(countryCode: 'US'),
          XAINewsSearchSource(countryCode: 'US'),
        ],
      ),
    ),
  ),
);
```

## 4. Why Search Is Invocation-Owned For xAI

xAI live search is query-shaped and time-sensitive.

The following controls can vary naturally per request:

- mode
- sources
- date range
- citation preference
- result count

That makes invocation options the right primary home.

Model-level defaults may still be added later, but they should not be the primary design center.

## 5. Request Encoding Rule

`XAIGenerateTextOptions.search` should encode to xAI `search_parameters` exactly and only when the active profile is xAI.

Mapping rule:

- `XAISearchMode.off` -> `mode: "off"`
- `XAISearchMode.auto` -> `mode: "auto"`
- `XAISearchMode.on` -> `mode: "on"`
- `returnCitations` -> `return_citations`
- `fromDate` / `toDate` -> `from_date` / `to_date` in `YYYY-MM-DD`
- `maxSearchResults` -> `max_search_results`
- typed sources -> xAI `sources`

The new primary API should **not** keep a top-level `liveSearch` boolean.

That boolean remains a compatibility-only migration input.

## 6. Legacy Compatibility Mapping Rule

Legacy xAI search helpers are migration inputs, not the new design basis.

### Compatibility-only inputs

- `liveSearch`
- `searchParameters`
- `webSearchEnabled`
- `webSearchConfig`

### Migration direction

- `liveSearch == true` maps to `XAILiveSearchOptions.autoWeb()` in the compatibility layer only
- legacy xAI `searchParameters` now map directly only for the audited web/news subset with supported modes and valid date ranges
- shared `webSearchConfig` now maps only to the xAI subset that the old builder can actually express

This means the new primary API speaks in xAI-native typed search terms, not in old root-builder web-search shortcuts.

## 7. Result Projection Rule

### Phase-1 chat live-search projection

For the current chat-completions xAI path, the common output contract is enough:

- citations map into `SourceReference`
- decoded results project through `SourceContentPart`
- streaming citations project through `SourceEvent`
- Flutter renders them through `SourceUiPart`

For this path, no xAI-specific search custom event is required in V1.

### Provider-owned detail

If xAI later exposes richer citation detail than URL-only output, keep that detail in:

- provider metadata on `SourceReference`
- or xAI-owned custom kinds if the payload is no longer "just a source"

## 8. Future xAI Provider-Defined Search Tools

Future xAI search tools should **not** be merged into `XAILiveSearchOptions`.

Recommended future ownership:

- `XAITools.webSearch(...)`
- `XAITools.xSearch(...)`

That future API belongs beside other xAI-native tools.

### Projection rule for future tool paths

If those tool paths are added later:

- generic tool-loop semantics may still use common tool events and parts with `providerExecuted: true`
- xAI-specific search metadata, replay payloads, or special UI cards must remain provider-owned through xAI namespaced metadata or custom kinds

So the architecture can reuse common tool lifecycle without pretending that all xAI search payloads are common-core concepts.

## 9. Flutter Guidance

For phase 1:

- render xAI citations through `SourceUiPart`
- do not create xAI-specific live-search widgets in the common Flutter layer

For future tool-based xAI search:

- keep any richer xAI search result cards in provider-owned Flutter helpers
- let the common chat layer continue rendering shared sources and generic tool state

## 10. Follow-Up Implementation Slice

1. Add `xai_options.dart` with typed search models.
2. Refactor the OpenAI-family option resolver so xAI profiles can accept `XAIGenerateTextOptions` without widening shared family options.
3. Encode `search_parameters` exactly in the xAI chat-completions path.
4. Add tests for request encoding, source projection, and rejection of invalid provider-option/profile combinations.
5. Revisit compatibility expansion only after the typed options and codec tests land.
