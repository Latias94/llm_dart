# 170 OpenAI Responses Support Extraction

## Why This Slice Exists

After the shared OpenAI streaming support extraction, `openai_responses_codec.dart` was still carrying too much endpoint-local helper code in one file:

- output item decoding
- MCP approval/result output projection
- source annotation mapping and deduplication keys
- response/item/stream metadata shaping

That code is still specific to the Responses API, but it does not belong in the main protocol flow section of the codec.

## What Changed

This slice adds:

- `packages/llm_dart_openai/lib/src/openai_responses_support.dart`

The new support module now owns the Responses-specific helper surface for:

- message/reasoning/function-call output decoding
- MCP approval and MCP call output projection
- source annotation decoding and deduplication keys
- response/item/stream metadata builders
- message-output logprob collection

`openai_responses_codec.dart` keeps ownership of request encoding, stream event sequencing, finish-reason handling, and transport-facing protocol behavior.

## Boundary Decision

This extraction is intentionally endpoint-local.

We are **not** trying to create one generic OpenAI-family output decoder shared by chat-completions and Responses, because the output item model is a Responses-specific protocol concern.

So the right split is:

- `openai_streaming_support.dart` for truly shared OpenAI-family parsing primitives
- `openai_responses_support.dart` for Responses-only projection and metadata helpers
- `openai_responses_codec.dart` for the actual Responses wire protocol flow

## Why This Is Better

- keeps the main codec readable as a protocol coordinator
- makes Responses-specific custom output handling easier to audit in isolation
- narrows future refactors because source/metadata/output projection logic is no longer interleaved with stream control flow
- moves the package closer to a stable "request encoding / stream parsing / capability facade" structure without over-abstracting

## Non-Goals

This slice does not:

- change shared event semantics
- change the public provider API
- merge Responses helpers with chat-completions helpers
- widen shared core abstractions

## Follow-Up

The next worthwhile OpenAI-family cleanup is to inspect whether `openai_chat_completions_codec.dart` still has enough endpoint-local replay/output helper mass to justify a smaller chat-completions-local support file, while keeping the stream lifecycle primitives in the already-shared support layer.
