# Changelog

## [0.11.0-alpha.1] - 2026-05-12

- Alpha release of the Flutter adapter package.
- Adds `ChatController` and Flutter-friendly persistence helpers on top of the
  pure Dart chat runtime.
- Use this package when building Flutter chat UI around `llm_dart_chat`.
- Stays layered above `llm_dart_chat` and the AI helper surface, so Flutter UI
  code does not depend on concrete provider implementations.
