# Changelog

## [Unreleased]

- Ollama embedding-model orchestration now delegates settings resolution,
  request validation/body construction, transport request projection, and
  response/provider metadata decoding to focused internal modules while
  preserving provider behavior.
- Refactored Ollama chat request encoding into internal options policy, prompt
  projection, binary prompt encoding, and request assembly modules. Public
  model settings, invocation options, and wire behaviour are unchanged.

## [0.11.0-alpha.1] - 2026-05-12

- Alpha release of the dedicated Ollama provider package.
- Moves the modern Ollama chat, embedding, model catalog, options, and
  capability descriptor APIs into this dedicated package.
- Keeps the model-first API shape with `ollama(...).chatModel(...)`,
  `ollama(...).embeddingModel(...)`, and
  `ollama(...).catalog().listModels()`.
- Ollama chat and embedding models now implement provider-side `doGenerate(...)`,
  `doStream(...)`, and `doEmbed(...)` contracts; app code should use shared
  helpers from `llm_dart_ai` or the root package.
