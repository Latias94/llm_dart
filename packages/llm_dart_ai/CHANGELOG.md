# Changelog

## [Unreleased]

- Refactored structured output into a public facade, output strategy, JSON
  support, stream result, and runner modules. Public `OutputSpec` APIs and
  `generateOutput`/`streamOutput` behavior are unchanged.
- Split text call result facades from runner glue while keeping
  `generateTextCall` and `streamTextCall` public behavior unchanged.
- Split `StreamTextRunResult` and provider cancellation stream support out of
  the stream text runner implementation without changing stream behavior.

## [0.11.0-alpha.1] - 2026-05-12

- Alpha release of the shared AI helper package.
- Use this package directly when you want generation helpers without depending
  on the root `llm_dart` package.
- Includes text generation/streaming helpers, result accumulation, and
  structured output utilities.
- Owns the user-facing helper surface over provider contracts, including
  `generateText(...)`, `streamText(...)`, `embed(...)`, `embedMany(...)`,
  `generateImage(...)`, `generateSpeech(...)`, and `transcribe(...)`.
- Calls provider-side `do*` methods internally so app code can stay on stable
  helpers while provider authors implement lower-level contracts.
