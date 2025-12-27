# ADP-0006: Standard Surface = `llm_dart_ai` Tasks + Prompt IR (Vercel-style)

## Context

`llm_dart` is a monorepo split into multiple packages (core, AI tasks, provider
utils, providers, and protocol reuse layers). The project goal is to stay an
**all-in-one suite** while also supporting **pick-and-choose subpackages**.

We want to align with the Vercel AI SDK philosophy:

- Keep a **narrow, stable, provider-agnostic** API surface.
- Treat provider-specific features as **escape hatches**.
- Reuse protocol layers (`anthropic-compatible`, `openai-compatible`) to avoid
  re-implementing the same wire logic across providers.

Provider scope note:

- Our “standard providers” (Vercel-style) are: **OpenAI**, **Anthropic**, and
  **Google (Gemini)**.
- Other providers can still be supported via protocol reuse layers or separate
  packages, but they do not define the standard surface.

## Problem

Historically, `llm_dart` exposed many provider methods directly (e.g.
`provider.chatStream(...)`) and users built prompts as `List<ChatMessage>`.

This creates drift and long-term maintenance risk:

- `ChatMessage` is already close to “wire format” and is hard to keep stable
  across providers and protocols (tool loops, multi-modal parts, caching
  markers, reasoning blocks).
- Providers differ in what they support and how they represent it. Promoting
  provider-specific knobs into a “unified API” forces an ever-growing surface
  area or a brittle support matrix.
- Without a stable prompt IR, we cannot evolve adapters without breaking user
  code.

## Decision

### 1) Standard surface lives in `llm_dart_ai`

We treat the **task APIs** in `package:llm_dart_ai/llm_dart_ai.dart` as the
primary stable surface:

- Text: `generateText`, `streamText`, `streamChatParts`
- Structured output: `generateObject`
- Tool loops: `runToolLoop`, `streamToolLoop`, `runToolLoopUntilBlocked`
- Embeddings: `embed`
- Images: `generateImage`
- Speech: `generateSpeech`, `streamSpeech`
- Transcription: `transcribe`, `translateAudio`

Provider capability methods (`ChatCapability.chatStream(...)`, etc.) remain
supported but are considered **low-level**.

### 2) Prompt IR is the recommended input type

We introduce and recommend a provider-agnostic prompt IR:

- `Prompt` / `PromptMessage` / `PromptPart`

Task APIs accept Vercel-style prompt inputs:

- `system` + exactly one of: `prompt` / `messages` / `promptIr`

The recommended path is passing `promptIr: Prompt(...)` to tasks directly.
Legacy helper aliases (e.g. `generateTextFromPromptIr`) remain available for
compatibility via `package:llm_dart_ai/legacy.dart` (not exported by default).
They are deprecated and planned to be removed in `0.12.0-alpha.1`.

Providers can optionally implement prompt-native traits
(`PromptChatCapability`, `PromptChatStreamPartsCapability`) so prompt parts can
remain lossless across adapter boundaries (instead of forcing
`Prompt.toChatMessages()`).

### 3) Provider-specific functionality uses escape hatches

We do not expand the standard surface to cover every provider feature. Instead:

- Request-time knobs: `LLMConfig.providerOptions[providerId]`
- Provider-executed tools: `LLMConfig.providerTools` (`ProviderTool`)
- Response passthrough: `ChatResponse.providerMetadata[providerId]`

This keeps the standard API small, while still enabling power users to access
provider features.

### 4) `ChatMessage` is protocol-level; keep it but stop promoting it

We keep `ChatMessage` and related “wire-like” types for:

- custom providers/capabilities
- protocol continuity where exact assistant blocks must be preserved

However, the recommended app-level flow is Prompt IR.

## Consequences

### Positive

- The standard surface is smaller, clearer, and closer to Vercel AI SDK.
- Prompt IR gives us room to evolve provider adapters without forcing users to
  author provider-shaped message blocks.
- Provider features ship without bloating the standard API (escape hatches).

### Trade-offs / Risks

- Some features will remain “provider-only” and require using escape hatches.
- Prompt IR introduces one more abstraction layer; we must keep its semantics
  stable and well-documented.
- Not all providers can be perfectly lossless when converting between prompt IR
  and protocol wire formats; prompt-native traits reduce but do not eliminate
  this risk.

## Migration plan

1. Prefer `llm_dart_ai` tasks in examples and documentation.
2. Prefer `Prompt` + task prompt inputs (`promptIr: ...`); keep `ChatMessage`
   for low-level users and protocol adapters.
3. Deprecate user-facing “wire format” shortcuts over time (e.g.
   `ChatMessage.extensions` in app code).
4. Keep the umbrella `llm_dart` package as a convenience bundle, but recommend
   `llm_dart_ai` + provider subpackages for new code.

## Open questions

- Should we add a lightweight `warnings` channel to task results (Vercel-style)
  for “best-effort forwarded” settings?
- How far should prompt IR go for modalities (video/audio segments, PDFs, etc.)
  before it becomes too provider-shaped?
