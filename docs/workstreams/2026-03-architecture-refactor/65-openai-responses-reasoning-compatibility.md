# OpenAI Responses Reasoning Compatibility

## Purpose

This note freezes how OpenAI Responses reasoning-model compatibility should be
handled after comparing the migrated `llm_dart_openai` package with
`repo-ref/ai`.

The concrete question is:

- which reasoning-model request rules should stay provider-owned on the
  Responses path
- and how much of that logic belongs beside the chat-completions mainline

## Reference Direction

`repo-ref/ai` already treats Responses reasoning-model compatibility as an
OpenAI-owned request-shaping concern.

Its Responses path keeps these rules inside provider-owned options and model
capability helpers:

- `systemMessageMode`
- `reasoningEffort`
- `forceReasoning`
- default system-prompt shaping to `developer` for reasoning models
- warning-based removal of `temperature` and `topP` when reasoning models do
  not allow non-reasoning parameters
- OpenAI-only `serviceTier` validation for `flex` and `priority`

That is provider-specific wire policy, not shared text-generation semantics.

## Current `llm_dart_openai` Status

The migrated Responses path now aligns with that direction:

- system prompts now support provider-owned `system`, `developer`, and `remove`
  shaping on the Responses mainline
- known OpenAI reasoning-model families now default system prompts to
  `developer`
- `forceReasoning` now applies the same system-prompt and request-compatibility
  policy to unrecognized OpenAI model IDs
- `reasoningEffort` now encodes through the Responses `reasoning.effort`
  object only for reasoning-model requests
- OpenAI reasoning models now warning-drop `temperature` and `topP` unless
  `reasoningEffort == none` and the model family explicitly supports
  non-reasoning parameters
- non-reasoning models now warn instead of silently accepting
  `reasoningEffort`
- unsupported OpenAI `serviceTier` values are now warning-dropped instead of
  being passed through blindly

Example:

```dart
const CallOptions(
  providerOptions: OpenAIGenerateTextOptions(
    forceReasoning: true,
    reasoningEffort: OpenAIReasoningEffort.low,
  ),
)
```

## Frozen Boundary

### 1. Keep This Provider-Owned

These Responses rules should stay inside `llm_dart_openai`.

They should not become:

- shared `GenerateTextOptions` fields
- shared prompt semantics
- shared cross-provider reasoning capability flags

Reasons:

- the Responses wire contract is OpenAI-specific
- these are request-compatibility details, not cross-provider user intent
- even OpenAI-compatible providers do not guarantee identical reasoning
  behavior

### 2. Keep Capability Logic Shared Inside The Provider Package

The same audited OpenAI model-capability helper should serve both:

- chat-completions
- Responses

That avoids one path drifting away from the other while still keeping the logic
provider-owned instead of pushing it into `llm_dart_core`.

### 3. Keep Shared Options Generic

The shared `GenerateTextOptions` surface should continue to express generic
generation intent such as:

- `temperature`
- `topP`
- `maxOutputTokens`

Provider codecs remain responsible for validating, translating, or removing
those settings when the wire contract requires it.

## Architectural Conclusion

This slice closes another real OpenAI mainline gap with `repo-ref/ai`:

- both OpenAI text paths now use explicit provider-owned reasoning-model
  request shaping
- shared `GenerateTextOptions` stays stable
- OpenAI model capability checks now live in one provider-owned helper instead
  of being scattered

The more meaningful remaining OpenAI questions are now:

- whether any remaining Responses-only persistence or continuation policy
  should later surface above `previousResponseId`
- whether any search-preview or other model-family quirks deserve separate
  audited request-shaping slices
- whether assistant replay should ever broaden beyond the current conservative
  chat-completions subset
