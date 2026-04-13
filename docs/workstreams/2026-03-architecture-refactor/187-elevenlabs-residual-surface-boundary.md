# 187 ElevenLabs Residual Surface Boundary

## Why This Decision Exists

After the package-owned `llm_dart_community` ElevenLabs surfaces landed, the
remaining unresolved questions were no longer about whether ElevenLabs had any
modern path at all.

The remaining questions were narrower:

- should file-based transcription become another modern helper outside the
  shared `TranscriptionModel`
- should voice catalogs, realtime audio, model/account helpers, and other
  provider-shaped APIs move into the modern package now
- or should those remain explicit residual provider-owned or compatibility-only
  surfaces

This matters because the repository wants a truthful modern API, not another
"move every endpoint into the new package" cleanup round.

## What Was Reviewed

Current package-owned modern ElevenLabs surfaces already cover:

- `ElevenLabs(...).speechModel(...)`
- `ElevenLabs(...).transcriptionModel(...)`
- provider-owned speech settings and invocation options
- provider-owned transcription options for language, diarization, timestamp
  granularity, and file-format hints

Current root compatibility surfaces still cover:

- file-path convenience transcription
- voice catalogs
- realtime audio
- model/account helpers
- broader residual provider-shaped admin/audio helpers

Relevant files:

- `packages/llm_dart_community/lib/src/elevenlabs_speech_model.dart`
- `packages/llm_dart_community/lib/src/elevenlabs_transcription_model.dart`
- `packages/llm_dart_community/lib/src/elevenlabs_options.dart`
- `lib/src/compatibility/providers/elevenlabs/shell_support.dart`
- `lib/src/compatibility/providers/elevenlabs/elevenlabs_audio_compat.dart`
- `lib/src/compatibility/providers/elevenlabs/elevenlabs_models_compat.dart`

## Frozen Decision

### 1. File-based transcription stays legacy-only for now

The current shared `TranscriptionModel` contract is byte-oriented:

- `TranscriptionRequest(audioBytes: ...)`

That is a good shared-core boundary because it is platform-neutral and honest
across Dart and Flutter targets.

So file-path convenience should **not** become the reason to widen or fork the
modern transcription contract.

Current decision:

- keep file-path convenience transcription in the root compatibility layer for
  now
- do not add a modern `transcribeFile(...)` helper yet

If a future provider-owned helper is added, it should be justified as a real
provider-owned convenience surface, not as a stealth rewrite of the shared
`TranscriptionModel`.

### 2. Voice/realtime/admin helpers stay outside the shared audio model layer

The remaining ElevenLabs APIs are provider-shaped rather than shared-audio
contract overlap.

That includes:

- voice catalogs
- realtime audio sessions
- model/account helpers
- cloning and similar provider-specific admin helpers

Current decision:

- keep those out of the shared `SpeechModel` / `TranscriptionModel` layer
- keep them residual provider-owned or compatibility-only for now
- only add a later provider-owned modern helper if concrete product demand
  proves one specific typed surface is worthwhile

### 3. Shared-capability ElevenLabs migration is effectively complete

Given those residual APIs are now explicitly outside the shared-capability
migration target, the modern ElevenLabs migration should be considered complete
for the current workstream scope:

- speech generation is modern
- byte-oriented transcription is modern
- residual provider-shaped APIs are intentionally not blockers for that
  migration

## Why This Is Better

### 1. It keeps the shared audio contracts honest

The modern package should represent the true shared overlap:

- generate speech from text
- transcribe audio bytes into text and segments

It should not absorb filesystem convenience or admin/catalog endpoints just to
look broader.

### 2. It fits Dart and Flutter better

Byte-oriented transcription is a better core contract across:

- mobile
- desktop
- server
- web

File-path convenience is platform-specific and belongs in app code or in an
explicit provider-owned convenience layer later if real demand proves it.

### 3. It keeps ElevenLabs extras provider-owned

Voice catalogs, realtime, and admin APIs are real provider-specific features.

They are not missing shared parity work.

Treating them as residual provider-owned surfaces is more honest than forcing
them into the modern shared-capability package before a stable typed design
exists.

## Non-Goals

This decision does **not**:

- remove current root ElevenLabs helper coverage
- forbid future provider-owned modern helpers forever
- widen shared `SpeechModel` or `TranscriptionModel`
- claim that every ElevenLabs API is now migrated into `llm_dart_community`

It only freezes which surfaces belong to the current shared-capability migration
target and which do not.

## Conclusion

ElevenLabs is now frozen as:

- shared-capability modern migration covers speech plus byte-oriented
  transcription
- file-path transcription stays legacy-only for now
- voice/realtime/admin/model/account helpers stay provider-owned residual
  surfaces until a concrete typed helper is justified

That keeps the community package truthful and lets the workstream stop treating
provider-shaped residual APIs as unfinished shared migration debt.
