# 169 OpenAI Streaming Support Extraction

## Why This Slice Exists

The OpenAI-family package had reached a point where `openai_chat_completions_codec.dart` and `openai_responses_codec.dart` were each carrying their own partial stream-state machinery:

- per-part started/ended tracking for text and reasoning
- indexed tool-call delta accumulation
- JSON tool-argument decode/error shaping
- `<think>...</think>` extraction helpers for OpenAI-compatible assistant text

The duplication was not yet catastrophic, but it was already pushing the OpenAI compatibility layer away from the clearer three-layer shape we want:

1. request encoding
2. stream parsing
3. provider facade / transport orchestration

## What Changed

This slice introduces a package-local shared support module:

- `packages/llm_dart_openai/lib/src/openai_streaming_support.dart`

It centralizes the small cross-codec primitives that belong to stream parsing rather than to either specific endpoint:

- `OpenAIStreamPartState`
- `OpenAIIndexedToolCallAccumulator`
- `OpenAIStreamToolCallState`
- `appendOpenAIThinkingAndText(...)`
- `appendOpenAILogprobs(...)`
- `tryDecodeOpenAIJsonValue(...)`
- `formatInvalidOpenAIToolInputError(...)`

## Boundary Decision

The extracted module is intentionally narrow.

It does **not** try to merge chat-completions and Responses into one generic codec, because the wire protocols remain meaningfully different:

- chat-completions still has single-choice delta semantics and fixed text/reasoning IDs
- Responses has multi-item output streams, output indices, provider-native output families, and approval/MCP flow events

So the right boundary is shared parsing state and parsing helpers, not a forced unified transport decoder.

## Why This Is Better

- reduces repeated parser-state code without hiding endpoint-specific semantics
- keeps `openai_chat_completions_codec.dart` and `openai_responses_codec.dart` focused on protocol mapping
- makes future OpenAI-compatible provider work less risky because tool-call delta accumulation and thinking-tag parsing now live in one place
- keeps the provider package aligned with the broader refactor goal: smaller responsibility-focused modules instead of large endpoint bus files

## Non-Goals

This slice does not:

- redefine shared core events
- unify finish-reason policies between endpoints beyond existing behavior
- widen public API surface
- introduce a generic “OpenAI stream codec” abstraction

## Follow-Up

The next high-value OpenAI-family cleanup is to continue auditing whether any remaining stream-specific provider metadata builders or custom-output projection helpers should move into endpoint-local support modules, while leaving the endpoint decoders themselves as the protocol owners.
