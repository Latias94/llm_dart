# Text Call Result Runner Boundary

Date: 2026-05-17

## Reference

This slice continues the alignment with `repo-ref/ai` text generation layers,
especially:

- `repo-ref/ai/packages/ai/src/generate-text/generate-text-result.ts`
- `repo-ref/ai/packages/ai/src/generate-text/stream-text-result.ts`
- `repo-ref/ai/packages/ai/src/generate-text/generate-text.ts`
- `repo-ref/ai/packages/ai/src/generate-text/stream-text.ts`

The reference separates result shapes from the runner functions that produce
them. The Dart implementation keeps the existing `generateTextCall` /
`streamTextCall` public seam, but moves the result facade implementation away
from the runner glue.

## Problem

`packages/llm_dart_ai/lib/src/model/text_call.dart` had become a mixed module:

- public text call result facades
- raw stream collection into `GenerateTextResult`
- structured output stream adaptation
- `generateTextCall` and `streamTextCall` runner glue
- chat UI projection accessors

That made the module shallow. The caller-facing interface was small, but a
maintainer had to understand raw stream replay, structured output side
channels, text result accessors, and runner dispatch in one file.

## Decision

Keep `text_call.dart` as the public facade and split the implementation:

- `text_call_result.dart`
  - `GenerateTextCallResult<T>`
  - `StreamTextCallResult<T>`
  - raw stream collection and structured stream adaptation factories
- `text_call_runner.dart`
  - `generateTextCall`
  - `streamTextCall`
  - dispatch between raw text runtime calls and structured output calls
- `text_call.dart`
  - show-list facade that exports only the existing public result and runner
    names

The internal `createGenerateTextCallResult(...)` helper is intentionally not
exported through the facade. It exists only so the runner module can construct
the result facade without widening the package-level public seam.

## Behavior Contract

The refactor preserves these contracts:

- `GenerateTextCallResult<T>` and `StreamTextCallResult<T>` remain available
  from `package:llm_dart_ai/llm_dart_ai.dart`.
- `generateTextCall(...)` and `streamTextCall(...)` keep their existing
  signatures and behavior.
- raw `streamTextCall(...)` still replays the full text event stream and
  exposes an empty `partialOutputStream`.
- structured `streamTextCall(...)` still delegates to `streamOutputResult(...)`
  and exposes parsed output, partial output, and element side channels.
- `llm_dart_core` compatibility exports continue to resolve through the same
  public names.

## Benefits

Locality improves because stream result facade behavior now lives in
`text_call_result.dart`, while runtime dispatch stays in `text_call_runner.dart`.

Leverage improves because future work can deepen raw stream collection,
structured output adaptation, or text call runner policy without changing the
single public import seam.

This is also a safer stepping stone toward a fuller run/result/event alignment:
`StreamTextRunResult`, `StreamTextCallResult`, and `StreamOutputResult` can now
be compared as result facade modules rather than mixed runner files.
