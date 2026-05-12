# Changelog

## [0.11.0-alpha.1] - 2026-05-12

- Alpha release of the OpenAI-family provider package.
- Use this package directly when you need OpenAI-specific options, native tool
  support, model profiles, or lower-level provider APIs.
- Includes package-local short factories such as `openai(...)`, `groq(...)`,
  `deepSeek(...)`, `openRouter(...)`, `xai(...)`, and `phind(...)` so apps can
  use the focused package without depending on the root facade.
- OpenRouter profiles can attach app attribution headers through
  `OpenRouterProfile(appReferer: ..., appTitle: ...)`.
- The root `llm_dart` package and `package:llm_dart/openai.dart` re-export the
  same model-first path for convenience.
- OpenAI-family models now implement the provider-side `doGenerate(...)`,
  `doStream(...)`, `doEmbed(...)`, and non-text `doGenerate(...)` contracts;
  app code should use shared helpers from `llm_dart_ai` or the root package.
- Image and file prompt-part request controls, including OpenAI image detail,
  are represented with typed `OpenAIPromptPartOptions` instead of
  `ProviderMetadata`.
