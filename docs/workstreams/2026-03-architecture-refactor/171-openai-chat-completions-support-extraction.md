# 171 OpenAI Chat Completions Support Extraction

## Why This Slice Exists

After the shared streaming-support extraction and the Responses-specific support split, `openai_chat_completions_codec.dart` still mixed protocol flow with several endpoint-local projection helpers:

- assistant message text/reasoning decoding
- top-level and streamed citation projection
- tool-call output decoding for non-streaming responses
- response metadata shaping under provider namespaces

That logic is specific to chat-completions, but it does not need to live inside the main wire-protocol coordinator.

## What Changed

This slice adds:

- `packages/llm_dart_openai/lib/src/openai_chat_completions_support.dart`

The new support class now owns the chat-completions-specific helper surface for:

- assistant text/reasoning extraction
- top-level citation projection
- streamed citation projection with deduplication
- non-streaming tool-call output decoding
- provider-scoped response metadata shaping

`openai_chat_completions_codec.dart` keeps ownership of:

- request encoding
- chunk sequencing
- tool-call delta accumulation/finalization
- usage and finish-reason decoding
- transport-facing protocol control flow

## Boundary Decision

This is another endpoint-local extraction, not a generic OpenAI-family decoder.

Chat-completions and Responses still have different wire models, so the right structure is:

- `openai_streaming_support.dart` for truly shared stream primitives
- `openai_chat_completions_support.dart` for chat-completions-only projection helpers
- `openai_responses_support.dart` for Responses-only projection helpers
- codec files as protocol coordinators

## Why This Is Better

- reduces chat-completions codec size without hiding protocol-specific behavior
- keeps provider-namespace-aware projection logic together in one focused module
- makes future compatibility-provider maintenance safer because citation and assistant-text parsing now have one owner
- strengthens the package layout around a clearer "request encoding / stream parsing / capability facade" direction

## Non-Goals

This slice does not:

- change shared stream events
- widen shared core abstractions
- unify chat-completions and Responses into one generic codec
- change replay or compatibility policies

## Follow-Up

The next worthwhile OpenAI-family pass is a lighter ownership audit of what remains inside each codec after the support splits, to decide whether any further extraction would still improve architecture or would start becoming mechanical file-splitting.
