# Open Questions

## P0 - Frozen

## 1. New Top-Level Facade Naming

Originally considered:

- keep `ai()` as the main entry point
- switch to `AI.openai(...).chatModel(...)`
- keep both, with `ai()` as compatibility only

Current conclusion:

- keep both
- new documents should promote `AI.*`
- keep `ai()` until the migration window ends

## 2. Where Provider-Specific Options Should Live

Originally considered:

- pass typed invocation options on each call
- mostly pass typed model options when creating the model
- support both layers

Current conclusion:

- support both layers
- model-level options carry stable provider features
- invocation-level options carry dynamic per-call parameters

## 3. Whether Files, Assistants, and Moderation Belong in the Shared Spec

Current conclusion:

- they do not belong in the phase-1 shared spec
- keep them as provider-package-specific APIs for now

## 4. Whether the Flutter Layer Should Depend on Flutter Foundation

Current conclusion:

- `llm_dart_core` does not depend on Flutter
- `llm_dart_flutter` may depend on `foundation`

## P1 - To Be Confirmed During Phase 1 or 2

## 5. OpenAI-Compatible Family Boundary

Needs confirmation:

- should the OpenAI-compatible family include all xAI and DeepSeek capabilities
- or only the protocol-overlap portion, with special capabilities exposed through separate adapters

Current recommendation:

- move only the protocol-overlap portion into the family core
- represent special capabilities through provider profiles and custom codecs

## 6. Whether the `community` Package Will Grow Too Large

Needs confirmation:

- should Ollama and ElevenLabs stay merged temporarily
- or should they be split from the start

Current recommendation:

- merge them in phase 1
- split later only if complexity justifies it

## 7. Whether `llm_dart_flutter` Should Start in Phase 1

Needs confirmation:

- should it start in parallel with core
- or should it wait until the text mainline stabilizes

Current recommendation:

- define the interfaces early
- implement the full layer in M5

## 8. Whether Generic Remote Provider Options Should Exist In `HttpChatTransport`

Needs confirmation:

- should the generic HTTP chat transport later expose provider-specific remote options
- or should those remain backend-defined contracts outside the generic transport envelope

Current recommendation:

- do not support generic remote provider options in phase 1
- keep the transport request envelope JSON-safe and provider-neutral
- if this capability is needed later, add a separate namespaced transport field instead of serializing typed `ProviderInvocationOptions`

## P2 - Can Be Deferred

## 9. Whether `llm_dart_core` Should Be Published

Current recommendation:

- keep it internal to the repository in phase 1
- evaluate separate publishing only after the API stabilizes

## 10. Whether to Provide a Widget Layer

Current recommendation:

- not in this workstream
- provide state, session, and transport only

## 11. `SourceReference` Typing Status

Resolved in the current breaking round:

- `SourceReference` now carries an explicit `kind`
- the current common kinds are `url`, `document`, and `other`
- `SourceReference` may carry an optional `filename` for document citations
- provider-specific citation detail still belongs in provider metadata
- `GeneratedFile` remains separate from source citations

## 12. Malformed Tool Input Status

Resolved in the current breaking round:

- malformed tool input now uses a dedicated `ToolInputErrorEvent`
- tool execution errors still use `ToolResultEvent(isError: true)`
- Flutter UI projection currently reuses the existing tool error rendering path
- provider adapters can adopt malformed-input signaling incrementally
- `10-malformed-tool-input-design.md` documents the frozen boundary

## 13. Reasoning File Status

Resolved in the current breaking round:

- `reasoning-file` should become a common cross-provider model
- the first concrete driver is Google, because the reference mainline already distinguishes thought-only files in generate, stream, and prompt replay paths
- keep one shared `GeneratedFile` payload and add distinct prompt/content/stream/UI wrappers for reasoning-only files

## 14. How Example-Only Dependencies Should Leave The Root Package

Needs confirmation:

- should example-heavy flows such as MCP integration move into their own example package or app
- or should the root package keep example-only dev dependencies until compatibility cleanup is nearly complete

Current recommendation:

- keep example-only dependencies at the root only as a temporary migration compromise
- once the new facade and package layout stabilize, move examples that need extra dependencies into their own package or app

## 15. Tool Definition Boundary Status

Resolved in the current breaking round:

- `llm_dart_core` now standardizes only common function-tool declarations
- the common tool request model uses object-rooted `ToolJsonSchema`
- shared `ToolChoice` now carries only cross-provider semantics
- provider-native tools remain outside the common request model and continue through provider-owned options or APIs
- `12-tool-definition-boundary.md` documents the frozen boundary

## 16. Provider-Native Tool Entry Status

Resolved in the current breaking round:

- provider-native tools now enter through provider-package typed settings or invocation options
- Google and Anthropic both have initial native tool entry APIs in their provider packages
- invocation-level native tool lists override provider-model defaults
- `13-provider-native-tool-entry.md` documents the frozen boundary

## 17. Assistant Prompt Replay Fidelity Status

Resolved in the current breaking round:

- assistant prompt history must round-trip replayable assistant semantics instead of storing only a display-oriented summary
- replayable prompt parts need optional part-level provider metadata
- reasoning parts, reasoning files, replayable custom parts, and relevant part metadata should survive `ChatUiMessage -> PromptMessage` reconstruction
- citations, UI-only data parts, and transport-only markers still stay out of prompt history

## 18. Legacy Compatibility Facade Status

Resolved in the current breaking round:

- `LLMBuilder.build()` now returns compatibility provider subclasses for migrated OpenAI, Google, Anthropic, DeepSeek, OpenRouter, Groq, and xAI chat paths
- the compatibility layer uses per-request routing instead of one global build-time switch
- bridge-compatible requests go to the new package-owned `LanguageModel` implementations
- unsupported or unported legacy request shapes fall back to the old provider implementations instead of silently degrading behavior
- `15-legacy-compatibility-facade.md` documents the frozen policy

## 19. Legacy Stream Projection Status

Resolved in the current breaking round:

- the old `ChatStreamEvent` surface remains intentionally smaller than the new core stream model
- start markers, response metadata, step markers, files, sources, approvals, denied outputs, and custom events remain in the new core / Flutter layers only
- compatibility projection keeps only the legacy event shapes that the old root-package stream API can represent safely

## 20. Anthropic Provider-Native Result Replay Boundary

Resolved in the current breaking round:

- Anthropic replay and compatibility routing now explicitly follow request-side re-encoding fidelity rather than decode breadth
- the current raw legacy bridge-safe result subset now includes `tool_result`, `mcp_tool_result`, `web_search_tool_result`, and `web_fetch_tool_result` inside their exact replay-safe shapes
- legacy raw `tool_result` replay remains restricted to string `content` so the wire shape does not get normalized into a different JSON form
- `web_search_tool_result` now has a provider-owned replay path through `CustomPromptPart` / `CustomContentPart` / `CustomUiPart`
- `web_fetch_tool_result` now has a provider-owned replay path through `CustomPromptPart` / `CustomContentPart` / `CustomUiPart`
- legacy raw `web_search_tool_result` and `web_fetch_tool_result` now also have restricted bridge paths for exact user-role replay
- `code_execution_tool_result`, `bash_code_execution_tool_result`, and `text_editor_code_execution_tool_result` now have a provider-owned replay path through `anthropic.result.code_execution`
- legacy raw execution result blocks still remain fallback-only
- the recommended execution direction is now one canonical provider-owned kind, `anthropic.result.code_execution`, with exact raw block preservation and provider-owned file handles
- those provider-owned file handles now resolve through the typed `AnthropicFiles` API instead of a shared core file abstraction
- the recommended long-term expansion path remains provider-owned custom parts rather than widening the common core tool-result model with Anthropic-only block typing
- `16-anthropic-provider-native-result-replay.md` documents the frozen boundary
- `18-anthropic-execution-replay-contract.md` documents the execution replay contract and file-handle boundary
- `19-anthropic-provider-native-files-api.md` documents the provider-native files API boundary

## 21. Event Completeness After The UI Audit

Resolved in the current breaking round:

- the current `TextStreamEvent` surface is already sufficient for parity with the reference provider stream layer
- the remaining differences in `repo-ref/ai` are mostly UI transport chunk concepts such as `start`, `finish`, `message-metadata`, and `abort`
- those UI transport concepts should not be copied into the shared Dart event model
- `ToolCallEvent`, `ToolResultEvent`, `ToolInputErrorEvent`, and unified `ToolUiPart` remain the correct Dart mapping for tool lifecycle state
- `StepStartEvent` and `StepFinishEvent` remain shared Dart session semantics even though the reference UI protocol places step markers above the provider stream layer
- the shared event-envelope codec should use `step-start` / `step-end` as the canonical serialized names while keeping legacy `step-finish` decode-compatible during migration
- `20-event-completeness-audit.md` documents the frozen conclusion

## 22. Root OpenAI-Family Facade Status

Resolved in the current breaking round:

- the root `AI` facade now owns the stable convenience entry points for OpenAI-family profiles such as OpenRouter, DeepSeek, Groq, xAI, and Phind
- those constructors are thin profile selections over `llm_dart_openai`, not aliases for legacy root-package provider factories
- legacy `LLMBuilder` and compatibility-provider routing remain independent from the new facade surface
- this keeps the new primary API moving forward without forcing premature migration of every old provider-specific behavior

## 23. OpenAI-Family Legacy Routing Matrix Status

Resolved in the current breaking round:

- Phind should stay out of the compatibility resolver for now
- DeepSeek now has a conservative compatibility route for the audited `deepseek-chat` subset
- OpenRouter now has a conservative compatibility route for the audited plain-chat subset
- Groq now has a conservative compatibility route for the audited text-and-function-tool subset
- xAI now has a conservative compatibility route for the audited text-and-function-tool subset plus the audited legacy live-search migration subset
- Phind has now been re-audited and still stays facade-only because its legacy request and response protocol is provider-specific
- Groq tool replay, multimodal traffic, and ignored legacy extras still stay on legacy fallback
- xAI prompt-side tool replay, multimodal traffic, and unsupported search shapes still stay on legacy fallback
- OpenRouter search-shaped requests and OpenRouter DeepSeek R1 traffic still stay on legacy fallback
- `deepseek-reasoner` and DeepSeek-specific legacy extensions still stay on legacy fallback
- the refactored `llm_dart_openai` package now has an initial OpenAI-family chat-completions mainline, and non-Responses profiles run there directly through the new facade
- the remaining blocker is no longer package runtime support; it is the missing bridge-safe legacy subset audit for each provider, or for each additional subset of an already-routed provider
- each provider also still carries legacy-specific behavior that needs its own audit before a bridge-safe subset can be declared
- `22-openai-family-facade-and-legacy-routing.md` now records the current matrix, blockers, and next prerequisites

## 24. Search Boundary Status

Resolved in the current breaking round:

- shared citation output remains the common boundary through `SourceReference`, `SourceContentPart`, `SourceEvent`, and `SourceUiPart`
- search request controls remain provider-owned and do not widen the shared core or OpenAI-family option surfaces
- provider-native search lifecycle or rich search payloads remain provider-owned through custom parts, custom events, and provider metadata
- legacy builder search fields remain compatibility-only migration inputs rather than the design basis for the new primary API
- `28-provider-owned-search-boundary.md` documents the frozen rule

## 25. OpenRouter And xAI Typed Search Surface Status

Resolved in the current breaking round:

- OpenRouter search in the new primary API is now frozen as provider-owned model/profile shaping rather than a shared invocation-option surface
- the first stable OpenRouter search contract is explicit online-model routing only; legacy `searchPrompt`, `maxSearchResults`, and `useOnlineShortcut` stay compatibility-only until a real wire contract is proven
- the package-owned OpenRouter chat-completions mainline now already accepts `OpenRouterChatModelSettings(search: OpenRouterSearchOptions.onlineModel())`
- the compatibility bridge now also allows the explicit `:online` model shape and the bare `webSearchEnabled` migration input, while richer OpenRouter search helpers still stay on fallback
- xAI chat live search in the new primary API is now frozen as provider-owned invocation options that encode to xAI `search_parameters`
- the package-owned xAI chat-completions mainline now already accepts typed `XAIGenerateTextOptions` and maps xAI citations into shared source parts/events
- legacy `liveSearch`, `webSearchEnabled`, and `webSearchConfig` remain compatibility-only migration inputs instead of stable primary API fields
- the compatibility bridge now also accepts those legacy migration inputs, but only for the audited web/news `search_parameters` subset that the old xAI builder can actually express
- future xAI provider-defined search tools should stay in a separate xAI-native tool API instead of being merged into the chat live-search option bag
- `29-openrouter-search-options-design.md` and `30-xai-live-search-options-design.md` document the frozen design
