# Provider-Owned Search Boundary

## Goal

This note freezes the boundary for search-related request options, result shapes, stream events, and UI projection.

The main rule is simple:

- shared citation output may be unified
- search request controls and provider-native search semantics stay provider-owned

This is the search-specific version of a broader migration rule:

- protocol overlap does not imply behavior overlap

## 1. Why This Boundary Must Be Frozen Now

The recent provider audits make the same problem visible from different angles:

- OpenRouter search is currently expressed through model shaping such as `:online` plus builder shortcuts
- xAI search is expressed through provider-native `search_parameters`
- Anthropic search is expressed through provider-native web tools and result blocks
- Google search or grounding is expressed through provider-native native-tool or grounding paths
- OpenAI search is expressed through built-in tools and provider-specific output items

These are not one shared request contract with different labels.

They are different search protocols that only partially converge on two outcomes:

- the model may cite sources
- the model may expose provider-native search calls or search results

The local `repo-ref/ai` points in the same direction:

- the provider layer keeps a common typed `source` output
- provider-native search calls and search tools still live inside provider packages

So we should not widen the Dart shared core just because multiple providers have something that humans would describe as "search".

## 2. Frozen Shared Core Search Contract

The shared core should continue to own only the provider-agnostic citation and projection primitives:

- `SourceReference`
- `SourceContentPart`
- `SourceEvent`
- `SourceUiPart`

This shared contract is enough for:

- URL citations
- document citations
- source rendering in Flutter chat UIs
- transport serialization of shared citation data

Provider-specific citation detail may still survive through provider metadata on `SourceReference`.

That is the correct shared boundary.

The shared core should **not** add:

- `SearchOptions`
- `SearchResultContentPart`
- `SearchQueryContentPart`
- `SearchCallEvent`
- provider-specific search filter fields on `SourceReference`
- search-provider-specific UI part subclasses

If a provider emits richer search lifecycle detail than a plain citation, that detail should stay provider-owned.

## 3. Frozen Request-Side Rule

Search request controls stay provider-owned.

They should enter the architecture through one of these paths only:

- provider-owned typed invocation options
- provider-owned typed native tool declarations
- provider-owned profile or request shaping
- compatibility-only legacy builder mapping during migration

They should **not** expand the shared OpenAI-family option surface.

### Provider-specific request ownership

| Provider | Search request shape | Long-term owner |
| --- | --- | --- |
| OpenAI | built-in web-search tool / Responses search items | `llm_dart_openai` typed options and native tool helpers |
| Anthropic | `web_search_*` / `web_fetch_*` native tool families | `llm_dart_anthropic` typed options and native tool helpers |
| Google | grounding / Google-native search tools | `llm_dart_google` typed options and native tool helpers |
| OpenRouter | builder shortcuts, `:online`, profile-owned shaping | OpenRouter-specific typed options or profile internals in `llm_dart_openai` |
| xAI | `liveSearch`, `searchParameters`, web/news source config | xAI-specific typed options in `llm_dart_openai` |
| Phind | provider-specific protocol | dedicated provider path if migration ever happens |

### Frozen compatibility rule

The old root-builder search entries such as:

- `webSearchEnabled`
- `webSearchConfig`
- `searchPrompt`
- `useOnlineShortcut`
- `maxSearchResults`

remain compatibility-only migration inputs.

They are **not** the design basis for the new primary API.

That means:

- the new `AI.*` facade should not normalize all provider search behavior behind one shared search option surface
- the compatibility layer may continue mapping legacy search fields provider-by-provider during migration
- providers whose search mapping is not frozen must stay on fallback for search-shaped legacy requests

## 4. Frozen Result-Side Rule

Search output splits into two layers.

### Shared layer

If the provider output can be represented as a citation or source reference, it should map into:

- `SourceContentPart`
- `SourceEvent`
- `SourceUiPart`

Examples:

- OpenAI URL or file annotations
- Google grounding sources
- Anthropic citation locations
- future provider citations that are semantically just sources

### Provider-owned layer

If the provider output represents search lifecycle or provider-native search payloads beyond a citation, it should map into:

- `CustomContentPart`
- `CustomEvent`
- `CustomUiPart`
- provider metadata on common parts when only small extra detail is needed

Examples:

- OpenAI `web_search_call`
- Anthropic `web_search_tool_result`
- future xAI search-result payloads or search-call metadata
- OpenRouter provider-native search artifacts if they ever become explicit

This split is already consistent with current architecture:

- common citations are renderable through shared source parts
- richer provider-native search detail is replayable through provider-owned custom kinds

## 5. Frozen UI Projection Rule

Flutter and transport rendering should follow this priority:

1. Render shared citations through `SourceUiPart`.
2. Render provider-native search detail through provider-owned custom UI parts when available.
3. Keep provider-specific search cards or search-status UIs out of the common core widget model.

This means a chat UI can still be useful even without a provider-specific renderer:

- shared citations remain visible
- raw provider-native search detail can still survive in custom parts

This also means we should not create generic UI primitives such as:

- `SearchUiPart`
- `SearchStatusUiPart`
- `SearchQueryUiPart`
- per-provider source-card subclasses

Those are renderer concerns, not shared domain requirements.

## 6. Replay And Serialization Rule

Search replay should follow the same rule as other provider-native result families:

- provider-native search payloads that must round-trip exactly stay in provider-owned custom prompt/content/UI parts
- shared sources are serialized as shared source objects

Recommended custom kind examples remain:

- `openai.web_search_call`
- `anthropic.result.web_search`
- future provider-owned search kinds under their provider namespace

This keeps search replay faithful without widening the shared content model for one provider's protocol.

## 7. What This Means For Current Provider Audits

### OpenRouter

- plain no-search subset may bridge
- search-shaped legacy traffic stays fallback-only until OpenRouter-specific search shaping is frozen

### xAI

- the audited text subset may bridge
- the audited legacy live-search migration subset may also bridge now that xAI typed options and shared citation projection are frozen
- unsupported search shapes, richer provider-native search payloads, and replay-specific search traffic still stay provider-owned and fallback-only at the legacy bridge layer

### Anthropic

- provider-native web-search and web-fetch result replay already proves the provider-owned custom-part path

### Google

- shared source projection is already the right output boundary for grounding citations
- additional Google-native search controls should remain Google-owned typed options

### OpenAI

- built-in search tools stay OpenAI-owned typed options
- shared citations still map into shared source parts
- provider-native search call items stay OpenAI-owned custom kinds

## 8. Non-Goals

This document does not propose:

- one universal search options class in `llm_dart_core`
- one shared search result schema for all providers
- automatic migration of every legacy search-shaped request into the new architecture
- removal of the compatibility builder search helpers during the current migration window

The correct direction is controlled convergence:

- shared sources where semantics truly overlap
- provider-owned options and custom payloads where protocols differ

## 9. Immediate Follow-Up

1. Keep OpenRouter search-shaped compatibility requests on fallback until provider-owned shaping is explicit.
2. Keep xAI compatibility routing limited to the audited live-search migration subset until the next provider-owned search or replay subset is explicitly frozen.
3. Let Anthropic and OpenAI continue proving the provider-owned custom-part replay path for search-native payloads.
4. Add provider-owned renderer helpers in `llm_dart_flutter` only when a provider-native search payload becomes important enough to render specially.
