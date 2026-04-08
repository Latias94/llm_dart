# 109. Community Provider Event And Non-Text Result Gap

## Question

After the latest Ollama and ElevenLabs shell thinning, what still remains
structurally misaligned with `repo-ref/ai`?

More specifically:

- do community-provider migration blockers still come from missing shared
  stream events?
- or is the more honest remaining gap now in non-text result richness and
  response metadata?

## What Was Compared

This review compares the current Dart implementation with the relevant
reference layers:

- `packages/llm_dart_community/lib/src/ollama_language_model.dart`
- `packages/llm_dart_community/lib/src/elevenlabs_speech_model.dart`
- `packages/llm_dart_community/lib/src/elevenlabs_transcription_model.dart`
- `repo-ref/ai/packages/ai/src/generate-text/stream-text-result.ts`
- `repo-ref/ai/packages/ai/src/ui-message-stream/ui-message-chunks.ts`
- `repo-ref/ai/packages/provider/src/speech-model/v4/speech-model-v4.ts`
- `repo-ref/ai/packages/provider/src/transcription-model/v4/transcription-model-v4.ts`
- `repo-ref/ai/packages/elevenlabs/src/elevenlabs-speech-model.ts`
- `repo-ref/ai/packages/elevenlabs/src/elevenlabs-transcription-model.ts`

## Conclusion

The remaining structural gap is no longer a shared event-gap problem.

For the current Ollama and ElevenLabs migration slice:

- no additional shared `TextStreamEvent` classes are required
- Ollama already fits the existing shared text-event surface well enough
- ElevenLabs speech/transcription do not have a meaningful text-stream event
  parity problem because they are unary non-text model calls
- the more important gap versus `repo-ref/ai` is that shared non-text result
  surfaces in `llm_dart_core` are still thinner than the reference result
  layer

That means the next worthwhile refactor target is not event proliferation.
It is non-text result richness.

## Ollama Event Audit

The package-owned modern Ollama language model already emits the shared events
that matter for its wire protocol:

- `StartEvent`
- `ResponseMetadataEvent`
- `ReasoningStartEvent` / `ReasoningDeltaEvent` / `ReasoningEndEvent`
- `TextStartEvent` / `TextDeltaEvent` / `TextEndEvent`
- `ToolCallEvent`
- `FinishEvent`
- `ErrorEvent`

What it does not emit is also telling:

- no `ToolInput*` events
- no `ToolResultEvent`
- no `SourceEvent`
- no `FileEvent`
- no `ReasoningFileEvent`
- no `RawChunkEvent`

For Ollama, those are not currently migration blockers:

- the wire protocol does not expose streamed tool-input deltas
- shared tool results still come from runner/session continuation, not from the
  provider stream itself
- Ollama does not expose shared source or generated-file semantics here
- raw-chunk forwarding would only be a debugging nicety, not a structural
  migration dependency

So the honest conclusion is:

- Ollama does not need more shared event types to keep migrating

## ElevenLabs Event Audit

The package-owned modern ElevenLabs provider surfaces are currently:

- `SpeechModel`
- `TranscriptionModel`

These are request/response model APIs, not text-stream providers.

That means the question is not whether ElevenLabs is missing more
`TextStreamEvent` variants.

The relevant question is whether the shared non-text result layer carries
enough stable information for:

- Flutter voice UX
- diagnostics
- persistence or analytics
- future provider parity beyond ElevenLabs

## The Real Gap: Thin Shared Non-Text Results

Compared with the reference repository, the current shared Dart non-text
results are intentionally thin:

- `SpeechGenerationResult` exposes `audioBytes`, `mediaType`, and
  `providerMetadata`
- `TranscriptionResult` exposes `text` and `providerMetadata`

The current ElevenLabs package already has more information than those shared
types expose directly:

- speech response headers such as request/history/cost identifiers
- transcription language
- transcription language probability
- transcription word timing payloads
- transcription additional format payloads

Right now, that richer information is tunneled through provider metadata.

That works, but it is weaker than the reference result surface in three ways:

1. common app-facing fields stay hidden inside provider namespaces
2. debugging and telemetry need provider-specific metadata parsing even for
   fairly generic concerns
3. future community-provider parity risks looking like “more providerMetadata”
   instead of a clean shared capability contract

## What `repo-ref/ai` Gets Right Here

The reference repository does **not** solve this by widening text-stream
events.

Instead, its non-text model interfaces carry richer result data directly:

- speech returns warnings plus request/response metadata
- transcription returns warnings, request/response metadata, segments,
  language, and duration

Provider-specific extras still remain provider-owned.

This is the important lesson to borrow:

- keep provider-specific extras provider-owned
- but do not force obviously cross-provider non-text result data to hide inside
  provider metadata forever

## Recommended Boundary

The next shared boundary should be:

- keep `TextStreamEvent` stable for community-provider migration
- keep realtime, voice catalog, cloning, and admin APIs provider-owned
- add a richer shared non-text result layer only where multiple providers can
  honestly share it

The most plausible shared additions are:

- a lightweight shared response metadata value object for non-text model calls
- shared warnings on speech/transcription results
- shared transcription segments
- optional shared transcription language
- optional shared transcription duration

The following should still remain provider-owned:

- ElevenLabs `historyItemId`
- ElevenLabs `characterCost`
- ElevenLabs raw `words`
- ElevenLabs `additionalFormats`
- provider-specific speech/admin/realtime response payloads

## Migration Impact

This conclusion changes the refactor priority order:

1. do **not** spend the next breaking slice on more shared text-stream events
2. do **not** try to invent an audio-specific UI chunk layer just because the
   reference repository has richer result wrappers
3. move the next shared design effort toward non-text result metadata and typed
   transcript structure

That direction is more useful for Flutter app integration too:

- chat-plus-voice UIs benefit from typed segments and language directly
- diagnostics benefit from stable response metadata
- provider-specific extras can still stay namespaced and optional

## Recommended Next Step

The next workstream note should define a shared speech/transcription result
layer that stays narrower than the full reference implementation but no longer
forces common non-text metadata to hide behind provider-specific maps.
