# ADP-0007: OpenAI Responses API is OpenAI-only (not part of openai-compatible)

## Context

`llm_dart` aligns with the Vercel AI SDK philosophy:

- Keep the **standard surface** narrow (`llm_dart_ai` tasks).
- Reuse protocol layers to avoid duplication.
- Keep provider-specific innovation behind escape hatches.

We have two OpenAI-shaped protocol families:

- **Chat Completions** (widely implemented by “OpenAI-compatible” providers)
- **Responses API** (OpenAI-specific; includes OpenAI built-in tools such as web search, file search, computer use)

## Problem

If we put **Responses API semantics** into `llm_dart_openai_compatible`, the “compatible baseline” grows into an OpenAI-only surface:

- “OpenAI-compatible” providers generally do **not** support Responses endpoints or its tool semantics.
- The compatible package becomes harder to reason about and harder to maintain.
- It blurs the boundary between “protocol reuse” and “provider-only features”, increasing refactor drift.

This conflicts with the Vercel split:

- `@ai-sdk/openai-compatible` focuses on the OpenAI-compatible baseline.
- OpenAI Responses capabilities live in the OpenAI provider package.

## Decision

1. `llm_dart_openai_compatible` is **Chat Completions baseline only**.
   - It does not model or switch into the Responses API.
   - It remains suitable for providers like Groq/DeepSeek/xAI/OpenRouter/etc.

2. OpenAI Responses API lives in `llm_dart_openai` only.
   - OpenAI provider decides between Chat Completions vs Responses.
   - Message conversion for Responses input lives in `llm_dart_openai` (OpenAI-only helper), not in the compatible layer.

3. Standard surface does not expand for Responses-only features.
   - OpenAI built-in tools are configured via `providerTools` / `providerOptions` and surfaced via `providerMetadata`.
   - The task APIs remain provider-agnostic; OpenAI-only capabilities stay OpenAI-only.

## Consequences

### Positive

- Clear protocol boundary: compatible baseline stays small and stable.
- Less accidental coupling: OpenAI-only features do not leak into compatibles.
- Easier to add new compatible providers without carrying OpenAI-only semantics.

### Trade-offs

- Some shared utilities (e.g. message conversion) may exist twice (Chat Completions vs Responses).
- Advanced users must learn that Responses tooling is OpenAI-only, not “part of compat”.

## Migration plan

- If you previously relied on `OpenAIClient(...useResponsesAPI: true).convertMessage(...)` to build Responses `input`:
  - Switch to `OpenAIResponsesMessageConverter` (OpenAI-only), or
  - Use the `OpenAIResponses` capability directly.

## Open questions

- Should we extract a dedicated OpenAI-only protocol package (e.g. `llm_dart_openai_responses`) in the future, or keep it inside `llm_dart_openai`?

