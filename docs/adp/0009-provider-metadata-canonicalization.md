# ADP 0009: Provider metadata canonicalization

## Context

`providerMetadata` is the response-time escape hatch for provider-specific
fields that are intentionally not part of the standardized surface.

Today the repository follows an AI SDK–inspired namespacing convention:

- Always emit a base namespace key equal to the **base provider id**
  (the prefix before the first `.` in `providerId`; e.g. `openai` for
  `openai.chat` and `openai.responses`).
- Additionally emit one or more capability aliases (e.g. `openai.chat`,
  `openai.responses`). In many cases, the capability key matches the provider
  instance `providerId`.

This helped with early Vercel AI SDK fixture parity and protocol reuse.

## Problem

As the fearless refactor continues (parts-first streaming, typed source parts,
typed provider tool parts, Responses API support, etc.), alias expansion creates
three long-term issues:

1) **Schema drift risk**
   - Multiple keys must mirror the same payload exactly.
   - Subtle differences can slip in as providers evolve.

2) **Increased breaking surface**
   - Downstream users may “pick a key at random” and get stuck on non-canonical
     aliases (`openai.chat`, `google.generative-ai`, etc.).
   - This makes future breaking changes (e.g. removing legacy streaming) harder.

3) **Maintenance cost**
   - Every new provider feature potentially adds more alias keys.
   - Tests must cover more permutations to prevent regressions.

We need a single canonical policy that keeps AI SDK parity possible while
reducing long-term costs.

## Decision

### 1) Canonical key

The canonical provider metadata key is always the **base provider id** (without
capability suffixes).

Examples:

- OpenAI (Responses, providerId `openai`): canonical key is `openai`
- OpenAI (Chat Completions, providerId `openai.chat`): canonical key is `openai`
- Anthropic: canonical key is `anthropic`
- Google (Gemini API): canonical key is `google`
- Google Vertex: canonical key is `vertex`

Historical note (Vertex):

- Earlier refactor iterations emitted `providerMetadata['google-vertex']` for
  Vertex express mode. This has been aligned to `providerMetadata['vertex']`
  for AI SDK v6 parity, with `google-vertex` kept as a legacy input alias.

### 2) Alias policy

- Existing aliases remain during a migration window.
- We stop adding new aliases by default.
- If a new alias is introduced for fixture parity, it must:
  - be explicitly justified, and
  - be covered by conformance tests that assert exact payload equivalence.

### 3) Payload equivalence rule (while aliases exist)

If both canonical and alias keys are emitted for a given response, the alias
payload must be identical to the canonical payload (deep-equal JSON shape).

### 4) Deprecation path

- Short term (current fearless refactor): keep emitting existing aliases, but
  treat them as **compatibility only**.
- Next alpha (target): deprecate alias keys in docs and recommend consuming the
  canonical key only.
- Removal window: remove aliases in a future pre-release once downstream has a
  migration guide and tests have proven parity.

## Consequences

Positive:

- Clear rule for downstream code: always read `providerMetadata[baseProviderId]`.
- Lower drift risk: one canonical schema to maintain.
- Easier to evolve the standard surface without being trapped by legacy keys.

Negative:

- Some AI SDK fixture parity may require temporary exceptions (documented).
- A future alias removal is a breaking change (but planned and guided).

## Migration plan

1) Update docs:
   - `docs/provider_metadata.md` should recommend the canonical key only and
     document the alias deprecation window.
2) Add conformance tests:
   - Assert `providerMetadata` always contains the canonical key for supported
     providers.
   - Assert alias payloads (when present) deep-equal the canonical payload.
3) Gradually stop emitting aliases:
   - First in new features/providers.
   - Later remove existing aliases in a dedicated breaking pre-release with a
     migration guide.

## Open questions

1) Should we expose a helper for consumers:
   - e.g. `readProviderMetadata(providerMetadata, providerId)` that always
     reads the base provider id key and falls back to single-entry maps?

Status:

- Implemented: `readProviderMetadata` is available in `llm_dart_provider_utils`.
