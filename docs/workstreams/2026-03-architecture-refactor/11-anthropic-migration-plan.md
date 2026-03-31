# Anthropic Migration Plan

## Goal

This document defines how the legacy Anthropic implementation should move into `packages/llm_dart_anthropic` without re-importing the old monolith architecture.

The intent is to migrate Anthropic in slices, not as one giant file move.

## Current Legacy Surface

The existing root implementation currently mixes several concerns:

- transport setup and Dio behavior in `client.dart`
- request encoding in `request_builder.dart`
- stream parsing and high-level chat behavior in `chat.dart`
- model capability/config logic in `config.dart`
- MCP connector models in `mcp_models.dart`
- file APIs in `files.dart`
- provider facade and convenience constructors in `provider.dart` and `anthropic.dart`

That shape was acceptable in the old monolith, but it is not the target shape for the new workspace.

## What Must Move Into The New Package

The new `llm_dart_anthropic` package should eventually own:

- typed Anthropic model settings
- typed Anthropic invocation options
- Anthropic request encoding
- Anthropic stream chunk decoding to `TextStreamEvent`
- Anthropic result decoding to `ContentPart`
- Anthropic MCP connector typed models
- Anthropic-specific provider-native APIs such as files

The new package must not own:

- generic HTTP executor responsibilities
- generic SSE decoding responsibilities
- root facade compatibility
- the old `LLMConfig.extensions` mainline

## Package-Internal Module Layout

The recommended internal layout is:

- `src/anthropic.dart`
  - package-level provider entry
- `src/anthropic_language_model.dart`
  - `LanguageModel` implementation
- `src/anthropic_options.dart`
  - typed model and invocation options
- `src/anthropic_messages_codec.dart`
  - prompt -> Anthropic request body
- `src/anthropic_stream_codec.dart`
  - stream chunk -> `TextStreamEvent`
- `src/anthropic_result_codec.dart`
  - response JSON -> `GenerateTextResult`
- `src/anthropic_mcp_models.dart`
  - MCP connector typed models
- `src/shared/...`
  - package-private helpers only if needed

Important rule:

- do not recreate the old `config + client + request_builder + provider` coupling pattern inside the new package

## Feature Placement Rules

### Extended Thinking

Anthropic thinking belongs in:

- `ReasoningContentPart`
- `ReasoningStartEvent` / `ReasoningDeltaEvent` / `ReasoningEndEvent`
- typed invocation options for request-side controls

It does not justify new core content types.

### Interleaved Thinking

Interleaved thinking is provider-specific request behavior.

It belongs in:

- typed invocation options
- provider-internal request headers or beta feature flags

It does not belong in `CallOptions.headers` as an application concern.

### Cache Control

Anthropic cache markers are provider-specific detail.

They should move to:

- provider metadata when the information is informational
- custom parts when the information needs to remain renderable or inspectable

They should not widen the common usage model prematurely.

### Web Search Tool

Anthropic server-side web search should remain an Anthropic adapter concern.

That means:

- request encoding may translate Anthropic-specific web-search config into the proper Anthropic tool wire shape
- returned citations should flow through common source parts where possible
- any Anthropic-only detail should remain in provider metadata or provider-namespaced custom parts

### MCP Connector

Anthropic MCP connector support belongs in:

- typed Anthropic invocation options or provider-native helper APIs for request-side configuration
- provider-namespaced custom parts or metadata for provider-specific returned detail
- dedicated provider-native models such as `AnthropicMcpServer`

It must not pull `mcp_dart` into the package, because Anthropic MCP connector support is not a local MCP client implementation.

### Code Execution And Downloadable Files

Anthropic code execution belongs in:

- typed Anthropic tool-definition helpers
- provider-owned custom replay parts for execution result blocks
- provider-native files APIs for downloadable output handles

It does not belong in:

- new Anthropic-only core event families
- fake common file projection when the provider only returned a file ID
- widened shared `ToolResultPromptPart` typing for Anthropic-only result variants

## First Migration Slice

The first useful slice should be:

1. typed Anthropic options
2. MCP connector typed models
3. request/result/stream codec boundaries

Why this order:

- it freezes the provider-owned surface first
- it avoids migrating high-level chat orchestration before the data contracts are stable
- it gives later code migration a clear target instead of translating old `LLMConfig.extensions` ad hoc again

## Current Progress Snapshot

The current migration now goes beyond the thin text-generation mainline.

The new package already owns:

- `AnthropicChatModelSettings`
- `AnthropicGenerateTextOptions`
- `AnthropicFilesSettings`
- `AnthropicCacheControl`
- `AnthropicMcpServer` and related MCP typed models
- `AnthropicMessagesCodec`
- `AnthropicMessagesResultCodec`
- `AnthropicStreamCodec`
- `AnthropicLanguageModel`
- package-level `Anthropic` facade
- package-level `Anthropic.files(...)`
- `AnthropicCodeExecutionReplay`
- package tests for `generate()`, `stream()`, typed MCP models, files, and execution replay

What this now proves:

- Anthropic request encoding is package-owned rather than root-monolith-owned
- Anthropic streaming and non-streaming responses can map into the frozen core result and stream models
- Anthropic reasoning, native-tool replay, MCP configuration, and execution replay now all have package-owned boundaries
- provider-specific beta/header behavior can stay in the provider package without widening the common API
- provider-native files and execution downloads can stay provider-owned without widening shared file models

What is still intentionally separate:

- the compatibility-only legacy raw bridge and any remaining fallback-only replay families
- any future Anthropic-only helper surface that does not belong in `LanguageModel`
- broader capability helpers or model-specific limits that should remain package-private

## Legacy-To-New Mapping

| Legacy area | New package target |
| --- | --- |
| `config.dart` | typed options plus package-private capability helpers |
| `request_builder.dart` | `anthropic_messages_codec.dart` |
| `chat.dart` stream parsing | `anthropic_stream_codec.dart` plus `LanguageModel.stream()` |
| `chat.dart` response parsing | `anthropic_result_codec.dart` plus `LanguageModel.generate()` |
| `client.dart` | thin provider client on top of `llm_dart_transport` |
| `mcp_models.dart` | `anthropic_mcp_models.dart` |
| `files.dart` | provider-native API module, separate from `LanguageModel` |

## Immediate Constraints

During migration:

- avoid importing root `lib/core/*` or `lib/models/*` into the new package
- translate legacy `extensions` usage into typed options or provider-native APIs instead of copying it over
- keep request/stream/result codecs JSON-safe and side-effect free
- keep provider metadata namespaced under `anthropic`
- keep provider-specific streamed details in `providerMetadata`, `CustomEvent`, or provider-native result payloads instead of inventing new Anthropic-only core stream events

## Exit Criteria For The Anthropic Text Mainline

The Anthropic text mainline should be considered migrated only when:

- `LanguageModel.generate()` works through the new package
- `LanguageModel.stream()` produces core `TextStreamEvent`
- tool use works through common tool events and content parts
- thinking works through common reasoning events and parts
- MCP connector request-side configuration is represented without `extensions`
- no new code in the package depends on the old root monolith abstractions

Current status:

- the exit criteria above are now satisfied for the Anthropic text mainline
- follow-up work should stay on narrower provider-native replay-policy cleanup, optional future provider-owned APIs, and legacy-root cleanup rather than re-opening the basic text boundary
- `16-anthropic-provider-native-result-replay.md` now freezes the next replay boundary for provider-native result blocks
- `18-anthropic-execution-replay-contract.md` now freezes the recommended payload direction for execution-oriented replay and downloadable file handles
- `19-anthropic-provider-native-files-api.md` now freezes the provider-owned files boundary for execution file handles
- `56-anthropic-status-reconciliation.md` now records the remaining real Anthropic gaps so stale TODO wording does not reopen already-migrated work
