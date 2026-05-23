# Provider Options Seam Deepening

## Why This Workstream Exists

`llm_dart_provider` now owns the most important cross-provider contracts:
model options, invocation options, prompt-part options, tool options, replay
options, metadata, and JSON serialization support. Most of that ownership is
healthy, but `lib/src/common/provider_options.dart` has become a shallow
module: its interface nearly matches the implementation surface.

The file currently mixes:

- JSON provider option bag transport
- typed provider invocation options
- typed-to-bag projection
- provider prompt-part and tool option marker interfaces
- replay prompt-part options and codec
- provider option resolver helpers
- JSON bag validation, deep merge, freezing, equality, and hashing helpers

The result still works, but it makes future provider-option decisions harder to
audit. Callers and tests must mentally parse unrelated option concepts before
they can reason about one seam.

## Goal

Deepen the provider options seam while preserving current behavior:

- keep `llm_dart_provider` as the owner of shared provider option contracts
- keep existing public exports stable unless a deliberate breaking decision is
  recorded
- split the current implementation into focused internal modules
- make replay prompt options visibly separate from invocation options
- make JSON bag transport visibly separate from typed option interfaces
- keep provider metadata output-side and replay-only

## Non-Goals

- Do not publish `llm_dart_provider_utils`.
- Do not flatten provider-native typed options into weak shared maps.
- Do not remove `ProviderOptionsBag` from `llm_dart_provider` in the first
  slice.
- Do not change provider package behavior.
- Do not reopen prompt metadata as a request customization path.

## Candidate Source Files

- `packages/llm_dart_provider/lib/src/common/provider_options.dart`
- `packages/llm_dart_provider/lib/src/common/call_options.dart`
- `packages/llm_dart_provider/lib/src/prompt/prompt_message.dart`
- `packages/llm_dart_provider/lib/src/tool/tool_definition.dart`
- `packages/llm_dart_provider/lib/src/serialization/prompt_part_provider_options_json_codec.dart`
- `packages/llm_dart_provider/test/provider_contracts_test.dart`

## Architecture Direction

Use a facade-preserving split first. The current public `foundation.dart`
export can continue to point at the stable provider option surface while
implementation details move into smaller files.

The split should increase depth:

- callers still learn one provider options seam
- maintainers get locality inside focused modules
- tests can target bag transport, typed option resolution, and replay options
  independently

## Success Criteria

- `provider_options.dart` no longer mixes every provider option concept in one
  implementation file.
- JSON bag behavior remains unchanged.
- typed provider option resolution remains unchanged.
- replay prompt-part option serialization remains unchanged.
- provider package public exports remain intentional and documented.
- package analysis, provider tests, dependency guards, and diff hygiene pass.
