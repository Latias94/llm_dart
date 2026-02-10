# AI SDK v3 Parity Refactor: TODO

Status: Draft (fearless refactor; breaking changes allowed)  
Last updated: 2026-02-10

This TODO list tracks concrete work required to reach **semantic and structural
parity** with the Vercel AI SDK v3 stream part model, while keeping Dart public
APIs idiomatic.

Reference: `docs/ai_sdk_v3_refactor_purpose.md`

---

## P0 (must-do): Canonical stream parts parity

### 0.1 Complete the canonical part set in `llm_dart_core`

- [ ] Add missing part types to `packages/llm_dart_core/lib/core/stream_parts.dart`:
  - [x] `raw` passthrough part (AI SDK: `type: 'raw'`)
  - [x] `file` part for model-generated files (AI SDK: `type: 'file'`)
  - [ ] Align `error` part semantics with AI SDK (streamable/multiple vs terminal)
- [ ] Decide and document tool-related part strategy:
  - [ ] Represent `tool-input-start|delta|end` as string deltas (AI SDK-style)
  - [ ] Represent `tool-call`, `tool-result`, and `tool-error` parts explicitly
- [ ] Make block ids a contract:
  - [ ] Ensure every `text-*`, `reasoning-*`, and `tool-input-*` part carries a non-empty id
- [ ] Usage parity (finish usage payload):
  - [x] Extend `UsageInfo` to carry AI SDK v3-style cache/text/reasoning splits
  - [x] Encode v3 `finish.usage` as `{ inputTokens, outputTokens, raw? }`

### 0.1.1 Open Questions / Decisions (record choices here)

- [x] Error semantics:
  - [x] Treat `error` as a streamable/multiple part (AI SDK-style) in the
    canonical JSON shape.
  - [x] Keep “terminal error” behavior provider-specific; termination is
    expressed by stream completion (and optionally a final `finish` if present).
- [x] Block id injection:
  - [x] Inject missing ids in the **normalization layer** (`llm_dart_ai`) as the
    long-term solution; providers may still provide ids when available.
  - [x] For fixture/golden stability, allow deterministic counter-based id
    injection in the v3 JSON encoder until normalization is fully migrated.
- [x] Tool result representation:
  - [x] Canonical JSON stores `result` as JSON-like objects when available.
  - [x] For legacy `ToolResult.content: String`, decode JSON best-effort; if
    decode fails, keep a string.
  - [x] Stringification to provider wire format happens at provider request
    compilation boundaries (not in canonical parts).
- [x] Source modeling:
  - [x] Canonical JSON uses AI SDK v3 `type:'source'` + `sourceType`.
  - [x] `LLMSourceUrlPart` / `LLMSourceDocumentPart` remain Dart-friendly
    wrappers but must encode losslessly into the canonical v3 shape.
- [ ] File part payload encoding:
  - [x] Decide stable JSON encoding for bytes (for `.jsonl` goldens):
    - If `data` is a base64 `String`, keep it as-is.
    - If `data` is raw bytes (`Uint8List`), encode as a base64 `String` in the v3 JSONL encoder.
    - Very large base64-like strings may be redacted by the golden normalizer.

### 0.2 Add a stable JSON codec for parts (fixture-friendly)

- [ ] Implement `LLMStreamPart` JSON serialization/deserialization helpers:
  - [ ] Stable key naming and ordering (golden output stability)
  - [ ] Round-trip tests
- [ ] Provide a JSONL helper for streams:
  - [ ] `Stream<LLMStreamPart>` -> `.jsonl` lines
  - [ ] `.jsonl` lines -> `List<LLMStreamPart>`

### 0.2.1 Golden fixtures conventions

- [ ] Directory layout:
  - [ ] `test/fixtures/v3_parts/<provider>/<scenario>.jsonl` (canonical parts goldens)
  - [ ] `test/fixtures/v3_parts/<provider>/<scenario>.meta.json` (optional; human notes)
- [ ] Golden stability rules:
  - [ ] Do not include timestamps unless fixture explicitly asserts them.
  - [ ] Prefer deterministic ids (counter-based) when providers do not supply ids.
  - [ ] Preserve provider-only fields under `providerMetadata` or `raw` only.

### 0.3 Ensure orchestration emits v3-consistent boundaries

- [ ] In `llm_dart_ai` (`packages/llm_dart_ai/lib/src/stream_parts.dart`):
  - [ ] Inject `stream-start` exactly once (already done via `ensureStreamStartPart`)
  - [ ] Inject/normalize missing block ids (text/reasoning/tool input)
  - [ ] Ensure exactly one final `finish` part at end of stream

---

## P0 (must-do): Tool loop parity (semantic)

### 1.1 Typed tool call lifecycle (AI SDK-style)

- [ ] Add canonical representation for:
  - [ ] parsed tool calls (`tool-call`)
  - [ ] tool results (`tool-result`)
  - [ ] tool errors (`tool-result` with `isError: true` at provider-v3 layer)
  - [x] “invalid tool call” behavior (best-effort) in local tool loop (invalid JSON / schema mismatch / unknown tool)
- [ ] Update `llm_dart_ai` tool loop to emit the canonical tool parts:
  - [ ] stream: `streamToolLoopParts*`
  - [ ] non-stream: `runToolLoop*` (if/when it exposes tool events)

### 1.2 Optional repair hook (fearless-friendly)

- [ ] Add optional hook(s) to tool loop / streaming transformer:
  - [ ] `parseToolCall` (decode + schema validation)
  - [ ] `repairToolCall` (user-provided strategy; no default “model re-ask” yet)

---

## P1: Sources/files parity and propagation

- [ ] Normalize sources into the canonical parts:
  - [ ] unify/bridge `source-url` + `source-document` into AI SDK v3 `source`
  - [ ] keep `providerMetadata` for extra provider-specific citation data
- [ ] Add file part support where provider returns generated binary/base64 files

---

## P1: Tool name mapping and collision safety

We already have collision-safe mapping utilities:

- `packages/llm_dart_provider_utils/lib/utils/tool_name_mapping.dart`

Remaining work:

- [ ] Ensure every provider that supports provider-native tools uses mapping:
  - [ ] map local function tool names -> provider request tool names (rewrite on collision)
  - [ ] map provider tool request names -> stable provider tool ids
- [ ] Add fixture-style tests for collisions and mapping stability

---

## P2: Provider-by-provider migration checklist

For each streaming provider implementation:

- [ ] Map raw provider stream into canonical parts
- [ ] Emit `response-metadata` as soon as available (id/model/timestamp)
- [ ] Emit tool input stream parts when tools are streamed incrementally
- [ ] Emit `finish` with typed `usage` + typed `finishReason`
- [ ] Preserve provider-only fields via `providerMetadata` and/or `raw` parts

Recommended order:

1. OpenAI Responses (richest part surface)
2. Anthropic (reasoning/thinking + tool blocks)
3. OpenAI-compatible baseline (Azure/Groq/DeepSeek/xAI compatibility edge cases)

---

## P2: Execution plan (minimal tooling)

- [ ] Add a small “golden generator” tool (repo-local):
  - [ ] Reads a selected provider fixture (vendored under `repo-ref/ai`)
  - [ ] Replays/decodes it into canonical parts
  - [ ] Writes `.jsonl` golden outputs under `test/fixtures/v3_parts/...`
- [ ] Add a “golden check” test harness:
  - [ ] Loads expected `.jsonl`
  - [ ] Compares canonical parts with stable normalization (key order, omitted nulls)
  - [ ] Prints a minimal diff on mismatch

---

## P2: Test plan (fixtures-first)

- [ ] Add a v3-part golden test harness:
  - [ ] input: vendored AI SDK fixtures under `repo-ref/ai/.../__fixtures__`
  - [ ] expected: repo-local goldens under `test/fixtures/...`
  - [ ] assertion: parsed canonical parts JSONL deep-equals expected JSONL
- [ ] Add targeted “nasty stream boundaries” fuzz tests:
  - [ ] tool input JSON split across arbitrary chunk boundaries
  - [ ] usage arriving after finish_reason (common in OpenAI-compatible/Azure)
