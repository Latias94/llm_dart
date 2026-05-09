# Changelog

## [0.11.0-alpha.1] - 2026-05-09

- Alpha release of the dedicated ElevenLabs provider package.
- Moves the modern ElevenLabs speech, transcription, voice catalog, options,
  and capability descriptor APIs into this dedicated package.
- Keeps the model-first API shape with `elevenLabs(...).speechModel(...)`,
  `elevenLabs(...).transcriptionModel(...)`, and
  `elevenLabs(...).voices().listVoices()`.
