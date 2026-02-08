# Streaming Unification TODO (Fearless Refactor)

Status: draft (breaking changes expected)  
Last updated: 2026-02-08

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

- `LLMStreamStartPart({List<String> warnings})` (optional)
- `LLMResponseMetadataPart({String? id, String? model, Map<String, dynamic>? raw})`
- `LLMSourcePart({String id, String sourceType, String url, String? title, Map<String, dynamic>? providerMetadata})`
- Provider-executed tools (server tools):
  - `LLMProviderToolStartPart(...)`
  - `LLMProviderToolDeltaPart(...)`
  - `LLMProviderToolResultPart(...)`
  - `LLMProviderToolEndPart(...)`
- `LLMFinishPart` enhancement:
  - include `finishReason` + `usage` explicitly (not only via `ChatResponse.providerMetadata`)

Optional but valuable (for multi-block providers):

- add `blockId` to text/reasoning parts so multiple output blocks can be represented
  without flattening.

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
- Added fuzz/fixture-style tests for chunk boundary robustness

Still has drift risk:

- `openai-compatible responses` has both `chatStream` and `chatStreamParts` parsing streams

---

## Milestones (TODO checklist)

### M0 — Decision + scope lock

- [ ] Decide: expand current `LLMStreamPart` vs introduce `LLMStreamPartV2`
- [ ] Define the “provider tool” representation (typed parts vs `providerExecuted` flag)
- [ ] Define `finishReason` unified mapping (or keep raw + best-effort unified)
- [ ] Define source/citation typing (URLs, file ids, provider-native citations)

### M1 — Core: stream parts & types (breaking)

- [ ] Update `packages/llm_dart_core/lib/core/stream_parts.dart` with new parts
- [ ] Add stable `finishReason` model (core) and propagate it through parts/results
- [ ] Update `packages/llm_dart_ai/lib/src/stream_parts.dart` adapters accordingly
- [ ] Update `packages/llm_dart_ai/lib/src/tool_loop.dart` parts-mode loop integration

### M2 — Tool loop safety upgrades

- [ ] Ensure tool loop only executes “local function tools”
- [ ] If provider tools are emitted as tool-like parts, add explicit skip rules
- [ ] Add tests: provider tool parts never become `ChatResponse.toolCalls`

### M3 — Provider migrations (single parsing path)

Priority order:

- [ ] `openai-compatible responses`: derive legacy from parts; remove duplicate parsing
- [ ] `openai` + `azure` providers (Responses mode): ensure consistent parts semantics
- [ ] `xai.responses`: emit citations/sources + server tool lifecycle via typed parts
- [ ] `google`/`vertex`: emit grounding sources via typed parts
- [ ] `anthropic`/`anthropic-compatible`: emit citations via typed parts

### M4 — Conformance tests (offline)

- [ ] Add “source part” conformance tests per provider that supports citations
- [ ] Add “provider tool part” conformance tests (web/file/search/code)
- [ ] Expand chunk-fuzz coverage to the new part types
- [ ] Add a global “no drift” guard: `chatStream` must be derived from parts

### M5 — Documentation + migration guide

- [ ] Update `docs/roadmap.md` MVP 3 status + link this tracker
- [ ] Add a migration guide (next alpha) describing new parts + adapter behavior
- [ ] Update provider docs to mention typed `source` and provider tool parts

### M6 — Cleanup + removal window

- [ ] Deprecate legacy `ChatStreamEvent` surfaces (with a removal version target)
- [ ] Remove duplicate helpers and keep a single recommended streaming API

---

## Open questions

- Should we store `finishReason` on `ChatResponse` or only on `LLMFinishPart`?
- Should multi-block outputs be modeled (block ids) or flattened (status quo)?
- Should `providerMetadata` remain the escape hatch for raw data, even when typed parts exist?

