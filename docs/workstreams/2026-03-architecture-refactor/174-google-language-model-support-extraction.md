# 174 Google Language Model Support Extraction

## Why This Slice Exists

The cross-provider propagation audit concluded that Google, unlike Anthropic, is
already carrying a meaningful preparation layer inside
`google_language_model.dart`.

That file still mixed transport orchestration with pure support logic for:

- provider-options normalization
- shared response-format adaptation
- request-header construction
- JSON object response decoding
- base-URL normalization

Those helpers are stable, local, and independent from actual transport
execution.

## What Changed

This slice adds:

- `packages/llm_dart_google/lib/src/google_language_model_support.dart`

The support module now owns the pure preparation helpers:

- `resolveGoogleProviderOptions(...)`
- `buildGoogleRequestHeaders(...)`
- `decodeGoogleJsonObject(...)`
- `normalizeGoogleBaseUrl(...)`
- `resolveGoogleSharedResponseFormat(...)`

`google_language_model.dart` now reads more clearly as the transport-facing
facade that:

- prepares one resolved provider-options payload
- delegates request encoding to the Google request codec
- performs the HTTP or SSE transport call
- delegates result and stream decoding back to provider codecs

## Boundary Decision

This extraction is intentionally smaller than the OpenAI language-model support
split.

Google does not currently need a route-planning layer or a profile-aware
request-model resolver. So the support file only takes the pure helpers that
actually reduce facade noise today.

## Why This Is Better

- keeps the language-model class focused on request execution flow
- makes provider-options normalization easier to audit in isolation
- creates one stable place for Google shared response-format adaptation
- freezes the selective-propagation policy in code, not just in design notes

## Non-Goals

This slice does not:

- introduce a generic cross-provider language-model helper framework
- widen the shared response-format model
- change any Google public API surface
- yet extract Google result/stream shared projection logic

## Follow-Up

The next higher-value Google pass is not another facade split. It is evaluating
whether result and stream decoding should share a local projection support layer
for grounding, thought-signature metadata, `functionCall.id`, and
`code_execution` ownership.
