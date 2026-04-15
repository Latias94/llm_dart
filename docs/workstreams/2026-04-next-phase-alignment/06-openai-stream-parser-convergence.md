# OpenAI Stream Parser Convergence

## Goal

Keep the OpenAI-family provider implementation aligned with the mature
provider-adapter shape from `repo-ref/ai` without copying its package
granularity.

The practical target is a clear three-layer split inside `llm_dart_openai`:

- request encoding
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

## Boundary Decision

This is deliberately not a public event-model expansion.

Tool-call delta aggregation is provider-parser infrastructure, not a shared
core abstraction. The shared `TextStreamEvent` surface remains the cross-provider
contract, while OpenAI-specific chunk shapes stay inside `llm_dart_openai`.

That keeps provider-specific richness available without forcing other providers
to adopt OpenAI lifecycle vocabulary.

## Remaining Seams

The next useful OpenAI-family seams are:

- split request encoders from stream decoders once file size or test friction
  justifies it
- keep Chat Completions and Responses metadata adapters private until repeated
  downstream needs appear
- avoid widening common OpenAI-family options for provider-specific behavior
  from OpenRouter, xAI, Groq, or Phind

## Validation

The convergence pass is covered by:

- `dart analyze .` in `packages/llm_dart_openai`
- `dart test test/openai_chat_completions_stream_codec_test.dart test/openai_responses_stream_codec_test.dart`
- `dart test` in `packages/llm_dart_openai`

