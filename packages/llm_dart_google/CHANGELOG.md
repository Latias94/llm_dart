# Changelog

## [0.11.0-alpha.1] - 2026-05-12

- Alpha release of the Google/Gemini provider package.
- Use this package directly when you need Google-specific options, image or
  speech models, or lower-level provider APIs.
- Includes the package-local `google(...)` short factory so apps can use the
  focused package without depending on the root facade.
- The root `llm_dart` package and `package:llm_dart/google.dart` re-export the
  same model-first path for convenience.
- Google models now implement the provider-side `doGenerate(...)`,
  `doStream(...)`, `doEmbed(...)`, and non-text `doGenerate(...)` contracts;
  app code should use shared helpers from `llm_dart_ai` or the root package.
- Provider-specific request controls stay in typed Google provider options
  instead of metadata-shaped request bags.
