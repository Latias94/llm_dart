# Shared Web Search And Raw Extension Boundary

## Goal

This note freezes the boundary for two legacy root-package convenience surfaces:

- shared root `LLMBuilder` web-search helpers
- `createProvider(..., extensions: ...)`

The goal is not to remove them immediately. The goal is to stop presenting them
as stable architecture guidance when the refactor has already frozen narrower,
provider-owned primary APIs.

## 1. Why This Boundary Needed To Be Frozen

The migrated architecture now makes two things clear:

- search behavior is provider-owned, not one stable shared invocation contract
- raw extension maps are still useful for migration, but they are not a safe
  long-term public design surface

The root compatibility layer can still keep these helpers working, but it
should stop implying that they are the preferred way to express search or
provider-specific options.

## 2. Landed Decision

The following root-builder helpers are now explicitly deprecated as legacy
compatibility migration helpers:

- `enableWebSearch()`
- `webSearch()`
- `quickWebSearch()`
- `newsSearch()`
- `searchLocation()`
- `advancedWebSearch()`

In addition, the `extensions` parameter on `createProvider(...)` is now also
explicitly deprecated as a raw compatibility escape hatch.

## 3. Why The Root Search Helpers Are Deprecated

Even though those helpers still map to real compatibility behavior for some
providers, they do not represent one frozen cross-provider contract:

- Anthropic search is provider-owned web-search tool shaping
- Google search is provider-owned grounding / built-in tool behavior
- OpenRouter search is provider-owned online-model shaping
- xAI search is provider-owned live-search invocation options

So the root helpers are migration conveniences, not a stable architectural
abstraction that should keep growing.

## 4. Why `createProvider(..., extensions: ...)` Is Deprecated

The raw `extensions` bag still exists for compatibility, but exposing it as a
normal convenience parameter encourages the exact coupling this refactor is
trying to shrink:

- new code keeps depending on string keys
- provider/runtime/search concerns keep mixing in one bag
- migration pressure away from compatibility paths becomes weaker

So the parameter should remain available for temporary migration code only.

## 5. Recommended Replacement Direction

For the stable primary API:

- prefer `AI.openai(...)`, `AI.anthropic(...)`, `AI.google(...)`,
  `AI.openRouter(...)`, and `AI.xai(...)`
- use provider-owned typed settings or provider-owned call options for search
  behavior

For root-package compatibility users who are still migrating:

- use provider-specific builder helpers where the repository has already frozen
  an audited migration path
- treat raw `extensions` and shared search helpers as temporary transition-only
  APIs

## 6. What Still Remains Supported

This decision does **not** remove compatibility support today:

- the root builder helpers still write into the canonical compatibility search
  shape
- `createProvider(..., extensions: ...)` still works
- flat legacy extension inputs are still readable where the migration layer has
  not fully moved away from them yet

The change is about honesty of boundary, not sudden behavior removal.

## 7. Architectural Consequence

After this decision:

- provider-owned search APIs are the only stable direction
- raw extension injection is now clearly marked as a compatibility-only escape
  hatch
- future cleanup can focus on shrinking compatibility surfaces instead of
  accidentally widening them
