# 10 ElevenLabs Audio Compatibility Support Extraction

## Why This Slice Exists

`lib/src/compatibility/providers/elevenlabs/elevenlabs_audio_compat.dart`
was still carrying several different responsibilities at once:

- compatibility audio capability methods
- internal ElevenLabs-specific response models
- text-to-speech request shaping
- speech-to-text multipart field shaping
- voice-list mapping
- speech-to-text response normalization
- a duplicated bytes-versus-file fallback path

That made the root compatibility audio module heavier than it needed to be,
even though the provider shell above it was already thinner.

## What Changed

This slice extracts provider-local request and response shaping into:

- `lib/src/compatibility/providers/elevenlabs/elevenlabs_audio_support.dart`

The public compatibility capability entry stays the same:

- `lib/src/compatibility/providers/elevenlabs/elevenlabs_audio_compat.dart`

The split is intentionally narrow:

- `ElevenLabsAudio` now acts more clearly as a capability shell plus client
  dispatch layer
- `ElevenLabsAudioSupport` now owns request-body/query shaping, multipart field
  construction, voice mapping, supported-language listing, and speech-to-text
  response normalization

## Why This Is Better

### 1. It removes codec work from the capability shell

The compatibility class now reads more honestly:

- validate the request source
- choose the bytes or file fallback path
- call the client
- delegate provider-local shaping and parsing to support code

That is a better ownership split than one file mixing all the details inline.

### 2. It removes duplicated STT normalization logic

Before this slice, the bytes and file speech-to-text paths both repeated:

- field shaping
- response parsing
- word-list normalization into final text

That duplication is now localized in one provider-owned support module.

### 3. It keeps compatibility behavior stable

This slice is intentionally structural.

It does **not** change the frozen compatibility behavior, including:

- fixed legacy text-to-speech output format shaping
- byte-input speech-to-text query-param handling
- file-input speech-to-text fallback behavior
- current word-join normalization when ElevenLabs returns word timing entries

## Validation

This slice adds targeted compatibility coverage for:

- text-to-speech request shaping and response mapping
- byte-input speech-to-text multipart shaping and normalized word replay
- file-input speech-to-text fallback preserving the current no-query path

The existing provider bridge tests also stay green, so the modern bridge and
legacy fallback boundary remains intact.

## What Did Not Change

This slice does not:

- widen the shared audio model
- move file-path transcription into the modern package
- add streaming TTS implementation
- add realtime audio support
- change the provider bridge gating in `shell_support.dart`

Those are separate questions.

## Why This Matches The Current Architecture

The repository is not trying to copy `repo-ref/ai` file-for-file.

The useful pattern is ownership clarity:

- provider shell
- request shaping
- response shaping
- modern provider-owned bridge

This slice pushes ElevenLabs closer to that structure without pretending the
remaining residual provider APIs should all move into the modern package now.

## Follow-Up

After this slice, the next worth-it follow-up is **not** another symmetry-only
split.

The next honest question is whether any remaining residual ElevenLabs audio
behavior deserves:

- a narrower provider-local support split,
- or a documented decision to stay as compatibility-only fallback.

## Bottom Line

This was a real mixed-responsibility cleanup:

- the capability shell is thinner
- request and response shaping are localized
- duplicated STT fallback logic is reduced
- public compatibility behavior stays stable
