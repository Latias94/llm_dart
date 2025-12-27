# Provider Options Reference (Draft)

This document is the **single source of truth** for `LLMConfig.providerOptions`
keys supported by each provider package.

`providerOptions` can also be attached at the prompt layer (Vercel AI SDK style):

- `ChatMessage.providerOptions` (per-message / per-part in our current model)
- `ToolCall.providerOptions` (per-tool-call / tool-result message parts)

Providers may apply prompt-level provider options as overrides or hints.

For HTTP/transport configuration (proxy, headers, timeouts), see:

- `docs/transport_options_reference.md`

Guiding rule (Vercel AI SDK style):

- Keep the standard API surface narrow
- Put provider-only knobs behind `providerOptions[providerId]`
- If a feature becomes truly stable and cross-provider, we can later promote it
  into the standard surface

---

## 1) Cross-provider conventions

These keys are *conventions*, not guarantees. Providers that support them should
use the same key names and compatible shapes.

### 1.0 Propagation (call / message / tool)

When a provider supports `providerOptions` at multiple layers, the recommended
precedence is:

1) Explicit protocol fields (e.g. a `cache_control` field that is already set on
   a content block)
2) Tool-call / tool-result `providerOptions`
3) Message `providerOptions`
4) Config-level `LLMConfig.providerOptions` (defaults)

Example (Anthropic-compatible prompt caching):

```dart
final messages = [
  ChatMessage.system(
    'System prompt (cached)',
    providerOptions: {
      'anthropic': {
        'cacheControl': {'type': 'ephemeral'},
      },
    },
  ),
  ChatMessage.user('Hello'),
];
```

### 1.1 `extraBody` / `extraHeaders`

- `providerOptions[providerId]['extraBody']`: `Map<String, dynamic>`
- `providerOptions[providerId]['extraHeaders']`: `Map<String, String>`

Used as an escape hatch to merge provider-native request fields/headers.

### 1.2 Web search (provider-native tool)

Web search is intentionally **not** standardized into a single abstraction.
Configure it via provider options and let the provider execute it server-side.

Recommended:

- Prefer `providerTools` (typed `ProviderTool` catalogs) when the provider offers a server-side tool.
- Use `providerOptions` as a legacy best-effort escape hatch.

Legacy keys:

- `providerOptions[providerId]['webSearchEnabled']`: `bool`
- `providerOptions[providerId]['webSearch']`: `Map<String, dynamic>` (**legacy best-effort**; prefer `providerTools`)

### 1.3 OpenAI-compatible (Chat Completions) optional params

For providers built on `llm_dart_openai_compatible` (including the pre-configured
`*-openai` registries such as `groq-openai`, `deepseek-openai`, `xai-openai`,
plus `google-openai` and `openrouter`), the compatibility layer
forwards a best-effort subset of OpenAI Chat Completions optional parameters.

These are **not** part of the standardized surface; providers may ignore or
reject them. Use `providerOptions[providerId]`:

- `reasoningEffort`: `String` (`low`/`medium`/`high`) → provider-specific mapping
  (typically `reasoning_effort`; OpenRouter uses `reasoning.effort`)
- `jsonSchema`: `StructuredOutputFormat` → `response_format` (OpenAI structured outputs)
- `embeddingEncodingFormat`: `String` → `encoding_format` (Embeddings)
- `embeddingDimensions`: `int` → `dimensions` (Embeddings)
- `frequencyPenalty`: `double` → `frequency_penalty`
- `presencePenalty`: `double` → `presence_penalty`
- `logitBias`: `Map<String, double>` → `logit_bias`
- `seed`: `int` → `seed`
- `parallelToolCalls`: `bool` → `parallel_tool_calls`
- `logprobs`: `bool` → `logprobs`
- `topLogprobs`: `int` → `top_logprobs`
- `verbosity`: `String` → `verbosity`
- `user`: `String` → `user` (overrides `LLMConfig.user` if both are set)

---

## 2) Provider namespaces

### 2.1 `openai`

Scope note:

- These keys apply to the **OpenAI provider package** (`llm_dart_openai`).
- `llm_dart_openai_compatible` intentionally targets the **Chat Completions**
  baseline only; it does not implement Responses semantics (see `docs/adp/0007-openai-responses-openai-only.md`).

Guide: [docs/providers/openai.md](providers/openai.md)

Common keys:

- `reasoningEffort`: `String` (`low`/`medium`/`high`)
- `jsonSchema`: `StructuredOutputFormat`
- `voice`: `String`
- `embeddingEncodingFormat`: `String`
- `embeddingDimensions`: `int`

OpenAI extras (Chat/Responses):

- `useResponsesAPI`: `bool`
- `previousResponseId`: `String`
- `builtInTools`: `List<Map<String, dynamic>>` (OpenAI Responses built-in tools)
- `include`: `List<String>` (Responses-only; extra response fields to include)
  - The SDK also auto-includes tool-related fields when the corresponding
    built-in tool is enabled (web search sources, file search results, computer use images).
- `frequencyPenalty`: `double`
- `presencePenalty`: `double`
- `logitBias`: `Map<String, double>`
- `seed`: `int`
- `parallelToolCalls`: `bool`
- `logprobs`: `bool`
- `topLogprobs`: `int`
- `verbosity`: `String`

Web search:

- `webSearchEnabled`: `bool`
- `webSearch`: `Map<String, dynamic>` (**legacy best-effort**; prefer `providerTools`)
- Behavior: when enabled/configured, forces `useResponsesAPI=true` and injects the `web_search_preview` built-in tool if missing. The SDK does **not** rewrite `model`; if a tool requires a specific model, the OpenAI API is the source of truth.

File search (Responses built-in tool):

- `fileSearchEnabled`: `bool`
- `fileSearch`: `Map<String, dynamic>` (OpenAI `file_search` tool config; supports `vectorStoreIds` / `vector_store_ids` + extra parameters)
- Behavior: when enabled/configured, forces `useResponsesAPI=true` and injects `file_search` into `builtInTools` if missing.

Computer use (Responses built-in tool):

- `computerUseEnabled`: `bool`
- `computerUse`: `Map<String, dynamic>` (requires `displayWidth`, `displayHeight`, `environment`; extra keys become tool parameters)
- Behavior: when enabled/configured, forces `useResponsesAPI=true` and injects `computer_use_preview` into `builtInTools` if missing.

### 2.2 `anthropic`

Guide: [docs/providers/anthropic.md](providers/anthropic.md)

Thinking/reasoning:

- `reasoning`: `bool`
- `thinkingBudgetTokens`: `int`
- `interleavedThinking`: `bool`

Request fields:

- `metadata`: `Map<String, dynamic>`
- `container`: `String`
- `mcpServers`: `List<Map<String, dynamic>>` (Anthropic MCP servers JSON)

Caching:

- `cacheControl`: `Map<String, dynamic>` (Anthropic cache_control shape)

Web search:

- `webSearchEnabled`: `bool`
- `webSearch`: `Map<String, dynamic>` (**legacy best-effort**; prefer `providerTools`)

Web fetch:

- `webFetchEnabled`: `bool`
- `webFetch`: `Map<String, dynamic>` (**legacy best-effort**; prefer `providerTools`)
- Note: `web_fetch_20250910` requires the beta header `anthropic-beta: web-fetch-2025-09-10`.
  `llm_dart_anthropic` auto-adds it when provider-native web fetch is enabled.

### 2.3 `minimax` (Anthropic-compatible)

MiniMax reads its own namespace first and may fall back to `anthropic` for
shared Anthropic shapes.

Guide: [docs/providers/minimax.md](providers/minimax.md)

- Official Anthropic-compatible base URLs (MiniMax docs):
  - International: `https://api.minimax.io/anthropic` (LLM Dart normalizes to `/anthropic/v1/`)
  - China: `https://api.minimaxi.com/anthropic` (LLM Dart normalizes to `/anthropic/v1/`)
- Auth headers are Anthropic-compatible by default:
  - `x-api-key: <MINIMAX_API_KEY>`
  - `anthropic-version: 2023-06-01`
- Model ids are MiniMax-specific (MiniMax docs); common values include:
  - `MiniMax-M2.1` (default in `llm_dart_minimax`)
  - `MiniMax-M2.1-lightning`
  - `MiniMax-M2`, `MiniMax-M1`, `MiniMax-M1-80k`

- Supports all keys listed under `anthropic` via `providerOptions['minimax']`
  (with optional fallback to `providerOptions['anthropic']`)
- Escape hatches: `providerOptions['minimax']['extraBody']` / `extraHeaders`
- Provider-native web search/tooling support (Anthropic `web_search_*` / `web_fetch_*`)
  is provider-dependent; LLM Dart does not maintain an “unsupported matrix”.
- MiniMax may ignore some Anthropic request fields at the API layer; LLM Dart does
  not strip parameters and forwards requests best-effort.

Example (recommended):

```dart
final config = LLMConfig(
  apiKey: 'MINIMAX_API_KEY',
  baseUrl: minimaxAnthropicV1BaseUrl,
  model: minimaxDefaultModel,
  providerOptions: {
    'minimax': {
      // Same shape as Anthropic-compatible options (best-effort).
      'reasoning': true,
      'thinkingBudgetTokens': 512,

      // Escape hatches.
      'extraHeaders': {
        'x-trace-id': 'trace-123',
      },
      'extraBody': {
        // Provider-specific request keys (forwarded as-is).
        'foo': 'bar',
      },
    },
  },
);
```

### 2.4 `google`

Guide: [docs/providers/google.md](providers/google.md)

Thinking/reasoning (Gemini-native):

- `includeThoughts`: `bool`
- `thinkingBudgetTokens`: `int`
- `reasoningEffort`: `String` (`low`/`medium`/`high`)

Generation:

- `candidateCount`: `int`
- `enableImageGeneration`: `bool`
- `responseModalities`: `List<String>` (e.g. `['TEXT','IMAGE']`)
- `safetySettings`: `List<Map<String, dynamic>>` or `List<SafetySetting>`
- `maxInlineDataSize`: `int` (bytes; default: 20MB)

Embeddings (Gemini-native):

- `embeddingTaskType`: `String`
- `embeddingTitle`: `String`
- `embeddingDimensions`: `int`

Web search:

- `webSearchEnabled`: `bool`
- `webSearch`: `Map<String, dynamic>` (**legacy best-effort**; prefer `providerTools`)

### 2.5 `google-openai` (OpenAI-compatible)

Gemini via OpenAI-compatible interface reads:

1) `providerOptions['google-openai']`
2) fallback to `providerOptions['google']`

Supported keys (same as `google` thinking subset):

- `includeThoughts`: `bool`
- `thinkingBudgetTokens`: `int`
- `reasoningEffort`: `String`

### 2.6 `openrouter` (OpenAI-compatible)

Guide: [docs/providers/openrouter.md](providers/openrouter.md)

Web search:

- `webSearchEnabled`: `bool`
- `webSearch`: `Map<String, dynamic>` (**legacy best-effort**; prefer setting `:online` explicitly)
- `useOnlineShortcut`: `bool` (legacy; no longer rewrites the model)

### 2.7 `groq` / `groq-openai` (OpenAI-compatible)

Guide: [docs/providers/groq.md](providers/groq.md)

Namespace note:

- Provider package: `providerOptions['groq']`
- OpenAI-compatible registry: `providerOptions['groq-openai']`

Groq follows the Vercel AI SDK provider option shapes and maps them to the
OpenAI Chat Completions request body:

- `reasoningFormat`: `String` (`parsed`/`raw`/`hidden`) → `reasoning_format`
- `reasoningEffort`: `String` (`low`/`medium`/`high`/`none`/`default`) → `reasoning_effort`
- `structuredOutputs`: `bool` (default: `true`)
  - When `true` and `jsonSchema` is set: uses `response_format.type=json_schema`
  - When `false` and `jsonSchema` is set: uses `response_format.type=json_object`
- `parallelToolCalls`: `bool` → `parallel_tool_calls`
- `user`: `String` → `user` (overrides `LLMConfig.user` if both are set)
- `serviceTier`: `String` (`on_demand`/`flex`/`auto`) → `service_tier`
  - Overrides the standard `LLMConfig.serviceTier` (OpenAI semantics) when set.

### 2.8 `xai` / `xai-openai` (OpenAI-compatible)

Guide: [docs/providers/xai.md](providers/xai.md)

Namespace note:

- Provider package: `providerOptions['xai']`
- OpenAI-compatible registry: `providerOptions['xai-openai']`

Live search:

- `liveSearch`: `bool`
- `searchParameters`: `SearchParameters` JSON
- `webSearchEnabled`: `bool`
- `webSearch`: `Map<String, dynamic>` (converted into `SearchParameters`, **legacy best-effort**; prefer `searchParameters`)

Embeddings:

- `embeddingEncodingFormat`: `String`
- `embeddingDimensions`: `int`

### 2.8.1 `xai.responses` (Responses API)

Guide: [docs/providers/xai.md](providers/xai.md)

Namespace note:

- Responses provider id: `providerOptions['xai.responses']`

Responses-only knobs (best-effort):

- `store`: `bool`
- `previousResponseId`: `String` → `previous_response_id`
- `parallelToolCalls`: `bool` → `parallel_tool_calls`

Server-side tools should be configured via `LLMConfig.providerTools` (not
`providerOptions`).

### 2.9 `deepseek` / `deepseek-openai` (OpenAI-compatible)

Guide: [docs/providers/deepseek.md](providers/deepseek.md)

Namespace note:

- Provider package: `providerOptions['deepseek']`
- OpenAI-compatible registry: `providerOptions['deepseek-openai']`

OpenAI-style extras:

- `logprobs`: `bool`
- `topLogprobs`: `int`
- `frequencyPenalty`: `double`
- `presencePenalty`: `double`
- `responseFormat`: `Map<String, dynamic>`
  - Forwarded to the Chat Completions request as `response_format` (best-effort; DeepSeek is the source of truth).

### 2.10 `elevenlabs`

Guide: [docs/providers/elevenlabs.md](providers/elevenlabs.md)

Voice settings:

- `voiceId`: `String`
- `stability`: `double`
- `similarityBoost`: `double`
- `style`: `double`
- `useSpeakerBoost`: `bool`

### 2.11 `ollama`

Guide: [docs/providers/ollama.md](providers/ollama.md)

Local runtime knobs:

- `numCtx`: `int`
- `numGpu`: `int`
- `numThread`: `int`
- `numa`: `bool`
- `numBatch`: `int`
- `keepAlive`: `String`
- `raw`: `bool`
- `reasoning`: `bool`

Structured output:

- `jsonSchema`: `StructuredOutputFormat`

<!-- Phind support has been removed from the umbrella package (`llm_dart`).
     Keep using the OpenAI-compatible escape hatches for providers that are
     still shipped. -->
