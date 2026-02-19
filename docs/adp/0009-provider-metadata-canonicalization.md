# ADP 0009: Provider metadata canonicalization

## Context

`providerMetadata` is the response-time escape hatch for provider-specific
fields that are intentionally not part of the standardized surface.

Today the repository follows an AI SDK–inspired namespacing convention:

- Emit a base namespace key equal to the **base provider id** (the prefix
  before the first `.` in `providerId`; e.g. `openai` for `openai.chat` and
  `openai.responses`).

Historically, some providers also emitted capability aliases (e.g.
`openai.chat`, `openai.responses`, `google.generative-ai`). This helped early
fixture parity, but increases drift and maintenance cost.

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

The canonical provider metadata key should be stable and deterministic.

In practice, downstream code should read via:

- `readProviderMetadata(providerMetadata, providerId)`

This prefers the base provider id when present (e.g. `openai` for
`openai.chat` / `openai.responses`) and falls back to `providerId` (and
single-entry maps) when needed.

Providers should **emit the canonical key only** by default.

Examples:

- OpenAI (Responses, providerId `openai`): canonical key is `openai`
- OpenAI (Chat Completions, providerId `openai.chat`): canonical key is `openai`
- Anthropic: canonical key is `anthropic`
- Google (Gemini API): canonical key is `google`
- Google Vertex: canonical key is `vertex`
- xAI Responses (providerId `xai.responses`): canonical key is `xai`

Historical note (Vertex):

- Earlier refactor iterations emitted `providerMetadata['google-vertex']` for
  Vertex express mode. This has been aligned to `providerMetadata['vertex']`
  for AI SDK v6 parity, with `google-vertex` kept as a legacy input alias.

### 2) Legacy aliases

`readProviderMetadata` supports legacy alias keys if they appear in recorded
fixtures, but providers should not emit them going forward.

## Consequences

Positive:

- Clear rule for downstream code: always read via `readProviderMetadata(providerMetadata, providerId)`.
- Lower drift risk: one canonical schema to maintain.
- Easier to evolve the standard surface without being trapped by legacy keys.

Negative:

- Some AI SDK fixture parity may require temporary exceptions (documented).
- A future alias removal is a breaking change (but planned and guided).

## Migration plan

1) Update docs:
   - `docs/provider_metadata.md` should recommend the canonical key only and
     recommend using `readProviderMetadata(...)` for namespaced provider ids.
2) Add conformance tests:
   - Assert `providerMetadata` contains the canonical key and does not contain
     capability aliases by default.

## Open questions

1) Should we expose a helper for consumers:
   - e.g. `readProviderMetadata(providerMetadata, providerId)` that always
     reads the base provider id key and falls back to single-entry maps?

Status:

- Implemented: `readProviderMetadata` is available in `llm_dart_provider_utils`.
