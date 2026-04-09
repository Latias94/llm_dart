# 138. OpenAI Responses `content_part.done` Stream Alignment

## Question

After the main OpenAI Responses stream codec had already aligned on reasoning,
tool input, MCP flows, sources, and finish metadata, was there still a real
event-level gap versus `repo-ref/ai` worth closing?

## What Was Reviewed

- `packages/llm_dart_openai/lib/src/openai_responses_codec.dart`
- `packages/llm_dart_openai/test/openai_responses_stream_codec_test.dart`
- `packages/llm_dart_openai/test/openai_language_model_test.dart`
- `repo-ref/ai/packages/openai/src/responses/openai-responses-language-model.ts`
- `repo-ref/ai/packages/openai/src/responses/openai-responses-language-model.test.ts`

## Decision

Yes. The modern OpenAI Responses codec should explicitly handle
`response.content_part.done`.

This is not a new shared event-family decision. It is provider codec coverage
work inside the already-frozen event model.

## Why This Chunk Matters

`repo-ref/ai` uses `response.content_part.done` for two important stream-time
behaviors:

- preserving final text-part metadata such as annotations and logprobs
- replaying source annotations even when the stream does not rely only on
  `response.output_text.annotation.added`

Without this handling, a Dart stream could miss:

- `TextEndEvent` annotation metadata
- source projection when annotations are only visible on the completed content
  part
- deduped annotation behavior across `annotation.added` and final content-part
  payloads

## Implemented Alignment

The codec now:

- handles `response.content_part.done` for `output_text` parts
- appends part-level logprobs into the rolling stream logprobs collection
- emits missing `SourceEvent`s from the part annotations
- dedupes annotation-derived sources across both
  `response.output_text.annotation.added` and `response.content_part.done`
- emits `TextEndEvent` with OpenAI provider metadata that includes the final
  annotations payload

## What This Does Not Change

This does not widen `TextStreamEvent`.

It stays aligned with the earlier event-boundary decisions:

- shared event families were already sufficient
- the remaining work is provider coverage discipline
- OpenAI-specific wire quirks should be solved in the OpenAI codec, not by
  adding new common events

## Practical Result

The modern `llm_dart_openai` stream path is now closer to `repo-ref/ai` for
annotation-heavy Responses streams, especially when OpenAI emits completed
content parts with citations or file references before final response closure.
