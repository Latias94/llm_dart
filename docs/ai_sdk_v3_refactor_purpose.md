# AI SDK v3 Parity Refactor: Purpose

Status: Draft (fearless refactor, breaking changes allowed)  
Last updated: 2026-02-10

This document defines the **purpose**, **goals**, and **non-goals** of the
ongoing refactor to align `llm_dart`'s streaming/event data structures with the
Vercel AI SDK v3 stream part model (vendored under `repo-ref/ai`).

Primary references:

- Vercel AI SDK repository: `https://github.com/vercel/ai` (Apache-2.0)
- AI SDK v3 stream parts (canonical): `repo-ref/ai/packages/provider/src/language-model/v3/language-model-v3-stream-part.ts`
- AI SDK v3 sources/files/finish reason:
  - `repo-ref/ai/packages/provider/src/language-model/v3/language-model-v3-source.ts`
  - `repo-ref/ai/packages/provider/src/language-model/v3/language-model-v3-file.ts`
  - `repo-ref/ai/packages/provider/src/language-model/v3/language-model-v3-finish-reason.ts`
- Our standard surface: `docs/standard_surface.md`
- Streaming unification tracker: `docs/streaming_unification_todo.md`
- Provider parity tracker: `docs/provider_ai_sdk_parity_todo.md`

## Repo layout mapping (AI SDK -> llm_dart)

This refactor intentionally follows the AI SDK split between:

- **canonical model** (parts + semantics)
- **provider adapters** (request compilation + stream parsing)
- **orchestration** (tool loops + normalization)

Approximate mapping:

| AI SDK (repo-ref/ai) | llm_dart package(s) | Notes |
| --- | --- | --- |
| `packages/provider` | `packages/llm_dart_core` | Canonical part types (`LLMStreamPart`, finish reasons, usage) |
| `packages/provider` | `packages/llm_dart_provider_utils` | Shared emitters/codecs/dedupe (sources, tool parts, stable JSON) |
| `packages/ai` (high-level) | `packages/llm_dart_ai` | Dart-flavored tasks + tool loops + normalization |
| `packages/openai` | `packages/llm_dart_openai` + `packages/llm_dart_openai_compatible` | Responses API parsing is the parity anchor |
| `packages/anthropic` | `packages/llm_dart_anthropic` + `packages/llm_dart_anthropic_compatible` | Messages SSE -> canonical parts |
| `packages/xai` | `packages/llm_dart_xai` | Responses-like mapping + fixtures |

`repo-ref/ai` is used as a **read-only reference** and as a source of fixtures;
it is not part of the published Dart API surface.

---

## Why we are doing this

We want `llm_dart` to:

1. Keep a **small, stable, provider-agnostic “standard surface”** (Vercel-style).
2. Enable **fearless refactors** without constantly breaking provider behavior.
3. Use vendored AI SDK fixtures (`repo-ref/ai`) to provide **high-signal offline
   conformance tests** for streaming semantics.

The fastest way to achieve (2) and (3) is to converge on AI SDK's v3 stream part
model as a **canonical internal representation**, while keeping the public Dart
APIs idiomatic and intentionally narrow.

---

## North-star outcome

### 1) Canonical data model parity (internal)

Our `LLMStreamPart` (or a dedicated v3-compatible sibling type) can represent
every AI SDK v3 part **losslessly**, including:

- `stream-start` (with warnings)
- `response-metadata`
- text blocks (`text-start|delta|end`)
- reasoning blocks (`reasoning-start|delta|end`)
- tool input stream (`tool-input-start|delta|end`)
- tool call + result (`tool-call|tool-result`) and tool errors via `tool-result.isError=true`
- sources (`source` with `sourceType: url|document`)
- generated files (`file`)
- raw passthrough (`raw`)
- errors (`error`) as *streamable* parts (not strictly terminal)
- finish (`finish` with typed `usage` + typed `finishReason`)

### 2) Public API stays Dart-flavored (external)

We keep the external task APIs and tool loop ergonomics:

- Tasks: `llm_dart_ai` (`generateText`, `streamChatParts`, `generateObject`, tool loops, …)
- Prompt IR stays provider-agnostic and Dart-friendly
- Provider escape hatches remain:
  - request-time: `providerOptions` / `providerTools`
  - response-time: `providerMetadata`

The internal v3 parity should not force users to write TypeScript-style code.

---

## Key decisions (recorded constraints)

These are the “hard edges” that keep us close to AI SDK v3 while still being
Dart-friendly:

1. **Tool names come from the request** (when available):
   - Provider-native tool `toolName` is resolved from `LLMConfig.providerTools[*].name`.
   - When absent, we fall back to provider tool type (e.g. `web_search`).
2. **Provider tool deltas are debug-only by default**:
   - `LLMProviderToolDeltaPart` emission is opt-in via provider option
     `emitProviderToolDeltas=true` (default `false`).
3. **`providerExecuted` is semantic, not decorative**:
   - Encode `providerExecuted` only when it is `true` in v3 JSON.
   - Omit it for client-executed tool calls (e.g. “local shell” style).
4. **MCP approval request semantics match AI SDK**:
   - `approvalId` is provider-issued (e.g. `mcpr_*`).
   - `toolCallId` is a stable stream-local id (e.g. `id-0`) and is **not**
     required to equal `approvalId`.
   - `toolName` uses the `mcp.<name>` prefix and the tool call is `dynamic=true`.
5. **Sources are deduped and get stable ids**:
   - Source ids use the `id-<seq>` prefix for fixture parity and determinism.

---

## Goals (what “done” means)

### G0: Stable fixture-driven tests

Given a vendored AI SDK fixture (or replay text fixture), we can:

- Parse provider output into v3-compatible parts
- Serialize to a stable JSON(-lines) representation
- Compare against expected golden output (order + critical fields)

### G1: Semantic parity for streaming/tooling

We converge on AI SDK semantics for the tricky parts:

- Block boundaries and stable block ids (text/reasoning/tool input)
- Tool call parsing and “invalid tool call” behavior (best-effort)
- Provider-executed tools are never surfaced as locally executable tool calls
- Finish usage + finishReason are always emitted in a single final `finish` part
  (and never prematurely)

### G2: Provider adapters become thinner

Providers should focus on:

- Request compilation
- Transport + streaming parsing
- Mapping provider events into canonical parts

Everything else (tool loop orchestration, adapters, codecs) should live in
shared packages:

- `llm_dart_core` (types)
- `llm_dart_ai` (task APIs + orchestration)
- `llm_dart_provider_utils` (shared HTTP/SSE/JSONL/tooling helpers)

---

## Non-goals (explicitly not doing)

- **Not** building a “unified API that exposes every provider feature”.
  Provider-specific behavior remains behind escape hatches.
- **Not** aiming for byte-for-byte equality of raw SSE/HTTP chunks.
  We test the **post-parse canonical parts**.
- **Not** maintaining per-model capability matrices.
  If a provider rejects a request, we surface the provider error.
- **Not** making Dart APIs mimic the AI SDK API surface.
  Only the internal canonical **data shape and semantics** converge.

---

## Design principles

1. **Canonical parts are complete**: every provider stream can be mapped to the
   canonical model, even if some fields are best-effort.
2. **Lossless where possible**: when a provider emits extra data, preserve it
   via `providerMetadata` or `raw` parts, not by inventing new “standard” fields.
3. **Order is a contract**: part ordering is validated via fixtures and must
   be stable across refactors.
4. **Idiomatic Dart externally**: public APIs remain simple, typed, and
   discoverable; internal parity does not leak into user-facing ergonomics.

---

## Success metrics

- We can replay AI SDK fixtures and pass offline conformance tests for:
  - ordering of parts
  - finish semantics (usage + finishReason)
  - tool call parsing behavior
  - sources/files parts (when provider supports them)
- Provider packages no longer need bespoke “reserved tool name” heuristics
  (use tool name mapping + canonical part types instead).

---

## Appendix A: V3 Stream Part Mapping Table (Contract)

This table defines the **target contract** for our canonical stream parts.
The canonical reference is AI SDK v3:

- `repo-ref/ai/packages/provider/src/language-model/v3/language-model-v3-stream-part.ts`

Legend:

- **Required**: must be present in our canonical representation.
- **Best-effort**: populate when available; otherwise omit and/or preserve via
  `providerMetadata` or `raw`.

### A.1 Common metadata fields

- `providerMetadata`:
  - Shape: a provider-id namespaced map.
  - Contract: never use it to expand the standard surface; preserve provider-only
    fields here when not representable canonically.

### A.2 Part-by-part mapping

#### stream-start

- AI SDK: `type: 'stream-start'` + `warnings: SharedV3Warning[]`
- Contract:
  - Emit exactly once at the beginning of every stream.
  - Warnings are optional but must be a list (possibly empty).

#### response-metadata

- AI SDK: `type: 'response-metadata'` + `{ id?, timestamp?, modelId? }`
- Contract:
  - Emit as soon as response id/model/timestamp become available.
  - `timestamp` should be an ISO-8601 string in JSON representations.

#### text blocks

- AI SDK:
  - `text-start` with `id` (required)
  - `text-delta` with `id` + `delta`
  - `text-end` with `id`
- Contract:
  - `id` must be non-empty for every text part.
  - Preserve `providerMetadata` on boundaries and deltas when available.

#### reasoning blocks

- AI SDK:
  - `reasoning-start` with `id` (required)
  - `reasoning-delta` with `id` + `delta`
  - `reasoning-end` (AI SDK includes no `id` on end in provider v3; downstream
    transformations often still associate it with a block id)
- Contract:
  - We treat reasoning as a block with a stable id, and we must keep that id
    consistently across start/delta/end in our canonical representation.
  - If a provider has no explicit id, inject one deterministically.

#### tool input stream

- AI SDK:
  - `tool-input-start` with `id` + `toolName` (+ flags)
  - `tool-input-delta` with `id` + `delta` (string)
  - `tool-input-end` with `id`
- Contract:
  - `delta` is always a string (raw JSON string fragments are allowed).
  - `id` must be non-empty for every tool-input part.
  - Preserve `dynamic`, `title`, and provider-executed flags if present.

#### tool-call / tool-result (and tool errors)

- AI SDK emits typed tool call and result parts in the AI-layer transformation.
- Contract:
- A canonical stream must be able to represent:
    - Parsed tool calls (`tool-call`)
    - Tool results (`tool-result`)
    - Tool errors (represented as `tool-result` with `isError: true` at the
      provider-v3 layer; a higher-level AI-layer `tool-error` part can be
      introduced later if we add a transformation API similar to Vercel's
      `generateText`/`streamText`)
    - Invalid tool calls (best-effort flags + error payload)
  - Provider-executed tools must never be surfaced as locally executable calls.

#### source

- AI SDK: `type: 'source'` + `sourceType: 'url'|'document'` + fields
- Contract:
  - Preserve `sourceId`/`id`, and keep a stable mapping for citations.
  - Preserve provider-only citation fields via `providerMetadata`.

#### file

- AI SDK: `type: 'file'` with `{ mediaType, data }` (base64 or bytes)
- Contract:
  - Preserve the media type and raw payload without lossy conversions.
  - For `.jsonl` goldens (JSON-only), we encode raw bytes as base64 strings for
    determinism and portability; runtime stream parts may still carry `Uint8List`.

#### raw

- AI SDK: `type: 'raw'` + `rawValue: unknown`
- Contract:
  - Used as an escape hatch for debugging and fixture comparisons when needed.
  - Not required in all streams, but must be supported.

#### error

- AI SDK: `type: 'error'` + `error: unknown` (may occur multiple times)
- Contract:
  - Errors are streamable parts (not necessarily terminal).
  - A stream may still end with a `finish` after non-fatal errors, depending on
    provider semantics.

#### finish

- AI SDK: `type: 'finish'` + `{ usage, finishReason, providerMetadata? }`
- Contract:
  - Emit exactly once, and only after all other parts that belong to the
    response are delivered.
  - `finishReason` must be typed as `{ unified, raw }` semantics (AI SDK v3).
  - `usage` should be encoded in the AI SDK v3 shape:
    - `inputTokens`: `total/noCache/cacheRead/cacheWrite` (when available)
    - `outputTokens`: `total/text/reasoning` (when available; `text` may be derived as `total - reasoning`)
    - `raw`: preserve the provider usage object when available (best-effort)

---

## Appendix B: Fixture Alignment Contract (What we test)

We explicitly test **post-parse canonical parts**, not raw network data.

- We do **not** assert on raw SSE chunk boundaries, timing, or transport-level
  details.
- We **do** assert on:
  - part ordering
  - required fields per part type
  - finish semantics (single final `finish` with typed `usage` + typed `finishReason`)
  - tool lifecycle semantics (input stream, parsing, invalid calls, results)
  - preservation of provider-only data via `providerMetadata` and/or `raw`

Golden format recommendation:

- JSON Lines (`.jsonl`): one canonical part per line as a JSON object.
- Store goldens under `test/fixtures/v3_parts/<provider>/<scenario>.jsonl`.
