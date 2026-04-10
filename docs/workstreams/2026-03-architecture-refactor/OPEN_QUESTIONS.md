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
- `llm_dart_chat` does not depend on Flutter
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

## 7. Whether The Reusable Chat Runtime Should Stay Inside `llm_dart_flutter`

Current conclusion:

- split the reusable runtime into `llm_dart_chat`
- keep `llm_dart_flutter` as the thin Flutter adapter layer
- this keeps the package count medium-grained while matching the reference
  layering principle more closely

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
- the remaining differences in `repo-ref/ai` are mostly UI transport chunk concepts such as `start`, `finish`, `message-metadata`, and transient `data-*` delivery
- those UI transport concepts should not be copied into the shared Dart event model
- `ToolCallEvent`, `ToolResultEvent`, `ToolInputErrorEvent`, and unified `ToolUiPart` remain the correct Dart mapping for tool lifecycle state
- `StepStartEvent` and `StepFinishEvent` remain shared Dart session semantics even though the reference UI protocol places step markers above the provider stream layer
- `AbortEvent` is now the narrow shared lifecycle exception for aborted-turn projection and local stop flows rather than evidence that full message lifecycle markers belong in the core event layer
- the transport-only transient UI-data target is now implemented above persisted `ChatUiMessage` state through runtime/session chunks and a framework-neutral side-channel, not through more shared core events
- the shared event-envelope codec should use `step-start` / `step-end` as the canonical serialized names while keeping legacy `step-finish` decode-compatible during migration
- `20-event-completeness-audit.md` documents the frozen conclusion
- `93-ui-transport-transient-data-boundary.md` documents the frozen boundary and the implemented transient delivery path

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

## 26. Legacy Preset Factory Deprecation Scope

Resolved in the current breaking round:

- the repository now distinguishes between stable primary chat facades, base compatibility constructors, and deprecated compatibility preset helpers
- extra chat/reasoning/vision/code preset helpers should now deprecate once the stable `AI.*(...).chatModel(...)` replacement already exists
- base compatibility constructors should stay non-deprecated when the old root provider surface is still needed
- helper surfaces with no stable replacement yet should not be deprecated prematurely
- `33-legacy-factory-entrypoint-deprecations.md` documents the frozen scope

## 27. Old Compatibility API Removal Window

Resolved in the current breaking round:

- deprecated compatibility APIs should stay alive throughout the `0.x` line
- the old root-package compatibility surface should not be removed before `1.0.0`
- removal should happen only after migration documentation and updated stable examples exist
- `34-legacy-api-removal-window.md` documents the frozen policy

## 28. Bridge-Incompatible Provider Result Guidance

Resolved in the current breaking round:

- fallback-only provider-native result families should now describe the migration direction explicitly instead of using generic unsupported wording
- if a provider-owned replay path already exists, migration guidance should point users to that path while still keeping the raw legacy bridge on fallback
- if no provider-owned replay path exists yet, migration guidance should point users to the old provider path instead
- `35-bridge-incompatible-provider-result-migration-guidance.md` documents the frozen wording rule

## 29. Step Lifecycle And Step Result Boundary

Resolved in the current breaking round:

- the remaining maturity gap versus `repo-ref/ai` is mainly step-lifecycle orchestration, not missing shared core stream events
- `TextStreamEvent` remains the raw provider-stream boundary and should not absorb UI transport markers or callback-oriented lifecycle payloads
- the current `LanguageModel.generate/stream` plus `generateText` / `streamText` helpers remain single-step provider-call abstractions
- if step-level hooks are added later, they should live in a higher-level multi-step runner above those low-level helpers and synthesize `StepResult`-style snapshots from the existing common models
- those synthesized step results should be built from current shared data such as content parts, tool calls/results, sources, files, finish metadata, usage, warnings, and provider metadata
- Flutter chat/session APIs remain on the message/session projection layer and should not depend on the future step-lifecycle callback surface
- `42-provider-capability-and-step-lifecycle-boundary.md` documents the frozen conclusion
- `43-single-step-calls-vs-multi-step-runner.md` documents the runner boundary

## 30. Shared Runner Continuation Ownership

Resolved in the current breaking round:

- the shared runner now owns only declared common function-tool continuation
  through an app-supplied executor
- if that executor is missing, the runner stops honestly and returns the
  current run result instead of pretending it can continue unsupported work
- approval-gated continuation stays outside the shared runner
- provider-executed built-in tools stay provider-owned
- dynamic or schema-less tool families stay provider-owned or app-owned until a
  truly common contract exists
- Flutter chat adapters remain separate, but local-output and approval timing
  now belong to the shared `llm_dart_chat` session runtime
- `45-continuation-ownership-matrix.md` documents the frozen ownership rule

## 31. Shared Runner Stop Policy And Mutation Hooks

Resolved in the current breaking round:

- the current shared runner keeps `maxSteps` only as a guardrail
- shared `stopWhen` semantics do not enter phase-1 `llm_dart_core`
- shared `prepareStep` mutation hooks still stay out of the runner
- retry budgets, retry classification, fallback chains, and model switching stay
  app-owned
- if streamed multi-step orchestration is added later, it should be a separate
  layer above `streamText(...)`, not a redefinition of the current single-step
  stream helper
- `46-runner-stop-policy-and-mutation-hooks.md` documents the frozen boundary

## 32. Provider Tool And Continuation Matrix

Resolved in the current breaking round:

- OpenAI Responses remains the richer provider-owned continuation path for
  built-in tools and approvals
- OpenAI chat-completions remains a function-tool-only mainline with explicit
  rejection or warning-based downgrade for provider-native continuation shapes
- Anthropic can mix native and shared tool declarations in one request, but
  provider-executed continuation and native result families remain
  provider-owned
- Google native tools remain provider-owned, and Gemini 3 mixed native-plus-
  function-tool requests now stay model-gated behind
  `includeServerSideToolInvocations`
- provider-native tool forcing or selection must remain provider-owned rather
  than widening shared `ToolChoice`
- `47-provider-tool-and-continuation-matrix.md` documents the audited matrix

## 33. Provider-Owned Native Tool Selection

Resolved in the current breaking round:

- shared `ToolChoice` stays limited to the common function-tool contract
- provider-owned native-tool forcing or selection must stay in provider-owned
  settings or invocation options
- provider-owned native-tool selection must not silently merge with shared
  `toolChoice`
- Anthropic is the first realistic provider candidate for a later
  provider-owned selection surface
- Google should not expose a public native-tool selection API until a concrete
  policy need appears beyond the current model-gated mixed-tool circulation
  contract
- `48-provider-owned-native-tool-selection-design.md` documents the frozen
  design

## 34. Google Mixed-Tool Migration Contract

Resolved in the current breaking round:

- official Gemini 3 docs now describe a broader mixed built-in/function-tool
  `generateContent` path
- that path depends on server-side tool-context circulation rather than just a
  wider request-side tool list
- `llm_dart_google` now implements a provider-owned Gemini 3 mixed-tool subset:
  built-in tools plus function declarations in one request, guarded by
  `includeServerSideToolInvocations`
- current Google behavior stays intentionally conservative outside that subset:
  non-Gemini-3 models reject the circulation flag, and native-tool calls
  without the flag still warning-drop shared function-tool config
- one replay prerequisite is now closed:
  provider-originated Gemini 3 `functionCall.id` values now survive decode and
  common function-tool continuation when the provider actually returned them
- another replay prerequisite is now closed:
  Google now has a provider-owned `google.result.function_response` helper for
  exact multimodal `functionResponse.parts` follow-up replay of common
  function-tool results
- another circulation slice is now closed:
  assistant-side Google server `toolCall` / `toolResponse` parts can now round
  trip through provider-owned custom content/UI/prompt/event payloads without
  widening the shared event model
- the remaining Google questions are now about public selection policy and
  richer Flutter/renderer projection, not about widening shared `ToolChoice`
  or the shared runner
- `49-google-mixed-tool-migration-design.md` documents the frozen migration
  design

## P1 - Newly Opened After The Current Refactor Round

## 35. Structured Generation And Main Text Call Naming Status

Resolved in the current breaking round:

- shared structured generation should not freeze around standalone
  `generateObject` / `streamObject` naming
- shared structured generation should continue through `OutputSpec`
- `generateTextCall(...)` and `streamTextCall(...)` are now the recommended
  app-facing text call layer
- `generateText(...)` and `streamText(...)` remain the low-level raw helpers
- `generateOutput(...)`, `streamOutput(...)`, and `streamOutputResult(...)`
  remain focused convenience surfaces above the same shared contracts
- `51-shared-structured-output-boundary.md` records the output-spec boundary
- `52-structured-output-result-surface.md` records the streamed result surface
- `53-main-text-call-result-layer.md` records the additive main-call result
  layer
- `54-main-text-api-naming-freeze.md` records the frozen naming decision

## 36. Shared Streamed Runner Status

Resolved in the current breaking round:

- `llm_dart_core` now also provides `StreamTextRunner` /
  `streamTextRun(...)` as an additive streamed multi-step orchestration layer
- `streamText(...)` remains the raw single-step helper
- the streamed runner stays intentionally narrow and mirrors the same shared
  continuation subset as `GenerateTextRunner`
- the stitched `eventStream` now stays provider-step-only in the narrow phase
  instead of synthesizing local tool-result or other inter-step projection
  events
- `165-streamed-runner-design.md` documents the additive streamed-runner
  boundary
- `166-streamed-runner-inter-step-projection-policy.md` documents the frozen
  inter-step projection policy

## 37. Whether `llm_dart_chat` Needs A Dedicated Finish Callback Surface

Needs confirmation:

- should `ChatSession` later expose a dedicated `onFinish`-style callback or
  observer surface
- or should final-state and final-message handling continue to rely on the
  existing `states` stream only

Current recommendation:

- keep the current `states`-driven runtime contract for now
- only revisit a dedicated finish callback if at least two concrete Flutter or
  backend integration cases show that state-stream diffing is too indirect

## 38. Remote UI Stream Layer Status

Resolved in the current breaking round:

- the repository should add a dedicated UI/session chunk layer above
  `TextStreamEvent` and below `ChatUiMessage`
- that new layer should stay narrower than `repo-ref/ai` and should not copy a
  second full text/tool/reasoning chunk vocabulary
- the recommended initial runtime chunk families are `message-start`,
  `message-metadata`, `event`, `data-part`, and `message-finish`
- HTTP transport wire control remains separate; `checkpoint`, `keepalive`, and
  reconnect tokens stay transport-owned rather than entering the shared UI
  chunk model
- a future richer HTTP protocol revision should separate `transport-start`
  from `message-start` instead of continuing the current mixed `start` chunk
- `87-dedicated-ui-stream-chunk-layer.md` documents the frozen direction

## 39. Root Chat Entrypoint Boundary Status

Resolved in the current breaking round:

- the root package now exposes `package:llm_dart/chat.dart` as the focused
  pure Dart chat-runtime entrypoint
- that entrypoint re-exports `llm_dart_chat`, `core.dart`, `transport.dart`,
  and the stable `AI` facade
- Flutter adapters remain outside the root package and continue through
  `package:llm_dart_flutter/llm_dart_flutter.dart`
- `91-root-chat-entrypoint-boundary.md` documents the frozen boundary

## 40. Root Legacy Entrypoint Boundary Status

Resolved in the current breaking round:

- the root package now exposes `package:llm_dart/legacy.dart` as the explicit
  compatibility shell
- migration-oriented code can depend on that compatibility entrypoint before the
  broad `llm_dart.dart` barrel shrinks further
- focused modern imports should continue through `ai.dart`, `chat.dart`,
  provider entrypoints, `core.dart`, and `transport.dart`
- `92-legacy-entrypoint-boundary.md` documents the frozen boundary
