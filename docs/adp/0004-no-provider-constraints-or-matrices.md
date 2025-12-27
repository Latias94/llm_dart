# ADP-0004: No Provider-side Constraints or Capability Matrices

Status: Accepted  
Date: 2025-12-22  
Scope: `llm_dart_core`, `llm_dart_ai`, provider packages, protocol packages

## Context

`llm_dart` is being refactored toward a Vercel AI SDK-style split:

- A narrow and stable “standard surface” (task APIs in `llm_dart_ai`).
- Providers and protocol layers as composable packages.
- Explicit escape hatches for provider-specific behavior via:
  - `LLMConfig.providerOptions` / `LLMConfig.providerTools`
  - `ChatMessage.providerOptions` / `ToolCall.providerOptions`
  - `ChatResponse.providerMetadata`

Historically, parts of the codebase attempted to:

- Maintain per-model/per-provider “supports X” matrices.
- Strip or omit parameters that looked unsupported.
- Replace unsupported inputs with placeholder text.

This creates long-term maintenance burden and can silently change user intent.

## Decision

### 1) The SDK does not enforce provider feature constraints

Provider and protocol implementations should not:

- Validate “unsupported” parameters by model id.
- Strip request keys because a model “probably” rejects them.
- Rewrite inputs (e.g. replacing an image or file with placeholder text).

Instead, requests are forwarded best-effort and the provider API is the source
of truth. If a provider rejects a feature, it should return an API error.

### 2) Capability reporting is informational only

`ProviderCapabilities.supports(...)` is a best-effort hint:

- Useful for selection/UI/documentation.
- Not a guarantee and not used for strict validation.

Providers may report broad capability sets without model-level differentiation.

### 3) Protocol-level structural validation is still allowed

We still enforce invariants that are required to construct a valid protocol
request, for example:

- Tool call arguments must be valid JSON where the wire format requires JSON.
- Protocol adapters may throw when an input cannot be represented in the target
  protocol shape (e.g. Anthropic Messages API does not accept `ImageUrlMessage`).

### 4) Default behavior must be conservative across “compatible” providers

When a protocol package is reused by a compatible provider (e.g. MiniMax via the
Anthropic Messages API), the default behavior should avoid assuming Anthropic-
only features. For example:

- Do not send `anthropic-beta` headers by default for non-`anthropic` provider ids.
- Let users opt in via `providerOptions[providerId].extraHeaders`.

## Consequences

### Positive

- Less long-term maintenance and fewer stale matrices.
- Fewer surprising behaviors (no silent stripping/rewriting).
- Better alignment with Vercel AI SDK’s approach (small unified surface, escape hatches).

### Negative / trade-offs

- Users may see more provider-side API errors (this is intended).
- Some “nice” guardrails move to app-level code (examples/recipes).

## Migration notes

- Move provider-only knobs to `providerOptions` (namespaced).
- Represent provider-executed features as `ProviderTool` where applicable.
- Keep concrete implementations of app-level tools (web search/fetch, file access)
  out of the standard surface unless they are truly cross-provider and stable.

