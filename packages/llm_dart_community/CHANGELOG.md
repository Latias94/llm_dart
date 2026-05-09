# Changelog

## [0.11.0-alpha.1] - 2026-05-08

- Alpha release of the community provider package.
- Adds modern Ollama chat/embedding models and ElevenLabs speech/transcription
  models.
- Includes package-local `ollama(...)` and `elevenLabs(...)` short factories
  for the same model-first style used by the focused provider packages.
- Adds capability profiles for these models so apps can gate UI and fallbacks
  from library-provided model descriptions.
