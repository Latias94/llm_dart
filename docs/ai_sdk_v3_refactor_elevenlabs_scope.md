# ElevenLabs parity scope (AI SDK v3-inspired)

Last updated: 2026-02-11

This refactor primarily targets AI SDK v3 **stream parts** parity for chat-like
providers. ElevenLabs is different: it is an **audio provider** (TTS/STT/voices)
and does not naturally map onto AI SDK v3 stream parts.

This document defines what “parity” means for ElevenLabs in this repo.

## Goals

- Keep request/response mapping consistent with the Vercel AI SDK ElevenLabs
  provider semantics (field names, defaults, and provider option shapes).
- Keep provider metadata stable and namespaced under `elevenlabs`.
- Provide **fixture-driven contract tests** so refactors stay fearless even for
  non-chat surfaces.

## Non-goals

- ElevenLabs is not part of `test/fixtures/v3_parts/*` and does not participate
  in v3 stream-part JSONL goldens.
- We do not attempt to emulate the AI SDK `SpeechModelV3` / `TranscriptionModelV3`
  object model in Dart. We keep Dart public APIs idiomatic (`TTSRequest`,
  `STTRequest`, etc).

## Surfaces covered

### Text-to-speech (TTS)

Contract invariants:

- Uses `POST /v1/text-to-speech/{voice_id}` with `output_format` in query params.
- Request body:
  - `text` (required)
  - `model_id` (defaults from config)
  - `voice_settings` only when non-empty (merged from config defaults + request overrides)
  - Optional request fields: `language_code`, `seed`, context fields, etc.
- `TTSResponse.providerMetadata` contains `elevenlabs`.

### Speech-to-text (STT)

Contract invariants:

- Uses `POST /v1/speech-to-text` as multipart form-data.
- Form fields include `model_id` and `file`, plus optional knobs when provided
  (`language_code`, `diarize`, `num_speakers`, etc).
- `STTResponse.providerMetadata` contains `elevenlabs`.

### Voices

Contract invariants:

- Uses `GET /v1/voices`.
- Output mapping remains stable (`VoiceInfo` list).

## Fixtures and tests

We maintain small handcrafted fixtures under:

- `test/fixtures/elevenlabs/tts/*.request.json` / `*.response.json`
- `test/fixtures/elevenlabs/stt/*.request.json` / `*.response.json`

And a single fixture-driven contract test:

- `test/providers/elevenlabs/elevenlabs_contract_fixtures_test.dart`

These fixtures are intentionally small and focused (do not store real audio,
only tiny byte samples).
