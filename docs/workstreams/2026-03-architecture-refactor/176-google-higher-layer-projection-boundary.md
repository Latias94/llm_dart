# 176 Google Higher-Layer Projection Boundary

## Why This Decision Exists

After the Google codec-local projection support landed, the next question was
whether higher-level replay and UI helpers should start depending on that new
support module directly.

The relevant higher-level Google surfaces are:

- `google_function_response_replay.dart`
- `google_custom_part.dart`
- `google_custom_part_summary.dart`
- `google_message_mapper.dart`

Those files exist for replay, inspection, and rendering-oriented use cases. They
should not need to know how the result and stream codecs internally pair
`code_execution` parts or stitch grounding events.

## Frozen Decision

Higher-level Google replay and UI helpers should **not** depend directly on
`google_content_projection_support.dart`.

Instead, the dependency boundary is:

- codec-local projection support stays below result/stream decoding
- replay and UI helpers stay above provider-owned custom part and replay models
- only narrow Google metadata helpers may be shared across those layers when
  they encode a stable provider metadata contract

## What Changed

This slice adds:

- `packages/llm_dart_google/lib/src/google_provider_metadata_support.dart`

That support file now owns the narrow cross-layer metadata helpers that are
valid outside the codec-local projection layer:

- `buildGoogleGenerationMetadata(...)`
- `googleThoughtSignatureMetadata(...)`
- `googleFunctionCallIdMetadata(...)`

`google_content_projection_support.dart` now depends on this narrower metadata
support, and `google_function_response_replay.dart` also reuses
`googleFunctionCallIdMetadata(...)` without depending on codec-local projection
helpers.

## Why This Boundary Is Better

- avoids leaking codec traversal concerns into replay and UI helpers
- keeps `google_content_projection_support.dart` free to evolve with codec
  internals
- still removes real metadata drift risk where the same provider metadata keys
  are used across layers
- keeps Flutter-facing helper APIs aligned with provider-owned replay payloads,
  not low-level decode machinery

## What Stays Above The Boundary

The following layers should continue to work through provider-owned replay and
custom-part APIs instead of codec-local projection support:

- `GoogleCustomPart`
- `GoogleCustomPartSummary`
- `GoogleMessageMapper`
- any future dedicated Flutter rendering helper

If these helpers need richer information later, the preferred direction is to
extend provider-owned replay/custom-part payloads first, not to expose or depend
on codec-local projection internals.

## Non-Goals

This slice does not:

- expose `google_provider_metadata_support.dart` as a public package API
- move all Google metadata reads into one universal helper layer
- introduce Flutter-only renderer models in `llm_dart_google`
- imply that other providers now need an identical metadata-support file

## Follow-Up

The next Google-specific question is no longer whether UI helpers should depend
on codec-local support. That is now frozen. The next question is whether any
future richer Google renderer needs additional provider-owned replay payload
fields, or whether the current custom-part summary layer is already enough.
