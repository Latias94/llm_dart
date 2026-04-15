# OpenAI Stream Parser Convergence

## Goal

Keep the OpenAI-family provider implementation aligned with the mature
provider-adapter shape from `repo-ref/ai` without copying its package
granularity.

The practical target is a clear four-layer split inside `llm_dart_openai`:

- request encoding
- response/result decoding
- stream-event parsing
- language-model facade and profile routing

## Current Cut

The OpenAI stream parser already has a shared support layer:

- `OpenAIStreamState`
- `OpenAIStreamPartState`
- `OpenAIIndexedToolCallAccumulator`
- text and reasoning start/delta/end helpers
- logprobs aggregation helpers
- JSON tool-input resolution helpers

This pass extends that shared support layer by moving indexed tool-call delta
state into `openai_streaming_support.dart`.

Both OpenAI Chat Completions and OpenAI Responses now use the same helper for:

- resolving or creating stream tool-call state
- applying partial tool argument deltas
- marking the stream as containing tool calls
- preserving the per-index accumulator as the owner of incremental tool input

The OpenAI-family codec files now act as thin facades around physically
separated request, response, and stream parser layers:

- `openai_chat_completions_codec.dart`
  - routes request encoding to `openai_chat_completions_request_encoder.dart`
  - routes result decoding to `openai_chat_completions_response_decoder.dart`
  - routes stream decoding to `openai_chat_completions_stream_decoder.dart`
- `openai_responses_codec.dart`
  - routes request encoding to `openai_responses_request_encoder.dart`
  - routes result decoding to `openai_responses_response_decoder.dart`
  - routes stream decoding to `openai_responses_stream_decoder.dart`

The request-encoding layer owns outbound provider payload shaping:

- `openai_chat_completions_request_encoder.dart`
  - owns Chat Completions request shaping, prompt replay encoding, model
    compatibility shaping, and tool/body encoding helpers
- `openai_responses_request_encoder.dart`
  - owns Responses request shaping, replay-item encoding, reasoning/service
    tier compatibility shaping, and tool/body encoding helpers

The response-decoding layer owns non-streaming provider payload normalization:

- `openai_chat_completions_response_decoder.dart`
  - owns Chat Completions result content, logprobs, usage, finish reason, and
    error decoding
- `openai_responses_response_decoder.dart`
  - owns Responses result output item traversal, logprobs collection, usage,
    finish reason, and error decoding

The stream-decoding layer owns incremental event parsing and remains free to
reuse response-decoder helpers for terminal usage and finish reason mapping.

## Boundary Decision

This is deliberately not a public event-model expansion.

Tool-call delta aggregation is provider-parser infrastructure, not a shared
core abstraction. The shared `TextStreamEvent` surface remains the cross-provider
contract, while OpenAI-specific chunk shapes stay inside `llm_dart_openai`.

That keeps provider-specific richness available without forcing other providers
to adopt OpenAI lifecycle vocabulary.

## Remaining Seams

The next useful OpenAI-family seams are:

- factor any repeated metadata-shaping helpers only when a second provider
  family needs the same behavior
- keep Chat Completions and Responses metadata adapters private until repeated
  downstream needs appear
- avoid widening common OpenAI-family options for provider-specific behavior
  from OpenRouter, xAI, Groq, or Phind

## Validation

The convergence pass is covered by:

- `dart analyze packages/llm_dart_openai`
- `dart test packages/llm_dart_openai`
- `dart run tool/check_workspace_dependency_guards.dart`
- `dart run tool/check_root_package_boundary_guards.dart`
