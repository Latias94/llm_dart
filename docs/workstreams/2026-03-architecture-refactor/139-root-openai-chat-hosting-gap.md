# 139. Root OpenAI Chat Hosting Gap

## Question

After the OpenAI compatibility shell relocation and the modern
`llm_dart_openai` chat migration, is the root `OpenAIProvider` still carrying
more chat ownership than it should?

## What Was Reviewed

- `lib/src/compatibility/providers/openai/provider_compat.dart`
- `lib/src/compatibility/providers/openai/chat.dart`
- `lib/src/compatibility/providers/openai/responses.dart`
- `lib/src/compatibility/providers/openai_family_compat_provider.dart`
- `lib/src/compatibility/legacy_chat_adapter.dart`
- `lib/src/compatibility/legacy_chat_adapter_streaming.dart`
- `docs/workstreams/2026-03-architecture-refactor/58-openai-chat-migration-status.md`
- `docs/workstreams/2026-03-architecture-refactor/130-openai-residual-api-classification.md`
- `docs/workstreams/2026-03-architecture-refactor/136-openai-public-compatibility-api-policy.md`

## Finding

Yes.

There is now a clear split inside the repository:

- compatibility bridge construction for legacy `LLMConfig` already prefers the
  modern `llm_dart_openai` text path through `LegacyChatCapabilityAdapter`
- but the public root `OpenAIProvider` still self-hosts its own legacy
  chat-completions and Responses stream parsing modules

That means OpenAI currently has two different compatibility-era chat
implementations in play:

1. the bridge path used by `buildCompatOpenAIProvider(...)`
2. the direct root-provider path used by `OpenAIProvider(...)` and
   `createOpenAIProvider(...)`

## Why This Matters

This is not only a duplication problem.

It is an ownership problem.

The repository already decided that the modern package owns the main OpenAI
text-generation evolution:

- chat-completions request shaping
- Responses request shaping
- reasoning compatibility
- persistence policy
- native-tool declarations
- modern stream codec coverage

But the root provider still keeps a second, separate stream/request stack for
the same chat families.

That makes future OpenAI fixes more expensive because stream and request
behavior can drift between:

- the modern package path
- the compatibility bridge path
- the public root provider path

## Important Nuance

This does **not** mean the whole root `OpenAIProvider` should disappear now.

The root provider still owns residual compatibility-only APIs that the modern
package does not replace directly:

- Responses lifecycle CRUD helpers
- file management
- moderation
- assistants
- legacy completion
- compatibility image/audio/file convenience surfaces

So the problem is narrower:

- the root provider still being public is acceptable
- the root provider still self-hosting so much chat logic is the real remaining
  structure gap

## Recommended Direction

### Keep the public root provider surface

Do not remove:

- `OpenAIProvider`
- `OpenAIConfig`
- `createOpenAIProvider(...)`

That public compatibility policy is already frozen.

### Re-evaluate chat ownership inside the root provider

The next structural question should be:

> Can the root provider keep owning residual non-chat APIs while delegating the
> bridge-safe chat path to the modern package internally?

That is the higher-value next move than continuing to deepen the old
self-hosted chat codec stack.

### Do not blindly switch everything at once

A direct swap would be risky if it accidentally changes behavior for:

- direct `OpenAIProvider(...).responses` lifecycle helpers
- residual root-only request options
- compatibility-only replay edges that the legacy path still tolerates

So the next slice should be framed as ownership narrowing, not as an automatic
full rewrite.

## Recommended Next Slice

Freeze one explicit policy first:

- either the root `OpenAIProvider` chat path becomes an internal adapter over
  modern `llm_dart_openai` whenever the request stays inside the already-audited
  bridge-safe subset
- or the root provider explicitly remains a self-hosted compatibility holdout
  until the residual OpenAI non-chat APIs shrink further

My recommendation is the first option.

It matches the architecture better because the bridge path already proved that:

- modern OpenAI models can be projected back into the old `ChatCapability`
  surface
- the old event projection layer already exists
- the remaining real value in the root provider is mostly outside the text path

## Practical Result

This keeps the next OpenAI refactor focused:

- do not widen shared abstractions
- do not re-open the public compatibility API decision
- instead, narrow root chat ownership so OpenAI text behavior converges on one
  modern implementation source with compatibility projection above it
