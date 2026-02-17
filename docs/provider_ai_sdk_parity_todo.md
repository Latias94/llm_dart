# Provider AI SDK Parity TODO (Fearless Refactor)

Status: draft (behavioral changes expected)  
Last updated: 2026-02-10

This tracker compares `llm_dart` providers against Vercel AI SDK semantics
(`repo-ref/ai`) with a focus on the **standard surface**:

- Prompt IR native compilation (`PromptChatCapability` / `PromptChatStreamPartsCapability`)
- Parts-first streaming (`LLMStreamPart`)
- Typed `finishReason` + `usage` on `LLMFinishPart`
- Typed citations/sources (`LLMSourceUrlPart` / `LLMSourceDocumentPart`)
- Provider-executed tools as typed parts (never local `toolCalls`)
- Provider metadata namespacing + alias equivalence conformance

Notes:

- This is not an “official API surface” tracker. For official endpoints coverage,
  see `docs/provider_official_api_alignment.md`.
- The goal is **semantic parity**, not byte-for-byte fixture equality.

---

## Global invariants (must hold)

- Provider-executed tools never become local `ChatResponse.toolCalls`.
- `LLMStreamPart` is the primary stream representation; legacy streaming is adapter-only.
- If a provider emits metadata aliases, alias payloads deep-equal the canonical payload.

---

## Provider checklist

### OpenAI (`llm_dart_openai`)

- [x] Responses streaming emits typed source parts (URL + document citations)
- [x] Responses streaming emits provider tools as typed parts
- [x] Finish part includes typed `usage` + `finishReason`
- [x] providerMetadata alias equivalence (`openai.responses` mirrors `openai`)
- [x] Prompt IR file reference parts (Responses request compilation)
  - `FileUrlPart` (PDF) and `FileIdPart` (PDF/image) are compiled to Responses inputs.

### OpenAI-compatible baseline (`llm_dart_openai_compatible`)

- [x] Prompt IR native request compilation (multi-part grouping)
- [x] Streaming chunk fuzz coverage (tool/text boundary robustness)
- [x] Finish part includes typed `usage` + `finishReason`
- [x] Typed citations/sources for Responses annotations (when provider supports them)

### Anthropic-compatible baseline (`llm_dart_anthropic_compatible`)

- [x] Prompt IR native compilation + `overrideRole` splitting (order-preserving)
- [x] Typed citations/sources via stream parts
- [x] Finish part includes typed `usage` + `finishReason`
- [x] Provider tools emitted as typed parts (never local toolCalls)

### Google (Gemini API) (`llm_dart_google`)

- [x] Prompt IR native compilation (content parts grouping)
- [x] Prompt IR file reference parts (AI SDK parity)
  - `FileUrlPart` -> `fileData.fileUri`
  - `FileIdPart(id: 'files/...')` -> `fileData.fileUri`
  - Optional strict URL validation: `providerOptions['google']['supportedFileUrlsOnly']=true`
- [x] Grounding sources emitted as typed source parts
- [x] Code execution emitted as provider tool typed parts
- [x] Finish part includes typed `usage` + `finishReason`
- [x] providerMetadata alias equivalence (`google.chat` mirrors `google`)

### Google Vertex (express mode) (`llm_dart_google_vertex`)

- [x] Request-side `providerOptions` are scoped under `providerOptions['vertex']` (legacy: `google-vertex`, `google`)
- [x] Prompt IR file URL strict mode is namespaced (`supportedFileUrlsOnly`)
- [x] Response metadata is emitted under `providerMetadata['vertex']`
- [x] providerMetadata alias equivalence (`vertex.chat` mirrors `vertex`)
- [x] Source parts conformance (should match Google grounding)

### xAI (`llm_dart_xai`)

- [x] Chat Completions: request mapping + citations alignment (AI SDK style)
- [x] Responses streaming: typed source parts + provider tool parts
- [x] Finish part includes typed `usage` + `finishReason`

### Ollama (`llm_dart_ollama`)

- [x] Prompt IR native compilation groups text+images and tool result roles
- [x] Finish part includes typed `usage` + `finishReason`
- [x] Streaming chunk boundary fuzz (JSONL)

---

## Next refactor steps (recommended)

1) Expand offline conformance tests for any remaining providers that emit sources/citations.
2) Extract provider-shared helpers into `llm_dart_provider_utils`:
   - source extraction + dedupe utilities
   - finish metadata propagation helpers
   - providerMetadata alias wrapping patterns

---

## Migration notes

- Google Vertex metadata key:
  - canonical: `providerMetadata['vertex']`
  - alias: `providerMetadata['vertex.chat']`
  - see `docs/migrations/0.12.0-alpha.1.md`
