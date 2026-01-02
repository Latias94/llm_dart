# Stability policy (API surface tiers)

This repository is a multi-package monorepo split in a Vercel AI SDK style.
The primary goal is to keep a **stable, provider-agnostic** surface while
allowing provider packages to innovate independently.

This document defines the stability tiers we commit to.

## Tier 1 (Stable): task-first, provider-agnostic surface

These APIs are intended to be stable and are the recommended entrypoints for
most users:

- `llm_dart_ai`: task APIs (`generateText`, `streamText`, `generateObject`, tool
  loops, etc.)
- `llm_dart_core`: provider-agnostic types and contracts (capabilities, prompt
  IR, shared request/response types)
- `llm_dart_builder`: provider selection + configuration builders

Tier 1 changes should be:

- additive when possible
- backward compatible across minor versions
- clearly documented (migration notes) when breaking is unavoidable

## Tier 2 (Mostly stable): provider package entrypoints

Provider packages (e.g. `llm_dart_openai`, `llm_dart_google`, `llm_dart_anthropic`)
aim to keep their *entrypoint shape* stable:

- `<provider>.dart` (e.g. `openai.dart`, `google.dart`) remains the recommended
  import for the provider package.
- `llm_dart_<provider>.dart` may re-export the recommended entrypoint and factory
  helpers.

Tier 2 may still change in breaking ways when the upstream provider APIs change,
but we try to minimize churn by keeping the main entrypoint stable.

## Tier 3 (Unstable / opt-in): low-level transport and provider-specific details

These APIs are considered implementation details and are not guaranteed stable:

- provider internal HTTP clients and transport strategies (`client.dart`,
  `dio_strategy.dart`, and any subpath library with similar purpose)
- provider-specific modules that mirror upstream endpoints and may change
  frequently (for example, OpenAI-only `Assistants` / `Responses` additions)
- any `src/` paths

If you need Tier 3 APIs, import them explicitly via subpath libraries (opt-in),
and pin versions accordingly.

## Opt-in subpath libraries (Tier 3) index

This list is non-exhaustive, but highlights the most common "escape hatch"
imports that are intentionally kept out of the recommended provider entrypoints:

- `llm_dart_openai`
  - `package:llm_dart_openai/assistants.dart`
  - `package:llm_dart_openai/responses.dart`
  - `package:llm_dart_openai/client.dart`
  - `package:llm_dart_openai/dio_strategy.dart`
- `llm_dart_openai_compatible`
  - `package:llm_dart_openai_compatible/client.dart`
  - `package:llm_dart_openai_compatible/dio_strategy.dart`
- `llm_dart_anthropic_compatible`
  - `package:llm_dart_anthropic_compatible/client.dart`
  - `package:llm_dart_anthropic_compatible/dio_strategy.dart`
- OpenAI-compatible providers (wrappers)
  - `package:llm_dart_deepseek/client.dart`
  - `package:llm_dart_deepseek/dio_strategy.dart`
  - `package:llm_dart_groq/client.dart`
  - `package:llm_dart_groq/dio_strategy.dart`
  - `package:llm_dart_phind/client.dart`
  - `package:llm_dart_phind/dio_strategy.dart`
  - `package:llm_dart_xai/client.dart`
  - `package:llm_dart_xai/dio_strategy.dart`
- `llm_dart_google`
  - `package:llm_dart_google/client.dart`
  - `package:llm_dart_google/dio_strategy.dart`
- `llm_dart_ollama`
  - `package:llm_dart_ollama/client.dart`
  - `package:llm_dart_ollama/dio_strategy.dart`
- `llm_dart_elevenlabs`
  - `package:llm_dart_elevenlabs/client.dart`
  - `package:llm_dart_elevenlabs/dio_strategy.dart`
- `llm_dart_xai`
  - `package:llm_dart_xai/responses.dart` (provider-native Responses API adapter)
- `llm_dart_anthropic` / `llm_dart_minimax`
  - `package:llm_dart_anthropic/client.dart`
  - `package:llm_dart_anthropic/dio_strategy.dart`
  - `package:llm_dart_minimax/client.dart`
  - `package:llm_dart_minimax/dio_strategy.dart`

## Design rules (enforced)

- `llm_dart_core` must remain provider-agnostic (no OpenAI-only models shipped
  from the core surface).
- Provider packages must not re-export protocol reuse layers (`*_compatible`)
  from their main provider entrypoints.
- Provider packages must keep low-level HTTP utilities opt-in (not exported from
  `<provider>.dart`).
