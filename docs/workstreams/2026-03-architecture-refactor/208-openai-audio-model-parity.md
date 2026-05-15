# 208 OpenAI Audio Model Parity

## Why This Slice Exists

After the OpenAI image and model-capability parity passes, the modern
`llm_dart_openai` audio models still had a few provider-owned behavior gaps
versus `repo-ref/ai`:

- speech sent unsupported `language` through to OpenAI
- speech accepted invalid `speed` and arbitrary output formats without a local
  compatibility decision
- speech did not encode the OpenAI defaults that make request bodies stable
- transcription could not request timestamp granularities on
  `gpt-4o-transcribe` because it required `verbose_json` for every model
- transcription did not expose OpenAI's `include[]` request option
- transcription did not map word-level responses back into shared segments when
  segment-level data was absent

## Decision

Keep the shared `SpeechModel` and `TranscriptionModel` request shapes narrow.
OpenAI-specific knobs stay in typed provider options, while provider behavior
does the compatibility work locally:

- `OpenAISpeechOptions.outputFormat` resolves to one of
  `mp3`, `opus`, `aac`, `flac`, `wav`, or `pcm`
- unsupported OpenAI speech output formats warning-fallback to `mp3`
- OpenAI speech defaults `voice` to `alloy` and `response_format` to `mp3`
- OpenAI speech warning-drops `language` because the endpoint does not support
  language selection
- OpenAI speech validates `speed` in the OpenAI-supported `0.25..4.0` range
- `OpenAITranscriptionOptions.include` maps to multipart `include[]`
- timestamp requests default to `verbose_json` for Whisper-style models but
  `json` for `gpt-4o-transcribe` and `gpt-4o-mini-transcribe`
- transcription decodes `segments` first and falls back to `words` only when
  `segments` is absent
- transcription normalizes OpenAI language names such as `english` into shared
  ISO language codes such as `en`

## Why This Matches The Reference Direction

The useful reference pattern is not to widen the shared helper layer for every
OpenAI audio detail.

The right split is:

- shared helpers own capability-level invariants and transport pass-through
- provider packages own endpoint-specific request defaults, downgrade warnings,
  and response normalization
- capability descriptors advertise only options that are actually sent to the
  provider

That keeps OpenAI parity from leaking provider policy into `llm_dart_core`.

## Validation

This slice is validated with:

- `dart test test\openai_speech_model_test.dart test\openai_transcription_model_test.dart test\openai_model_describer_test.dart`

## Follow-Up

The remaining OpenAI parity work should stay focused on concrete provider-owned
drift rather than reopening a broad migration umbrella. The next useful audit
area is likely request/response error and warning parity across the non-text
models, especially where OpenAI-compatible family profiles differ from native
OpenAI behavior.
