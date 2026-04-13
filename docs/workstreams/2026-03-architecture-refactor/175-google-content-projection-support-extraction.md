# 175 Google Content Projection Support Extraction

## Why This Slice Exists

The cross-provider audit identified the Google result/stream codec pair as a
stronger structural target than a purely cosmetic file split.

`google_result_codec.dart` and `google_stream_codec.dart` both carried closely
related projection logic for:

- thought-signature metadata
- `functionCall.id` provider metadata
- `code_execution` tool call and tool result pairing
- shared finish-level provider metadata shaping
- grounding-source projection above the existing
  `extractGroundingSources(...)` decoder

That duplication increased the risk of drift between non-streaming and streaming
decoding.

## What Changed

This slice adds:

- `packages/llm_dart_google/lib/src/google_content_projection_support.dart`

The new support module now owns Google codec-local shared projection helpers
such as:

- `GoogleCodeExecutionTracker`
- `GoogleProjectedToolCall`
- `GoogleProjectedToolResult`
- thought-signature and `functionCall.id` metadata helpers
- shared `code_execution` tool call/result projection
- shared finish/provider metadata shaping
- grounding-source projection helpers for content parts and stream events

`google_result_codec.dart` and `google_stream_codec.dart` now remain focused on:

- protocol traversal
- block lifecycle sequencing
- choosing which projection path applies for a given raw part

## Boundary Decision

This support file is intentionally codec-local.

It does not widen the shared core and it does not attempt to invent a generic
cross-provider projection layer. The abstractions stay Google-shaped because the
wire contract is still provider-specific.

## Why This Is Better

- reduces drift risk between result and stream decoding
- keeps `code_execution` pairing behavior defined in one place
- centralizes the Google-specific metadata contract used by both codecs
- makes the next Google refactors more likely to stay local and surgical

## Non-Goals

This slice does not:

- unify Google text/reasoning block lifecycle with other providers
- move raw grounding-source decoding out of `google_shared.dart`
- expose a new public package API
- imply that Anthropic now needs the same extraction immediately

## Follow-Up

The next question is no longer whether Google needs this support layer. It is
whether any later Google-specific UI helper or replay utility should reuse this
projection support directly, or continue to stay above provider-owned custom
part and event helpers.
