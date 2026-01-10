# LLM Dart Monorepo Architecture (Target + MVPs)

> Status: Draft (proposed end-state + phased plan)  
> Scope: `llm_dart` as an “all-in-one suite”, while allowing users to pick subpackages.  
> Primary references: Vercel AI SDK package split (`repo-ref/ai`) and current `llm_dart` design (capabilities + builder + registry).
>
> Canonical north-star summary: `docs/refactor_vision.md`

---

## 0. Current progress (implemented in repo)

This section is a living status snapshot to prevent refactor progress from getting lost.

Provider-by-provider alignment tracker:

- `docs/provider_alignment_progress.md`
- Protocol reuse layer docs: `docs/protocols/README.md`

### 0.1 Completed (high signal)

- **MVP0 (core→provider decoupling)**:
  - Core registry no longer auto-imports/registers all providers.
  - Umbrella registration moved to `BuiltinProviderRegistry` (`llm_dart` entrypoints call `ensureRegistered()`).
  - Standard provider set is explicitly defined (Vercel-style): OpenAI, Anthropic, Google (Gemini).
    - Umbrella provides `BuiltinProviderRegistry.registerStandard()` / `ensureStandardRegistered()` in addition to `registerAll()` / `ensureRegistered()`.
  - Umbrella registration policy is documented in `docs/umbrella_policy.md`.

- **Examples migrated to task APIs (Vercel-style)**:
  - Examples now prefer `llm_dart_ai` streaming/task APIs (`streamText` / `streamChatParts` / `streamToolLoopPartsWithToolSet`) instead of calling `provider.chatStream(...)` directly.
  - The `provider.chatStream(...)` surface remains the low-level capability interface; `example/03_advanced_features/custom_providers.dart` intentionally still demonstrates it.
  - Examples and example READMEs no longer import `package:llm_dart/llm_dart.dart` or call `ai()`; they use explicit subpackages + `register*()` + `LLMBuilder()` (and provider wrapper builders where available).
  - `ai()` remains a legacy convenience in the umbrella package (auto-registers built-in providers via `BuiltinProviderRegistry`).

- **OpenAI-compatible examples cleaned up**:
  - `example/04_providers/others/openai_compatible.dart` now reflects the primary OpenAI-compatible presets we smoke test in this repo (`deepseek-openai`, `groq-openai`, `xai-openai`, `google-openai`, `openrouter`).

- **Namespaced provider options (Vercel-style)**:
  - `LLMConfig.providerOptions` added (namespaced JSON-like map).
  - Builders can write provider options via `providerOption/providerOptions/option`.
  - `LLMBuilder.providerConfig((p) => ...)` added as a convenience wrapper that merges a `ProviderConfig` map into `providerOptions` for the currently selected provider.
  - `LLMBuilder` buffers provider-only knobs until a provider is selected, then writes them into the selected provider namespace in `providerOptions`.
  - Providers source provider-only knobs from `providerOptions`, including:
    - Anthropic-compatible: `reasoning/thinkingBudgetTokens/interleavedThinking`, `metadata/container/mcpServers`
    - Ollama: `numCtx/numGpu/numThread/numa/numBatch/keepAlive/raw/reasoning`
    - ElevenLabs: `voiceId/stability/similarityBoost/style/useSpeakerBoost`
    - DeepSeek: `logprobs/topLogprobs/frequencyPenalty/presencePenalty/responseFormat`
  - Google Gemini (OpenAI-compatible: `google-openai`) reads thinking/reasoning options from `providerOptions['google-openai']` (fallback to `providerOptions['google']`).
  - Anthropic prompt caching now supports config-level default via `providerOptions['anthropic']['cacheControl']` (in addition to message-level cache markers).
  - `LLMConfig` now reads `providerOptions` / `transportOptions` in a best-effort way (no `cast<String, dynamic>()` traps when parsing JSON).
  - `ChatResponse.providerMetadata` is available as the standard response “escape hatch” for provider-specific output data (e.g. ids, cache stats), and `llm_dart_ai.GenerateTextResult` forwards it.
  - `ChatResponseWithAssistantMessage` added: tool loops can persist provider-specific assistant content blocks when required by a protocol (e.g. Anthropic/MiniMax thinking signatures).
  - Google streaming requests now choose the correct streaming endpoint based on the called method (no longer depending on `GoogleConfig.stream`).
  - Google provider-native web search now injects the correct Gemini tool shapes (`googleSearch` / `googleSearchRetrieval`) instead of the legacy snake_case key.
  - **Legacy unified web search removed**:
    - `WebSearchConfig` and `LLMBuilder.enableWebSearch()/webSearch()` were removed.
    - Web search is configured via provider-native `providerTools` and provider-specific `providerOptions`.

### 0.2 Breaking changes (recent)

- `LLMConfig.extensions` was removed. Use `providerOptions` for provider-only knobs and `transportOptions` for transport/HTTP.
- `ChatMessage.extensions` is deprecated for user code and reserved for protocol-internal content blocks. Prefer `Prompt` IR + `providerOptions`.
- `LLMBuilder.extension(...)` (legacy, global) and the old `LLMBuilder` image/audio convenience setters were removed. Use namespaced `providerOptions` (`option/providerOption/providerConfig`) and task request objects in `llm_dart_ai`.
- `LLMBuilder.providerConfig((p) => ...)` writes into `providerOptions`.
- `createProvider(...)` accepts `providerOptions` (use `LLMBuilder()` + `providerOptions` / provider wrapper builders for more complex setup).
- Google chat now selects the streaming endpoint based on `chatStream/chatStreamParts` rather than `GoogleConfig.stream`.
- **Core cancellation is now HTTP-client-agnostic**:
  - `llm_dart_core` no longer depends on Dio. `CancelToken` lives in core and is used across all capability interfaces.
  - `llm_dart_provider_utils` provides the Dio bridge (`withDioCancelToken`) for providers that use Dio under the hood.
- **Builder is transport-agnostic**:
  - `llm_dart_builder` no longer depends on Dio types.
  - Advanced users can still pass a pre-configured Dio instance via `HttpConfig.dioClient(...)` (stored as `customDio`) and providers will consume it if they use Dio.
- **Umbrella exports avoid Dio by default**:
  - `package:llm_dart/llm_dart.dart` no longer exports Dio-specific helpers like `HttpConfigUtils` / `BaseHttpProvider`.
  - Import advanced transport utilities from `package:llm_dart_provider_utils/llm_dart_provider_utils.dart`.
- **Provider package entrypoints are standardized (Vercel-style)**:
  - Each provider package exposes a stable `<provider>.dart` entrypoint (e.g. `package:llm_dart_openai/openai.dart`) plus the default `package:llm_dart_openai/llm_dart_openai.dart`.
  - Factory/registration APIs are exposed via `<provider>_factory.dart` (e.g. `openai_factory.dart`, `google_factory.dart`) and re-exported by the default entrypoint.
  - Avoid importing from `package:*/*/src/*` paths; use the public entrypoints instead.

- **Legacy umbrella shims removed**:
  - Removed subpath imports like `package:llm_dart/core/*`, `package:llm_dart/models/*`, `package:llm_dart/providers/**`, `package:llm_dart/builder/*`.
  - Import directly from the subpackages (`llm_dart_core`, `llm_dart_builder`, `llm_dart_provider_utils`, and provider packages) or use the umbrella exports in `package:llm_dart/llm_dart.dart`.

- **Standard layers split (real packages; legacy shims removed)**:
  - `packages/llm_dart_core` created: core types + shared models live here (`llm_dart` now re-exports it from `lib/llm_dart.dart`).
  - `packages/llm_dart_provider_utils` created: shared HTTP/SSE/tooling utilities live here (import directly when needed).
- `packages/llm_dart_builder` created: base `LLMBuilder` + `HttpConfig/ProviderConfig` live here (umbrella re-exports it).
  - `BaseProviderFactory` moved into `llm_dart_provider_utils` so provider packages can implement factories without depending on the umbrella.
  - `packages/llm_dart_openai` created: OpenAI provider moved here and now exposes `registerOpenAI()` for subpackage-only users.
  - `packages/llm_dart_openai_compatible` created: OpenAI-compatible configs/factories (+ `OpenRouterBuilder`) moved here and now exposes `registerOpenAICompatibleProviders()`.
  - **OpenAI-compatible protocol layer is now truly standalone**:
    - Moved reusable `OpenAIClient/OpenAIChat/OpenAIEmbeddings` into `llm_dart_openai_compatible`.
    - Introduced `OpenAIRequestConfig` so OpenAI-specific config and generic compatible config share the same protocol implementation.
    - Added `providerId/providerName` to `OpenAIRequestConfig` so protocol-level logging/error messages and provider-specific behavior don’t rely on baseUrl guessing.
    - `llm_dart_openai` depends on `llm_dart_openai_compatible` (re-export stubs keep old internal imports stable), while `llm_dart_openai_compatible` no longer depends on `llm_dart_openai`.
  - `packages/llm_dart_deepseek` created: DeepSeek provider moved here and exposes `registerDeepSeek()`.
  - `packages/llm_dart_groq` created: Groq provider moved here and exposes `registerGroq()`; implementation reuses the OpenAI-compatible protocol layer.
  - `packages/llm_dart_google` created: Google (Gemini) provider moved here (chat/stream/tools + embeddings + images + TTS) and exposes `registerGoogle()`; `BuiltinProviderRegistry` calls `registerGoogle()`.
  - `packages/llm_dart_ollama` created: Ollama provider moved here (chat/stream/tools + embeddings + completion API + model listing) and exposes `registerOllama()`; `BuiltinProviderRegistry` calls `registerOllama()`.
  - Phind provider package has been removed from this repository.
  - `packages/llm_dart_elevenlabs` created: ElevenLabs provider moved here and exposes `registerElevenLabs()`.
    - Streaming TTS implemented via ElevenLabs `/text-to-speech/{voice_id}/stream` route and surfaced as `textToSpeechStream`.

- **Publish-ready internal dependencies (monorepo hygiene)**:
  - All internal package dependencies are now expressed as **version constraints** (no `path:` in any `pubspec.yaml`), so each subpackage (and the `llm_dart` suite) can be published.
  - Local development uses Dart pub workspaces (`workspace:` at repo root + `resolution: workspace` in members) to resolve internal packages via local paths.
  - `melos.yaml` remains optional tooling for scripts/versioning/publishing workflows.

- **Protocol reuse layer (Anthropic-compatible)**:
  - `packages/llm_dart_anthropic_compatible` created and now hosts reusable:
    - `config`, `client`, `dio_strategy`, `request_builder`, `chat`, `mcp_models`
  - `request_builder` was split into a small public entry (`lib/request_builder.dart`) plus focused parts under `lib/src/request_builder/*` (guarded by conformance tests).
  - `chat` is being decomposed the same way: `lib/chat.dart` as the stable entrypoint, with implementation split under `lib/src/chat/*` (e.g. `response`, `sse_parser`, `stream_parts`).
    - `chatStreamParts` streaming parser was extracted into `lib/src/chat/stream_parts.dart` (keeps behavior stable while enabling smaller future refactors).
    - `chatStream` SSE parsing was extracted into a stateful helper: `lib/src/chat/sse_parser.dart` (buffer + tool_use accumulation).
    - SSE parsing primitives are now shared via `llm_dart_provider_utils`:
      - `utils/sse_line_buffer.dart` (chunk → complete lines)
      - `utils/sse_chunk_parser.dart` (event/data parsing over buffered lines)
    - JSONL (newline-delimited JSON) parsing is shared via `utils/jsonl_chunk_parser.dart` (used by local JSON-streaming providers like Ollama).
  - Compatible client/strategy supports overriding `providerName` so reuse providers (e.g. MiniMax) don’t log/label as “Anthropic”.
  - `AnthropicChat` supports injecting a custom `AnthropicRequestBuilder` to adapt request compilation for provider variants while reusing the same protocol implementation.
    - We do **not** use it to maintain per-model capability matrices, silently strip “unsupported” keys, or rewrite user inputs (see `docs/adp/0004-no-provider-constraints-or-matrices.md`).
  - Escape hatches are supported to avoid over-standardizing provider-specific features:
    - `providerOptions['anthropic']['extraBody']` merges into the outgoing request JSON.
    - `providerOptions['anthropic']['extraHeaders']` merges into the outgoing HTTP headers.

- **First real consumer of anthropic-compatible reuse**:
  - `packages/llm_dart_minimax` created (Anthropic-compatible route only for now).
  - Default base URL aligns with Vercel AI SDK's MiniMax provider:
    - International: `https://api.minimax.io/anthropic/v1/`
    - China: `https://api.minimaxi.com/anthropic/v1/`
    - MiniMax docs also use `.../anthropic` (without `/v1`); LLM Dart accepts both and normalizes to `/v1/`.
  - Umbrella registers `minimax` provider and exposes `LLMBuilder.minimax()`.
  - `llm_dart_minimax` now exposes `registerMinimax()` for subpackage-only users.
  - MiniMax reads namespaced provider options from `providerOptions['minimax']` first (fallback to `providerOptions['anthropic']`) to keep ergonomics consistent with the chosen provider id.
  - MiniMax forwards Anthropic-compatible requests **best-effort**:
    - No provider-side constraints enforcement (e.g. temperature ranges).
    - No silent stripping of “ignored/unsupported” request keys.
    - Protocol-level validation still applies when the wire format cannot represent an input (e.g. `ImageUrlMessage` is not representable in Anthropic Messages API and throws).
  - Anthropic-compatible streaming conformance is now shared:
    - Protocol suite lives in `test/protocols/anthropic_compatible/` (baseline `AnthropicChat` test).
    - Providers (e.g. MiniMax) call into the suite to assert:
      - required part ordering (e.g. `thinking_delta` before `text_delta`)
      - tool call streaming semantics (`tool_use` → `LLMToolCall*Part` + `response.toolCalls`)
      - provider-native web search is **not** exposed as a local tool call (`web_search` filtered)
      - stable namespacing (e.g. `providerMetadata['minimax']`)
    - `AnthropicConfig.copyWith(...)` preserves `providerId`, preventing metadata key regressions (e.g. `minimax`, not `anthropic`).
  - Anthropic-compatible request builder conformance is now shared:
    - `test/protocols/anthropic_compatible/request_builder_conformance_test.dart` asserts:
      - providerOptions / providerTools both bridge into provider-native web search tool config and inject `web_search_*` tool definitions
      - collision-safe renaming when a local tool name collides with provider-native `web_search`
      - default `cacheControl` behavior (system blocks + last tool)
  - Anthropic-compatible tool loop persistence conformance is now shared:
    - `test/protocols/anthropic_compatible/tool_loop_persistence_conformance.dart` asserts:
      - `ChatResponseWithAssistantMessage.assistantMessage` preserves full `content` blocks (including `tool_use`)
      - The next request can replay those blocks and pair them with `tool_result` correctly
  - Anthropic-compatible collision-safe tool naming conformance is now shared:
    - `test/protocols/anthropic_compatible/tool_name_mapping_conformance_test.dart` asserts:
      - when provider-native `web_search` is enabled, a local tool named `web_search` is auto-renamed in the request (e.g. `web_search__1`)
      - responses/streams map `web_search__1` back to the original local tool name (`web_search`)
      - provider-native `web_search` is still not surfaced as a local tool call (only in `providerMetadata`)
  - Anthropic-compatible protocol feature conformance is expanding:
    - `test/protocols/anthropic_compatible/cache_control_marker_conformance_test.dart` asserts per-message/tool `cache_control` marker semantics.
    - `test/protocols/anthropic_compatible/mcp_tool_blocks_conformance_test.dart` asserts MCP connector blocks (`mcp_tool_use`/`mcp_tool_result`) parsing and exposure.
    - `test/protocols/anthropic_compatible/redacted_thinking_conformance_test.dart` asserts redacted thinking placeholder + replay safety via `assistantMessage`.
    - `test/protocols/anthropic_compatible/tool_result_error_detection_conformance_test.dart` asserts request-side `tool_result.is_error` inference rules.
    - `test/protocols/anthropic_compatible/message_sequence_conformance_test.dart` asserts the first non-system message must be `user`.

- **Anthropic provider becomes a real package**:
  - `packages/llm_dart_anthropic` created with Anthropic provider shell + files/models modules.
  - Umbrella `lib/providers/anthropic/{anthropic,provider,files,models}.dart` now forward-export from `llm_dart_anthropic`.
  - `llm_dart_anthropic` now owns `AnthropicProviderFactory` + `registerAnthropic()` (umbrella re-exports for compatibility).

- **MVP3 (Vercel-style task APIs) — initial cut**:
  - `packages/llm_dart_ai` created as a real package (with `pubspec.yaml`).
  - Implements minimal provider-agnostic tasks:
    - `runToolLoop` (non-streaming): execute local tool calls and feed results back to the model until a final response is produced
    - `runToolLoopUntilBlocked` (non-streaming): stop early and return a `ToolLoopBlocked` state when a tool call needs user approval
    - `streamToolLoop` (streaming): stream parts while executing tool calls between steps, yielding a final `FinishPart` once completed
    - `ToolSet` / `functionTool`: bundle tool schemas with local handlers for easier tool-loop usage
      - `LocalTool.needsApproval`: optional per-tool approval predicate (Vercel-style)
      - `ToolApprovalRequiredError`: thrown/emitted when approval is required (opt-in via `needsApproval`)
      - `executeToolCalls` + `encodeToolResultsAsToolCalls`: helpers for “manual resume” flows
    - `generateText`
    - `generateObject` (prefers tool calling, falls back to extracting JSON from text)
    - `streamText` (maps existing `ChatStreamEvent` → `TextStreamPart`)
    - `embed`
    - `generateImage`
    - `generateSpeech` / `generateSpeechFromText`
    - `streamSpeech` / `streamSpeechFromText`
    - `transcribe` / `transcribeFromAudioBytes` / `transcribeFromFile`
    - `translateAudio` (audio→English, when supported)
  - Legacy convenience aliases (`*FromPromptIr` / `*FromPrompt`) live in `package:llm_dart_ai/legacy.dart` (not exported by default).
  - Umbrella `llm_dart` re-exports `package:llm_dart_ai/llm_dart_ai.dart` for “all-in-one” users.
  - Concrete tool implementations (web fetch/search, file access, etc.) are intentionally kept out of the standard surface; ship them as examples/recipes or app-level code.

- **Unified stream parts (Vercel-style) — MVP shipped (initial)**:
  - Added `LLMStreamPart` types in `llm_dart_core` (text/reasoning/tool boundaries + providerMetadata + finish/error).
  - Added `streamChatParts(...)` in `llm_dart_ai` as an adapter on top of legacy `ChatStreamEvent`.
  - Added `streamToolLoopParts(...)` in `llm_dart_ai` to expose local tool execution via `LLMToolResultPart` and emit a single `LLMFinishPart` at the end.
  - Legacy streaming APIs (`streamText` / `streamToolLoop`) now map from `LLMStreamPart` adapters internally to keep one source of truth.
  - Added `ChatStreamPartsCapability` (provider-native stream parts) and implemented it for:
    - OpenAI Responses (`llm_dart_openai`)
    - OpenAI-compatible Chat Completions protocol layer (`llm_dart_openai_compatible`, reused by Groq/DeepSeek/OpenRouter, etc.)
    - Anthropic-compatible (`llm_dart_anthropic_compatible`, used by MiniMax)
    - Google Gemini (`llm_dart_google`)
    - Ollama (`llm_dart_ollama`)
  - `streamToolLoopParts(...)` now prefers provider-native parts when available (so provider metadata can flow through tool loops).

- **Provider-native web search (Vercel-style)**:
  - Web search is treated as a provider-executed tool, not a local function tool.
  - Anthropic-compatible `web_search_*` is filtered out from local tool call surfaces to avoid accidental execution in local tool loops.
  - **Migration in progress**:
    - Prefer `LLMConfig.providerTools` (typed `ProviderTool` catalogs) for provider-native web search / grounding tools.
    - Namespaced `providerOptions[*]['webSearchEnabled'|'webSearch']` remain as legacy best-effort escape hatches for compatibility.
    - OpenRouter web search is a provider detail (`:online` model suffix). LLM Dart does not rewrite models automatically; set it explicitly if needed.
    - xAI uses `providerOptions['xai']['searchParameters'|'liveSearch']` (native shape); `webSearch*` keys are legacy.
  - `LLMConfig.providerTools` is now writable via `LLMBuilder.providerTool(s)`, and providers can gradually bridge it into native request formats.
    - Implemented bridges: OpenAI (`openai.web_search_preview` / `openai.file_search` / `openai.computer_use_preview`), Anthropic-compatible (`*.web_search_*`), Google (`google.google_search`).
    - Provider helpers:
      - Prefer typed tool catalogs: `LLMBuilder.providerTool(GoogleProviderTools.webSearch(...))`, `LLMBuilder.providerTool(AnthropicProviderTools.webSearch(...))`.
    - Typed tool catalogs (recommended): `OpenAIProviderTools`, `AnthropicProviderTools`, `GoogleProviderTools`.
    - `LLMBuilder` web search convenience methods were removed.
- OpenAI Responses exposes web search calls + citations via:
  - `providerMetadata['openai']['webSearchCalls']`
  - `providerMetadata['openai']['annotations']`
  - OpenAI Responses auto-adds `include: ['web_search_call.action.sources']` when the built-in web search tool is enabled.
  - OpenAI factory bridges `LLMConfig.providerTools` ids (`openai.web_search_preview`, `openai.file_search`, `openai.computer_use_preview`) into Responses built-in tools (in addition to `providerOptions['openai']['builtInTools']`).
  - Similarly auto-adds:
    - `file_search_call.results` (built-in file search)
    - `computer_call_output.output.image_url` (built-in computer use)
  - OpenAI Responses streaming emits a best-effort `CompletionEvent` even if the stream ends with `[DONE]` (no `response.completed`), so `providerMetadata` remains available in streaming flows.
  - **Collision-safe tool naming (ToolNameMapping)**:
    - Anthropic, Google, and OpenAI Responses now use `ToolNameMapping` to avoid name collisions between local function tools and provider-native tools.
    - Example: when provider-native web search is enabled, a user-defined local tool named `web_search` / `google_search` / `web_search_preview` is automatically rewritten (e.g. `web_search__1`) in the outgoing request, and mapped back to the original name in responses/events.
    - OpenAI Responses also caches incremental `tool_calls[*].function.name` by index to handle streams that only send `function.arguments` deltas after the first chunk.

- **HTTP error handling cleanup**:
  - `DioErrorHandler` moved from `llm_dart_core` to `llm_dart_provider_utils` (core no longer imports Dio for error mapping).
  - `DioErrorHandler` is intentionally **not** re-exported by the umbrella `llm_dart` package to keep the default surface provider/HTTP-agnostic.

- **Provider-specific web search tool options (Anthropic)**:
  - Added `AnthropicWebSearchToolOptions` in `llm_dart_anthropic_compatible` to match Anthropic server tool option shapes (Vercel-style: provider-specific options).
  - `AnthropicProviderTools.webSearch(...)` uses `options:` only.

- **Provider-specific web fetch tool options (Anthropic)**:
  - Added `AnthropicWebFetchToolOptions` in `llm_dart_anthropic_compatible` to match Anthropic server tool shapes (e.g. `web_fetch_20250910`).
  - Added `AnthropicProviderTools.webFetch(...)` and `AnthropicBuilder.webFetchTool(...)`.
  - Anthropic request builder injects `web_fetch_*` and streaming filters do not surface provider-native `web_fetch` as local tool call parts/events.
  - Anthropic HTTP layer auto-adds the beta header `web-fetch-2025-09-10` when web fetch is enabled.

- **Provider-specific web search tool options (Google)**:
  - Added `GoogleWebSearchToolOptions` in `llm_dart_google` to match Vercel AI SDK provider tool input schema (`mode`, `dynamicThreshold`).
  - `GoogleChat` bridges these options into `googleSearchRetrieval.dynamicRetrievalConfig` for non-Gemini-2 models.
  - Added `google.code_execution` / `google.url_context` provider tools (Gemini 2.0+ only) and bridged them into request JSON.

### 0.2 Notes / constraints learned

- `packages/llm_dart` (a stale directory without `pubspec.yaml`) was removed to avoid confusing Melos/package discovery. Only directories with `pubspec.yaml` are treated as publishable units.
- Naming alignment: this repo currently uses `llm_dart_core` for “provider/core types” (what the draft called `llm_dart_provider`).
- Extension key hygiene matters: DeepSeek’s `fromLLMConfig` now reads the canonical camelCase keys (with snake_case fallback) to avoid silent “option not applied” bugs during the migration.

---

## 1. Goals / Non-goals

### Goals

1. **Suite + composability**: keep `llm_dart` as a convenient full bundle, while enabling `pub add llm_dart_xxx` for selective use.
2. **Stable “standard” surface**: define a narrow, provider-agnostic core that stays stable long-term.
3. **Provider-specific extensibility**: support provider-only features (cache, web search, Realtime, special tool types, etc.) without bloating the standard core.
4. **Protocol reuse**: make it easy for a new provider to reuse an existing “standard protocol implementation” (e.g., OpenAI-compatible, Anthropic-compatible) rather than re-implementing everything.
5. **Gradual migration**: ship MVPs that unblock splitting without breaking most users, then improve ergonomics.

Related conventions:

- Provider escape hatches cookbook: `docs/provider_escape_hatches.md`
- Provider-native tool catalogs: `docs/provider_tools_catalog.md`
- Transport options reference: `docs/transport_options_reference.md`
- Standard surface definition: `docs/standard_surface.md`

### Non-goals

1. A single “mega unified interface” that exposes every provider feature as a common API.
2. Forced perfect abstraction of features like web search (semantics vary significantly by provider).
3. Rewriting every provider at once (we prioritize incremental refactors).

---

## 2. Key design choices (mirroring Vercel AI SDK)

ADPs (decisions we want to keep stable during fearless refactors):

- `docs/adp/0001-provider-tools-first-class.md`

### 2.1 What is “standard” vs “provider”?

Vercel AI SDK keeps “standard” very narrow:

- A **standard model interface** (`@ai-sdk/provider`) for common tasks (language/embedding/image/speech/transcription/rerank).
- A **standard utilities layer** (`@ai-sdk/provider-utils`) for tool/schema/middleware/stream parsing.
- A **protocol reuse layer** (`@ai-sdk/openai-compatible`) for providers that share the same wire format.
- A **unified orchestration layer** (`ai`) providing stable, user-facing functions (`generateText`, `embed`, `generateImage`, …).
- Provider packages depend on standard layers; standard layers do **not** depend on providers.

In practice, Vercel’s “standard providers” set is also small:

- `@ai-sdk/openai`
- `@ai-sdk/anthropic`
- `@ai-sdk/google`

This architecture allows:

- Provider innovation via **providerOptions/providerMetadata** without expanding the standard API.
- New providers to reuse the OpenAI-compatible stack (or reuse another provider package’s internal implementation).

**LLM Dart should adopt the same rule**:

- The “standard core” must not import provider implementations.
- Provider-only features flow through **namespaced provider options** + **provider metadata**, not through new standard interfaces unless they are truly universal and stable.

### 2.2 Unified entrypoint: keep both, recommend one

LLM Dart started as “unified provider interface” (capability traits). Vercel AI SDK’s unified API is “unified tasks” (generateText/embed/…) and “unified model interface”.

To preserve your original value proposition while moving closer to Vercel’s split:

- Keep the **low-level interface** (“model/capability style”) for power users.
- Add a **recommended high-level entrypoint** (“task functions”) for long-term stability and composability.

This yields:

- Fewer breaking changes as provider features evolve.
- A stable top-level UX similar to Vercel AI SDK.

---

## 3. Target package layout (end-state)

This is the “final” split, with clear dependency direction and “standards” isolated from providers.

### 3.1 Packages (Dart)

**Standard layers**

1. `llm_dart_core` (aka “provider/core types”)
   - Pure interfaces + shared types (models, messages, tools, schemas, errors, usage, stream parts).
   - No HTTP. No provider implementations.
   - No “auto registry of providers”.

2. `llm_dart_provider_utils`
   - HTTP primitives, SSE parsing, retries, request/response helpers.
   - Tool schema helpers, structured output helpers, validation, middleware primitives.
   - Depends on `llm_dart_core`.

3. `llm_dart_openai_compatible` (protocol reuse)
   - A generic implementation for OpenAI-compatible wire format (chat, stream, tools, maybe embeddings/images/audio if compatible).
   - Produces standard `LanguageModel` (and others) + typed errors.
   - Depends on `llm_dart_core` + `llm_dart_provider_utils`.

4. `llm_dart_anthropic_compatible` (optional but recommended)
   - Same idea for Anthropic-style Messages API compatibility, enabling “minimax uses anthropic standard” reuse.
   - If you prefer fewer packages, this can be achieved by making `llm_dart_anthropic` expose a reusable internal “anthropic-compatible transport” that other providers depend on (similar to `@ai-sdk/google-vertex` depending on `@ai-sdk/anthropic`).

**Orchestration layer**

5. `llm_dart_ai`
   - Stable user-facing task functions:
     - `generateText`, `streamText`
     - `generateObject` (schema guided + parse)
     - `embed`
     - `generateImage`
     - `generateSpeech`, `transcribe`
     - `rerank`
   - Agent/tool loop utilities (optional, but matches Vercel’s “agent” module).
   - Depends on `llm_dart_core` + `llm_dart_provider_utils`.
   - Does not depend on specific providers.

**Provider packages**

6. `llm_dart_openai`
   - Uses OpenAI Responses/ChatCompletions, built-in tools, file APIs, etc.
   - Depends on `llm_dart_core` + `llm_dart_provider_utils` (and optionally `llm_dart_openai_compatible` for shared pieces).

7. `llm_dart_google`, `llm_dart_xai`, `llm_dart_groq`, `llm_dart_deepseek`, …
   - Prefer reusing `llm_dart_openai_compatible` when appropriate.
   - Otherwise implement standard interfaces directly.

**Suite bundle**

8. `llm_dart` (umbrella)
   - Re-exports `llm_dart_ai` + common providers + common utils for convenience.
   - This is the “all-in-one suite” users can still install.

### 3.2 Dependency graph (rule)

```
llm_dart_core
   ↑
llm_dart_provider_utils
   ↑           ↑
llm_dart_ai    llm_dart_openai_compatible (protocol)
   ↑           ↑
   └──── providers (openai/google/xai/...)
                ↑
              llm_dart (umbrella)
```

Hard rule: `llm_dart_core` must not import anything provider-specific.

---

## 4. “Standard” interfaces (what we unify)

### 4.1 Model interfaces (Vercel-style)

Define standard “Model” interfaces (names illustrative):

- `LanguageModel` (non-stream + stream)
- `EmbeddingModel`
- `ImageModel`
- `SpeechModel` (TTS)
- `TranscriptionModel` (STT)
- `RerankingModel`

Each “model call” takes:

- Standardized input (prompt/messages/tools/options)
- Optional `providerOptions` for provider-specific settings
- Optional cancellation token

Each output includes:

- Standard output data
- `usage`
- Optional `providerMetadata` (namespaced)
- Stream uses standardized stream parts (text/reasoning/tool/result/metadata/finish/error/raw)

### 4.2 Stream parts (upgrade path from current ChatStreamEvent)

Vercel’s stream parts include block boundaries (`text-start`, `text-delta`, `text-end`, etc.) and carry `providerMetadata`.

LLM Dart can adopt the same shape:

- Text blocks: start/delta/end
- Reasoning blocks: start/delta/end
- Tool blocks:
  - tool input start/delta/end (for progressive JSON tool args)
  - tool call + tool result parts
- Response metadata / finish / error / raw

**Backward compatibility**:

`ChatStreamEvent` can be an adapter on top of the new stream parts for a transition period.

---

## 5. Provider-specific features: how we support them without polluting “standard”

### 5.1 Provider options (input) — namespaced, Vercel-style

Adopt a namespaced structure similar to Vercel’s `providerOptions`:

```dart
/// keys are provider IDs, values are provider-specific JSON-like objects
typedef ProviderOptions = Map<String, Map<String, dynamic>>;
```

Examples:

- Anthropic prompt caching:
  - `providerOptions['anthropic']?['cacheControl'] = {'type': 'ephemeral', 'ttl': '1h'}`
- OpenAI Responses built-in tools config:
  - `providerOptions['openai']?['builtInTools'] = [...]`
- xAI live search parameters:
  - `providerOptions['xai']?['searchParameters'] = {...}`

This prevents a global dumping ground with key collisions by keeping provider-only knobs namespaced.

Provider options are not only config-level: we propagate them at the prompt
layer too (aligned with Vercel AI SDK):

- `LLMConfig.providerOptions` (call defaults)
- `ChatMessage.providerOptions` (per message)
- `ToolCall.providerOptions` (per tool call / tool result)

Providers can implement a precedence model such as:

1) explicit protocol fields already set (e.g. `cache_control` on a block)
2) tool `providerOptions`
3) message `providerOptions`
4) config `providerOptions` (default)

### 5.2 Provider metadata (output)

Similarly:

```dart
typedef ProviderMetadata = Map<String, Map<String, Object?>>;
```

Examples:

- `providerMetadata['anthropic']?['cacheReadTokens'] = ...`
- `providerMetadata['openai']?['id'] = ...`
- `providerMetadata['openai']?['webSearchCalls'] = ...` (OpenAI Responses built-in web search)

### 5.3 Provider tools (not only function tools)

Currently, LLM Dart tool abstraction is primarily “function tools”. That makes features like:

- OpenAI Responses built-in tools (web_search/file_search/computer_use)
- Anthropic web_search tool
- xAI live search

hard to express in one consistent “tool story”.

The Vercel approach supports both “function tools” and “provider tools” and streams tool lifecycle parts.

LLM Dart target:

- Standard: `FunctionTool` (+ schema)
- Extension: `ProviderTool` (opaque to standard layer; only provider understands)
- Orchestration (`llm_dart_ai`) should provide a tool loop that can execute function tools locally, while allowing providers to execute provider tools internally.
- Orchestration should allow a “tool approval interrupt” mode:
  - if `needsApproval(...) == true`, stop before executing tools and return a blocked state (or emit `ToolApprovalRequiredError` in streaming).

Practical rule of thumb (Vercel-style):

- Web search should be treated as a **provider-native tool** (server-side / built-in), not a local function tool.
- Local tool loops should execute only tools that have local handlers.

---

## 6. Protocol reuse (“minimax uses anthropic standard”)

See also: `docs/adp/0003-anthropic-compatible-protocol-reuse.md`.
Template: `docs/templates/anthropic_compatible_provider/`.

Vercel achieves reuse in two ways:

1. Many providers reuse `@ai-sdk/openai-compatible` directly.
2. Some providers depend on other provider packages for shared logic (e.g., `@ai-sdk/google-vertex` depends on `@ai-sdk/anthropic` + `@ai-sdk/google`).

LLM Dart should support both:

### Option A (cleanest): dedicated protocol packages

- `llm_dart_openai_compatible`: generic OpenAI-compatible implementation
- `llm_dart_anthropic_compatible`: generic Anthropic-compatible implementation

Then:

- `llm_dart_minimax` can depend on `llm_dart_anthropic_compatible` and just provide defaults.

### Option B (fewer packages): provider packages expose reusable “compat layer”

- `llm_dart_anthropic` exposes an internal-but-public `AnthropicCompatibleClient` or `AnthropicTransport`.
- `llm_dart_minimax` depends on `llm_dart_anthropic` and reuses it.

Trade-off:

- Option A keeps “standard protocols” conceptually separate (closer to `openai-compatible` package).
- Option B is fewer packages but can entangle release cycles.

#### Decision (recommended)

- **Final target: Option A** (`llm_dart_anthropic_compatible` as a protocol reuse package).
  - Rationale: “Minimax uses Anthropic standard” is protocol reuse; it should not force users to pull the full `llm_dart_anthropic` provider package when they only want minimax.
  - This mirrors Vercel’s `@ai-sdk/openai-compatible` pattern: protocol packages depend only on the standard layers, never on provider packages.
- **Implementation status**: Option A is implemented.
  - The reusable Anthropic-compatible transport lives in `llm_dart_anthropic_compatible`.
  - `llm_dart_anthropic` and `llm_dart_minimax` reuse it, so protocol-level fixes can ship without touching provider-only modules.

Extraction triggers (practical):

### MiniMax recommended usage (Anthropic-compatible)

- Use the provider package + task layer (pick-and-choose friendly):
  - `llm_dart_minimax` + `llm_dart_builder` + `llm_dart_ai`
- MiniMax guide (in this repo):
  - `docs/providers/minimax.md`
- Prefer provider options for provider-only knobs:
  - `providerOptions['minimax']['cacheControl']` (Anthropic prompt caching shape)
  - `providerOptions['minimax']['extraBody']` / `extraHeaders` (escape hatch)
- Example (tool approval interrupt + manual resume):
  - `example/04_providers/minimax/anthropic_compatible_tool_approval.dart`
- MiniMax provider package README (subpackage users):
  - `packages/llm_dart_minimax/README.md`

- ≥2 providers reuse the Anthropic wire format.
- Provider-only features (cache/web_search/tool streaming) require independent iteration in the protocol layer.
- Dependency footprint matters for “pick subpackages” users.
- Testing now has a single shared conformance suite for the protocol (`test/protocols/anthropic_compatible/`).

---

## 7. MVP roadmap (phased, shippable milestones)

This section defines MVPs that converge on the target end-state while keeping risk manageable.

### MVP 0 — Unblock splitting (remove core→provider coupling)

**Goal**: make it technically possible to split packages without circular imports.

Actions:

1. Remove provider imports from “core”:
   - Example in current code: `core/capability.dart` imports Google TTS provider types. Move that to a provider package.
2. Remove “auto-register all providers” from the core registry:
   - Current `core/registry.dart` imports every provider factory.
   - Move built-in registration to umbrella `llm_dart` or a dedicated `llm_dart_builtin` package.
3. Deprecate provider-specific convenience methods in global builder:
   - Keep DX-only builder conveniences in the umbrella `llm_dart` package.
   - Provider subpackages should not depend on `llm_dart_builder` (subpackage users can configure features via `providerTools` / `providerOptions`).

Deliverables:

- No core layer depends on providers.
- Providers register themselves (or are registered by umbrella package).

### MVP 1 — Extract the “standard layer” packages

**Goal**: create `llm_dart_core` and `llm_dart_provider_utils`.

Actions:

1. Move shared types (messages, tools, schemas, errors, stream parts) into `llm_dart_core`.
2. Move HTTP/SSE/tool validation utilities into `llm_dart_provider_utils`.
3. Keep umbrella `llm_dart` re-exporting everything for backwards compatibility.

Deliverables:

- Clear dependency DAG.
- Users can depend on `llm_dart_core` for types without pulling providers.

### MVP 2 — Protocol reuse package (OpenAI-compatible)

**Goal**: replace “core/openai_compatible_configs.dart + transformers” with a real protocol package.

Actions:

1. Create `llm_dart_openai_compatible` with:
   - Shared client, request builder, SSE parser, tool mapping.
   - Support for “provider overrides” via `providerOptions`.
2. Migrate “OpenAI-compatible providers” to reuse it (xAI/Groq/DeepSeek…).

Deliverables:

- New providers can be added by just wiring defaults.
- Reduced duplicated logic across providers.
 - Protocol package can be depended on without pulling `llm_dart_openai`.

### MVP 3 — Unified user entrypoint (`llm_dart_ai`)

**Goal**: provide stable, provider-agnostic user-facing APIs (Vercel-style).

Actions:

1. Introduce `llm_dart_ai` task functions that take a `LanguageModel` (etc.):
   - `generateText({ model, prompt, tools, ... })`
   - `streamText(...)`
   - `generateObject({ schema, ... })`, etc.
2. Provide a minimal “tool loop agent” as an opt-in module.
3. Keep existing provider interface (`ChatCapability`) as compatibility layer or adapter.

Deliverables:

- New recommended docs use `llm_dart_ai`.
- Providers remain swappable and composable.

### MVP 4 — Split providers into independent packages

**Goal**: allow `pub add llm_dart_openai` without installing others.

Actions:

1. Each provider becomes a package depending only on standard layers (+ protocol layer if reused).
2. Umbrella `llm_dart` depends on common providers and re-exports them.

Deliverables:

- True “pick subpackages” experience.
- Faster CI/release for provider-specific fixes.

---

## 8. Backward compatibility strategy

LLM Dart already has users relying on:

- Legacy `ai().openai()...build()` chain builder (umbrella)
- `ChatCapability` / `EmbeddingCapability` / `TextToSpeechCapability` / `SpeechToTextCapability` traits
- `ChatStreamEvent` stream types

Proposed compatibility plan:

1. Keep current APIs in umbrella `llm_dart` for a while.
2. Under the hood, gradually implement them as adapters over the new model/task layers.
3. Mark provider-specific builder conveniences as deprecated in global builder, and re-home them.
4. Provide a migration guide once MVP 3 ships.

---

## 9. Concrete mapping from current code to target split (high-level)

Legacy hotspots that changed during the split (examples from early refactor state):

- Core importing providers (fixed): core no longer imports provider types; provider-specific capability interfaces live in provider packages.
- Core registry importing all provider factories (fixed): built-in registration lives in `BuiltinProviderRegistry` (umbrella).
- Provider-specific features living in “core” (fixed): OpenAI-compatible configs/transformers live in `llm_dart_openai_compatible`.

---

## 10. Open questions (to validate before coding)

1. Do we want `llm_dart_anthropic_compatible` as a separate protocol package (Option A), or should “Anthropic-standard reuse” be done by depending on `llm_dart_anthropic` (Option B)?
   - **Decision**: Option A implemented.
2. Versioning:
   - lockstep versions for all subpackages (monorepo style), or independent semver per package?
3. Migration tolerance:
   - How aggressively can we deprecate the current builder-centric API?
