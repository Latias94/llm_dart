# TODO

## Setup

- [x] Create the provider options seam deepening workstream
- [x] Record the problem, target state, non-goals, and candidate source files
- [x] Add the workstream to the workstream index

## POS-010 Audit Current Provider Option Ownership

- [x] Inventory every public type and helper currently exported from
      `provider_options.dart`
- [x] Classify each item as bag transport, typed invocation, prompt-part
      option, tool option, replay option, or resolver policy
- [x] Confirm which symbols are public contract and which are implementation
      support
- [x] Validation: `dart analyze packages/llm_dart_provider`

## POS-020 Split JSON Bag Transport

- [x] Move `ProviderOptionsBag` and JSON bag helpers into a focused internal
      module
- [x] Preserve `ProviderOptionsBag` construction, validation, merge, equality,
      hashing, and `toJsonMap` behavior
- [x] Keep public exports stable
- [x] Validation:
      `dart test packages/llm_dart_provider/test/provider_contracts_test.dart`

## POS-030 Split Typed Invocation Resolution

- [x] Move `ProviderInvocationOptions`, `ProviderInvocationOptionsBundle`,
      `ProviderInvocationOptionsBagProjection`, and typed resolver helpers into
      a focused internal module
- [x] Preserve typed-plus-bag precedence behavior
- [x] Keep wrong-provider error messages stable
- [x] Validation:
      `dart test packages/llm_dart_provider/test/provider_contracts_test.dart`

## POS-040 Split Prompt-Part, Tool, And Replay Options

- [x] Move prompt-part option interfaces and codecs into focused modules
- [x] Move tool option interfaces and codecs into focused modules
- [x] Move `ProviderReplayPromptPartOptions` and its JSON codec into a focused
      replay module
- [x] Preserve serialization compatibility and replay metadata guards
- [x] Validation:
      `dart test packages/llm_dart_provider/test/prompt_part_provider_options_json_codec_test.dart`

## POS-050 Verification And Closeout

- [x] Run `dart analyze packages/llm_dart_provider`
- [x] Run `dart test packages/llm_dart_provider/test`
- [x] Run workspace dependency guards
- [x] Run provider replay metadata guard
- [x] Run provider metadata namespace guard
- [x] Run `git diff --check`
- [x] Update evidence, handoff, and closeout notes
