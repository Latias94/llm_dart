# AI SDK v3 Parity Refactor: TODO

Status: Draft (fearless refactor; breaking changes allowed)  
Last updated: 2026-02-11

This TODO list tracks concrete work required to reach **semantic and structural
parity** with the Vercel AI SDK v3 stream part model, while keeping Dart public
APIs idiomatic.

Reference: `docs/ai_sdk_v3_refactor_purpose.md`

---

## P0 (must-do): Canonical stream parts parity

### 0.1 Complete the canonical part set in `llm_dart_core`

- [x] Add missing part types to `packages/llm_dart_core/lib/core/stream_parts.dart`:
  - [x] `raw` passthrough part (AI SDK: `type: 'raw'`)
  - [x] `file` part for model-generated files (AI SDK: `type: 'file'`)
  - [x] Align `error` part semantics with AI SDK (streamable/multiple vs terminal) in the v3 JSON shape
- [x] Decide and document tool-related part strategy:
  - [x] Represent `tool-input-start|delta|end` as string deltas (AI SDK-style) in the v3 JSON codec
  - [x] Represent `tool-call` and `tool-result` explicitly; represent tool errors via `tool-result.isError=true`
- [x] Make block ids a contract:
  - [x] Ensure every `text-*`, `reasoning-*`, and `tool-input-*` part carries a non-empty id (normalization + codec injection)
- [x] Usage parity (finish usage payload):
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
- [x] Provider tool delta policy:
  - [x] `LLMProviderToolDeltaPart` emission is opt-in via provider option
    `emitProviderToolDeltas=true` (default `false`) to stay close to AI SDK v3
    (which does not require a dedicated “tool-delta” concept in the canonical
    part set).
- [x] File part payload encoding:
  - [x] Decide stable JSON encoding for bytes (for `.jsonl` goldens):
    - If `data` is a base64 `String`, keep it as-is.
    - If `data` is raw bytes (`Uint8List`), encode as a base64 `String` in the v3 JSONL encoder.
    - Very large base64-like strings may be redacted by the golden normalizer.

### 0.2 Add a stable JSON codec for parts (fixture-friendly)

- [x] Implement `LLMStreamPart` -> AI SDK v3 JSON encoding:
  - [x] Stable key naming and ordering (via golden normalizer)
  - [x] Deterministic block id injection for fixtures (counter-based fallback)
- [ ] Implement AI SDK v3 JSON -> `LLMStreamPart` decoding (optional; only if needed for round-trips)
- [x] Provide JSONL helpers for goldens:
  - [x] parts -> `.jsonl` stable lines
  - [ ] `.jsonl` lines -> parts (only if decoding is implemented)

### 0.2.1 Golden fixtures conventions

- [x] Directory layout:
  - [x] `test/fixtures/v3_parts/<provider>/<scenario>.jsonl` (canonical parts goldens)
  - [x] `test/fixtures/v3_parts/<provider>/<scenario>.meta.json` (human notes + assertions)
- [x] Golden stability rules:
  - [x] Prefer deterministic ids (counter-based) when providers do not supply ids.
  - [x] Preserve provider-only fields under `providerMetadata` or `raw` only.
  - [x] Redact very large base64-like blobs in goldens (hash + length) to keep repo size manageable.

### 0.3 Ensure orchestration emits v3-consistent boundaries

- [ ] In `llm_dart_ai` (`packages/llm_dart_ai/lib/src/stream_parts.dart`):
  - [ ] Inject `stream-start` exactly once (already done via `ensureStreamStartPart`)
  - [x] Inject/normalize missing block ids (text/reasoning/tool input) via `ensure_block_ids.dart`
  - [ ] Ensure exactly one final `finish` part at end of stream (only if providers ever emit multiple finish events)

---

## P0 (must-do): Tool loop parity (semantic)

### 1.1 Typed tool call lifecycle (AI SDK-style)

- [x] Add canonical representation for:
  - [x] parsed tool calls (`tool-call`) via `LLMToolCall*Part` + v3 codec mapping
  - [x] tool results (`tool-result`) via `LLMToolResultPart`
  - [x] tool errors via `tool-result.isError=true`
  - [x] “invalid tool call” behavior (best-effort) in local tool loop (invalid JSON / schema mismatch / unknown tool)
- [x] Update `llm_dart_ai` tool loop to emit canonical tool lifecycle parts for streaming APIs:
  - [x] stream: `streamToolLoopParts*`
  - [ ] non-stream: `runToolLoop*` (if/when we expose tool events)

### 1.2 Optional repair hook (fearless-friendly)

- [x] Add optional hook(s) to tool loop / streaming transformer:
  - [x] `parseToolCall` (decode + schema validation; invalid tool calls emit error results)
  - [x] `repairToolCall` (user-provided strategy; default is strict/no-repair)
  - [x] Provide conservative built-in strategy helpers (opt-in)

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

Current status (fixture-backed v3 golden tests in this repo):

- [x] OpenAI Responses (`packages/llm_dart_openai` via `responses.dart`)
- [x] OpenAI Chat Completions (SSE chat.completion.chunk streams)
- [x] Azure OpenAI (Responses API shape)
- [x] Anthropic (messages SSE; expand remaining fixtures)
- [x] OpenAI-compatible baseline (DeepSeek fixtures)
- [x] xAI Responses
- [x] Open Responses (LMStudio fixtures; OpenAI Responses stream shape)

Remaining (recommended next targets):

- [ ] Groq (OpenAI-compatible; add fixtures + goldens)
  - Note: AI SDK currently does not ship Groq `*.chunks.txt` fixtures; for Groq/Ollama/etc we should add small handcrafted contract fixtures under `test/fixtures/openai_compatible/` and keep `repo-ref` fixtures as the primary reference when available.
- [ ] Google Gemini (streaming + usage; align usage mapping)
- [ ] Ollama (streaming + usage; align usage mapping)
- [ ] Vertex AI (Google Vertex; usage + metadata)
- [ ] MiniMax / ElevenLabs (non-chat surfaces; define parity scope)

Recommended order:

1. OpenAI Responses (richest part surface)
2. Anthropic (reasoning/thinking + tool blocks)
3. OpenAI-compatible baseline (Azure/Groq/DeepSeek/xAI compatibility edge cases)

---

## P2: Execution plan (minimal tooling)

- [x] Add a small “golden generator” tool (repo-local):
  - [x] Reads selected `test/fixtures/**.chunks.txt` stream captures (sourced from AI SDK fixtures)
  - [x] Replays/decodes into canonical parts
  - [x] Writes `.jsonl` goldens under `test/fixtures/v3_parts/...` and ensures `.meta.json` exists
  - Entry point: `tool/update_v3_goldens.dart` (see `melos goldens:check` / `melos goldens:update`)
  - [x] Supports incremental updates via `--scenarios=a,b,c` to avoid full-suite runs
- [x] Add a “golden check” test harness:
  - [x] Loads expected `.jsonl`
  - [x] Compares canonical parts with stable normalization (key order, omitted nulls)
  - [x] Prints a minimal diff on mismatch (line + expected/actual)

---

## P2: Test plan (fixtures-first)

- [x] Add a v3-part golden test harness:
  - [x] input: replayable stream captures under `test/fixtures/**.chunks.txt` (sourced from AI SDK fixtures)
  - [x] expected: repo-local goldens under `test/fixtures/v3_parts/...`
  - [x] assertion: encoded canonical parts JSONL deep-equals expected JSONL
- [ ] Add targeted “nasty stream boundaries” fuzz tests:
  - [x] out-of-order `tool-input-delta` before tool-input start (OpenAI/Azure specific)
  - [ ] tool input JSON split across arbitrary chunk boundaries
  - [ ] usage arriving after finish_reason (common in OpenAI-compatible/Azure)

---

## P1: Fixture provenance + licensing hygiene

We intentionally reuse AI SDK fixtures/snapshots because they are the highest
signal spec we have for stream semantics.

- [x] Add an optional `upstream` block to each `*.meta.json`:
  - repository (e.g. `vercel/ai`)
  - commit hash / tag
  - original fixture path(s) in AI SDK
- [x] Track the pinned upstream reference commit:
  - update `test/fixtures/v3_parts/_upstream.json` when bumping `repo-ref/ai`
- [x] Document the “what to copy” rule:
  - prefer copying *only* the minimal fixtures that cover a semantic edge case
  - avoid bulk-copying entire snapshot suites to keep repo size manageable
- [x] Add a small helper script (optional) to sync/select fixtures from `repo-ref/ai`
  into `test/fixtures/**.chunks.txt` with stable naming.

### Anthropic fixture coverage notes (as of 2026-02-11)

We vendor AI SDK Anthropic `*.chunks.txt` fixtures under
`test/fixtures/anthropic/messages` and maintain matching v3 parts goldens.

Notable fixtures that validate usage and deferred tool search flows:

- `anthropic-message-delta-input-tokens.chunks.txt`
- `anthropic-tool-search-deferred-bm25.chunks.txt`
- `anthropic-tool-search-deferred-regex.chunks.txt`

Additional fixtures that validate provider-executed tools and dynamic tools:

- `anthropic-web-search-tool.1.chunks.txt` (server tool `web_search`)
- `anthropic-web-fetch-tool.1.chunks.txt` (server tool `web_fetch`)
- `anthropic-mcp.1.chunks.txt` (dynamic MCP tools)
- `anthropic-code-execution-20250825.1.chunks.txt`
- `anthropic-code-execution-20250825.2.chunks.txt`
- `anthropic-code-execution-20250825.pptx-skill.chunks.txt`
