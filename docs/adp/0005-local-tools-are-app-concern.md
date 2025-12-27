# ADP-0005: Local tools live in apps/examples, not the SDK

## Context

`llm_dart` provides:

- A narrow “standard surface” (`llm_dart_ai`) aligned with Vercel AI SDK.
- Provider adapters and protocol reuse layers.
- Tool protocol types (`Tool`, `ToolCall`, `ToolResult`) and orchestration (tool loops).

We also support provider-native tools via escape hatches:

- Request-time: `providerOptions`
- Provider-executed tools: `providerTools`
- Response-time: `providerMetadata`

During the fearless refactor we repeatedly hit scope creep when considering SDK-shipped “tool implementations” (e.g. web search, web fetch, file access).

## Problem

Shipping a “tools library” inside the SDK tends to create long-term ownership burdens:

- **Security & policy**: network/file access, prompt injection surfaces, sandbox expectations.
- **Compatibility**: different runtimes (Flutter/web/server) have different I/O primitives.
- **Maintenance**: users expect “official tools” to be stable and bug-fixed quickly.
- **Semantics**: “web search” and “web fetch” vary widely across providers and apps.

This conflicts with our non-goal: we do not want a unified API that exposes every feature.

## Decision

- `llm_dart` will **not** ship first-party implementations of local tools (web search/web fetch/file tools/etc.) as part of the standard surface.
- The SDK will remain responsible for:
  - Tool protocol modeling (`Tool`, `ToolCall`, `ToolResult`)
  - Orchestration (`runToolLoop*`, `streamToolLoop*`)
  - Escape hatches for provider-native tools (`providerTools` + `providerOptions`)
- Concrete local tool implementations should live in:
  - **Application code**, or
  - **Examples/recipes** (where they can be copied and audited by users)

## Consequences

Positive:

- Keeps the standard surface small and stable (Vercel-style).
- Avoids taking responsibility for security-sensitive I/O helpers.
- Encourages apps to own their data access policy and sandbox model.

Trade-offs:

- Less “batteries included” for quick demos.
- Users may build similar tools repeatedly across projects.

Mitigations:

- Provide high-quality examples/recipes and recommended patterns.
- Keep tool loop APIs ergonomic so apps can plug in tools easily.

## Migration plan

- If any local tool implementations exist in SDK packages, move them into examples/recipes.
- Keep provider-native web search as provider tools:
  - Configure via `providerTools` and provider-specific `providerOptions`.

## Open questions

- Should we maintain a separate community-driven `llm_dart_recipes` repo for tools/examples?
- Do we want a minimal “toolkit” package with **pure utilities only** (no I/O), e.g. JSON schema helpers?

