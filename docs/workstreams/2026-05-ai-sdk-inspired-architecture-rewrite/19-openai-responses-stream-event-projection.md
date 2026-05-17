# OpenAI Responses Stream Event Projection

## Decision

Split OpenAI Responses stream event projection into deeper provider-owned
modules while keeping `decodeOpenAIResponsesStreamChunk` as the stable stream
router.

This is a package-internal refactor. Public OpenAI options, stream event
classes, provider metadata shape, source de-duplication, MCP approval/result
events, partial-image custom events, logprobs aggregation, and finish behaviour
remain unchanged.

## Reference Shape

`repo-ref/ai` keeps OpenAI Responses stream conversion provider-owned and
handles event families such as text deltas, reasoning summaries, annotations,
hosted tools, MCP approvals, partial image events, terminal response metadata,
and finish usage inside the OpenAI provider layer.

The Dart package keeps a smaller router because `LanguageModelStreamEvent` is
already the shared provider-facing event contract. The useful lesson is the
ownership shape: provider-native stream vocabulary stays behind OpenAI
Responses modules instead of being flattened into a weak shared abstraction.

## Problem

`openai_responses_stream_event_codec.dart` had a compact entry interface but
too much implementation knowledge behind it:

- top-level Responses chunk routing
- message output item start/end handling
- text delta/done lifecycle and logprobs collection
- reasoning summary start/delta/end lifecycle
- source annotation decoding and duplicate suppression
- content-part done handling with text-end metadata
- partial image custom stream events
- output-item done routing for function calls, MCP approval requests, MCP
  calls, reasoning items, and provider custom items

That made future Responses stream features risky because unrelated event
families had to be edited in the same file.

## Implemented Shape

- Added `openai_responses_text_reasoning_stream_projection.dart`.
  - Owns message text start/end, text delta/done, and reasoning summary
    lifecycle projection.
- Added `openai_responses_source_annotation_stream_projection.dart`.
  - Owns annotation source events, duplicate suppression, content-part done
    source decoding, text-end metadata, and logprobs aggregation from completed
    content parts.
- Added `openai_responses_output_item_stream_projection.dart`.
  - Owns `response.output_item.added` and `response.output_item.done` routing
    by item type.
- Added `openai_responses_mcp_stream_projection.dart`.
  - Owns MCP approval request and provider-executed MCP call stream event
    projection.
- Added `openai_responses_custom_stream_projection.dart`.
  - Owns partial image custom events and generic provider custom output items.
- Kept `openai_responses_stream_event_codec.dart`.
  - It now routes by chunk `type` and delegates event-family projection to the
    deeper modules.

## Benefit

This deepens the OpenAI Responses stream module:

- text/reasoning lifecycle changes have locality separate from MCP and hosted
  tool projection
- source annotation behaviour has a focused test surface around duplicate
  suppression and content-part metadata
- output item routing is explicit and can grow as OpenAI adds item types
- partial image/custom stream events remain OpenAI-owned without leaking into
  shared provider utilities
- the public `OpenAIResponsesCodec` stream entrypoint stays stable

## Verification

- `dart test test/openai_responses_stream_codec_test.dart` in
  `packages/llm_dart_openai`
- `dart test test/openai_fixture_contract_test.dart` in
  `packages/llm_dart_openai`
- `dart test` in `packages/llm_dart_openai`
- `dart analyze` in `packages/llm_dart_openai`
- root `dart analyze`
- `git diff --check`

New focused coverage locks:

- message `response.output_item.done` completes text without becoming a custom
  event
- `response.content_part.done` logprobs are preserved on both text-end and
  finish metadata

## Remaining Risks

OpenAI's newer hosted tool stream event families such as shell, apply-patch,
tool-search, and code-interpreter deltas are still represented only where this
Dart package currently exposes equivalent native behaviours. If those native
tools become public Dart provider tools, the new output item and custom stream
projection modules are the right places to add them.
