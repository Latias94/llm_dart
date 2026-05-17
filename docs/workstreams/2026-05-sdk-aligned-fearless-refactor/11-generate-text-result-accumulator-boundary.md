# Generate Text Result Accumulator Boundary

Date: 2026-05-17

## Reference

This slice continues the alignment with `repo-ref/ai` stream event and result
projection layers, especially:

- `repo-ref/ai/packages/ai/src/generate-text/generate-text-result.ts`
- `repo-ref/ai/packages/ai/src/generate-text/stream-text-result.ts`
- `repo-ref/ai/packages/ai/src/generate-text/stream-language-model-call.ts`
- `repo-ref/ai/packages/ai/src/generate-text/generate-text-events.ts`
- `repo-ref/ai/packages/ai/src/generate-text/tool-execution-events.ts`
- `repo-ref/ai/packages/ai/src/generate-text/tool-output-denied.ts`

The reference separates result facades, stream event vocabulary, and tool
projection concerns. The Dart implementation keeps the public
`GenerateTextResultAccumulator` seam while moving event-family state into
smaller internal modules.

## Problem

`packages/llm_dart_ai/lib/src/model/generate_text_result_accumulator.dart`
had become a mixed module:

- public accumulator and collection helpers
- text and reasoning content buffering
- streamed tool input state and JSON input decoding
- tool call, tool result, approval request, and denial projection
- response metadata, provider metadata, warnings, usage, finish, and error
  lifecycle state

That made the accumulator shallow. The public accumulator is a real seam
because stream runners, text calls, object output, and compatibility exports all
consume the same result-building behavior, but the implementation bundled too
many independent reasons to change.

## Decision

Keep `generate_text_result_accumulator.dart` as the public facade and split the
implementation:

- `generate_text_result_content_buffer.dart`
  - text and reasoning part buffering
  - content part insertion and replacement
  - tool call part indexing
  - source, file, custom, and content append helpers
- `generate_text_result_tool_projection.dart`
  - streamed tool input partial state
  - tool input JSON decoding
  - tool call upsert behavior
  - tool result, approval request, and denied output projection
- `generate_text_result_lifecycle.dart`
  - warnings, response metadata, finish reason, usage, provider metadata, and
    streamed error state
  - final `GenerateTextResult` construction
- `generate_text_result_accumulator.dart`
  - public `GenerateTextResultAccumulator` and `collectGenerateTextResult`
    entrypoints
  - event-family dispatch only

This follows the reference lesson without copying its TypeScript result object
shape. Dart still keeps one simple accumulator interface for runtime call sites.

## Behavior Contract

The refactor preserves these contracts:

- `GenerateTextResultAccumulator` remains publicly exported from
  `llm_dart_ai`.
- `collectGenerateTextResult` keeps the same public behavior.
- `llm_dart_core` compatibility exports continue to resolve the same names.
- text and reasoning deltas still require matching start events.
- streamed tool input still decodes JSON, maps empty input to `null`, and
  preserves invalid JSON as raw text.
- tool input errors still create replayable tool error results.
- tool output denial still requires a known tool call and creates a replayable
  denied tool result.
- provider metadata merge behavior remains last-write-wins per nested key.
- model `ErrorEvent` still throws from `build()`/collection.
- `RunFinishEvent` still acts as the final result signal for aborted streams.

## Benefits

Locality improves because content buffering, tool projection, and lifecycle
state now have separate modules.

Leverage improves because all stream result consumers still use the same public
accumulator seam, while future event additions can be implemented in the module
that owns that event family instead of expanding one mixed switch body.

This leaves a clearer next step: runner loop control can be deepened separately
from result projection if `GenerateTextRunner` and `StreamTextRunner` continue
to grow.
