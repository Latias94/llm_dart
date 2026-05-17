# Structured Output Module Boundary

Date: 2026-05-17

## Reference

This follow-up uses the mature `repo-ref/ai` structured output shape as the
architecture reference, especially:

- `repo-ref/ai/packages/ai/src/generate-object/output-strategy.ts`
- `repo-ref/ai/packages/ai/src/generate-object/structured-output-events.ts`
- `repo-ref/ai/packages/ai/src/generate-object/generate-object.ts`

The Dart implementation does not copy the TypeScript package shape. It keeps
the existing `OutputSpec` public seam and the current `generateOutput` /
`streamOutput` behavior while deepening the modules behind that seam.

## Problem

`packages/llm_dart_ai/lib/src/model/output_spec.dart` had accumulated several
separate responsibilities:

- public structured output types and events
- output strategy implementations for text, JSON, object, array, and choice
- JSON decoding, object-root validation, partial JSON freezing, and deep
  equality helpers
- non-streaming and streaming runner glue
- stream result replay, side channels, and chat UI projection accessors

That made the file a shallow module: the interface looked small, but the
implementation mixed parsing rules, stream projection, result facade behavior,
and runtime call orchestration in one locality. The deletion test showed that
most of the complexity would reappear across callers if the public seam were
removed, so the seam itself was earning its keep. The issue was the mixed
implementation behind it.

## Decision

Keep `output_spec.dart` as the stable public facade and split the implementation
into deeper internal modules:

- `output_spec_foundation.dart`
  - typedefs, structured output context, final result type, and stream event
    vocabulary
- `output_spec_strategy.dart`
  - `OutputSpec` and concrete output strategies
- `output_spec_json.dart`
  - JSON parsing, schema shape validation, partial JSON freezing, deep equality,
    choice option normalization, and usage serialization helpers
- `output_runner.dart`
  - `generateObject`, `streamObject`, `generateOutput`, `streamOutput`, and
    runner-owned parse/error projection glue
- `output_stream_result.dart`
  - `StreamOutputResult` / `StreamObjectResult` replay facade and side-channel
    projections

The facade exports only the public seam:

- generation helpers
- result and event types
- output spec strategy types
- stream result facade types

It intentionally does not export `output_spec_json.dart` helpers or
`createStreamOutputResult(...)`.

## Behavior Contract

The refactor preserves these contracts:

- `JsonOutputSpec`, `ObjectOutputSpec`, `ArrayOutputSpec`, `ChoiceOutputSpec`,
  and `TextOutputSpec` remain publicly available through `llm_dart_ai`.
- `generateOutput` and `streamOutput` still inject `OutputSpec.responseFormat`
  and reject an explicit `GenerateTextOptions.responseFormat`.
- array output remains wrapped as an object with an `elements` array, matching
  the reference strategy that avoids top-level array generation where providers
  are less reliable.
- choice output remains wrapped as an object with a `result` field.
- streaming partial events are emitted only when partial output changes by
  structured deep equality.
- JSON partial output returned by `JsonOutputSpec.parsePartial` remains deeply
  immutable.
- structured output parse failures are still wrapped as validation
  `ModelError`s with response context details.

## Benefits

Locality improves because future parser/schema changes are contained in
`output_spec_json.dart`, runner orchestration remains in `output_runner.dart`,
and stream result replay stays in `output_stream_result.dart`.

Leverage improves because callers still import one public facade while the
implementation is now easier to test through focused seams. The public
`OutputSpec` interface remains the test surface; helper extraction does not
create new public utility contracts prematurely.

The split also keeps room for future Vercel-AI-SDK-inspired output work:
validated final results, richer partial validation, provider-native structured
output modes, and telemetry callbacks can be added behind the existing public
seam without mixing those concerns into one file again.
