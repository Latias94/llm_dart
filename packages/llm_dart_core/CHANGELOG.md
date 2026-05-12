# Changelog

## [0.11.0-alpha.1] - 2026-05-12

- Alpha release of the compatibility core package.
- Keeps historical foundation, model, stream, UI, and serialization imports
  available for existing code.
- New applications should normally import the root `llm_dart` package and use
  the model-first API.
- Re-exports the provider contract and AI helper boundary for compatibility,
  while new code should prefer the root package or focused split packages.
