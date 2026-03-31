# Milestones

## M0 - Architecture Freeze

Goals:

- freeze the core boundary documents
- freeze Prompt, Result, UI Message, and Stream Event naming
- freeze package boundaries

Acceptance criteria:

- the documents in this directory complete review
- all P0 questions in `OPEN_QUESTIONS.md` have conclusions

## M1 - Core Skeleton

Goals:

- establish the workspace
- make `llm_dart_core` and `llm_dart_transport` compile
- provide empty or minimal implementations for the new spec and shared functions

Acceptance criteria:

- the new package structure lands in the main branch
- the basic test foundation exists
- the old code still compiles

Current status:

- the workspace package skeleton is in place
- the workspace now also has an internal `llm_dart_test` package for shared fake transport and language-model helpers
- the root package now exposes a new `AI` facade plus focused entrypoints such as `ai.dart`, `core.dart`, `openai.dart`, `google.dart`, `anthropic.dart`, and `transport.dart`
- Flutter chat APIs now live behind the dedicated `llm_dart_flutter` package entrypoint instead of a root-package re-export
- the legacy `llm_dart.dart` entry still exposes `ai()` and the old builder surface while also exporting the new `AI` facade
- core usage, warning, and provider metadata models now have centralized merge semantics, JSON-safe provider-metadata serialization checks, and shared test coverage
- generic cross-layer errors now normalize into a typed `ModelError` envelope across stream events, UI metadata, Flutter session state, transport mapping, and snapshot persistence

## M2 - OpenAI Mainline

Goals:

- migrate OpenAI chat and responses to the new architecture
- make `generateText` and `streamText` usable
- establish the OpenAI-family profile mechanism

Acceptance criteria:

- the OpenAI text mainline works
- streaming, tool calling, reasoning, and structured-output coverage tests pass

Current status:

- minimal Responses-based text generation is implemented in `llm_dart_openai`
- an initial OpenAI-family chat-completions mainline now also exists in `llm_dart_openai`, including OpenAI opt-out from Responses plus default chat-completions routing for non-Responses profiles
- streaming text, reasoning summaries, and function-call outputs are mapped into the new core models
- chat-completions decoding now also covers text, reasoning text, tool calls, and streamed tool-input aggregation for the initial OpenAI-family path
- chat-completions request encoding now also covers user `FilePromptPart` mapping for image, audio, and PDF inputs in the migrated OpenAI-family path, and the Responses-first OpenAI compatibility route now again covers the common user image/file subset through migrated request encoding
- replay-critical OpenAI Responses metadata now survives decode, session replay, and request re-encoding for assistant message IDs, message phase, reasoning encrypted content, tool-call item IDs, and compaction items
- transport now has a concrete Dio executor, SSE decoder, cancellation abstraction, error mapping, per-attempt diagnostics, and transport-owned retry/timeout helpers
- `llm_dart_core` now also exposes `OutputSpec`-based `generateOutput(...)`, `streamOutput(...)`, and `streamOutputResult(...)`, with shared validation errors, a shared streamed-result accumulator above `TextStreamEvent`, best-effort partial structured-output events on the streaming path, buffered `partialOutputStream` / `elementStream<T>()` / final `output` result surfaces, and array `OutputElementEvent`s for newly completed elements
- `llm_dart_core` now also exposes additive main-call wrappers, `generateTextCall(...)` and `streamTextCall(...)`, so parsed output can live on a richer shared call surface without redefining the original low-level `generateText(...)` / `streamText(...)` helpers
- that naming direction is now also frozen: the additive call wrappers are the recommended app-facing text API, while the original helper names remain the low-level raw layer
- `llm_dart_core` now also exposes function-based shared capability helpers for non-text calls: `embed(...)`, `embedMany(...)`, `generateImage(...)`, `generateSpeech(...)`, and `transcribe(...)`
- the OpenAI family now has package-owned embedding and image model surfaces through `OpenAI.embeddingModel(...)` and `OpenAI.imageModel(...)`, with typed `OpenAIEmbeddingModelSettings` / `OpenAIImageModelSettings` and typed `OpenAIEmbedOptions` / `OpenAIImageOptions`
- the OpenAI family now also has package-owned `speechModel(...)` and `transcriptionModel(...)` surfaces with typed provider options, byte-response speech decoding, and multipart transcription request encoding above the transport layer
- Google now also has package-owned embedding, image, and speech model surfaces through `Google.embeddingModel(...)`, `Google.imageModel(...)`, and `Google.speechModel(...)`, with typed `GoogleEmbeddingModelSettings` / `GoogleImageModelSettings` / `GoogleSpeechModelSettings` and typed `GoogleEmbedOptions` / `GoogleImageOptions` / `GoogleSpeechOptions`
- Google current stable surfaces now also cover text-side candidate/safety/modality options plus Gemini image safety settings, while image and speech modality selection stay on their capability-specific model surfaces instead of one generic option bag
- `llm_dart_core` now also exposes `GenerateTextStepResult` as the first shared step-level snapshot wrapper without changing the single-step meaning of `generateText` / `streamText`
- `llm_dart_core` now also exposes `GenerateTextRunResult` and `GenerateTextStepStartEvent` as runner-facing pure model primitives
- `llm_dart_core` now also has a narrow non-streaming multi-step `GenerateTextRunner` and `runTextGeneration(...)` entrypoint that accumulates step snapshots, replays prior assistant/tool messages, and continues common function-tool steps through an app-supplied executor
- that runner boundary is still intentionally narrow: `generateText` / `streamText` remain single-step helpers, there is no shared `prepareStep`, and provider-native built-in tools, dynamic tools, and approval-gated continuation stay outside the shared runner
- continuation ownership is now also frozen more clearly: common function-tool loops belong to the shared runner, while approval-gated, provider-executed, dynamic, and chat-interactive continuation remain provider-owned or session-owned
- the stop-and-mutation boundary is now also frozen: `maxSteps` stays a guardrail, shared `stopWhen` and `prepareStep` stay out, and retry/model-switch policy remains app-owned
- only a separate streamed runner or a tightly-constrained pre-step hook may be reconsidered later if real shared usage proves the need
- provider-specific compatibility subset audits, broader endpoint coverage, and the remaining Google provider-owned streamed TTS plus any optional legacy multimodal-output projection decisions remain for the next step, while Anthropic is now mostly down to narrower provider-native replay-policy cleanup

## M3 - Anthropic And Google

Goals:

- migrate the Anthropic and Google mainlines
- represent provider-specific features through typed options, provider metadata, and custom parts

Acceptance criteria:

- Anthropic reasoning, tools, and MCP connector paths work
- Google chat, image, embedding, and TTS paths work

Current status:

- the Anthropic text-generation mainline is now wired through `llm_dart_anthropic`
- Anthropic request encoding, result decoding, stream decoding, MCP request models, and typed options are package-owned
- Anthropic assistant replay now keeps native tool replay paths and emits explicit warnings when unsupported assistant reasoning/file/custom replay parts are dropped
- Anthropic now also has package-owned provider-native replay paths for `web_search_tool_result`, `web_fetch_tool_result`, `tool_search_tool_result`, and execution-oriented result families, plus the provider-owned `AnthropicFiles` API for downloadable execution file handles
- Anthropic replay-policy cleanup is now largely closed, and the provider package now also exposes public tool-search native tools plus provider-owned deferred-loading controls for common function tools; the remaining Anthropic tool gap is now mainly optional custom tool-reference helpers and any future provider-owned native-tool selection surface
- the Google text-generation mainline is now wired through `llm_dart_google`
- Google now also has package-owned embedding, image, and speech model surfaces, and the current shared `ImageModel` / `SpeechModel` boundaries are now explicitly generation-only while image editing, image variation, and streamed TTS remain provider-owned
- Google request encoding, result decoding, stream decoding, grounding-source extraction, and typed options are package-owned
- Google thought signatures and reasoning-file artifacts now survive assistant replay, snapshot round-trip, and follow-up prompt reconstruction
- the shared tool-definition boundary is now frozen around common function tools and shared `ToolChoice`
- Anthropic and Google request codecs now consume `GenerateTextRequest.tools` / `toolChoice` for request-side function declarations
- initial provider-native tool entry APIs now exist in `llm_dart_google` and `llm_dart_anthropic`
- the current event decision remains stable: provider-native streamed details stay in common events plus `providerMetadata` or provider-namespaced custom payloads, not new Anthropic-only core events
- the provider tool/continuation matrix is now explicit: OpenAI Responses remains provider-owned and richer, OpenAI chat-completions stays function-tool-only, Anthropic mixes native and shared request tools but keeps provider-executed continuation provider-owned, and Google native tools remain provider-owned with a model-gated Gemini 3 mixed-tool path behind `includeServerSideToolInvocations`
- native-tool selection direction is now also frozen: shared `ToolChoice` stays unchanged, provider-owned selection must stay provider-owned and mutually exclusive with shared `toolChoice`, Anthropic is the first realistic candidate, and Google should not expose a public selection API until its mixed-tool policy needs are clearer than the current model-gated circulation contract
- the Google mixed-tool migration target is now also explicit and partially landed: the provider-owned Gemini 3 path now combines built-in tools and common function tools, replays server-side tool context through Google-owned custom parts, and keeps the shared core unchanged
- Google common function-tool replay now also preserves provider-originated Gemini 3 `functionCall.id` values through decode, shared-runner continuation, and request re-encoding when the provider actually returned those IDs
- Google now also has a provider-owned `google.result.function_response` replay helper for exact multimodal `functionResponse.parts` follow-up encoding, keeping richer Gemini 3 tool-result replay out of the shared tool-result model
- Google now also has provider-owned assistant-side `toolCall` / `toolResponse` replay helpers plus Gemini 3 request encoding for `includeServerSideToolInvocations`, so mixed-tool follow-up turns can preserve server-side tool context without widening shared events
- Google now also decodes assistant-side server `toolCall` / `toolResponse` parts into provider-owned custom content/events and can re-encode those custom prompt parts back into assistant history without widening shared events
- Google now also exposes provider-owned `GoogleCustomPart` parsing helpers so Flutter or other UI layers can render those custom replay payloads through one typed entrypoint without adding Google-specific logic to `llm_dart_flutter`
- Google now also exposes provider-owned `GoogleCustomPartSummary` helpers so Flutter or other UI layers can build lightweight render summaries without reparsing raw Google payload JSON
- Google now also exposes a provider-owned `GoogleMessageMapper` so Flutter or other UI layers can combine Google custom replay parsing with Google-specific part metadata such as thought signatures, `responsePart`, and file/tool IDs
- broader Google endpoints, any future Anthropic custom tool-reference helper surface, and any future Anthropic provider-owned tool-selection surface remain open

## M4 - Community Providers

Goals:

- move DeepSeek, Groq, xAI, and Phind into the OpenAI-family profile model
- move Ollama and ElevenLabs into the community package

Acceptance criteria:

- long-tail providers no longer duplicate full OpenAI implementations
- provider duplication drops visibly

## M5 - Flutter Chat Layer

Goals:

- make `llm_dart_flutter` usable
- land `ChatSession`, `ChatTransport`, and `ChatState`
- make both direct and HTTP transports work
- freeze a versioned HTTP request/chunk protocol that sits above `TextStreamEvent`

Acceptance criteria:

- the Flutter chat example runs on the new API
- reasoning, tools, sources, and files render naturally
- assistant-turn replay remains semantically faithful enough for follow-up provider calls, not only visually faithful in the UI
- HTTP transport reconnect semantics are defined through transport checkpoints rather than ad hoc core events

Current status:

- the baseline Flutter chat layer now has stable session, transport, controller, persistence, and message-mapper surfaces in `llm_dart_flutter`
- tool continuation is now also frozen more concretely at the session layer: mixed approval and tool-output steps wait for whole-step completion before the next assistant request is triggered
- `DefaultChatSession` now also offers an optional local `onToolCall` convenience callback for client-executed tools without pushing execute-style APIs back into `llm_dart_core`
- `llm_dart_flutter` now also exposes `ToolExecutionRegistry` as a thin name-based wrapper above `onToolCall`

## M6 - Compatibility Cleanup

Goals:

- degrade the old builder and capability interfaces into compatibility layers
- remove the old bus-style internals

Acceptance criteria:

- the README is centered on the new API
- old APIs have explicit deprecation markers
- duplicate registry logic, string-extension mainlines, and mixed-layer message logic are removed

Current status:

- `LLMBuilder.build()` now returns compatibility provider subclasses for OpenAI, Google, Anthropic, and the audited OpenAI-family subset routes when the builder has enough core config
- `LLMBuilder.build()` now also returns a compatibility DeepSeek provider subclass, but its routing remains restricted to the audited `deepseek-chat` subset
- `LLMBuilder.build()` now also returns a compatibility OpenRouter provider subclass, but its routing remains restricted to the audited plain-chat subset
- `LLMBuilder.build()` now also returns a compatibility Groq provider subclass, but its routing remains restricted to the audited text-only-and-function-tool-definition subset
- `LLMBuilder.build()` now also returns a compatibility xAI provider subclass, and its routing now covers the audited text subset plus the audited legacy live-search migration subset
- those compatibility providers route legacy chat requests into the new package-owned `LanguageModel` implementations only when the request shape is explicitly bridge-compatible
- the OpenAI compatibility bridge now covers the legacy text mainline plus common function tools, built-in tools, and structured output request encoding
- the DeepSeek compatibility bridge now covers the initial `deepseek-chat` text-and-function-tool subset while keeping `deepseek-reasoner` and DeepSeek-specific extensions on legacy fallback
- the OpenRouter compatibility bridge now covers the initial plain-chat subset while keeping search-shaped requests and OpenRouter DeepSeek R1 traffic on legacy fallback
- the Groq compatibility bridge now covers the initial text-and-function-tool-definition subset while keeping tool replay, multimodal traffic, and ignored legacy extras on legacy fallback
- the xAI compatibility bridge now covers the audited text-and-function-tool-definition subset plus the audited legacy live-search migration inputs (`liveSearch`, `searchParameters`, `webSearchEnabled`, `webSearchConfig`) for the web/news search-parameters subset, while prompt-side tool replay, multimodal traffic, unsupported search shapes, and ignored legacy extras stay on legacy fallback
- Phind has now been explicitly audited and still remains facade-only because the legacy provider protocol is not a plain chat-completions bridge target
- the Google compatibility bridge now covers the legacy text/multimodal mainline, image-generation-adjacent request settings, generated-image stream marker projection, and text-only structured-output request encoding
- the Anthropic compatibility bridge now covers legacy prompt-cache markers, lossless raw text/user-image/user-document `contentBlocks`, lossless raw assistant `tool_use` / `server_tool_use` / `mcp_tool_use` replay, lossless raw user `tool_result` / `mcp_tool_result` replay, and `MessageBuilder` tools blocks when they can map into prompt parts, provider metadata, and typed Anthropic cache options without silent feature loss
- Anthropic bridge gating is now explicitly anchored to request-side re-encoding fidelity, and the legacy raw bridge now explicitly allows `web_search_tool_result` and `web_fetch_tool_result` only inside exact replay-safe shapes
- the new Anthropic replay path now preserves `web_search_tool_result` through Anthropic-owned custom content/UI/prompt parts for session replay and request re-encoding, with matching legacy raw bridge support for exact user-role replay
- the new Anthropic replay path now preserves `web_fetch_tool_result` through Anthropic-owned custom content/UI/prompt parts for session replay and request re-encoding, with matching legacy raw bridge support for exact user-role replay
- the new Anthropic replay path now also preserves execution-oriented provider-native result blocks through `anthropic.result.code_execution`, while keeping the legacy raw bridge conservative
- `llm_dart_anthropic` now also exposes a provider-native `AnthropicFiles` API and file-handle helpers for execution downloads without widening the shared core
- the event completeness audit against `repo-ref/ai` is now also frozen: the shared stream model is already sufficient, and remaining lifecycle chunk gaps are transport/UI concerns rather than missing core event types
- the provider-owned search direction is now also frozen more concretely: OpenRouter search remains profile/model shaping, while xAI live search becomes provider-owned invocation options over `search_parameters`
- the package-owned OpenRouter mainline now also accepts provider-owned online-model settings, and the compatibility bridge now allows the explicit `:online` shape plus the bare `webSearchEnabled` migration input
- the package-owned xAI chat-completions mainline now also accepts typed `XAIGenerateTextOptions` and projects xAI citations through shared source parts and events
- legacy compatibility `jsonSchema` now routes through shared `GenerateTextOptions.responseFormat` instead of provider-specific compat injection, and shared `JsonResponseFormat` now also carries `strict` for OpenAI-family encoding
- deprecated compatibility markers now also cover the legacy preset helper families whose stable `AI.*(...).chatModel(...)` replacement already exists
- the old root-package compatibility removal window is now frozen as “no earlier than `1.0.0`”
- fallback-only provider-native Anthropic result families now also carry explicit migration guidance instead of generic unsupported wording
- provider stream coverage regression tests now explicitly cover OpenAI reasoning and failed-response paths, Anthropic malformed tool-input events, and Google source/file/reasoning-file stream paths
- the next recommended milestone is now explicit: expand provider coverage tests and renderer helpers without widening the shared event model
- the next provider-specific implementation step is now also explicit: re-audit broader OpenRouter search mapping and any xAI subsets beyond the audited legacy live-search migration subset
- incompatible legacy request shapes and bridge-shape conversion failures fall back to the old provider implementation instead of silently dropping provider-specific behavior
- legacy stream projection is now explicitly frozen as a lossy compatibility surface; richer event semantics remain in `llm_dart_core` and `llm_dart_flutter`
