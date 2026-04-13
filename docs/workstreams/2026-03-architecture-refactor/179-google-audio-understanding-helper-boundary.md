# 179 Google Audio-Understanding Helper Boundary

## Why This Decision Exists

`113-google-transcription-boundary.md` already froze one important rule:

- do not add a fake shared `TranscriptionModel` for Google

That still left one narrower open question:

- should `llm_dart_google` now add a provider-owned audio-understanding helper
  above multimodal prompting
- or should Google audio understanding continue to stay directly on the
  `LanguageModel` path for now

## What Was Reviewed

Existing boundary and status notes:

- `docs/workstreams/2026-03-architecture-refactor/113-google-transcription-boundary.md`
- `docs/workstreams/2026-03-architecture-refactor/57-google-compatibility-modality-status.md`
- `docs/workstreams/2026-03-architecture-refactor/124-google-residual-api-classification.md`

Current modern Google multimodal encoding path:

- `packages/llm_dart_google/lib/src/google_generate_content_codec.dart`

That codec already supports:

- inline binary prompt parts
- URI-backed file prompt parts
- prompt-shaped multimodal requests through `Google.chatModel(...)`

## Current Reality

The modern package already has the primitive needed for Google audio
understanding:

- multimodal prompt input through the language-model path

Apps can already do transcript-oriented or analysis-oriented Google audio calls
by combining:

- audio file input
- prompt text
- optional structured output

That means the current architecture already has a truthful execution path for:

- transcript generation
- summarization
- translation
- extraction
- prompt-shaped audio understanding

without adding a second higher-level helper yet.

## Frozen Decision

Google should **not** add a provider-owned audio-understanding helper for now.

The current rule becomes:

- keep Google audio understanding on multimodal prompting through
  `Google.chatModel(...)`
- keep the earlier decision that Google should not pretend to expose a dedicated
  shared `TranscriptionModel`
- defer any extra provider-owned helper until repeated app usage proves a
  stable, non-trivial abstraction above raw prompting

## Why This Is Better

### 1. The current path is already honest

Google's current public Gemini contract for this use case is still
prompt-oriented multimodal understanding.

The current `LanguageModel` path reflects that honestly.

### 2. There is no stable second abstraction yet

A real provider-owned helper would need to freeze questions such as:

- what fixed output shape it promises
- whether timestamps, diarization, translation, and summaries are one helper or
  several
- how much prompt shaping it hides
- whether it returns plain text, structured JSON, or richer typed objects

Those decisions are still product-specific, not yet general package rules.

### 3. The reference does not force a higher-level helper

The local `repo-ref/ai` snapshot does not push a Google-specific
audio-understanding helper either. That is another signal that the current
multimodal prompting path is an acceptable stopping point for now.

### 4. It avoids duplicating the language-model contract

If we add a helper too early, it would likely become thin sugar over:

- audio prompt parts
- one prompt template
- optional structured output

That is not enough architectural value yet to justify another maintained public
surface.

## Allowed Current Surface

The current intended Google audio-understanding path is:

- `Google.chatModel(...)`
- multimodal prompt input with audio bytes or file references
- prompt-shaped output, optionally with structured response formatting

That remains the modern provider-owned path.

## If We Revisit This Later

A future Google audio-understanding helper should only land if all of the
following become true:

- repeated real app usage shows the same transcript-oriented orchestration
  pattern
- the helper can promise something more stable than one prompt template
- the helper still stays provider-owned and does not widen shared core
- the helper adds value beyond what apps can already express with multimodal
  prompting plus `responseFormat`

## Non-Goals

This decision does not:

- change the current multimodal prompting support
- remove the possibility of a future Google-specific helper forever
- add a dedicated transcript result model for Google
- widen the shared non-text helper layer

## Conclusion

Google audio understanding is now frozen as:

- multimodal prompting today
- no fake shared transcription model
- no extra provider-owned audio-understanding helper yet

That keeps the modern package honest and avoids inventing a second abstraction
before the product contract is real.
