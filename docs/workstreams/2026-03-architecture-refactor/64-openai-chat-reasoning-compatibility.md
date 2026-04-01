# OpenAI Chat Reasoning Compatibility

## Purpose

This note freezes how OpenAI chat-completions reasoning-model compatibility
should be handled after comparing the migrated `llm_dart_openai` package with
`repo-ref/ai`.

The concrete question is:

- which reasoning-model request rules belong in the shared text-generation API
- and which rules should stay provider-owned in the OpenAI chat codec

## Reference Direction

`repo-ref/ai` already treats reasoning-model compatibility as an OpenAI-owned
chat request-shaping concern.

Its chat path keeps these rules in provider-owned options and capability
helpers:

- `reasoningEffort`
- `maxCompletionTokens`
- `forceReasoning`
- automatic `maxOutputTokens -> max_completion_tokens` mapping for reasoning
  models
- warning-based removal of `temperature`, `topP`, `logprobs`, and
  `topLogprobs` when reasoning models do not allow non-reasoning parameters
- OpenAI-only `serviceTier` validation for `flex` and `priority`
- conservative defaulting of system prompts to `developer` only for known
  reasoning-model families or explicit `forceReasoning`

That is not shared text-generation semantics. It is provider-owned wire
compatibility.

## Current `llm_dart_openai` Status

The migrated OpenAI chat-completions path now aligns with that direction:

- `OpenAIGenerateTextOptions` now exposes typed
  `OpenAIReasoningEffort`
- `OpenAIGenerateTextOptions` now exposes provider-owned
  `maxCompletionTokens`
- `OpenAIGenerateTextOptions` now exposes provider-owned
  `forceReasoning`
- reasoning-model requests now map shared `maxOutputTokens` to
  `max_completion_tokens`
- explicit `maxCompletionTokens` overrides the shared `maxOutputTokens`
  fallback on reasoning-model requests
- OpenAI GPT-5.1, GPT-5.2, GPT-5.3, and GPT-5.4 families now keep
  `temperature`, `topP`, and `logprobs` only when
  `reasoningEffort == none`
- `forceReasoning` now activates the same compatibility policy for unrecognized
  OpenAI model IDs and also defaults system prompts to `developer`
- unsupported OpenAI `serviceTier` values are now warning-dropped instead of
  being passed through blindly

Example:

```dart
const CallOptions(
  providerOptions: OpenAIGenerateTextOptions(
    forceReasoning: true,
    reasoningEffort: OpenAIReasoningEffort.none,
    maxCompletionTokens: 512,
  ),
)
```

## Frozen Boundary

### 1. Keep This Provider-Owned

These rules should stay in OpenAI typed provider options and codec helpers.

They should not become:

- shared `GenerateTextOptions` fields
- shared cross-provider capability flags
- shared prompt semantics

Reasons:

- the request contract is OpenAI-specific
- even OpenAI-compatible providers do not guarantee the same reasoning-model
  parameter rules
- these rules are about wire compatibility, not shared intent

### 2. Keep The Capability Heuristics Conservative

Automatic reasoning compatibility should stay limited to the OpenAI profile and
the audited model families.

That means:

- known OpenAI reasoning families stay allowlisted
- `gpt-5` chat variants stay out of the reasoning-model allowlist
- other OpenAI-family profiles should not inherit these heuristics silently

If DeepSeek, OpenRouter, Groq, xAI, or another profile later needs similar
logic, it should get its own audited policy.

### 3. Keep Shared Options Generic

The shared `GenerateTextOptions` surface should continue to describe generic
generation intent:

- `maxOutputTokens`
- `temperature`
- `topP`
- `topK`
- `stopSequences`

Provider codecs can still reinterpret or reject those settings when the wire
contract requires it.

That keeps the shared API stable while still letting OpenAI own its
reasoning-model compatibility rules.

## Architectural Conclusion

This slice closes another real OpenAI chat-completions gap with `repo-ref/ai`:

- reasoning-model compatibility is now explicitly owned by the OpenAI
  chat-completions codec
- shared `GenerateTextOptions` stays clean
- model-specific capability checks are now visible instead of being implicit or
  missing

The more meaningful remaining questions are now:

- whether any search-preview model quirks deserve a separate audited
  chat-completions slice
- whether assistant replay should ever broaden beyond the current narrow
  warning-based subset
