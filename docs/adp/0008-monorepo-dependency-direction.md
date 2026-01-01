# ADP-0008: Enforce monorepo dependency direction

## Context

`llm_dart` is a multi-package monorepo split into:

- `llm_dart_core` (types + traits)
- `llm_dart_provider_utils` (shared transport / protocol glue)
- Protocol reuse layers (e.g. `*_compatible`)
- Provider packages (OpenAI/Anthropic/Google and community providers)
- `llm_dart_ai` task APIs (standard surface)
- `llm_dart` umbrella (all-in-one convenience)

We are in a “fearless refactor” phase. Without guardrails, it is easy to
accidentally introduce reverse dependencies (e.g. `core` importing a provider),
which re-couples packages and makes further splits impossible.

## Problem

We need a lightweight, enforceable rule set that:

- Prevents reverse dependencies (core/utils depending on providers)
- Keeps protocol reuse layers provider-agnostic (Vercel-style)
- Preserves “pick subpackages” ergonomics and small dependency footprints

## Decision

Adopt and enforce the following dependency direction rules:

1) `llm_dart_core` depends on **no workspace packages**
2) `llm_dart_provider_utils` depends only on `llm_dart_core`
3) `llm_dart_ai` depends only on `llm_dart_core`
4) `llm_dart_builder` depends only on `llm_dart_core`
5) Protocol reuse packages (`*_compatible`) depend only on:
   - `llm_dart_core`
   - `llm_dart_provider_utils`
6) Provider packages depend only on:
   - `llm_dart_core`
   - `llm_dart_provider_utils`
   - protocol reuse packages (`*_compatible`)
7) Umbrella package `llm_dart` is unrestricted (it re-exports everything)

Enforcement:

- Add `tool/check_monorepo_deps.dart` and run it in CI.

## Consequences

Pros:

- Prevents accidental re-coupling during refactors
- Keeps protocol layers reusable across providers
- Keeps “pick-and-choose” dependency footprints small

Cons:

- Some “convenience” shared helpers must live in `provider_utils` or `ai`, not in
  provider packages
- Occasional refactors are required to move shared code upward

## Migration plan

- If CI reports a violation, move the shared code:
  - provider → protocol layer, or
  - provider → `llm_dart_provider_utils`, or
  - provider → app/examples (if it’s not a library concern)

## Open questions

- Should we enforce this at the analyzer level (imports) in addition to pubspec
  dependency checks?

