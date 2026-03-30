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
- the root package now exposes a new `AI` facade plus focused entrypoints such as `ai.dart`, `core.dart`, `openai.dart`, `google.dart`, `anthropic.dart`, `transport.dart`, and `flutter.dart`
- the legacy `llm_dart.dart` entry still exposes `ai()` and the old builder surface while also exporting the new `AI` facade

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
- replay-critical OpenAI Responses metadata now survives decode, session replay, and request re-encoding for assistant message IDs, message phase, reasoning encrypted content, tool-call item IDs, and compaction items
- transport now has a concrete Dio executor, SSE decoder, cancellation abstraction, and error mapping
- provider-specific compatibility subset audits, broader endpoint coverage, and non-text endpoints remain for the next step

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
- the Google text-generation mainline is now wired through `llm_dart_google`
- Google request encoding, result decoding, stream decoding, grounding-source extraction, and typed options are package-owned
- Google thought signatures and reasoning-file artifacts now survive assistant replay, snapshot round-trip, and follow-up prompt reconstruction
- the shared tool-definition boundary is now frozen around common function tools and shared `ToolChoice`
- Anthropic and Google request codecs now consume `GenerateTextRequest.tools` / `toolChoice` for request-side function declarations
- initial provider-native tool entry APIs now exist in `llm_dart_google` and `llm_dart_anthropic`
- the current event decision remains stable: provider-native streamed details stay in common events plus `providerMetadata` or provider-namespaced custom payloads, not new Anthropic-only core events
- broader Google endpoints and additional Anthropic provider-native APIs remain open

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
- the Google compatibility bridge now covers the legacy text/multimodal mainline plus text-only structured-output request encoding
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
- provider stream coverage regression tests now explicitly cover OpenAI reasoning and failed-response paths, Anthropic malformed tool-input events, and Google source/file/reasoning-file stream paths
- the next recommended milestone is now explicit: expand provider coverage tests and renderer helpers without widening the shared event model
- the next provider-specific implementation step is now also explicit: re-audit broader OpenRouter search mapping and any xAI subsets beyond the audited legacy live-search migration subset
- incompatible legacy request shapes and bridge-shape conversion failures fall back to the old provider implementation instead of silently dropping provider-specific behavior
- legacy stream projection is now explicitly frozen as a lossy compatibility surface; richer event semantics remain in `llm_dart_core` and `llm_dart_flutter`
