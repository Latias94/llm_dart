# Provider Escape Hatches Cookbook

This document standardizes how `llm_dart` exposes **provider-specific features** without expanding the core “unified” API surface.

For a per-provider key list, see:

- `docs/provider_options_reference.md`

The guiding principle (aligned with Vercel AI SDK) is:

- Keep “standard/unified” APIs **narrow and stable**
- Route provider-only innovation through:
  - **`providerOptions`** (request-time, provider-id namespaced)
  - **`providerMetadata`** (response-time, provider-id namespaced)

For some protocols, callers also need to persist a provider-specific assistant
message between tool loop steps (e.g. Anthropic thinking signatures). LLM Dart
supports this via `ChatResponseWithAssistantMessage`, which `llm_dart_ai`
tool loops will prefer when available.

---

## 1) Terminology

### 1.1 `providerId`

The canonical provider identifier used by the registry/builder, e.g.:

- `openai`, `groq`, `deepseek`, `xai`, `ollama`, `google`
- `xai.responses`: xAI Responses API (agentic tools)
- OpenAI-compatible registries (pre-configured): `groq-openai`, `deepseek-openai`, `xai-openai`
- `anthropic` (Anthropic standard)
- `minimax` (Anthropic-compatible provider)

### 1.1.1 Provider option namespaces (current)

Rule: provider-only knobs should be set under `providerOptions[providerId]`.

Some “compatible protocol” providers may also support a fallback namespace to
reduce duplication (documented below).

Current notable namespaces:

- `openai`: OpenAI-only + OpenAI “extra” knobs (Responses API, built-in tools, penalties, logprobs, etc.)
- `anthropic`: Anthropic Messages API knobs (thinking/reasoning, metadata/container/mcpServers, cacheControl, web search)
- `minimax`: Anthropic-compatible MiniMax knobs; reads `providerOptions['minimax']` first and may fall back to `providerOptions['anthropic']`
- `google`: Gemini-native provider knobs (thinking/reasoning, web search, embeddings)
- `google-openai`: Gemini via OpenAI-compatible interface; reads `providerOptions['google-openai']` first and falls back to `providerOptions['google']`
- `groq-openai` / `deepseek-openai` / `xai-openai`: pre-configured OpenAI-compatible provider ids (same key names as their provider-package counterparts, but namespaced by the `*-openai` provider id)
- `openrouter`: OpenRouter web search knobs (provider-specific; `:online` suffix is an OpenRouter detail)
- `xai`: Grok live search knobs
- `deepseek`: DeepSeek OpenAI-style extras (logprobs, penalties, responseFormat)
- `elevenlabs`: TTS knobs (voice settings)
- `ollama`: local Ollama knobs (numCtx/numGpu/keepAlive/raw, etc.)

### 1.2 `providerOptions` (request escape hatch)

`LLMConfig.providerOptions` is a JSON-like map that stores provider-only request knobs in a **provider-id namespace**:

```dart
LLMBuilder()
  .provider('minimax')
  .providerOptions('minimax', {
    'cacheControl': {'type': 'ephemeral'},
    'extraHeaders': {'x-foo': 'bar'},
    'extraBody': {'metadata': {'user_id': '123'}},
  });
```

Rules:

- Always namespace by `providerId`
- Prefer **lowerCamelCase keys**
- Provider packages should document their supported keys
- Treat `providerOptions` as the stable escape hatch for provider-only knobs.

#### 1.2.0 Prompt-level `providerOptions` (message / tool call)

In addition to config-level defaults, you can attach provider-specific options
directly to prompt items (aligned with Vercel AI SDK):

- `ChatMessage.providerOptions` (per message / per part in our current model)
- `ToolCall.providerOptions` (per tool call / tool result)

This is useful for provider-only knobs that are naturally *prompt-scoped*, such
as Anthropic prompt caching (`cache_control`).

Example:

```dart
final messages = [
  ChatMessage.system(
    'Cache this system prompt',
    providerOptions: {
      'anthropic': {'cacheControl': {'type': 'ephemeral'}},
    },
  ),
  ChatMessage.user('Hello'),
];
```

#### 1.2.1 Using `ProviderConfig` (convenience)

For some provider-only options, you can also use the fluent `ProviderConfig`
builder, which writes into `providerOptions` for the currently selected
provider:

```dart
registerOpenAI();

final provider = await LLMBuilder()
  .provider(openaiProviderId)
  .apiKey('...')
  .model('gpt-5-mini')
  .providerConfig((p) => p.frequencyPenalty(0.3).presencePenalty(0.2))
  .build();
```

### 1.3 `providerMetadata` (response escape hatch)

`ChatResponse.providerMetadata` is an optional provider-id namespaced map.

`llm_dart_ai.GenerateTextResult` forwards it:

```dart
final result = await generateText(...);
print(result.providerMetadata);
```

Recommended shape:

```json
{
  "minimax": {
    "id": "...",
    "model": "...",
    "stopReason": "..."
  }
}
```

---

## 2) Standard keys (cross-provider conventions)

These keys are not guaranteed to be supported by all providers, but when a provider supports them, it should use the same key names and compatible shapes.

### 2.0 Transport options (provider-agnostic)

HTTP/transport configuration is configured via:

- `LLMConfig.transportOptions` (preferred)
- `LLMBuilder.http((h) => ...)` (writes into `transportOptions`)

Reference:

- `docs/transport_options_reference.md`

### 2.0 Cancellation (standard)

Cancellation is part of the standard surface:

- All capability methods accept a provider-agnostic `CancelToken?`.
- Providers that use Dio (or another HTTP client) bridge this token internally.

Usage:

```dart
final token = CancelToken();
final future = provider.chat([ChatMessage.user('hi')], cancelToken: token);
token.cancel('user aborted');
await future;
```

Notes:

- LLM Dart does not attempt to standardize “what is cancellable” per provider.
  The underlying HTTP client/provider decides what can be interrupted.
- Cancellation detection should use `CancellationHelper.isCancelled(e)`.

### 2.1 `extraBody` (Map<String, dynamic>)

Merged into the outgoing request JSON body.

Use cases:

- Provider-only flags not worth standardizing
- Experimental vendor parameters
- Soft migration during refactors

### 2.2 `extraHeaders` (Map<String, String>)

Merged into request headers.

Use cases:

- Provider-specific routing headers
- Beta feature flags
- Observability headers

Notes:

- `extraBody/extraHeaders` should be provided via `providerOptions[providerId]`.
- Legacy `extensions['extraBody']` / `extensions['extraHeaders']` are not supported.

### 2.2.1 Legacy `ChatMessage.extensions` (deprecated)

`ChatMessage.extensions` is reserved for **protocol-internal** use (e.g. carrying
provider-native content blocks through legacy message conversion).

Notes:

- New user code should not write to `ChatMessage.extensions`.
- Prefer `Prompt` IR (`llm_dart_ai`) for prompt composition and `providerOptions`
  for provider-only knobs.

### 2.3 `cacheControl` (Anthropic-compatible shape)

When supported by an Anthropic-style provider, `cacheControl` uses Anthropic’s prompt caching shape, e.g.:

```json
{"type":"ephemeral"}
```

Notes:

- MiniMax (Anthropic-compatible) reads `providerOptions['minimax']['cacheControl']` first, then falls back to `providerOptions['anthropic']['cacheControl']`

### 2.3.1 Anthropic request fields (`metadata` / `container` / `mcpServers`)

These keys are **Anthropic-specific**, but shared by Anthropic-compatible providers, so they are configured via `providerOptions`:

- `providerOptions[providerId]['metadata']`: `Map<String, dynamic>` (merged into request `metadata`)
- `providerOptions[providerId]['container']`: `String` (request `container`)
- `providerOptions[providerId]['mcpServers']`: `List<AnthropicMCPServer>` JSON (request `mcp_servers`)

Notes:

- MiniMax (Anthropic-compatible) reads its own namespace first (e.g. `providerOptions['minimax']`) and may fall back to `providerOptions['anthropic']` for shared Anthropic shapes.

### 2.4 Web search: model-side (provider tool)

Web search is a good example of a feature that should **not** be forced into the standard API:

- Provider semantics vary (query formulation, citations, result limits, ranking, safety)
- Some providers implement it as a **server-side tool**
- Others implement it as a **built-in tool** or a **special search model**

Recommended rule:

- Treat web search as a **provider-native tool**.
- Do not try to execute it inside local tool loops.
- `LLMBuilder.enableWebSearch()` / `LLMBuilder.webSearch(...)` (and related helpers) have been removed; prefer explicit provider tools/escape hatches.

#### 2.4.0 Configuring provider-native web search (recommended: `providerTools`)

When a provider supports server-side web search / grounding / live search, configure it as a `ProviderTool`:

```dart
registerAnthropic();

await LLMBuilder()
  .provider(anthropicProviderId)
  .apiKey('...')
  .model('claude-sonnet-4-20250514')
  .providerTool(
    AnthropicProviderTools.webSearch(
      options: const AnthropicWebSearchToolOptions(maxUses: 2),
    ),
  )
  .build();
```

Alternatively, you can configure it via namespaced `providerOptions`:

```dart
registerGoogle();

final provider = await LLMBuilder()
    .provider(googleProviderId)
    .apiKey('...')
    .model('gemini-1.5-flash')
    .providerOptions('google', {
      'webSearchEnabled': true,
    })
    .build();
```

Prefer these keys (per-provider namespace):

- `providerOptions[providerId]['webSearchEnabled']`: `bool`
- `providerOptions[providerId]['webSearch']`: `Map<String, dynamic>` (**legacy best-effort**; prefer `providerTools`)

Notes:

- `webSearch` is intentionally a **provider-native** feature. Providers may interpret the same config differently.
- Legacy `extensions` keys for web search have been removed. Use `providerOptions` only.

##### OpenRouter (OpenAI-compatible): model `:online` shortcut

OpenRouter enables web search via the `:online` model suffix (provider-specific).
LLM Dart does not rewrite models automatically; set the suffix explicitly if you want it.

```dart
registerOpenAICompatibleProvider('openrouter');

await LLMBuilder()
  .provider('openrouter')
  .apiKey('...')
  .model('anthropic/claude-3.5-sonnet:online')
  .build();
```

Notes:

- `providerOptions['openrouter']['webSearchEnabled']` / `webSearch` are legacy escape hatches for app-side logic and examples.
- Prefer setting the model suffix explicitly, since OpenRouter treats this as a model-selection detail.

##### Anthropic (Messages API): `web_search_*` tool

Anthropic web search is a **server-side tool**. Configure it via `providerTools` and let the provider execute it:

```dart
registerAnthropic();

await LLMBuilder()
  .provider(anthropicProviderId)
  .apiKey('...')
  .model('claude-sonnet-4-20250514')
  .providerTool(
    AnthropicProviderTools.webSearch(
      toolType: 'web_search_20250305',
      options: const AnthropicWebSearchToolOptions(
        maxUses: 3,
        allowedDomains: ['example.com'],
        userLocation: AnthropicUserLocation(
          city: 'London',
          region: 'England',
          country: 'GB',
          timezone: 'Europe/London',
        ),
      ),
    ),
  )
  .build();
```

Notes:

- LLM Dart injects the provider-native `web_search_*` built-in tool into the outgoing request JSON when enabled/configured.
- Tool name collisions are handled via `ToolNameMapping` (a local function tool named `web_search` is automatically rewritten in the request, e.g. `web_search__1`).
- Use `toolType: 'web_search_YYYYMMDD'` to pin a specific Anthropic tool version.

##### MiniMax (Anthropic-compatible): web search (currently unsupported)

MiniMax's Anthropic-compatible endpoint may not support Anthropic provider-native `web_search_*` tools.

Notes:

- LLM Dart does not prevalidate provider-native tool support for Anthropic-compatible providers; if unsupported, the API will return an error response.
- For portable behavior, use a **local `FunctionTool`** for web search (tool loop executes it locally), or use a provider that supports provider-native web search.

##### Google (Gemini): `google_search` tool

```dart
registerGoogle();

await LLMBuilder()
  .provider(googleProviderId)
  .apiKey('...')
  .model('gemini-1.5-flash')
  .providerTool(
    GoogleProviderTools.webSearch(
      options: const GoogleWebSearchToolOptions(
        mode: GoogleDynamicRetrievalMode.dynamic,
        dynamicThreshold: 0.3,
      ),
    ),
  )
  .build();
```

Behavior:

- For Gemini 2 models, LLM Dart adds `{"googleSearch": {}}` to the request `tools`.
- For other Gemini models, LLM Dart adds `{"googleSearchRetrieval": {"dynamicRetrievalConfig": {...}}}` (when dynamic retrieval options are configured).

Tool name collisions are handled via `ToolNameMapping` (local tool names are rewritten only if they collide with provider-native tool names).

##### xAI (Grok): `search_parameters` / live search

Provide xAI-native `searchParameters` directly:

```dart
registerXAI();

await LLMBuilder()
  .provider(xaiProviderId)
  .apiKey('...')
  .model('grok-3')
  .providerOptions('xai', {
    'liveSearch': true,
    'searchParameters': SearchParameters.webSearch(maxResults: 5).toJson(),
  })
  .build();
```

In LLM Dart terms:

- Local tool loops (`llm_dart_ai`) are for **locally executable function tools**.
- Provider-native tools (e.g. Anthropic `web_search_20250305`, OpenAI `web_search_preview`) should be configured via provider packages/config and executed by the provider.
- Provider-only outputs should be read from `providerMetadata` (and `rawResponse` when necessary).

#### 2.4.1 OpenAI Responses: web search outputs (`providerMetadata['openai']`)

When using OpenAI Responses built-in web search tools, `llm_dart_openai` exposes provider-only outputs via:

- `providerMetadata['openai']['webSearchCalls']`: array of web search calls (provider-executed)
- `providerMetadata['openai']['annotations']`: aggregated `output_text.annotations` (e.g. URL citations) when present

Example shape:

```json
{
  "openai": {
    "id": "resp_...",
    "model": "gpt-4o-search-preview",
    "webSearchCalls": [
      {
        "id": "ws_...",
        "status": "completed",
        "action": { "type": "search", "query": "..." },
        "sources": [{ "type": "url", "url": "https://..." }]
      }
    ],
    "annotations": [{ "type": "url_citation", "url": "https://..." }]
  }
}
```

Notes:

- `action.type` is normalized to `search` / `openPage` / `findInPage` for convenience.
- Web search calls are **not** surfaced via `ChatResponse.toolCalls` (they are provider-executed).

#### 2.4.2 OpenAI Responses: other built-in tools (`providerMetadata['openai']`)

For other OpenAI Responses built-in tools, `llm_dart_openai` also exposes tool-call summaries via `providerMetadata`:

- `providerMetadata['openai']['fileSearchCalls']`: array of `file_search_call` items (including `queries` and optional `results` when included)
- `providerMetadata['openai']['computerCalls']`: array of `computer_call` items (id + status)

Additionally, when these tools are enabled, `llm_dart_openai` auto-adds the corresponding `include` fields so the response contains the richest available tool outputs:

- `file_search_call.results`
- `computer_call_output.output.image_url`

---

## 2.5 Provider metadata examples (Google / Ollama)

These providers expose useful provider-specific output fields via `ChatResponse.providerMetadata`.

### 2.5.0 Cross-provider metadata conventions (recommended)

To keep escape hatches ergonomic, providers should use these keys when possible:

- `id`: request/response identifier (when available)
- `model`: resolved model identifier/version (when available)
- `finishReason`: provider-native termination reason (end_turn/tool_use/stop/length/etc.)
- `usage`: a normalized token summary when the provider returns token counters

Notes:

- Some providers use different native terms (`stop_reason`, `done_reason`); keep the raw key too if it is useful, but prefer exposing `finishReason` as well.
- `usage` here is for provider-specific visibility; the standard `ChatResponse.usage` remains the primary cross-provider surface.

### 2.5.1 Google (Gemini)

`providerMetadata['google']` may include:

- `model`: `modelVersion` when available
- `finishReason` / `stopReason`
- `usage`: token counters from `usageMetadata`
- `promptFeedback` / `safetyRatings` when present

### 2.5.2 Ollama

`providerMetadata['ollama']` may include:

- `model`, `createdAt`, `doneReason` / `finishReason`
- `usage`: token counters when available
- `promptEvalCount`, `evalCount` and timing/duration fields when present

## 3) Provider families (how reuse works)

### 3.1 Anthropic-compatible providers (e.g. MiniMax)

Implementation pattern:

- Provider package reuses `llm_dart_anthropic_compatible`
- Request options are sourced from `providerOptions[providerId]` first, with an optional fallback to `providerOptions['anthropic']`

Example (MiniMax):

- Package: `llm_dart_minimax`
- Provider id: `minimax`
- Transport: Anthropic-compatible Messages API
- Example: `example/04_providers/minimax/anthropic_compatible_tool_approval.dart`

### 3.2 OpenAI-compatible providers

Implementation pattern:

- Provider package reuses `llm_dart_openai_compatible`
- Request options are sourced from `providerOptions[providerId]`
- `extraBody/extraHeaders` are supported as escape hatches

---

## 4) When to standardize vs keep as escape hatch

Standardize a capability only if:

- It is broadly supported across multiple providers, and
- Semantics can be made consistent, and
- You can commit to long-term stability

Otherwise:

- Keep it provider-specific via `providerOptions[providerId]`
- Expose any provider-only outputs via `providerMetadata[providerId]`

Examples that are often **provider-specific**:

- Web search (API semantics vary widely)
- Provider built-in tools (web_search/file_search/computer_use)
  - OpenAI (Responses API) built-in tools are configured via `providerOptions['openai']['builtInTools']` (or `webSearchEnabled/webSearch`, `fileSearchEnabled/fileSearch`, `computerUseEnabled/computerUse` convenience keys).
- Vendor caching semantics beyond simple “cacheControl”
- Realtime audio / multimodal pipelines

---

## 5) Safety guidance (tools)

If you expose tools that can do side effects (network/file/system), prefer a “tool approval interrupt” flow:

- Mark tools as needing approval (per-tool predicate)
- Stop the tool loop before executing tools
- Let the user/app decide to approve/deny

See:

- `runToolLoopUntilBlocked` + `ToolApprovalRequiredError` in `llm_dart_ai`
- Example: `example/04_providers/minimax/anthropic_compatible_tool_approval.dart`
