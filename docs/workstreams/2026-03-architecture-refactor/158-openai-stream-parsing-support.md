# 158 OpenAI Stream Parsing Support

## Why

After the OpenAI compatibility request-body cleanup, the next substantial
duplication inside the root OpenAI family sat in streamed response parsing:

- `OpenAIChat`
- `OpenAIResponses`

Both codecs still repeated the same incremental state management:

- whether reasoning content had already appeared,
- the previous text chunk used by reasoning-finish heuristics,
- the accumulated thinking buffer,
- stable streamed tool-call ids keyed by incremental index,
- `<think>...</think>` extraction,
- streamed tool-call delta aggregation rules.

The two APIs still need separate completion payload assembly and separate
top-level event interpretation, but their streamed incremental mechanics had
already drifted into the same compatibility plumbing duplicated twice.

## Decision

Extract a focused OpenAI-family stream parsing support helper that owns only
the shared incremental parsing state and helper actions.

Keep the API-specific parts local:

- chat-completions still owns `choices[].delta` decoding and completion payload
  shape,
- Responses still owns `response.output_text.delta`,
  `response.completed`, and Responses-specific completion payload shape,
- both codecs now share the same state container plus reasoning/text/tool-call
  incremental parsing helpers.

## What Changed

- Added
  `lib/src/compatibility/providers/openai/stream_parsing_support.dart`
  containing:
  - `OpenAIStreamParsingState`
  - shared reasoning-delta handling
  - shared text/thinking-tag handling
  - shared streamed tool-call-delta aggregation
- Replaced the duplicated per-class fields in `OpenAIChat` and
  `OpenAIResponses` with the shared state object.
- Removed duplicated `<think>` extraction and incremental tool-call id caching
  logic from both codecs.
- Added regression tests that verify:
  - chat-completions incremental tool-call ids stay stable across chunks,
  - Responses think-tag deltas become `ThinkingDeltaEvent`s and survive into
    the final completion snapshot.

## Architectural Effect

This pushes the root OpenAI compatibility layer closer to a cleaner internal
three-way split:

- request encoding,
- stream parsing,
- capability facade / response projection.

That is meaningfully closer to the layering discipline we want from
`repo-ref/ai`, without copying its exact file layout or package granularity.

It also narrows the remaining OpenAI cleanup scope: the next structural work
should focus more on capability-module boundaries and legacy-surface slimming,
not on repeatedly re-fixing duplicated stream internals.
