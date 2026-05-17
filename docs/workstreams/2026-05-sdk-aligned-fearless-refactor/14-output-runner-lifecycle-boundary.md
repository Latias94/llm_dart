# Output Runner Lifecycle Boundary

Date: 2026-05-17

## Reference

This slice continues the alignment with `repo-ref/ai` object generation and
streaming layers, especially:

- `repo-ref/ai/packages/ai/src/generate-object/generate-object.ts`
- `repo-ref/ai/packages/ai/src/generate-object/stream-object.ts`
- `repo-ref/ai/packages/ai/src/generate-object/output-strategy.ts`
- `repo-ref/ai/packages/ai/src/generate-object/parse-and-validate-object-result.ts`
- `repo-ref/ai/packages/ai/src/generate-object/structured-output-events.ts`

The reference keeps object runner entrypoints, output strategy, parse/validate
logic, and stream partial projection as separate concerns. The Dart
implementation keeps the public `generateOutput`/`streamOutput` and
`generateObject`/`streamObject` seams while moving parse lifecycle and partial
stream projection behind focused internal modules.

## Problem

`packages/llm_dart_ai/lib/src/model/output_runner.dart` mixed several
independent reasons to change:

- public object-first wrappers
- public generic output runner helpers
- response format conflict validation
- response format injection into shared text generation options
- structured output context construction
- final parse result construction
- validation error wrapping and diagnostic details
- streaming text accumulation
- partial output parsing, duplicate suppression, and element event projection

The public output runner seam is valuable because structured output callers get
a small interface, but the implementation had become shallow because stream
projection and final parse lifecycle were embedded directly in the public
runner file.

## Decision

Keep `output_runner.dart` as the public runner facade and split lifecycle
support:

- `output_runner_parsing.dart`
  - `GenerateTextOptions.responseFormat` conflict validation
  - output response format injection
  - structured output context construction
  - final `GenerateOutputResult` parsing
  - validation `ModelError` wrapping and diagnostic details
- `output_stream_projection.dart`
  - streaming partial parse attempts
  - duplicate partial output suppression
  - output element event projection
- `output_runner.dart`
  - public `generateObject`, `streamObject`, `generateOutput`,
    `streamOutput`, and `streamOutputResult`
  - text generation/streaming orchestration
  - object default decoder

This mirrors the reference object generation layering without changing the Dart
public API.

## Behavior Contract

The refactor preserves these contracts:

- `generateOutput`, `streamOutput`, `streamOutputResult`, `generateObject`, and
  `streamObject` keep their public surfaces.
- structured output response formats are still injected into text generation
  options.
- explicit `GenerateTextOptions.responseFormat` is still rejected on both
  generate and stream paths.
- final parse failures are still wrapped as validation `ModelError` values with
  structured output diagnostics.
- streaming output still forwards every text stream event.
- partial outputs are still emitted only when a newly parsed partial differs
  from the previous partial.
- array element events are still emitted only for newly completed elements.
- `llm_dart_core` compatibility behavior remains unchanged through the public
  runtime facades.

## Benefits

Locality improves because final parse/error lifecycle and streaming partial
projection now have their own modules.

Leverage improves because `output_runner.dart` now reads as a small public
runner facade over the text runtime, while future changes to parsing,
diagnostics, or partial projection can happen without editing the public
entrypoint module.

This leaves `output_spec_strategy.dart` as the remaining structured output
module that may deserve another deepening pass if the workstream continues.
