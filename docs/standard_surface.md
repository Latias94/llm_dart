# Standard Surface (What is "Unified" in llm_dart?)

This document defines the intentionally **narrow and stable** “standard surface”
of `llm_dart`, inspired by Vercel AI SDK.

Goal:

- Keep the cross-provider API small and predictable.
- Let provider-specific features evolve behind escape hatches.

Non-goal:

- A single unified API that exposes every provider feature.

Provider scope note:

- The “standard providers” set is intentionally small (Vercel-style):
  **OpenAI**, **Anthropic**, and **Google (Gemini)**.
- Additional providers can be supported, but they should use protocol reuse
  layers and escape hatches rather than expanding the standard surface.

---

## 1) Recommended standard entrypoint: `llm_dart_ai`

For most users, the recommended “standard” APIs are the **task functions** in:

- `package:llm_dart_ai/llm_dart_ai.dart`

Stable tasks (current):

- Text: `generateText`, `streamChatParts`
- Tool loop orchestration: `runToolLoop`, `streamToolLoopParts`, `runToolLoopUntilBlocked`
- Structured output: `generateObject`
- Embeddings: `embed`
- Rerank: `rerank` (and `rerankByEmbedding` as a best-effort fallback)
- Images: `generateImage`
- Speech (TTS): `generateSpeech`, `streamSpeech`
- Transcription (STT): `transcribe`, `translateAudio`

Prompt construction (Vercel-style, adapter-first):

- `Prompt` / `PromptMessage` / `PromptPart` (compile to `List<ChatMessage>` today)
- Prompt IR file references:
  - Inline bytes: `FilePart(mime, data, ...)`
  - URL reference: `FileUrlPart(mime, url, ...)`
  - Provider file id: `FileIdPart(mime, id, ...)`
  - Note: `FileUrlPart` / `FileIdPart` cannot be losslessly converted to legacy
    `ChatMessage`; tasks will require prompt-native capabilities.
- Task prompt inputs (Vercel-style):
  - `system` + exactly one of: `prompt` / `messages` / `promptIr`
  - Applies to text/object tasks and tool loop orchestration APIs.
- Tool loop streaming (recommended):
  - Prefer `streamToolLoopParts(..., promptIr: ...)` / `streamToolLoopPartsWithToolSet(..., promptIr: ...)`
  - Legacy `*FromPromptIr` / `*FromPrompt` aliases were removed as part of the fearless refactor cleanup

Provider support note:

- If a provider implements `PromptChatCapability` / `PromptChatStreamPartsCapability`, task APIs will prefer those methods and preserve prompt part structure without forcing `Prompt.toChatMessages()`.
- If a `Prompt` contains `FileUrlPart` / `FileIdPart` but the model does not
  implement the corresponding prompt capability, task APIs throw
  `InvalidRequestError` with guidance instead of falling back to legacy
  `ChatMessage` conversion.

Prompt vs `ChatMessage` (when to use which):

- Prefer `Prompt` for app-level prompt building:
  - It is our **stable prompt IR** and gives us room to evolve provider adapters
    without forcing users to hand-author provider-shaped message blocks.
  - It is the recommended “Vercel-style” path for long-term compatibility.
- Use `List<ChatMessage>` when you need the lowest-level surface:
  - Implementing custom providers/capabilities directly.
  - Replaying protocol-required assistant content blocks (e.g. tool loop
    continuity) where the adapter needs exact wire semantics.
- `MessageBuilder` was removed:
  - Prefer `Prompt` for app-level prompt composition.
  - Use `ChatMessage.*` factories if you need the legacy message model.
- Avoid using `ChatMessage.extensions` in user code:
  - It is deprecated for user code and reserved for protocol-internal blocks.
- Use prompt-scoped escape hatches sparingly:
  - `ChatMessage.providerOptions` / `ToolCall.providerOptions` are for
    message/tool-local provider knobs (e.g. caching markers, tool_result flags),
    not for general configuration.

Minimal examples:

```dart
// 1) Anthropic prompt caching (per-message)
final messages = [
  ChatMessage.user(
    'Summarize this document.',
    providerOptions: {
      'anthropic': {
        'cacheControl': {'type': 'ephemeral'},
      },
    },
  ),
];
```

```dart
// 2) Anthropic tool_result error flag (per tool result)
final toolResult = ToolCall(
  id: 'toolu_1',
  callType: 'function',
  function: const FunctionCall(
    name: 'fetch_url',
    arguments: '{"error":"upstream timeout"}',
  ),
  providerOptions: {
    'anthropic': {'isError': true},
  },
);

final messages = [
  ChatMessage.toolResult(results: [toolResult]),
];
```

These tasks take a provider model instance and return a provider-agnostic result
plus optional `providerMetadata` for provider-only outputs.

All tasks and capability methods accept a provider-agnostic `CancelToken?` for
best-effort cancellation.

### 1.1 Streaming (standardized parts)

The standard streaming representation is `LLMStreamPart` (Vercel AI SDK style).

Key points:

- Providers may implement `ChatStreamPartsCapability` directly.
- Legacy `chatStream()` / `ChatStreamEvent` was removed (breaking).
- Structural parts make streaming deterministic and inspectable:
  - `LLMStreamStartPart` (includes best-effort `warnings`)
  - `LLMResponseMetadataPart` (id/model/timestamp snapshots)
  - `LLMText*Part` / `LLMReasoning*Part` / `LLMToolCall*Part` boundaries
  - `LLMSourceUrlPart` / `LLMSourceDocumentPart` (citations / grounding)
  - Provider-executed tools as typed parts:
    - `LLMProviderToolCallPart` / `LLMProviderToolDeltaPart` /
      `LLMProviderToolResultPart` / `LLMProviderToolApprovalRequestPart`
  - `LLMFinishPart` (may carry typed `usage` + typed `finishReason`)

Safety rule:

- Local tool loops only execute **local function tools** (`ToolCall` /
  `LLMToolCall*Part`).
- Provider-executed tools are surfaced via `LLMProviderTool*Part` and must never
  be treated as local tool calls.

Note on capability reporting:

- `ProviderCapabilities.supports(...)` is a **best-effort hint**, not a guarantee.
- LLM Dart intentionally avoids maintaining per-provider/per-model “unsupported feature” matrices.
  If a provider/model rejects a parameter, tool, or modality, the API should return an error response.

---

## 2) What is NOT standard (escape hatches)

The following are intentionally **not** promoted into the standard surface
because semantics differ significantly between providers:

- Provider-native tools (web search / file search / computer use / grounding)
- Provider-specific caching controls
- Provider-specific reasoning/thinking knobs
- Raw provider protocol event shapes and provider-only response fields

Instead, use:

### 2.1 `providerOptions` (request-time)

- `LLMConfig.providerOptions[providerId]`

Reference:

- `docs/provider_options_reference.md`

### 2.2 `providerTools` (provider-executed tools)

- `LLMConfig.providerTools` (`ProviderTool`)

Reference:

- `docs/provider_tools_catalog.md`

### 2.3 `providerMetadata` (response-time)

- `ChatResponse.providerMetadata` (namespaced map; prefer the canonical key)

Reference:

- `docs/provider_escape_hatches.md`
- `docs/provider_metadata.md` (canonical key + alias policy)

### 2.4 Local tools (FunctionTool)

For provider-unsupported features (or when you want full control), use local
`FunctionTool`s executed by `llm_dart_ai` tool loops.

Recommendation:

- Put concrete tool implementations (web fetch, web search, file access, etc.)
  in your app code or in examples/recipes, and keep the SDK focused on the
  tool protocol + orchestration.

### 2.5 Transport utilities (advanced)

Low-level Dio utilities like `HttpConfigUtils` and `BaseHttpProvider` are not
part of the standard surface. Import them from:

- `package:llm_dart_provider_utils/llm_dart_provider_utils.dart`

---

## 3) Anthropic-compatible rule of thumb (Anthropic + MiniMax)

- If a feature requires provider-specific request JSON fields, prefer `providerOptions`.
- If a feature is a provider-executed tool, model it as `ProviderTool` (when supported).
- If a feature is not supported by the provider, the provider will typically return an API error; use a local `FunctionTool` if you need full control.

Example:

  - Anthropic `web_search_*` is provider-native and supported (configure via `providerTools`).
- MiniMax (Anthropic-compatible) may or may not support `web_search_*` provider-native tools depending on backend compatibility; LLM Dart does not hardcode an “unsupported matrix”.
