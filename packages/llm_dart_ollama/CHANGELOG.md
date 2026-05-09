# Changelog

## [0.11.0-alpha.1] - 2026-05-09

- Alpha release of the dedicated Ollama provider package.
- Moves the modern Ollama chat, embedding, model catalog, options, and
  capability descriptor APIs into this dedicated package.
- Keeps the model-first API shape with `ollama(...).chatModel(...)`,
  `ollama(...).embeddingModel(...)`, and
  `ollama(...).catalog().listModels()`.
