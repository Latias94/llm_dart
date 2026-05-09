# Changelog

## [0.11.0-alpha.1] - 2026-05-08

- Alpha release of the Anthropic provider package.
- Use this package directly when you need Anthropic-specific options, files
  support, or lower-level provider APIs.
- Includes the package-local `anthropic(...)` short factory so apps can use the
  focused package without depending on the root facade.
- The root `llm_dart` package and `package:llm_dart/anthropic.dart` re-export
  the same model-first path for convenience.
