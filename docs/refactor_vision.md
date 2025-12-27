# LLM Dart Refactor Vision (Vercel AI SDK-aligned)

This document is the **canonical north-star** for the ongoing fearless refactor:
the intended end-state, the key design trade-offs, and the MVP milestones that
get us there.

If something in code contradicts this document, either:

1) update the code to match the vision, or  
2) propose a decision change via an ADP in `docs/adp/`.

---

## Goals

- Keep `llm_dart` as an **all-in-one suite** (batteries included).
- Make **subpackage-only** usage first-class (pick only what you need).
- Keep the **standard surface** intentionally narrow and stable (Vercel-style).
- Support provider-specific innovation via **escape hatches**, not a bloated “one API for everything”.

## Non-goals

- A single unified API that exposes every provider feature.
- Maintaining provider/model capability matrices (“unsupported” should be owned by APIs).

---

## The Vercel-style split (how we map concepts)

Vercel AI SDK essentially splits:

- **Standard task APIs** (`generateText`, `streamText`, `generateObject`, `embed`, …)
- **Provider implementations** (OpenAI, Anthropic, Gemini, plus community providers)
- **Protocol reuse layers** (e.g. OpenAI-compatible)
- **Provider utils** (tool naming, transport helpers)

LLM Dart mirrors that, in Dart terms.

---

## Final architecture (target end-state)

### 1) `llm_dart_core` (types + capability traits)

Owns:

- Provider-agnostic types: `ChatMessage`, `ToolCall`, stream parts, cancellation.
- Capability traits: `ChatCapability`, `EmbeddingCapability`, `TextToSpeechCapability`, `SpeechToTextCapability`, etc.
- Escape hatch types:
  - `providerOptions` (request-time, namespaced by provider id)
  - `providerTools` (provider-executed tools, stable ids + options)
  - `providerMetadata` (response-time, namespaced by provider id)
  - `transportOptions` (HTTP/transport configuration)

Design rule:

- Core must not import providers (no core→provider coupling).

### 2) `llm_dart_ai` (standard surface)

Owns:

- Task APIs: `generateText`, `streamText`, `generateObject`, `embed`,
  `generateImage`, `generateSpeech`, `transcribe`, tool-loop orchestration.
- Provider-agnostic results and streaming parts.
- Prompt building recommended path: **Prompt IR**.

Design rule:

- Only tasks that are genuinely stable across providers belong here.

### 3) `llm_dart_provider_utils` (shared glue)

Owns:

- Transport helpers (Dio strategy glue, SSE/JSONL chunk parsing).
- Tool name mapping, collision-avoidance, and shared protocol utilities.

### 4) Protocol reuse layers (compatibility baselines)

Owns:

- `llm_dart_anthropic_compatible`: Anthropic Messages-wire-compatible transport + request builder.
- `llm_dart_openai_compatible`: OpenAI Chat Completions-wire-compatible transport + request builder.
  - (Next) Extract OpenAI Responses API as a parallel protocol path (OpenAI-only).

Design rule:

- Compatibility layers should be reusable by multiple “compatible providers”
  with minimal provider-specific adapters.

### 5) Provider packages

Owns:

- Concrete provider factories + thin adapters, one package per provider.

Provider taxonomy (Vercel-style):

- **Standard providers**: OpenAI / Anthropic / Google (Gemini)
- **Additional providers**:
  - Protocol-compatible providers (e.g. MiniMax → Anthropic-compatible)
  - OpenAI-compatible providers (DeepSeek/Groq/xAI/…)
  - Provider-native providers (Ollama, ElevenLabs, etc.)

### 6) Optional ergonomics

- `llm_dart_builder`: fluent config + registry building (opt-in).
- `llm_dart` umbrella: re-exports + default registration convenience (`ai()`).

---

## Standard vs provider-specific (the key trade-off)

### What is “standard”

We standardize **tasks**, not provider-specific features.

Standard tasks are things like:

- chat text generation (`generateText` / `streamText`)
- structured output (`generateObject`)
- embeddings (`embed`)
- images (`generateImage`)
- speech (`generateSpeech` / `transcribe`) **only if** we can keep semantics stable

### What is NOT “standard”

Provider-specific features (examples):

- web search / grounding tools
- cache controls
- “thinking” knobs / reasoning controls
- provider-specific streaming event details

These should be accessed via:

- `providerTools` (provider-native tool definitions)
- `providerOptions` (namespaced request knobs)
- `providerMetadata` (namespaced response outputs)

This is the same principle Vercel uses: only features with consistent semantics
graduate into the standard surface.

---

## Prompt model: `Prompt` vs `ChatMessage`

- `ChatMessage` is the **legacy message model** and the lowest-level surface.
- `Prompt` is our **Vercel-style prompt IR** (messages + typed parts + per-part providerOptions).

Rule of thumb:

- App code should prefer `Prompt`.
- Provider/protocol code may still use `ChatMessage` for exact wire semantics.

---

## MVP milestones (phased, shippable)

This repo already has a living checklist in `docs/roadmap.md`. The milestones
below are the “shape” we want to keep stable:

### MVP 0 — Unblock splitting (foundation)

- Remove core→provider coupling.
- Introduce escape hatches: `providerOptions`, `providerTools`, `providerMetadata`, `transportOptions`.

### MVP 1 — Anthropic-compatible baseline (first protocol layer)

- Make `llm_dart_anthropic_compatible` the first reusable protocol layer.
- Land a real consumer: MiniMax via Anthropic-compatible.

### MVP 2 — Prompt IR (adapter-first)

- Introduce `Prompt` IR and progressively route tasks/providers through it.
- Prefer `PromptChatCapability` / `PromptChatStreamPartsCapability` when available.

### MVP 3 — Provider tools as first-class (streaming + orchestration)

- Standard streaming parts should preserve tool lifecycle where possible.
- Tool loops should preserve provider-required assistant blocks across turns.

### MVP 4 — Expand protocol reuse + reduce duplication

- Extract OpenAI-compatible (Chat Completions) as a true reuse layer.
- Keep OpenAI Responses API as an OpenAI-only parallel protocol path.
- Keep provider packages thin (defaults + small adapters).

---

## Where to look next (in this repo)

- Target architecture + status snapshot: `docs/llm_dart_architecture.md`
- Standard surface definition: `docs/standard_surface.md`
- Living milestone checklist: `docs/roadmap.md`
- Decision log (ADPs): `docs/adp/README.md`

---

## Status snapshot (2025-12-23)

Recent high-signal changes:

- `llm_dart_ai` task APIs now use Vercel-style prompt inputs: `system` + exactly one of `prompt/messages/promptIr`.
- Legacy `*FromPromptIr` / `*FromPrompt` helpers are no longer exported by default and are deprecated:
  - Use `package:llm_dart_ai/legacy.dart` (or `package:llm_dart/legacy.dart`) if you still need them.
  - Planned removal: `0.12.0-alpha.1`.
- MiniMax (Anthropic-compatible) auth headers align with Vercel: `x-api-key` + `anthropic-version` (not `Authorization`).
- MiniMax provider is now a thin Anthropic-compatible wrapper (`MinimaxProvider`); protocol behavior lives in `llm_dart_anthropic_compatible`.
- Groq (OpenAI-compatible) request mapping aligns with Vercel providerOptions: `reasoningFormat`, `reasoningEffort`, `structuredOutputs`, `serviceTier`.
- Groq provider is now a thin OpenAI-compatible wrapper; chat/streaming is handled by `llm_dart_openai_compatible`.
- DeepSeek provider is now a thin OpenAI-compatible wrapper; chat/streaming is handled by `llm_dart_openai_compatible`.
- xAI provider is now a thin OpenAI-compatible wrapper; live search request mapping is handled by `llm_dart_openai_compatible`.
- Phind provider package exists as a thin OpenAI-compatible wrapper, but it is no longer shipped in the umbrella `llm_dart` package by default.
