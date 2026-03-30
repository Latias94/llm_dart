# Legacy Search Entrypoint Deprecations

## Goal

This note freezes which legacy root-package search entrypoints should now be marked deprecated after the OpenRouter and xAI search boundaries were audited.

The goal is not to remove those entrypoints immediately.

The goal is to stop presenting them as stable design surfaces when the new architecture has already frozen a narrower and more honest replacement.

## 1. Why These Deprecations Exist

The current migration has now established:

- OpenRouter search is provider-owned model shaping, not a stable generic request-option bag
- xAI live search is provider-owned invocation options, not a stable root-package convenience-helper surface
- legacy root-package helpers still exist for migration compatibility, but some of them imply behavior that the refactored architecture intentionally does not freeze

So the root package should start warning users away from the entrypoints that are now known to be legacy-only.

## 2. Deprecated OpenRouter Entrypoints

The following `OpenRouterBuilder` entrypoints should now be treated as deprecated:

- `webSearch()`
- `searchPrompt()`
- `useOnlineShortcut()`
- `maxSearchResults()`
- `forAcademicResearch()`
- `forNewsAndEvents()`
- `forTechnicalQueries()`
- `forGeneralSearch()`
- `forQuickSearch()`

### Why

These helpers imply richer semantics such as:

- `searchPrompt`
- `maxSearchResults`
- custom online-shortcut control

But the repository only proves one stable OpenRouter search behavior today:

- shape the model to `:online`

So those helpers are migration conveniences, not a stable architecture contract.

### Migration direction

For root-package compatibility users:

- use `OpenRouterBuilder.onlineSearch()` for the audited online intent

For the stable primary API:

- use `AI.openRouter(...).chatModel(..., settings: OpenRouterChatModelSettings(search: OpenRouterSearchOptions.onlineModel()))`

## 3. Deprecated xAI Entrypoints

The following legacy xAI convenience helpers should now be treated as deprecated:

- `createXAISearchProvider()`
- `createXAILiveSearchProvider()`

### Why

These helpers are tied to the old root-package xAI surface:

- `liveSearch`
- `searchParameters`

The new architecture has already frozen a more explicit primary path:

- `XAIGenerateTextOptions(search: XAILiveSearchOptions(...))`

So the convenience helpers should remain available only as migration shims.

### Migration direction

For root-package compatibility users:

- use `createXAIProvider(...)` only when staying on the old provider surface temporarily

For the stable primary API:

- use `AI.xai(...).chatModel(...)`
- pass typed `XAIGenerateTextOptions(search: ...)` at call time

## 4. What Is Not Deprecated Yet

The generic root-package web-search helpers are **not** deprecated globally yet:

- `enableWebSearch()`
- `basicWebSearch()`
- `newsSearch()`
- `advancedWebSearch()`

Reason:

- they still map to real provider behavior for providers such as Anthropic and Google
- the architectural issue is provider-specific, not proof that all shared migration helpers are useless

So deprecation should stay targeted.

## 5. Removal Policy

These deprecations are a migration signal, not an immediate deletion signal.

The expected order is:

1. warn through `@Deprecated`
2. document the stable replacement
3. keep compatibility behavior during the migration window
4. remove only after the old root-package API removal plan is frozen

## 6. Current Conclusion

The repository should now treat these legacy search entrypoints as compatibility-only surfaces.

That means:

- keep them working for migration
- stop presenting them as stable design guidance
- keep new examples and new docs on the provider-owned primary APIs instead
