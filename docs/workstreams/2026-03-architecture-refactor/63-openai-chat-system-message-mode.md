# OpenAI Chat System Message Mode

## Purpose

This note freezes how OpenAI chat-completions system messages should be encoded
after comparing the migrated `llm_dart_openai` package with `repo-ref/ai`.

The concrete question is:

- should system-message role selection be a shared prompt concern
- or should it remain a provider-owned request-shaping rule

## Reference Direction

`repo-ref/ai` already treats chat system-message role selection as an
OpenAI-owned concern.

Its chat path supports a provider-owned `systemMessageMode` with three modes:

- `system`
- `developer`
- `remove`

If no explicit override is provided, the reference chooses the mode based on the
OpenAI model family, and reasoning models default to `developer`.

That is request shaping, not shared prompt semantics.

## Current `llm_dart_openai` Status

The migrated chat-completions path now aligns with that rule:

- `OpenAIGenerateTextOptions` now exposes typed
  `OpenAISystemMessageMode.system`
- `OpenAIGenerateTextOptions` now exposes typed
  `OpenAISystemMessageMode.developer`
- `OpenAIGenerateTextOptions` now exposes typed
  `OpenAISystemMessageMode.remove`
- the OpenAI chat-completions path now defaults known OpenAI reasoning-model
  families to `developer`
- explicit overrides can still force `system` or `remove`
- `remove` emits a warning instead of silently discarding system instructions

Example:

```dart
const CallOptions(
  providerOptions: OpenAIGenerateTextOptions(
    systemMessageMode: OpenAISystemMessageMode.developer,
  ),
)
```

## Frozen Boundary

### 1. Keep This Provider-Owned

System-message role selection should stay in OpenAI typed provider options.

It should not become:

- a shared prompt-message field
- a shared `GenerateTextOptions` field
- a common cross-provider normalization rule

Reasons:

- different providers do not share this role contract
- even OpenAI-compatible providers do not guarantee identical handling
- this is request encoding policy, not shared message meaning

### 2. Keep The Shared Prompt Model Stable

`SystemPromptMessage` should continue to mean:

- a system-level instruction in the shared in-memory model

It should not imply:

- a guaranteed wire role of `system`
- a guaranteed wire role of `developer`
- a guaranteed replay behavior across providers

Those decisions belong in provider codecs.

### 3. Keep Default Heuristics Conservative

Automatic `developer` defaulting should stay limited to the migrated OpenAI
chat-completions path and the known OpenAI reasoning-model families.

This should not silently broaden into a generic OpenAI-family rule for:

- DeepSeek
- Groq
- OpenRouter
- xAI
- Phind

If those providers later need similar shaping, they should get their own audited
profile or provider-owned policy rather than piggybacking on an OpenAI-only
default.

## Architectural Conclusion

This alignment closes one more real structure gap with `repo-ref/ai`:

- system-message role shaping is now explicitly owned by the OpenAI
  chat-completions request layer
- the shared prompt model stays clean
- reasoning-model request shaping is no longer hard-coded to `system`

This also makes the remaining OpenAI chat-completions gaps clearer.

The more meaningful remaining questions are still:

- whether any reasoning-model parameter compatibility rules should later be
  audited and added
- whether assistant replay should ever broaden beyond the current narrow
  warning-based subset
- whether any richer OpenAI-owned continuation policy belongs on the public
  surface beyond the already-frozen Responses persistence boundary
