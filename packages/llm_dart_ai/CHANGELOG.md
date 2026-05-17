# Changelog

## [Unreleased]

- Refactored structured output into a public facade, output strategy, JSON
  support, stream result, and runner modules. Public `OutputSpec` APIs and
  `generateOutput`/`streamOutput` behavior are unchanged.
- Split text call result facades from runner glue while keeping
  `generateTextCall` and `streamTextCall` public behavior unchanged.
- Split `StreamTextRunResult` and provider cancellation stream support out of
  the stream text runner implementation without changing stream behavior.
- Split generate text runner support into public facade, tool execution, and
  prompt replay modules while preserving runner behavior.
- Split generate text result accumulation into content buffering, tool
  projection, and lifecycle modules while preserving public result collection
  behavior.
- Split stream text runner lifecycle support into event emission, active run
  state, and finish/error/abort closure modules while preserving stream
  behavior.
- Split generate text runner lifecycle support into active run state and
  finish/error/abort closure modules while preserving non-streaming runner
  behavior.
- Split structured output runner lifecycle support into final parse/error
  handling and streaming partial projection modules while preserving output
  runner behavior.
- Split output spec strategies into output-type-owned modules while preserving
  public `OutputSpec` exports and structured output behavior.
- Split output foundation and JSON support into focused type, parsing,
  validation, value, and diagnostics modules while preserving public exports and
  output behavior.

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
