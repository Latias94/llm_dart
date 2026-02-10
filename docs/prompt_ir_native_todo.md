# Prompt IR Native Support TODO (Fearless Refactor)

Status: draft (behavioral changes expected)  
Last updated: 2026-02-10

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
- Today, Prompt IR file parts are **bytes-only** (`FilePart.data: List<int>`),
  so URL-based documents / provider file references (AI SDK-style) must be
  modeled via new part types in a future breaking step.

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
- [x] OpenAI-compatible Chat Completions: prompt-native compilation
- [x] OpenAI (Responses): prompt-native compilation
- [x] DeepSeek + Groq: expose prompt-native forwarding (wrappers)
- [x] xAI: expose prompt-native forwarding (Chat Completions) + prompt-native compilation (Responses)
- [x] Ollama JSONL: prompt-native compilation (groups text+images; aligns tool result role with Ollama API)
- [ ] Any remaining providers that support multi-part content

### M2 — Conformance tests (offline)

- [x] Prompt multi-part message is compiled into a single provider message
  - Google: `test/providers/google/google_prompt_ir_request_body_test.dart`
  - OpenAI-compatible: `test/providers/openai_compatible/openai_compatible_prompt_ir_request_body_test.dart`
  - Ollama: `test/providers/ollama/ollama_prompt_ir_request_body_test.dart`
- [x] Prompt image + caption preserves ordering (text then image part)
  - Google: `test/providers/google/google_prompt_ir_request_body_test.dart`
  - OpenAI-compatible: `test/providers/openai_compatible/openai_compatible_prompt_ir_request_body_test.dart`
  - Anthropic: `test/providers/anthropic/anthropic_prompt_ir_documents_test.dart`
- [x] Prompt file + caption preserves ordering
  - Google: `test/providers/google/google_prompt_ir_request_body_test.dart`
  - Anthropic: `test/providers/anthropic/anthropic_prompt_ir_documents_test.dart`
- [x] Tool part `overrideRole` splits into valid wire messages (no mixed roles)
  - Anthropic-compatible: `test/protocols/anthropic_compatible/prompt_ir_compilation_conformance_test.dart`

### M3 – Cleanup

- [ ] Reduce reliance on `ChatMessage.protocolPayloads` for content-part wiring
- [x] Preserve protocol payloads through Prompt IR (`PromptMessage.protocolPayloads`)
  so tool loops do not lose provider-native continuity blocks (e.g. Anthropic thinking signatures).
- [ ] Ensure `llm_dart_ai` prefers prompt-native capabilities when available
- [x] Add URL-based file parts to Prompt IR (AI SDK parity)
  - e.g. `FileUrlPart(url, mimeType, ...)` for Anthropic/Google/OpenAI Responses
  - Anthropic-compatible: `test/protocols/anthropic_compatible/prompt_ir_compilation_conformance_test.dart`
  - Google: `test/providers/google/google_prompt_ir_request_body_test.dart`
  - OpenAI Responses: `test/providers/openai/openai_responses_prompt_ir_request_body_test.dart`
  - optionally support provider file ids (e.g. OpenAI `file-*`) as a separate part type

---

## Notes (AI SDK parity)

Reference implementation (TypeScript): `repo-ref/ai/`

Practical parity checklist:

- part grouping (single message with part arrays)
- multimodal ordering (text/image/file)
- tool call/result role semantics
- streaming uses the same request compilation path as non-streaming
