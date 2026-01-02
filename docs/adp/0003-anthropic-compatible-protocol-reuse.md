# ADP-0003: Anthropic-compatible Protocol Reuse (MiniMax as a Consumer)

Status: Accepted  
Date: 2025-12-22  
Scope: `llm_dart_anthropic_compatible`, `llm_dart_minimax`, `llm_dart_ai` tool loops

## Context

`llm_dart` is being refactored into a Vercel AI SDK-style monorepo split:

- A convenient umbrella package (`llm_dart`) for most users.
- Composable subpackages for advanced users (`llm_dart_ai`, `llm_dart_builder`, provider packages).
- A narrow “standard surface” for stable orchestration.
- Explicit escape hatches for provider-specific behavior via:
  - `LLMConfig.providerOptions` / `LLMConfig.providerTools`
  - `ChatResponse.providerMetadata`

Many providers expose “compatible” APIs (wire formats close to Anthropic/OpenAI),
but compatibility is never perfect. MiniMax is a concrete case: it provides an
Anthropic-compatible text API surface (docs: `https://platform.minimax.io/docs/api-reference/text-anthropic-api`).

## Problem

Without a first-class “protocol layer” package, each compatible provider tends to:

1. Copy/paste request/response parsing and SSE logic.
2. Drift in behavior (tool streaming aggregation, cancellation semantics, etc.).
3. Accumulate provider-specific conditionals inside the “standard” provider package.
4. Create a messy dependency graph (providers depending on each other instead of
   depending on protocol layers).

Additionally, Anthropic-style multi-step tool use has a protocol constraint:

- Consumers must preserve the full assistant `content` block list between turns
  for continuity (e.g. thinking signatures, tool_use blocks).

If an orchestration layer (tool loop) reconstructs assistant messages as plain
strings, follow-up requests can break even if tool calls/results are correct.

## Decision

### 1) Treat Anthropic-compatible as a standalone protocol package

Keep wire-format logic (request building, response parsing, SSE streaming, tool
aggregation, tool name mapping, and protocol-specific metadata extraction) in:

- `llm_dart_anthropic_compatible`

Provider packages that “speak Anthropic” must depend on this protocol package
instead of depending on `llm_dart_anthropic`.

### 2) Provider packages add defaults only (no provider-side constraints)

Compatible providers (e.g. MiniMax) should be implemented as thin wrappers:

- Use `AnthropicConfig.fromLLMConfig(..., providerOptionsNamespace: '<providerId>')`
  to read namespaced options (fallback to `anthropic`).
- Use `AnthropicClient` (opt-in: `package:llm_dart_anthropic_compatible/client.dart`) +
  `AnthropicChat` for the protocol implementation.
- Do **not** enforce provider-specific constraints or “support matrices” in the SDK.
  Requests are forwarded best-effort and the provider API is the source of truth.
  If a provider rejects a feature, it should return an API error.

MiniMax implementation pattern:

- Provider factory: `packages/llm_dart_minimax/lib/minimax_factory.dart`
- Config defaults + base URL normalization: `packages/llm_dart_minimax/lib/minimax.dart`

### 3) Tool loops must preserve provider-specific assistant content blocks

Introduce and use `ChatResponseWithAssistantMessage` so protocol layers can
provide an “assistant message to persist” that keeps structured content blocks
intact.

Tool loops (`llm_dart_ai`) must prefer this assistant message when present.

MiniMax relies on this via the Anthropic-compatible response:

- `packages/llm_dart_anthropic_compatible/lib/src/chat/response.dart`

### 4) Do not expand the standard surface for compatibility-only details

Compatibility details remain provider-specific and flow through escape hatches:

- `providerOptions['minimax']` / fallback `providerOptions['anthropic']`
  - `cacheControl` (Anthropic prompt caching shape)
  - `extraBody` / `extraHeaders` (explicit escape hatch)
- `providerMetadata['minimax']` (provider-specific response info)

We do not add “MiniMax-specific” knobs to the unified task APIs.

## Consequences

### Positive

- One source of truth for Anthropic wire-format behavior and streaming semantics.
- Compatible providers become small and maintainable (defaults + constraints).
- Tool loops remain stable while preserving protocol requirements (assistant
  content blocks).
- Cleaner dependency graph: “providers depend on protocol layers”, not on other
  provider packages.

### Negative / trade-offs

- Some provider behaviors cannot be validated without real API calls; we rely on
  conformance tests for invariants we control.

## Migration plan

1. Keep `llm_dart_anthropic_compatible` as the canonical protocol layer for
   Anthropic wire format.
2. Ensure each Anthropic-compatible provider:
   - Uses `providerOptionsNamespace: '<providerId>'`
   - Preserves assistant content blocks via `ChatResponseWithAssistantMessage`
3. Guard behavior with shared protocol conformance tests plus provider-specific
   suites:
   - Protocol: `test/protocols/anthropic_compatible/`
   - MiniMax: `test/providers/minimax/`
4. Use the monorepo provider template as a starting point:
   - `docs/templates/anthropic_compatible_provider/`

## Open questions

1. Should we add a standardized “ignored_fields” debug channel in
   `providerMetadata` for easier troubleshooting, or is it too noisy?
2. For other Anthropic-compatible providers, do we want a shared helper for
   “strip ignored keys” patterns, or keep it provider-local to prevent false
   assumptions across providers?
