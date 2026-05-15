# Anthropic Tool Configuration Extraction

## Summary

The second provider slice selected Anthropic as the non-OpenAI contrast
provider and extracted tool configuration into:

```text
packages/llm_dart_anthropic/lib/src/anthropic_tool_configuration.dart
```

The split keeps Anthropic provider-native semantics local while moving common
function tools, Anthropic native tools, `tool_choice`, deferred loading, and
tool cache-control encoding out of the large messages codec.

## Moved Responsibilities

The new helper owns:

- common function tool encoding
- Anthropic native tool encoding
- `ToolChoice` to Anthropic `tool_choice` mapping
- `SpecificToolChoice` validation against declared common function tools
- extended-thinking tool-choice compatibility validation
- deferred tool name normalization and warnings
- tool-search native-tool awareness for deferred loading warnings
- tool-level cache-control projection

## Retained Responsibilities

`anthropic_messages_codec.dart` still owns:

- top-level Messages request and token-count request body assembly
- system/user/assistant prompt block grouping
- user image/document/file source projection
- tool result and custom tool replay projection
- Anthropic code-execution replay handoff
- cache-control and file-source beta discovery across the final body

Those retained areas remain provider-specific and have not yet shown enough
cross-provider duplication to justify a shared utility package.

## Validation

Focused validation completed for this slice:

```powershell
dart format packages/llm_dart_anthropic/lib/src/anthropic_messages_codec.dart packages/llm_dart_anthropic/lib/src/anthropic_tool_configuration.dart
dart analyze packages/llm_dart_anthropic
dart test packages/llm_dart_anthropic/test/anthropic_messages_codec_test.dart
dart test packages/llm_dart_anthropic/test/anthropic_language_model_test.dart
dart run tool/check_workspace_dependency_guards.dart
dart run tool/check_root_package_boundary_guards.dart
dart run tool/check_core_compatibility_shell_guard.dart
```

All commands passed.

## Provider Utils Decision Signal

This slice does not justify a public `llm_dart_provider_utils` package.

The OpenAI and Anthropic slices both use local request/tool configuration
helpers, but their semantics are provider-specific:

- OpenAI Responses request encoding is driven by Responses input items,
  item references, reasoning compatibility, MCP continuations, and built-in
  tool shapes.
- Anthropic tool configuration is driven by Messages `tool_choice`,
  extended-thinking compatibility, Anthropic native tools, deferred loading,
  and beta/cache-control behavior.

Keep these helpers provider-local until a later inventory finds repeated,
stable behavior with the same contract in at least two providers.
