# Core Prompt Replay Test Alignment

Date: 2026-05-13
Status: implemented

## What Landed

This slice updates `llm_dart_core` compatibility tests to match the frozen
prompt replay boundary:

- prompt parts no longer expose or assert `providerMetadata`
- replay metadata is carried through `ProviderReplayPromptPartOptions`
- tests use `providerReplayMetadataFromOptions(...)` when they need to inspect
  replay metadata
- multi-step runner continuation tests assert typed replay options instead of
  checking removed prompt-side metadata fields

No production code changed in this slice. The goal is to remove stale test
expectations that contradicted the architecture line and caused broader
`llm_dart_core` analysis to fail.

## Boundary Rule

Provider metadata remains an output-side observation. When an output part needs
to be replayed into a later provider prompt, the prompt carries that replay
state explicitly as typed provider options.

This keeps ordinary input prompt data clean while preserving provider-native
continuation features such as Google thought signatures and provider tool-call
ids.

## Validation

- `dart analyze packages/llm_dart_core`
- `dart test packages/llm_dart_core/test/message_json_codec_test.dart packages/llm_dart_core/test/generate_text_runner_test.dart packages/llm_dart_core/test/stream_text_runner_test.dart`

## Remaining Work

Tool output objects still intentionally support output-side `providerMetadata`.
Future runtime event ownership work should decide whether replayed tool-output
metadata also needs a stricter typed replay wrapper when the full-stream event
classes move into `llm_dart_ai`.
