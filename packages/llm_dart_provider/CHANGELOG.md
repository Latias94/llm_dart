# Changelog

## [0.11.0-alpha.1] - 2026-05-08

- Alpha release of the provider contract package.
- Provides shared contracts for prompts, content parts, tools, results,
  metadata, model capabilities, and stream events.
- Includes UI message/projection types and JSON codecs for prompt, stream, and
  chat UI transport.
- Most app code reaches these types through `llm_dart`; custom provider authors
  can depend on this package directly.
