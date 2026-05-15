# Closure Audit

## Objective Restated

Complete the provider implementation kit and codec boundary refactor for this
workstream by proving a repeatable provider-local split pattern without
changing the public unified API, weakening provider-native behavior, or
introducing a premature public provider utility package.

The concrete completion line is:

- OpenAI Responses request encoding is split out of the large codec.
- OpenAI result and stream responsibilities are assessed and either split or
  intentionally retained.
- At least one non-OpenAI provider receives a comparable provider-local split.
- Extracted modules have clear single reasons to change and focused tests.
- Provider packages keep the existing dependency boundaries.
- No public `llm_dart_provider_utils` package is introduced without evidence.
- Focused provider tests, analysis, guards, and full release readiness pass.
- Workstream docs record closure and the provider-utils decision.

## Prompt-To-Artifact Checklist

| Requirement | Evidence |
| --- | --- |
| Preserve the public unified API and OpenAI facade. | `OpenAILanguageModel` still calls `OpenAIResponsesCodec.encodeRequest(...)`; the facade delegates internally to `OpenAIResponsesRequestCodec`. |
| Preserve provider-native features. | Existing OpenAI Responses tests still cover replay metadata, item references, MCP continuations, built-in tools, reasoning, logprobs, custom outputs, image/file inputs, and stream behavior. Anthropic tests still cover native tools, tool-search deferred loading, extended thinking compatibility, cache control, files, and custom replay. |
| Split OpenAI Responses request encoding. | `packages/llm_dart_openai/lib/src/openai_responses_request_codec.dart` owns request body assembly, prompt/replay encoding, request compatibility policy, tools, response format, and file/image request helpers. |
| Keep `openai_responses_codec.dart` out of request/body details. | `packages/llm_dart_openai/lib/src/openai_responses_codec.dart` contains the facade, non-stream result decoding, and stream decoding; `rg` shows request encoding in `openai_responses_request_codec.dart` and only facade delegation in `openai_responses_codec.dart`. |
| Assess OpenAI result/stream split. | `03-openai-responses-codec-boundary-audit.md` and `04-openai-responses-request-codec-extraction.md` document that result/stream decoding remains in the facade for this slice because the stream parser is stateful and higher risk. Stream tests passed unchanged. |
| Complete at least one non-OpenAI contrast split. | `packages/llm_dart_anthropic/lib/src/anthropic_tool_configuration.dart` owns Anthropic common/native tool encoding, tool choice mapping, deferred loading, cache-control projection, and thinking/tool-choice validation. |
| Keep extracted modules single-purpose. | OpenAI request codec changes when Responses request shapes change. Anthropic tool configuration changes when Anthropic tool configuration rules change. Response parsing, stream parsing, and transport remain outside those modules. |
| Keep provider packages dependency-clean. | `dart run tool/check_workspace_dependency_guards.dart` passed before and inside release readiness. |
| Do not introduce premature public provider utils. | `06-provider-utils-decision.md` documents the helper inventory and decision; there is no `packages/llm_dart_provider_utils` package. |
| Validate focused provider behavior. | Focused OpenAI and Anthropic tests passed before closure; full workspace tests and package tests passed inside release readiness. |
| Validate release readiness. | `dart run tool/release_readiness.dart` passed with all 13 steps green, finishing at `2026-05-15T10:13:40.409467`. |

## Focused Validation Evidence

Commands run during implementation:

```powershell
dart analyze packages/llm_dart_openai
dart test packages/llm_dart_openai/test/openai_responses_codec_test.dart
dart test packages/llm_dart_openai/test/openai_responses_stream_codec_test.dart
dart test packages/llm_dart_openai/test/openai_language_model_test.dart
dart analyze packages/llm_dart_anthropic
dart test packages/llm_dart_anthropic/test/anthropic_messages_codec_test.dart
dart test packages/llm_dart_anthropic/test/anthropic_language_model_test.dart
dart run tool/check_workspace_dependency_guards.dart
dart run tool/check_root_package_boundary_guards.dart
dart run tool/check_core_compatibility_shell_guard.dart
```

All commands passed.

## Release Readiness Evidence

`dart run tool/release_readiness.dart` passed with 13/13 steps:

- workspace dependency guards
- root package boundary guards
- core compatibility shell guard
- provider replay metadata guard
- transport boundary guard
- test legacy-import guard
- example API guard
- workspace analysis
- workspace tests
- workspace package tests
- consumer smoke
- workspace publish dry-run
- pub version availability

Result:

```text
Started: 2026-05-15T10:10:55.134423
Finished: 2026-05-15T10:13:40.409467
Elapsed: 2m 45s
Result: passed
```

## Explicitly Deferred

Ollama language model remains a future candidate.

Google GenerateContent was originally deferred because initial closure required
OpenAI Responses plus at least one non-OpenAI contrast split. It was later
completed as a follow-up slice and recorded in
`08-google-generate-content-codec-boundary.md`.

Do not treat that as a reason to publish shared utilities. The follow-up path
is to split Ollama only when a provider-specific feature change or audit
requires it.
