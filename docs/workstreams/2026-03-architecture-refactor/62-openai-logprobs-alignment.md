# OpenAI Logprobs Alignment

## Purpose

This note freezes how OpenAI `logprobs` should fit into the refactored
`llm_dart` architecture after comparing the current migrated package with
`repo-ref/ai`.

The goal is not to widen the shared core. The goal is to decide whether
`logprobs` belongs to:

- a shared text-generation abstraction
- provider-owned typed invocation options
- provider metadata on decoded results and stream events

## Reference Comparison

`repo-ref/ai` treats OpenAI `logprobs` as a provider-owned wire feature rather
than a shared cross-provider text option.

On the OpenAI chat-completions path:

- request-side `logprobs` can be `true` or a number
- the provider request encodes `logprobs: true`
- the provider request encodes `top_logprobs`
- decoded text output exposes logprob detail through provider metadata

On the OpenAI Responses path:

- request-side `logprobs` is expressed through `top_logprobs`
- requesting logprobs also forces `include: ['message.output_text.logprobs']`
- decoded message text and streamed text deltas surface logprob detail through
  provider metadata

That reference shape is important because it proves two things:

1. `logprobs` is a stable OpenAI-family provider feature worth preserving.
2. It still does not justify widening the shared `GenerateTextOptions` surface.

## Current `llm_dart_openai` Status

The migrated `llm_dart_openai` package now aligns with that provider-owned
boundary:

- `OpenAIGenerateTextOptions` now exposes a typed `OpenAILogProbs` option
- the Responses codec now encodes `top_logprobs`
- the Responses codec now automatically adds
  `message.output_text.logprobs` to `include`
- the chat-completions codec now encodes `logprobs` and `top_logprobs`
- both codecs now decode text logprob payloads into provider metadata for:
  - final `GenerateTextResult.providerMetadata`
  - non-stream text content parts
  - streamed text events
  - streamed `FinishEvent.providerMetadata`

The current typed shape is:

```dart
const CallOptions(
  providerOptions: OpenAIGenerateTextOptions(
    logprobs: OpenAILogProbs.top(3),
  ),
)
```

or:

```dart
const CallOptions(
  providerOptions: OpenAIGenerateTextOptions(
    logprobs: OpenAILogProbs.enabled(),
  ),
)
```

This keeps the API honest:

- the shared core is not forced to pretend that every provider has an equivalent
  logprob contract
- OpenAI callers still get a typed option rather than a raw `Object?` escape
  hatch

## Frozen Boundary

The refactor should now treat OpenAI `logprobs` with the following rules.

### 1. Keep Request Control Provider-Owned

`logprobs` should stay on `OpenAIGenerateTextOptions`, not on shared
`GenerateTextOptions`.

Reasons:

- provider wire contracts differ
- even within the OpenAI family, Responses and chat-completions encode it
  differently
- the shared core does not yet have a truthful cross-provider logprob model

### 2. Keep Decoded Detail In Provider Metadata

Decoded logprob payloads should stay in provider metadata on the final result,
text parts, text events, and streamed finish metadata.

Reasons:

- they are provider-owned detail attached to generated text
- they are useful to advanced callers and debugging tooling
- they do not need a shared first-class field to remain accessible

### 3. Do Not Pull Logprob Payload Shape Into Shared Core Yet

The shared core should not define:

- a shared token-logprob data model
- shared result-level logprob fields
- shared stream-event variants dedicated to logprobs

That would overfit the current OpenAI contract before at least one other
provider family proves the same abstraction is stable and valuable.

## Architectural Conclusion

`logprobs` is now no longer an OpenAI migration blocker.

It is now a closed provider-owned alignment item with the right placement:

- typed provider options for request-side control
- provider metadata for response and stream decode
- no shared-core widening

This is the same architectural category as:

- OpenAI `previous_response_id`
- OpenAI `service_tier`
- OpenAI prompt cache controls
- xAI live-search request controls

All of them are real provider features, but none of them should define the
shared text-generation contract.

## Remaining OpenAI Gaps After This Slice

After this alignment, the more meaningful remaining OpenAI-specific questions
are still:

- whether chat-completions assistant replay should broaden further beyond the
  current conservative boundary
- whether any richer Responses persistence controls should ever be exposed beyond
  `previousResponseId`
- whether any future OpenAI-owned result helpers are needed above raw provider
  metadata for Flutter or app-level tooling

Those are materially larger design questions than `logprobs`, and they should
be evaluated separately rather than reopening the shared option surface.
