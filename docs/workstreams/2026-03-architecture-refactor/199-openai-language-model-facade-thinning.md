# 199 OpenAI Language Model Facade Thinning

## Why This Slice Exists

After the earlier request-planning extraction into
`openai_language_model_support.dart`, the remaining
`openai_language_model.dart` body was already much smaller, but it still
repeated the same route-shaped transport shell four times:

- Responses `generate(...)`
- chat-completions `generate(...)`
- Responses `stream(...)`
- chat-completions `stream(...)`

That repetition was no longer a large architectural problem, but it still made
the facade harder to read than necessary because request planning, request
encoding, transport dispatch, and response decoding were still interleaved in
two nearly parallel branches.

## What Changed

This slice keeps all behavior inside `openai_language_model.dart`, but thins
the facade into clearer local helpers:

- `_encodeRequest(...)`
- `_buildTransportRequest(...)`
- `_routeUri(...)`
- `_decodeGenerateResponse(...)`
- `_decodeStreamEvents(...)`
- `_PreparedOpenAILanguageModelRequest`

The public facade methods now read more clearly as:

1. resolve the call plan
2. encode one prepared request
3. send one transport request
4. decode either the final result or the streamed events

## Boundary Decision

This is intentionally a **local facade cleanup**, not a new shared abstraction.

The cleanup does **not** move more behavior into
`openai_language_model_support.dart`, because that support file should keep
owning pure preparation logic, not transport execution.

The cleanup also does **not** add a generic provider execution helper, because
the remaining duplication was OpenAI-local and small enough to solve where it
lives.

So the resulting split stays explicit:

- `openai_language_model_support.dart`
  - route planning, provider-option normalization, request-model shaping,
    header construction, JSON-object response decoding
- codec files
  - endpoint-specific request and response protocol mapping
- `openai_language_model.dart`
  - transport-facing facade with small local execution helpers

## Why This Is Better

- reduces repeated transport request shells across Responses and
  chat-completions paths
- makes `generate(...)` and `stream(...)` easier to audit for behavioral drift
- keeps the facade aligned with the intended
  `planning -> encoding -> transport -> decoding` layering
- improves readability without creating another abstraction tier

## Non-Goals

This slice does not:

- change route-selection policy
- change request encoding
- change stream event sequencing
- introduce a generic cross-provider request executor
- widen any public API surface

## Validation

The slice is validated with:

- `dart analyze packages/llm_dart_openai/lib/src/openai_language_model.dart`
- `dart test packages/llm_dart_openai/test/openai_language_model_test.dart`

## Follow-Up

After this cleanup, the remaining large OpenAI files are now clearly the codec
files themselves rather than the transport facade.

That means future OpenAI refactor work should continue focusing on:

- codec-local readability and ownership boundaries
- endpoint-local support modules where they reduce real parsing weight
- avoiding new generic helper layers unless repeated pressure appears across at
  least two provider families
