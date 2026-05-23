# Provider Options Seam Deepening - Handoff

Status: Closed
Last updated: 2026-05-23

## Current State

This workstream closed after a facade-preserving split of
`packages/llm_dart_provider/lib/src/common/provider_options.dart`.

Before the split, one file owned:

- one file owns JSON bag transport, typed invocation options, prompt-part
  options, tool options, replay options, resolver helpers, and bag JSON
  internals
- the public seam is valuable, but the implementation has low locality
- provider tests already cover the critical behavior, so the first slices can
  be behavior-preserving splits
- POS-010 audit now classifies the current symbols into bag transport, typed
  invocation, prompt-part replay, tool options, and internal JSON support

The current state is:

- `provider_options.dart` is a stable library facade.
- `provider_options_bag.dart` owns `ProviderOptionsBag` and JSON bag helpers.
- `provider_invocation_options.dart` owns typed invocation contracts, bundle
  helpers, bag projection helpers, and invocation/model resolvers.
- `provider_prompt_part_options.dart` owns prompt-part option contracts and
  prompt-part resolver behavior.
- `provider_replay_prompt_part_options.dart` owns replay prompt-part options,
  replay JSON codec, and replay metadata extraction.
- `provider_tool_options.dart` owns tool option contracts and tool resolver
  behavior.
- `tool/check_provider_replay_metadata_guards.dart` now understands the
  provider options facade plus `part` files.

## Completed

- POS-010 provider option symbol ownership audit
- POS-020 JSON bag transport split
- POS-030 typed invocation resolution split
- POS-040 prompt-part, tool, and replay option split
- POS-050 verification and closeout

## Follow-On

No required follow-on remains for this lane. A future lane could revisit
whether these `part` files should become separate importable libraries, but the
current alpha architecture target was to deepen implementation locality without
changing the stable public provider option entrypoint.

## Validation

```powershell
dart analyze packages/llm_dart_provider
dart test packages/llm_dart_provider/test
dart run tool/check_workspace_dependency_guards.dart
dart run tool/check_provider_replay_metadata_guards.dart
dart run tool/check_provider_metadata_namespace_guards.dart
dart test test/tool/check_provider_replay_metadata_guards_test.dart
git diff --check
```

All commands passed on 2026-05-23. `git diff --check` only printed LF/CRLF
working-copy warnings and exited successfully.

## Notes

- Keep behavior stable for the first implementation slice.
- Do not introduce `llm_dart_provider_utils`.
- Do not move provider-native option policy into shared weak maps.
- Treat replay prompt-part options as input-side replay, not ordinary request
  metadata.
