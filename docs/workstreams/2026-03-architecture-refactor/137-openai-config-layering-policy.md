# 137. OpenAI Config Layering Policy

## Question

Now that the root OpenAI compatibility surface still stays public, how should
the internal implementation stop treating `OpenAIConfig` as one undifferentiated
flat bag of fields without breaking the public constructor yet?

## What Was Reviewed

- `lib/providers/openai/config.dart`
- `lib/src/compatibility/providers/openai/provider_compat.dart`
- `lib/src/compatibility/providers/openai/client.dart`
- `lib/src/compatibility/providers/openai/chat.dart`
- `lib/src/compatibility/providers/openai/responses.dart`
- `lib/src/compatibility/providers/openai/embeddings.dart`
- `lib/src/compatibility/providers/openai/audio.dart`
- `docs/workstreams/2026-03-architecture-refactor/130-openai-residual-api-classification.md`
- `docs/workstreams/2026-03-architecture-refactor/136-openai-public-compatibility-api-policy.md`

## Decision

### Keep the public `OpenAIConfig` constructor flat

Do not introduce a public nested config shape yet.

The root `OpenAIProvider` is still a compatibility host, so changing the public
constructor now would create migration churn before the residual root surface is
small enough to justify that break.

### Add internal grouped compatibility views for reads

Compatibility implementations should no longer read the flat config directly
everywhere. They should read through internal grouped views in:

- `lib/src/compatibility/providers/openai/config_views.dart`

The grouped views are:

- `requestCompat`
- `responsesCompat`
- `embeddingCompat`
- `audioCompat`

These views are internal implementation helpers, not a new public API layer.

## Field Ownership Matrix

### `requestCompat`

Owns the common request-shaping fields shared by chat-completions and Responses:

- `model`
- `maxTokens`
- `temperature`
- `topP`
- `topK`
- `systemPrompt`
- `tools`
- `toolChoice`
- `reasoningEffort`
- `jsonSchema`
- `stopSequences`
- `user`
- `serviceTier`

### `responsesCompat`

Owns OpenAI Responses residual state:

- `useResponsesAPI`
- `previousResponseId`
- `builtInTools`

### `embeddingCompat`

Owns embedding-only residual shaping:

- `embeddingEncodingFormat`
- `embeddingDimensions`

### `audioCompat`

Owns audio-only residual shaping:

- `voice`

### `originalConfig`

Still remains legacy adaptation glue for:

- compatibility access to old extension maps
- provider-family namespaced option reads
- transport and Dio override bridging

It does not become part of the grouped stable config model.

## Why This Policy Is Better Than A Public Nested Rewrite Right Now

It gives us a real internal boundary immediately without paying the migration
cost of a second public API break inside the same refactor window.

That matters because the current problem is not only that `OpenAIConfig` is
flat. The bigger problem is that capability modules treat every field as if it
belongs to every capability.

Grouped internal reads solve that ownership problem first.

## Consistency Fix Included In This Round

`config.voice` now participates in the text-to-speech default resolution path.

The effective OpenAI TTS voice is now resolved as:

- `request.voice`
- then `config.voice`
- then `OpenAIAudioCatalog.defaultVoice`

And the returned `TTSResponse.voice` now reports that resolved value instead of
dropping the config-level default.

## Practical Result

This keeps the current migration sequence disciplined:

- public compatibility config stays stable for now
- internal capability ownership becomes more explicit
- chat, Responses, embeddings, audio, and client message conversion stop
  scattering flat-field reads
- future extraction of capability-specific config slices becomes easier because
  the read boundary already exists
