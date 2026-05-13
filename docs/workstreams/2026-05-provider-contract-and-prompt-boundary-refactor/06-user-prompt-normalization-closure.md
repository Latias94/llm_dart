# User Prompt Normalization Closure

Date: 2026-05-14
Status: complete

## Decision

`llm_dart_ai` now owns the user-facing prompt layer through `ModelMessage` and
`ModelPart`. The runtime normalizes that layer into provider-facing
`PromptMessage` values before provider calls.

The normalization boundary is:

- user-facing code uses `ModelMessage` / `ModelPart`
- runtime calls `normalizeModelMessages(...)`
- provider-facing codecs continue to consume `PromptMessage`

## What Changed

- user prompt ergonomics no longer depend on constructing provider-facing
  prompt parts directly for common app flows
- prompt normalization validates missing tool results and invalid prompt
  transitions before provider calls
- provider-facing `PromptMessage` remains the lower-level contract for advanced
  provider/replay use cases

## Validation

- `packages/llm_dart_ai/test/prompt_normalization_test.dart`
- `packages/llm_dart_ai/test/prompt_validation_test.dart`

## Notes

This boundary keeps the provider contract narrow while leaving room for future
user-facing prompt convenience APIs above it.
