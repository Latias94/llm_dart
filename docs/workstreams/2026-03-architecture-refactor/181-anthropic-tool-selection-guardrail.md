# 181 Anthropic Tool-Selection Guardrail

## Why This Slice Exists

The native-tool selection design was already frozen earlier:

- shared `ToolChoice` stays common-function-oriented
- provider-owned native-tool selection must stay provider-owned
- Anthropic may gain a provider-owned selection surface later, but only if a
  real use case appears

During the Anthropic follow-up audit, one implementation drift remained:

- `SpecificToolChoice` could still flow through Anthropic request encoding even
  when the selected name was a native tool or an undeclared tool

That was broader than the frozen design intended.

## What Changed

`anthropic_messages_codec.dart` now enforces the intended phase-1 guardrail:

- `SpecificToolChoice` is accepted only for declared common function tools
- selecting a native tool by name through shared `SpecificToolChoice` is
  rejected
- selecting an undeclared tool name is also rejected

This keeps Anthropic aligned with the earlier design without adding a new
provider-owned public API yet.

## Why This Is Better

- keeps shared `ToolChoice` honest instead of letting it silently grow into a
  native-tool selector
- avoids freezing native-tool selection semantics before a real provider-owned
  surface exists
- keeps mixed common/native tool requests valid for `auto` and `required`
  without pretending `SpecificToolChoice` is already a provider-native forcing
  contract

## Boundary Decision

Anthropic still does **not** get a new provider-owned public selection API in
this slice.

The current boundary is:

- common function-tool forcing through shared `SpecificToolChoice`
- mixed declaration of common and native tools in one request
- no native-tool forcing-by-name API yet

If a future native-tool forcing need appears, it should land as a provider-owned
Anthropic selection surface, not by stretching shared `SpecificToolChoice`.

## Validation

This slice adds a targeted test that rejects:

- selecting `web_search` through shared `SpecificToolChoice`
- selecting an undeclared tool name through shared `SpecificToolChoice`

while keeping the existing Anthropic request path green.

## Non-Goals

This slice does not:

- add `disable_parallel_tool_use`
- add a public `AnthropicToolSelection` model
- change Anthropic mixed native/common tool declaration support
- widen shared `ToolChoice`

## Follow-Up

The remaining Anthropic tool-policy question is no longer whether shared
`SpecificToolChoice` should silently select native tools. That is now closed.

The remaining question is whether Anthropic ever needs a real provider-owned
selection surface beyond the current shared subset, and that should stay
demand-driven.
