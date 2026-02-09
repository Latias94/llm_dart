# Prompt IR Native Support TODO (Fearless Refactor)

Status: draft (behavioral changes expected)  
Last updated: 2026-02-09

This tracker focuses on **Prompt IR native support** across providers:
implementing `PromptChatCapability` / `PromptChatStreamPartsCapability` so
providers can compile `Prompt` directly, without `Prompt.toChatMessages()`.

Why this matters:

- `Prompt.toChatMessages()` emits **one `ChatMessage` per part**, which loses
  the original "multi-part message" structure (e.g. text + image in one user
  message).
- Vercel AI SDK compiles prompts **as late as possible** to preserve fidelity.
- Native prompt compilation reduces protocol hacks (`protocolPayloads`) and
  makes multi-modal/tool flows more predictable.

Core principle:

- If a provider wire format supports **content parts**, the provider should
  implement prompt-native compilation.

---

## Acceptance criteria

- For a `PromptMessage` containing multiple parts, the provider emits **one**
  wire message (or content entry) with multiple parts where the provider API
  supports it.
- `ToolCallPart` / `ToolResultPart` ordering is preserved.
- Role constraints are enforced:
  - system messages are validated per provider rules
  - tool blocks are emitted in valid roles (or split into multiple wire
    messages when a prompt message mixes roles via `overrideRole`)
- Streaming and non-streaming behavior matches (same request compilation path).

---

## Milestones

### M1 — Add prompt-native chat/streaming per provider

- [x] Google (Gemini) + Vertex: implement prompt-native compilation
- [x] Anthropic + Anthropic-compatible: prompt-native chat + streaming
- [ ] OpenAI-compatible Chat Completions: prompt-native compilation
- [ ] OpenAI (Responses): prompt-native compilation
- [ ] Ollama JSONL: prompt-native compilation (if it benefits multi-part inputs)
- [ ] Any remaining providers that support multi-part content

### M2 — Conformance tests (offline)

- [ ] Prompt multi-part message is compiled into a single provider message
- [ ] Prompt image + caption preserves ordering (text then image part)
- [ ] Prompt file + caption preserves ordering
- [ ] Tool part `overrideRole` splits into valid wire messages (no mixed roles)

### M3 — Cleanup

- [ ] Reduce reliance on `ChatMessage.protocolPayloads` for content-part wiring
- [ ] Ensure `llm_dart_ai` prefers prompt-native capabilities when available

---

## Notes (AI SDK parity)

Reference implementation (TypeScript): `repo-ref/ai/`

Practical parity checklist:

- part grouping (single message with part arrays)
- multimodal ordering (text/image/file)
- tool call/result role semantics
- streaming uses the same request compilation path as non-streaming

