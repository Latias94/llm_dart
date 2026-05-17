# Anthropic Code Execution Replay Boundary

## Summary

The Anthropic code execution replay follow-up slice split the public replay
surface from provider-local replay implementation details:

```text
packages/llm_dart_anthropic/lib/src/anthropic_code_execution_replay.dart
packages/llm_dart_anthropic/lib/src/anthropic_code_execution_replay_codec.dart
packages/llm_dart_anthropic/lib/src/anthropic_code_execution_replay_json.dart
packages/llm_dart_anthropic/lib/src/anthropic_code_execution_replay_result.dart
```

`AnthropicCodeExecutionReplay` remains the stable public seam exported by the
Anthropic package. It now owns only custom content/prompt/event conversion,
provider replay metadata plumbing, and the public constants expected by
callers. Replay JSON validation, block validation, execution result parsing,
file-handle parsing, and low-level JSON guard logic moved behind that seam.

This follows the `repo-ref/ai` Anthropic provider posture: code execution,
server tool calls, and provider-executed tool results stay provider-owned
because their wire vocabulary is not a stable cross-provider contract.

## Moved Responsibilities

`anthropic_code_execution_replay_codec.dart` owns:

- replay schema, kind, and canonical tool-name constants used by the facade
- replay payload validation
- code-execution result block validation
- replay JSON encoding

`anthropic_code_execution_replay_json.dart` owns:

- provider-local replay JSON object/list/string/int/bool guards
- path-aware `FormatException` messages for malformed replay data

`anthropic_code_execution_replay_result.dart` owns:

- public typed execution result models
- `AnthropicCodeExecutionBlockType`
- execution file-handle parsing
- execution result type dispatch

## Retained Responsibilities

`anthropic_code_execution_replay.dart` still owns:

- the public `AnthropicCodeExecutionReplay` facade
- `toCustomContentPart(...)`
- `toCustomPromptPart(...)`
- `toCustomEvent(...)`
- custom content/prompt/event parsing entry points
- prompt replay metadata conversion through `ProviderReplayPromptPartOptions`

The file re-exports `anthropic_code_execution_replay_result.dart`, so existing
imports of `anthropic_code_execution_replay.dart` and the package public barrel
continue to expose the typed result model.

## Provider Utils Decision Signal

This slice still does not justify a public `llm_dart_provider_utils` package.

The repeated shape is "validate JSON object and parse typed result", but the
actual interface is Anthropic-specific:

- code-execution result types are Anthropic wire types
- file handles use Anthropic file IDs and content block names
- replay metadata must flow through Anthropic provider metadata and shared
  `ProviderReplayPromptPartOptions`
- prompt replay blocks are Anthropic tool-result blocks, not provider-neutral
  tool output

If another provider grows a comparable public replay surface, the reusable
candidate should be evaluated at the replay-envelope level, not by extracting
these Anthropic wire guards into a broad utility module.

## Validation

Focused validation completed for this slice:

```powershell
dart test packages\llm_dart_anthropic\test\anthropic_code_execution_replay_test.dart
dart test packages\llm_dart_anthropic\test\anthropic_code_execution_replay_test.dart packages\llm_dart_anthropic\test\anthropic_messages_codec_test.dart packages\llm_dart_anthropic\test\anthropic_files_test.dart packages\llm_dart_anthropic\test\anthropic_fixture_contract_test.dart
dart test packages\llm_dart_anthropic
dart analyze packages\llm_dart_anthropic
dart analyze
git diff --check
```

All commands passed during the implementation slice.
