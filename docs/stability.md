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

## Design rules (enforced)

- `llm_dart_core` must remain provider-agnostic (no OpenAI-only models shipped
  from the core surface).
- Provider packages must not re-export protocol reuse layers (`*_compatible`)
  from their main provider entrypoints.
- Provider packages must keep low-level HTTP utilities opt-in (not exported from
  `<provider>.dart`).
