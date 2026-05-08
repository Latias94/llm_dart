# Changelog

## [0.11.0-alpha.1] - 2026-05-08

- Alpha release of the OpenAI-family provider package.
- Use this package directly when you need OpenAI-specific options, native tool
  support, model profiles, or lower-level provider APIs.
- OpenRouter profiles can attach app attribution headers through
  `OpenRouterProfile(appReferer: ..., appTitle: ...)`.
- Most app code can still access OpenAI through `openai(...)` from the root
  `llm_dart` package or `package:llm_dart/openai.dart`.
