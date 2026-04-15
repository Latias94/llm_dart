# Core Focused Entrypoints

## Goal

Validate whether `llm_dart_core` can reduce barrel ambiguity without splitting
the package.

This is a small, non-breaking spike:

- keep `package:llm_dart_core/llm_dart_core.dart` as the broad existing barrel
- add focused entrypoints for callers that want a narrower conceptual import
- do not move files or change public type ownership

## Added Entrypoints

The package now exposes:

- `package:llm_dart_core/foundation.dart`
  - shared primitive contracts such as warnings, errors, usage, metadata,
    provider options, cancellation, JSON schema, prompt/content parts, and tool
    definitions
- `package:llm_dart_core/model.dart`
  - self-contained model specifications, capability helpers, runners, and raw
    stream events
- `package:llm_dart_core/ui.dart`
  - shared UI message, UI chunk, mapper, and accumulator contracts
- `package:llm_dart_core/serialization.dart`
  - shared prompt, UI, and stream-event JSON codecs plus the related data
    contracts needed to use them

## Why This Is The Right Granularity

This follows the current boundary-map decision:

- clarify the internal ownership groups
- avoid adding new published packages before package pressure exists
- let future code choose narrower imports when it improves readability

It does not copy the `repo-ref/ai` package split literally.

## Why The Entrypoints Are Self-Contained

The focused entrypoints intentionally re-export their dependency contracts.

For example:

- `model.dart` also exports the foundation and raw stream-event contracts
  needed by `LanguageModel` and `GenerateTextRequest`
- `ui.dart` exports the foundation and raw stream events needed by UI
  accumulators
- `serialization.dart` exports the prompt/UI/event types needed by the codecs

This avoids a frustrating import style where users import a focused entrypoint
but still need to discover several dependent entrypoints for common use.

## Validation

The new focused entrypoints are covered by:

- `packages/llm_dart_core/test/focused_entrypoints_test.dart`

The test imports all focused entrypoints as aliases and verifies representative
types from each one compile and behave as expected.

The spike is also now validated against real downstream consumers:

- `llm_dart_transport`
  - foundation-only imports for transport cancellation and transport-to-model
    error mapping
  - serialization-only import for the HTTP chat transport protocol codec layer
  - UI-focused import for the server adapter layer
- `llm_dart_chat`
  - foundation-only import for prompt-only input helpers
  - model-focused import for request option shapes and direct model transport
  - UI-focused imports for session runtime, replay logic, tool handling, and
    stream readers
  - serialization-focused import for snapshot persistence codecs

That confirms the focused entrypoints are not only documentation convenience;
they already work as real package-boundary imports across both transport and
chat runtime layers.

## Bottom Line

This gives `llm_dart_core` a clearer public import story without creating
another package boundary.

If future package pressure appears, these focused entrypoints also provide a
low-risk migration map for deciding what could split later.
