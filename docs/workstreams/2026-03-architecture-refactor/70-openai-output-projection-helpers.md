# OpenAI Output Projection Helpers

## Purpose

This note records the next OpenAI-specific slice after the native-tool
declaration surfaces for `image_generation` and `mcp` landed.

The question was:

- do we need more shared event types to cover OpenAI Responses output families
  such as image-generation partials and MCP tool discovery?

The answer is now:

- no; the correct layer is provider-owned parsing, summary, and mapping above
  `CustomEvent` / `CustomUiPart`

## What Landed

`llm_dart_openai` now exposes a provider-owned output/helper layer for the
current high-value OpenAI Responses custom payloads:

- `OpenAICustomPart`
- `OpenAICustomPartSummary`
- `OpenAIMessageMapper`

The typed helper layer currently covers:

- `openai.image_generation_call`
- `openai.image_generation_call.partial_image`
- `openai.mcp_list_tools`

## Event Coverage Change

This slice also closes one real event-coverage gap:

- `response.image_generation_call.partial_image` now maps into
  `CustomEvent(kind: 'openai.image_generation_call.partial_image')`

That means partial images now flow through:

- shared stream events
- `ChatUiAccumulator`
- `CustomUiPart`
- provider-owned OpenAI helper parsing in Flutter or app code

without adding a new shared event class.

## Why This Layer Is Correct

These payloads are provider-shaped and useful in UI code, but they are not
good candidates for new shared abstractions.

They fit the existing architecture better as:

- shared `CustomEvent` / `CustomContentPart` / `CustomUiPart`
- provider-owned typed parser helpers
- provider-owned lightweight summaries and message mappers

That keeps the shared core stable while still giving Flutter and app code an
ergonomic API.

## What This Does Not Change

This slice does **not**:

- widen `TextStreamEvent`
- widen `ContentPart`
- widen `ChatUiPart`
- add a local MCP client dependency
- add OpenAI-specific replay contracts to the shared runner

The core remains unchanged; only provider-owned ergonomics improve.

## Remaining OpenAI Question

The next OpenAI provider-owned decision is now narrower:

- whether `code_interpreter` should become the next request-side declaration
  surface
- or whether the remaining hosted execution families should stay deferred until
  a concrete app use case appears

## Bottom Line

OpenAI-specific event completeness did not require more shared event types.

It required a provider-owned output/helper layer.

That layer now exists for the current high-value Responses custom payloads,
which improves Flutter/app integration without weakening the repository-wide
boundary rules.
