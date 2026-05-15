# Anthropic Fixture Contracts

## Why This Workstream Exists

OpenAI now has provider-local fixture and golden contracts for request
encoding and stream event projection. A single provider baseline is useful,
but it can accidentally encode OpenAI-specific assumptions into the convention.

Anthropic is the right second provider because its Messages API combines
system/user/assistant grouping, cache control, beta headers, extended thinking,
MCP servers, native server tools, provider-executed tool results, custom replay
parts, and stream metadata. If the same fixture convention works here without
new public helpers, it is strong evidence that the convention is provider-local
rather than OpenAI-specific.

## Scope

This workstream should:

- add Anthropic fixtures under
  `packages/llm_dart_anthropic/test/fixtures/anthropic/`
- add focused fixture contract tests in the Anthropic provider package
- cover Messages request body encoding
- cover request-side beta features and warnings
- cover tool call and tool result replay encoding
- cover stream chunks projected to unified language-model events
- record repeated OpenAI/Anthropic testing patterns without extracting a
  shared provider utility package yet
- keep public APIs unchanged

## Non-Goals

This workstream should not:

- add `llm_dart_provider_utils`
- move provider fixture helpers into a public package
- replace all existing Anthropic codec tests
- make network calls or require live credentials
- encode unstable timestamps, local paths, or environment-specific values

## Fixture Layout

Anthropic follows the provider-local convention:

```text
packages/llm_dart_anthropic/test/fixtures/anthropic/
```

Golden files use endpoint-first names:

```text
messages_request_body_golden.json
messages_request_metadata_golden.json
messages_replay_request_body_golden.json
messages_stream_events_golden.json
```

## Contract Rules

Fixture tests should:

- compare canonical JSON values, not stringified maps
- use Anthropic provider codecs and public provider contracts
- serialize stream projections with `LanguageModelStreamEventJsonCodec`
- keep input construction close to the assertion so the contract remains
  reviewable
- avoid broad shared helpers until a third provider proves the duplication is
  stable

Golden files should:

- be deterministic and platform-independent
- avoid secrets
- preserve behavior that matters across refactors
- keep request body, request metadata, replay, and stream contracts separated

## First Slice

The first Anthropic slice locks:

- Messages request body encoding for multimodal user input, cache control,
  Anthropic file references, function tools, native tools, MCP servers,
  tool-search deferral, extended thinking, and provider metadata
- request-side beta features and warnings for thinking, MCP, files, cache
  control, and unsupported shared sampling options
- tool replay for common tools, MCP tool use/results, web-search results, and
  Anthropic code-execution custom replay parts
- stream chunks mapped to unified events for response metadata, text,
  citations, thinking/signatures, common tool calls, MCP tool calls/results,
  server tool results, custom replay events, sources, code execution, usage,
  container metadata, and finish reasons

## OpenAI/Anthropic Repetition Audit

The first two provider fixture slices repeat these useful patterns:

- provider fixtures live inside the provider package
- request body goldens compare provider codec output directly
- stream event goldens use the shared language-model stream event envelope
- tests keep provider-specific input construction local to the provider
- fixture names are endpoint-first and contract-specific

The repetition is intentional for now. It is not enough evidence to create a
public provider utility package because the provider input construction remains
provider-specific, and only the fixture read/compare helpers are identical.

## Validation

Each slice should run:

```powershell
dart test packages\llm_dart_anthropic\test\anthropic_fixture_contract_test.dart
dart test packages\llm_dart_anthropic\test\anthropic_messages_codec_test.dart packages\llm_dart_anthropic\test\anthropic_stream_codec_test.dart packages\llm_dart_anthropic\test\anthropic_result_codec_test.dart packages\llm_dart_anthropic\test\anthropic_code_execution_replay_test.dart packages\llm_dart_anthropic\test\anthropic_language_model_test.dart packages\llm_dart_anthropic\test\anthropic_fixture_contract_test.dart
dart analyze packages\llm_dart_anthropic
dart run tool\check_workspace_dependency_guards.dart
```
