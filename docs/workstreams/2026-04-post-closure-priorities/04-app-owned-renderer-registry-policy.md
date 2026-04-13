# App-Owned Renderer Registry Policy

## Purpose

This note closes the remaining UI-extension question in the post-closure phase:

- should `llm_dart` add a shared renderer registry above `ChatMessageMapper`
  now
- or should richer provider-owned rendering continue through direct composition

## Current Composition Pattern

The current codebase already demonstrates a coherent composition model.

### Shared Baseline

The shared baseline remains:

- `ChatUiMessage`
- `ChatUiPart`
- `ChatMessageMapper`

This is the stable cross-provider layer.

### Provider-Owned Rich Helpers

Provider packages may add richer helpers such as:

- `OpenAICustomPart`
- `OpenAICustomPartSummary`
- `OpenAIMessageMapper`
- `GoogleCustomPart`
- `GoogleCustomPartSummary`
- `GoogleMessageMapper`

This keeps provider-specific parsing, replay payload inspection, and richer UI
metadata inside provider-owned packages instead of pushing them into
`llm_dart_core` or `llm_dart_flutter`.

### Application Composition

Applications can already compose:

- the shared `ChatMessageMapper`
- one or more provider-owned summary helpers
- one or more provider-owned message mappers

without another shared registry layer.

## Why A Shared Registry Is Not Justified Yet

The current repository does not show strong evidence for freezing a shared
registry contract.

Today:

- the provider-owned helper pattern is already understandable
- only a small number of providers currently expose richer UI helper sets
- there is no repeated repository-wide wrapper showing that direct composition
  has become noisy enough to justify another public layer
- `llm_dart_flutter` intentionally stays adapter-sized and does not try to
  become a provider-rendering bus

That means a shared registry now would mostly guess at future application
composition rather than solve a proven repeated problem.

## Boundary Decision

Do not add a shared renderer registry now.

The frozen rule is:

- keep shared rendering on `ChatMessageMapper`
- keep provider-specific rendering helpers in provider packages
- keep app-specific composition in application code for now

This keeps ownership honest:

- shared layers stay provider-neutral
- provider packages own provider-specific parsing
- applications own final render composition

## If A Registry Is Ever Added Later

If later integrations prove that a registry is worthwhile, it should be:

- additive
- app-owned in spirit
- above the shared model layer
- keyed by stable public identifiers such as `CustomUiPart.kind` and namespaced
  `ProviderMetadata`

It should not:

- parse provider wire JSON directly
- require every provider to expose the same mapper/helper trio for symmetry
- move provider-specific render logic into `llm_dart_core`
- turn `llm_dart_flutter` into a prebuilt widget or provider-rendering bus

The most honest future home would be either:

- a small additive helper in `llm_dart_flutter`
- or a separate higher-level package if the composition grows beyond simple
  helper dispatch

## Reopen Threshold

This question should only reopen if at least two independent integrations show
the same repeated composition pain.

Valid signals would look like:

- two different apps both building the same registry around
  `ChatMessageMapper` plus provider-owned summaries
- a repeated need to dispatch custom-part summaries through the same stable
  keying model
- a provider mix large enough that direct composition becomes materially noisy
  in real app code

Absent those signals, a shared registry would mostly be speculative API
surface.

## Bottom Line

The current pattern is already good enough:

- shared baseline mapper
- provider-owned custom-part and metadata helpers
- application-owned final composition

That is the right post-closure default.
Another shared renderer registry should remain deferred until repeated real app
usage proves it is worth freezing.
