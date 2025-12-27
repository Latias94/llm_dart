# llm_dart Roadmap (Vercel AI SDK-aligned)

This document captures the **target architecture** and a set of **incremental MVP milestones** for the ongoing fearless refactor.

Goals:

- Keep `llm_dart` as an “all-in-one” umbrella package.
- Also allow users to pick **individual subpackages** (providers, protocol layers, orchestration).
- Keep the “standard surface” intentionally **narrow** and stable (Vercel AI SDK style).
- Let provider-specific innovation ship via **escape hatches** (`providerOptions`, `providerTools`, `providerMetadata`).

Non-goals:

- A single unified API that exposes every provider feature.
- A hardcoded “support matrix” for provider-native features (if a provider errors, the provider errors).

---

## Target architecture (final form)

### Packages (conceptual mapping to Vercel AI SDK)

- `llm_dart_core`
  - Immutable types (messages, tools), capability traits, registry, cancellation, stream parts.
  - Escape hatch types: `providerOptions`, `providerTools`, `providerMetadata`, `transportOptions`.
- `llm_dart_ai` (standard surface)
  - Task APIs: `generateText`, `streamText`, `generateObject`, `embed`, `generateImage`, `generateSpeech`, `transcribe`, tool loop orchestration.
  - Provider-agnostic result types + `providerMetadata` passthrough.
- `llm_dart_provider_utils`
  - Transport helpers, request utilities, tool name mapping, protocol glue that multiple providers reuse.
- Protocol reuse layers
  - `llm_dart_anthropic_compatible` (Anthropic Messages-compatible baseline)
  - `llm_dart_openai_compatible` (OpenAI Chat Completions-compatible baseline)
- Provider packages
  - “standard” providers (e.g. `llm_dart_anthropic`)
  - “compatible” providers built on protocol layers (e.g. `llm_dart_minimax` → Anthropic-compatible)
- Optional ergonomics
  - `llm_dart_builder` (fluent config/registry builder)
  - `llm_dart` umbrella (re-export convenience)

### Interface split (standard vs provider)

- Standard tasks live in `llm_dart_ai` and operate on capability traits from `llm_dart_core`.
- Provider-specific functionality is accessed via:
  - `providerOptions` (request-time, provider-id namespaced)
  - `providerTools` (provider-executed tools; stable IDs + options)
  - `providerMetadata` (response-time, provider-id namespaced)

This mirrors Vercel’s approach: only truly stable cross-provider tasks graduate into the standard surface.

---

## Provider options propagation (Vercel-style)

We support a Vercel-like propagation model:

- `LLMConfig.providerOptions` (call defaults)
- `ChatMessage.providerOptions` (prompt-level overrides)
- `ToolCall.providerOptions` (tool-level overrides)

Recommended precedence:

1) explicit protocol fields already set (e.g. `cache_control` on a content block)
2) tool `providerOptions`
3) message `providerOptions`
4) config `providerOptions` (default)

---

## MVP milestones

### MVP 0 (foundation): monorepo split + escape hatches

Outcome:

- Packages split roughly like Vercel (`core` / `ai` / `provider-utils` / providers / protocol reuse).
- `transportOptions` becomes the only transport config entry point.
- `providerOptions` becomes the only provider-only knobs entry point (namespaced).

Status: done.

### MVP 1 (current): Anthropic-compatible as the first protocol baseline

Outcome:

- Treat Anthropic-compatible providers as first-class citizens via `llm_dart_anthropic_compatible`.
- Align provider-native tools to stable IDs + request-name mapping (`providerTools` + ToolNameMapping).
- Add prompt-level `providerOptions` propagation where it materially affects behavior (e.g. caching).

Status: in progress.

### MVP 2: Prompt parts model (Vercel-style prompt IR)

Outcome:

- Introduce a provider-agnostic prompt IR (parts) in `llm_dart_ai`:
  - text / image / file / tool-call / tool-result parts
  - part-level `providerOptions`
- Providers consume the prompt IR (or a lossless adapter), reducing the need for ad-hoc `extensions` content blocks.

Status: in progress (adapter-first).

Current implementation:

- Prompt IR types + adapter: `packages/llm_dart_core/lib/prompt/prompt.dart` (re-exported by `llm_dart_ai`)

### MVP 3: Provider tools become “first-class” in streaming + tooling

Outcome:

- Stream parts include provider tool lifecycle (start/delta/result) where supported.
- Shared `provider-utils` includes stable mapping logic and provider tool catalogs.

Status: planned.

### MVP 4: Expand protocol reuse + reduce provider duplication

Outcome:

- OpenAI-compatible baseline (Chat Completions) extracted and reused by compatible providers.
- OpenAI Responses API kept OpenAI-only (parallel protocol path).
- Providers become “defaults + small adapters” where possible.

Status: planned.

---

## Refactor status (living checklist)

- [x] Remove legacy `LLMConfig.extensions`; keep `providerOptions` + `transportOptions`.
- [x] Introduce `providerTools` + tool name mapping (Anthropic-compatible baseline).
- [x] Keep standard surface in `llm_dart_ai` (task APIs + tool loops).
- [x] Add prompt-level `providerOptions` on `ChatMessage` and `ToolCall`.
- [x] Deprecate `ChatMessage.extensions` for user code; keep as protocol-internal.
- [x] Add a Vercel-style prompt IR with part-level providerOptions (MVP 2).
- [x] Add task overloads/helpers that accept `Prompt` directly (MVP 2).
- [x] Streaming tool loops prefer prompt-native streaming when available (`PromptChatStreamPartsCapability` / `PromptChatCapability`).
- [x] Migrate standard examples/docs to `Prompt` (MVP 2).
- [x] Anthropic-compatible request builder covers PDF `FileMessage` and avoids silent “unsupported” substitutions.
- [x] Anthropic beta headers are Anthropic-only by default (safer for Anthropic-compatible providers like MiniMax).
- [x] Count-tokens requests reuse the request builder pipeline (no duplicate message conversion).
- [x] Adopt ADP-0004: no provider/model constraint matrices; forward best-effort and let APIs be the source of truth.
- [x] Remove Anthropic-compatible “ignored request keys” stripping (no silent dropping).
- [x] Move legacy OpenAI-compatible config/matrix types out of `llm_dart_core`.
- [x] Remove legacy `MessageBuilder` from core (Prompt IR is the replacement).
- [x] Hide legacy task helper aliases from default exports (use `package:llm_dart_ai/legacy.dart` or `package:llm_dart/legacy.dart`).
- [x] Deprecate `*FromPromptIr` / `*FromPrompt` helper aliases (planned removal: `0.12.0-alpha.1`).
