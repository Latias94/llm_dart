# Streaming Unification TODO (Fearless Refactor)

Status: draft (breaking changes expected)  
Last updated: 2026-02-09

This document tracks the milestone plan to unify streaming across providers
in a Vercel AI SDK–aligned way.

Core principle:

- **`LLMStreamPart` is the single source of truth.**
- All legacy streaming APIs (e.g. `chatStream` with `ChatStreamEvent`) are
  adapters that are derived from parts.

---

## Design constraints (must hold)

1) **Local tool loop safety**
   - `ChatResponse.toolCalls` means “client-side function tools to execute locally”.
   - Provider-executed/server tools (web search, file search, code execution, etc.)
     must never be surfaced as local `toolCalls` in the final `ChatResponse`,
     otherwise tool loops may accidentally execute them.

2) **Deterministic block boundaries**
   - `text` / `reasoning` / `tool` blocks have a stable start→delta→end sequence.
   - Cross-chunk boundaries must be robust (SSE chunk splits, partial tags, partial JSON).

3) **Provider fidelity via typed parts**
   - Provider-only outputs should be observable without forcing everything into
     `providerMetadata` maps.

---

## Proposed breaking changes (high level)

### A) Expand `LLMStreamPart` to cover “AI SDK style” semantics

Add new parts (names are placeholders; exact naming TBD):

- `LLMStreamStartPart({List<Map<String, dynamic>> warnings})` (optional)
- `LLMResponseMetadataPart({String? id, String? model, String? status, String? systemFingerprint, Map<String, dynamic>? providerMetadata, Map<String, dynamic>? raw})`
- `LLMSourceUrlPart({String sourceId, String url, String? title, Map<String, dynamic>? providerMetadata})`
- `LLMSourceDocumentPart({String sourceId, String mediaType, String title, String? filename, Map<String, dynamic>? providerMetadata})`
- Provider-executed tools (server tools):
  - `LLMProviderToolCallPart(...)` (server tool call)
  - `LLMProviderToolResultPart(...)` (server tool result)
  - (optional) `LLMProviderToolDeltaPart(...)` for status/progress
  - (optional) `LLMProviderToolApprovalRequestPart(...)` for provider-executed approvals
- `LLMFinishPart` enhancement:
  - include `finishReason` + `usage` explicitly (not only via `ChatResponse.providerMetadata`)

Optional but valuable (for multi-block providers):

- add `blockId` to text/reasoning parts so multiple output blocks can be represented
  without flattening.

### A.1) Additional breaking cleanups (recommended)

- Remove providerMetadata alias proliferation over time:
  - Today we sometimes expose both a base key (e.g. `openai`) and capability aliases
    (e.g. `openai.chat`, `openai.responses`).
  - During the refactor, prefer a **single canonical key** per provider (e.g. `openai`,
    `azure`, `xai.responses`), and migrate callers to that.
- Make `finishReason` a real, typed value:
  - Stop forcing consumers to decode finish semantics from ad-hoc provider metadata.
  - Keep raw provider reason as an escape hatch.

### B) Keep legacy events as adapters (until removal)

- Keep `ChatStreamEvent` temporarily, but treat it as a compatibility layer.
- Implement `chatStream` by mapping `chatStreamParts` (never parse provider streams twice).
- Deprecate direct provider implementations of `chatStream` where possible.

### C) Tool loop understands provider tools

Two acceptable models (choose one, or support both):

1) Provider tools are stream-only (typed parts) + recorded in `providerMetadata`;
   tool loop ignores them entirely.
2) Provider tools share the “tool” lane but carry a `providerExecuted=true` marker;
   tool loop must explicitly skip them.

Recommendation: prefer (2) to match AI SDK ergonomics while remaining safe.

---

## Current state snapshot (dev-remote)

Already aligned in code:

- `openai-compatible chat` legacy stream derived from parts
- `anthropic-compatible` legacy streams derived from parts
- `google` legacy stream derived from parts
- `ollama` legacy stream derived from parts
- `xai.responses` legacy stream derived from parts
- Providers emit `LLMResponseMetadataPart` snapshots when stable metadata is available
- Google emits `toolWarnings` via `LLMStreamStartPart(warnings: ...)` when streaming
- Text/reasoning parts support optional `blockId` + per-part `providerMetadata` (AI SDK-style)
- `streamChatParts` / `streamToolLoopParts` emit `LLMStreamStartPart` (AI SDK-style)
- `LLMFinishPart` can carry typed `usage` + `finishReason`
- Added fuzz/fixture-style tests for chunk boundary robustness

Still has drift risk:

- (none in `dev-remote` at the moment; keep watching for dual parsing paths)

---

## Breaking surface inventory (what will likely change)

These changes are expected to break downstream code:

- `LLMStreamPart` gains new subclasses (pattern matching `switch` becomes non-exhaustive).
- `TextStreamPart` and legacy streaming helpers may need to ignore or expose new parts.
- `ChatStreamEvent` is expected to be deprecated and removed (timeline TBD).
- `GenerateTextResult` / `streamText` may change how they surface sources and finish reason.
- Provider metadata keys may change (canonicalization; alias removal).

---

## Milestones (TODO checklist)

### M0 — Decision + scope lock

- [ ] Decide: expand current `LLMStreamPart` vs introduce `LLMStreamPartV2`
- [ ] Define the “provider tool” representation (typed parts vs `providerExecuted` flag)
- [ ] Define `finishReason` unified mapping (or keep raw + best-effort unified)
- [x] Define source/citation typing (URLs, documents, provider-native citations)

### M1 — Core: stream parts & types (breaking)

- [x] Update `packages/llm_dart_core/lib/core/stream_parts.dart` with new parts
- [x] Add stable `finishReason` model (core) and propagate it through parts/results
- [x] Emit `LLMResponseMetadataPart` snapshots for key providers (OpenAI-compatible, Anthropic, Google, xAI)
- [x] Update `packages/llm_dart_ai/lib/src/stream_parts.dart` adapters accordingly
- [x] Update `packages/llm_dart_ai/lib/src/tool_loop.dart` parts-mode loop integration

Acceptance criteria:

- All existing providers still compile.
- New part types are not dropped silently in core adapters (explicitly handled/ignored).

### M2 — Tool loop safety upgrades

- [x] Ensure tool loop only executes “local function tools”
- [x] If provider tools are emitted as tool-like parts, add explicit skip rules
- [x] Add tests: provider tool parts never become `ChatResponse.toolCalls`

Acceptance criteria:

- It is impossible for a provider-executed tool to be executed locally by mistake.

### M3 — Provider migrations (single parsing path)

Priority order:

- [x] `openai-compatible responses`: derive legacy `chatStream` from `chatStreamParts`
- [x] `openai-compatible responses`: remove legacy stream event parser code
- [ ] `openai` + `azure` providers (Responses mode): ensure consistent parts semantics
- [x] `openai-compatible responses`: emit server tool calls via typed parts
- [x] `openai-compatible responses`: emit server tool approval request via typed parts (MCP)
- [x] `xai.responses`: emit citations/sources via typed parts
- [x] `xai.responses`: emit server tool calls via typed parts (call/result)
- [x] `google`/`vertex`: emit grounding sources via typed parts
- [x] `google`/`vertex`: emit provider tool parts for code execution (call/result)
- [x] `anthropic`/`anthropic-compatible`: emit citations via typed parts

Acceptance criteria:

- Each provider has exactly one streaming parser/state machine.
- Legacy streams are adapters only.

### M4 — Conformance tests (offline)

- [ ] Add “source part” conformance tests per provider that supports citations
- [x] Add source part tests for OpenAI Responses + Google grounding + xAI citations
- [ ] Add “provider tool part” conformance tests (web/file/search/code)
- [x] Add provider tool part tests for OpenAI Responses + xAI Responses
- [x] Add provider tool approval request tests for OpenAI Responses (MCP)
- [ ] Expand chunk-fuzz coverage to the new part types
- [x] Add a global “no drift” guard: `chatStream` must be derived from parts
- [x] Azure: add request mapping tests for `/responses` + `api-version` (v1 + deployment URL modes)

### M5 — Documentation + migration guide

- [ ] Update `docs/roadmap.md` MVP 3 status + link this tracker
- [ ] Add a migration guide (next alpha) describing new parts + adapter behavior
- [ ] Update provider docs to mention typed `source` and provider tool parts

Migration guide must include:

- Before/after examples for consuming streams (parts vs legacy events).
- How to access citations/sources after typed parts land.
- Tool loop changes and how to safely handle provider tools.

### M6 — Cleanup + removal window

- [ ] Deprecate legacy `ChatStreamEvent` surfaces (with a removal version target)
- [ ] Remove duplicate helpers and keep a single recommended streaming API

---

## Open questions

- Should we store `finishReason` on `ChatResponse` or only on `LLMFinishPart`?
- Should multi-block outputs be modeled (block ids) or flattened (status quo)?
- Should `providerMetadata` remain the escape hatch for raw data, even when typed parts exist?

---

## Suggested execution order (pragmatic)

1) Remove duplicate parsing paths (largest drift risk, lowest product impact)
   - Start with `openai-compatible responses`.
2) Add typed `source` parts (low risk, high UX value).
3) Add provider tool lifecycle parts + tool loop skip rules (safety-critical).
4) Add `finishReason` typing and unify mapping across providers.

---

## Provider parity checklist (AI SDK alignment)

Goal: for each provider, confirm we match the Vercel AI SDK behavior for:

- streaming endpoint + auth
- SSE parsing (chunk boundaries, `[DONE]`, multi-line `data:`)
- parts semantics (text/reasoning/tool start→delta→end)
- sources/citations parts (dedupe, stable ids)
- provider tool lifecycle parts (call/delta/result/approval)
- tool loop safety (provider tools never become local tool calls)
- usage + finishReason mapping (toolCalls vs providerExecuted tools)

Status notes (dev-remote, best-effort):

- OpenAI + Azure (Responses): covered by fixtures + provider-tool alias tests; Azure `/responses` request mapping includes `api-version`.
- OpenAI-compatible (Chat/Responses): has streaming usage tail + `[DONE]` conformance tests.
- Google + Vertex: covered by SSE fixtures, streaming endpoint/auth tests, grounding source parts, code execution provider tool parts.
- Anthropic (+ compatible): covered by Vercel fixtures, citations source parts, web tools/provider tool parts, fuzz tests.
- xAI (Responses): covered by custom_tool_call streaming parsing + citations + provider tool parts.
