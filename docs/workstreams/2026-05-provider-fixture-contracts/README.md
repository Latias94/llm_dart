# Provider Fixture Contracts

## Why This Workstream Exists

The provider implementation refactor now has green release readiness, but many
provider behavior guarantees still live as inline expectations inside large
tests. Those expectations are useful, yet they are harder to audit as stable
contracts before another fearless refactor.

This workstream adds provider-owned fixture and golden contracts for request
encoding, stream event projection, tool replay, and provider metadata. The goal
is not to replace focused unit tests. The goal is to make the high-value wire
and unified-event contracts reviewable as small JSON artifacts.

## Scope

This workstream should:

- define where provider fixture and golden files live
- define a stable naming convention for provider contract fixtures
- add focused tests that compare provider outputs to JSON golden files
- start with OpenAI because its Responses and Chat Completions codec boundaries
  were just split
- keep fixtures package-local unless multiple providers prove the same helper
  contract
- keep public APIs unchanged

## Non-Goals

This workstream should not:

- add a public provider fixture package
- add a public `llm_dart_provider_utils` package
- replace all inline provider tests in one pass
- make network calls or depend on live provider credentials
- encode unstable timestamps or environment-specific paths into golden files

## Fixture Layout

Provider fixtures live inside each provider package:

```text
packages/<provider_package>/test/fixtures/<provider>/
```

Golden files use lower-case, endpoint-first names:

```text
<endpoint>_<contract>_golden.json
```

Examples:

```text
packages/llm_dart_openai/test/fixtures/openai/responses_request_body_golden.json
packages/llm_dart_openai/test/fixtures/openai/chat_completions_request_body_golden.json
packages/llm_dart_openai/test/fixtures/openai/responses_stream_events_golden.json
packages/llm_dart_openai/test/fixtures/openai/chat_completions_stream_events_golden.json
packages/llm_dart_google/test/fixtures/google/generate_content_request_body_golden.json
packages/llm_dart_google/test/fixtures/google/generate_content_stream_events_golden.json
```

## Contract Rules

Fixture tests should:

- compare canonical JSON values, not stringified maps
- use existing provider codecs and public provider contracts
- use provider stream event serialization when a stable event codec already
  exists
- avoid hiding behavior behind broad test helpers
- include enough request/stream input construction in the test to explain why
  the golden matters

Golden files should:

- be deterministic and platform-independent
- avoid secrets
- include only behavior that should be preserved across refactors
- prefer one focused behavior family per file

## First Slice

The first OpenAI slice locks:

- Responses request body encoding for multimodal input, tools, built-in MCP
  tools, structured output, replay metadata, compaction, and MCP approval
  continuation
- Chat Completions request body encoding for tool declarations, tool replay,
  structured output, provider options, and media/file user content
- Responses stream chunks mapped to unified events with response metadata,
  reasoning, text, tool input/call, sources, MCP approval, MCP result, custom
  output, and finish metadata
- Chat Completions stream chunks mapped to unified events with provider
  metadata, reasoning, text, tool input/call, xAI citations, and finish usage

## Google Slice

The first Google slice now locks:

- GenerateContent request body encoding for system/user/assistant/tool prompt
  history, media inputs, file references, function-call id replay, server-side
  tool replay, structured output, safety settings, reasoning, native tools, and
  multimodal tool results
- GenerateContent stream chunks mapped to provider model-call events with
  response metadata, usage, reasoning text, reasoning files, function calls,
  executable code, code execution results, server-side tool calls/responses,
  file output, grounding sources, URL context, safety ratings, and finish
  metadata

This slice keeps the fixture convention provider-local. It does not introduce a
shared fixture package or a public provider utility package.

## Validation

OpenAI fixture slices should run:

```powershell
dart test packages\llm_dart_openai\test\openai_fixture_contract_test.dart
dart analyze packages\llm_dart_openai
dart run tool\check_workspace_dependency_guards.dart
```

Google fixture slices should run:

```powershell
dart test packages\llm_dart_google\test\google_fixture_contract_test.dart
dart analyze packages\llm_dart_google
dart run tool\check_workspace_dependency_guards.dart
```
