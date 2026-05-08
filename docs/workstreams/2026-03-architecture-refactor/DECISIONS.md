# Decisions

## 2026-03-26

The following decisions are considered frozen for this workstream. Any future change should be treated as an explicit architecture change, not a return to open discussion.

## D1. Dual Top-Level Entry Strategy

- Keep `ai()` as a compatibility entry point.
- The new primary architecture should use `AI.*` style model factories.
- During migration, `ai()` becomes a facade only and stops defining the core design.

## D2. Unify Around Model Types and Use-Case Functions

The following objects belong in the shared spec:

- `LanguageModel`
- `EmbeddingModel`
- `ImageModel`
- `SpeechModel`
- `TranscriptionModel`
- `generateText`
- `streamText`
- `embed`
- `generateImage`
- `generateSpeech`
- `transcribe`

The following objects do not belong in the phase-1 shared spec:

- OpenAI Responses CRUD
- provider file, assistant, moderation, or admin APIs
- Anthropic MCP connector

## D3. Provider-Specific Options Use Two Typed Layers

- model-level typed options carry stable provider features
- invocation-level typed options carry per-call provider features
- `extensions` is no longer the main design path and remains compatibility or escape-hatch only

## D4. Message Models Must Stay Layered

Freeze the following three message boundaries:

- Prompt layer
- Result / Stream layer
- UI Chat layer

One message model must no longer attempt to serve all three roles.

## D5. Flutter Integration Uses A Split Runtime + Adapter Design

- `llm_dart_core` does not depend on Flutter
- the reusable chat-session layer lives in `llm_dart_chat`
- `llm_dart_flutter` adds Flutter-specific adapters such as `ChatController`
- phase 1 freezes interfaces first; widget-level implementation is not a first-phase goal

## D6. Use a Medium-Grained Workspace Split

Recommended first-phase package boundaries:

- `llm_dart_core`
- `llm_dart_transport`
- `llm_dart_chat`
- `llm_dart_openai`
- `llm_dart_anthropic`
- `llm_dart_google`
- `llm_dart_community`
- `llm_dart_flutter`
- `llm_dart`

## D7. OpenAI-Compatible Providers Share an OpenAI-Family Core

The following providers should no longer keep fully repeated long-term implementations:

- OpenRouter
- DeepSeek OpenAI-compatible
- Groq OpenAI-compatible
- xAI OpenAI-compatible
- Phind OpenAI-compatible

They should migrate toward an OpenAI-family profile model.

## D8. Dependency Direction Must Be One-Way

Freeze the dependency direction as:

- `llm_dart_core`
- `llm_dart_transport -> llm_dart_core`
- `llm_dart_chat -> core + transport`
- `llm_dart_openai / anthropic / google / community -> core + transport`
- `llm_dart -> core + transport + provider packages`
- `llm_dart_flutter -> llm_dart_chat`, and optionally direct `core` imports for adapter code

Explicitly disallow:

- core depending back on providers
- provider-package dependency cycles
- Flutter packages depending on concrete provider packages
- `llm_dart_flutter` absorbing reusable runtime logic back from `llm_dart_chat`

## D9. Third-Party Dependencies Must Stay in the Right Layer

- keep `dio`, but only inside `transport` and provider implementation layers
- keep `logging` as an internal implementation dependency only
- `http_parser` should stop being a long-term root-package runtime dependency and should be localized after migration
- `mcp_dart` stays out of the main library dependency chain and remains example or integration-package only

## D10. Provider-Specific Features Must Use Five Fixed Channels

Provider-specific features should be represented through:

- typed model settings
- typed invocation options
- provider metadata
- custom content or UI parts
- provider-native extension APIs

`extensions` remains compatibility or escape-hatch only and is no longer a first-class design path.

## D11. Provider Metadata Must Stay Namespaced And JSON-Safe

- `ProviderMetadata` is provider-owned detail, not a substitute for common core fields
- top-level keys must be namespace keys such as `openai`, `anthropic`, or `google`
- metadata values must stay JSON-safe so prompt, UI, and session persistence remain possible
- common concepts that already have stable fields or common UI metadata keys must not be pushed back into provider metadata

## D12. Serialization Must Use Explicit Versioned Codecs

- do not add ad hoc `toJson()` methods across all domain models as the primary design
- prompt history, UI messages, and session snapshots should use explicit codecs
- serialized top-level artifacts must carry a schema version and artifact kind
- session restore must serialize both prompt history and rendered UI messages, not only `ChatState.messages`

## D13. Result And Stream Layers Must Preserve Approval And Common Response Metadata

- `ContentPart` must include a first-class tool approval request part
- provider-executed approval flows must be representable in both `generate()` results and `stream()` events
- `GenerateTextResult` must expose common response metadata fields such as response ID, response timestamp, response model ID, and raw finish reason directly
- `FinishEvent` should carry `rawFinishReason` when the provider exposes one
- provider metadata should keep provider-owned detail and should not be the primary home for those common response fields

## D14. Common Call Controls Must Be Separate From Capability Settings

- do not create one mega shared options type for all model capabilities
- keep capability-specific settings with the capability request or capability-specific settings object
- use a small shared `CallOptions` object for common invocation controls such as timeout, headers, and typed `ProviderInvocationOptions`
- `ProviderInvocationOptions` must remain provider-specific and must not absorb common transport-ish controls

## D15. `TextStreamEvent` Stays a Model-Stream Boundary

- keep `TextStreamEvent` focused on cross-provider model stream semantics
- do not copy the full Vercel AI SDK UI-message chunk protocol into the core stream model
- finer-grained chat transport chunks such as message start/finish markers, abort markers, metadata patches, or UI-only tool chunk variants should be designed later as transport-level serialization for `HttpChatTransport`
- add new core stream events only when they represent stable cross-provider model semantics, not merely a convenient UI transport encoding

## D16. Transport Reconnect Uses Checkpoints Plus Current-Turn Replay

- reconnect remains a transport concern built on transport checkpoint tokens
- `HttpChatTransport` may keep a local replay buffer for the current assistant turn so the session layer can rebuild UI state after network failure
- `DefaultChatSession.resume()` should rebuild the current assistant turn from replay instead of seeding a partial assistant UI snapshot and expecting later deltas to continue safely
- this replay buffer is only for the active assistant turn, not for full chat-history restoration
- do not expand `TextStreamEvent` merely to carry reconnect or replay-only transport mechanics

## D17. `SourceReference` Uses Explicit Kinds

- `SourceReference` must carry an explicit `kind` instead of relying on nullable-field heuristics
- the current common kinds are `url`, `document`, and `other`
- `SourceReference` may also carry an optional `filename`, because document citations often need a stable display filename that should not be inferred from provider metadata
- `GeneratedFile` remains the common model for generated artifacts; citation sources stay separate
- provider adapters should keep provider-specific citation detail in provider metadata instead of widening the common source model for every provider-specific field

## D18. Malformed Tool Input Is A First-Class Stream Event

- malformed tool input must be represented by a dedicated `ToolInputErrorEvent`
- `ToolInputErrorEvent` is for pre-execution failure only
- `ToolResultEvent(isError: true)` remains execution/result-stage failure only
- the first projection round should reuse the existing `ToolUiPartState.outputError` rendering path instead of introducing a second tool-error UI state immediately
- provider adapters may adopt `ToolInputErrorEvent` incrementally when they can identify malformed input reliably

## D19. No Public `provider_utils` Package In Phase 1

- shared networking, streaming, and cancellation mechanics belong in `llm_dart_transport`
- provider-family reuse may live in provider-package-private modules such as `src/shared`
- do not create a public or semi-public `provider_utils` support package until stable multi-provider reuse is proven

## D20. The Root Package Is a Temporary Compatibility And Example Host

- the root `llm_dart` package may temporarily continue to host old-monolith code, compatibility APIs, and example-only dev dependencies
- new architecture work must add dependencies to the owning workspace package first, not to the root package
- root package dependencies should shrink as providers and examples move out, instead of becoming the permanent dumping ground again

## D21. Common Tool Definitions Freeze Around Function Tools Only

- `llm_dart_core` exposes only common function-tool declarations and shared `ToolChoice`
- the common request path currently standardizes `FunctionToolDefinition`, object-rooted `ToolJsonSchema`, and the four shared tool-choice states
- provider-native tools do not enter the common core request model in phase 1
- provider-only tool toggles or built-in tool families must stay in typed provider options or provider-native APIs
- provider adapters are responsible for mapping common function tools into provider wire formats

## D22. Provider-Native Tool Declarations Stay In Provider Packages

- provider-native tool classes belong in the owning provider package
- provider-native tools enter through typed provider model settings or typed invocation options
- invocation-level provider-native tool lists override model-level defaults instead of implicitly merging
- Google mixed-tool declaration and circulation stay provider-owned and model-gated through Google-owned options such as `includeServerSideToolInvocations`
- Anthropic may combine common function tools and provider-native tools when its wire format supports that directly

## D23. `reasoning-file` And Assistant Replay Fidelity Are First-Class

- `reasoning-file` is common cross-provider model semantics and should be represented across prompt, result/content, stream, and UI layers
- keep one shared `GeneratedFile` payload object; distinguish reasoning-vs-final file semantics with wrapper part/event types instead of many file payload classes
- replayable prompt parts should support optional part-level `ProviderMetadata`
- assistant prompt reconstruction must preserve reasoning parts, reasoning files, replayable custom parts, and relevant part metadata instead of collapsing assistant output into text plus pending tool state
- citations, UI-only data parts, and transport markers still stay out of prompt history

## D24. Provider Replay Fidelity Must Be Explicit Per Provider

- the shared core preserves replayable assistant semantics and JSON-safe provider metadata, but it does not force one provider-wire replay shape on every adapter
- provider adapters must either encode provider-valid replay items or emit explicit `ModelWarning`s when a replayable assistant part cannot be represented faithfully
- OpenAI Responses replay should preserve replay-critical metadata such as assistant message item IDs, message phase, reasoning encrypted content, tool-call item IDs, and `openai.compaction` state
- Anthropic Messages replay should preserve assistant text and provider-executed tool replay that maps to Anthropic-native blocks, but it should drop unsupported assistant reasoning/file/custom replay parts with explicit warnings instead of silently flattening them
- conversation-store-specific replay shortcuts such as OpenAI `item_reference` should not enter the shared architecture until the library has an explicit model for stored conversation context

## D25. Legacy Builder Compatibility Must Use Provider Subclasses Plus Safe Runtime Routing

- `LLMBuilder.build()` should keep returning legacy-compatible provider subclasses for migrated providers instead of a bare chat adapter
- the compatibility route now covers the legacy chat mainline for OpenAI, Google, Anthropic, plus audited OpenAI-family subset routes for DeepSeek, OpenRouter, Groq, and xAI
- each compatibility provider should route requests into the new package-owned `LanguageModel` implementation only when the legacy request can be represented faithfully
- unsupported legacy request shapes or bridge-shape conversion failures must fall back to the old provider implementation
- silent capability loss is forbidden; unknown or unported legacy provider features must block bridge usage instead of being dropped

## D26. Legacy Chat Stream Projection Stays Intentionally Lossy

- the rich event model belongs in `llm_dart_core` and `llm_dart_chat`, not in the old root-package `ChatStreamEvent` API
- the compatibility adapter should project only the legacy stream concepts that the old API can represent directly: text deltas, thinking deltas, tool-call deltas, completion, and errors
- start markers, response metadata, step markers, approvals, denied outputs, files, sources, custom events, and raw chunks must stay out of the old stream API
- expanding the old stream surface to mirror the Vercel AI SDK UI chunk vocabulary is explicitly out of scope for phase 1

## D27. Anthropic Provider-Native Result Replay Follows Exact Re-Encoding Fidelity

- Anthropic replay and legacy compatibility routing must be judged by request-side exact re-encoding fidelity, not by how many provider-native result blocks the decoder can recognize
- the current raw legacy bridge-safe Anthropic result subset is `tool_result`, `mcp_tool_result`, `web_search_tool_result`, and `web_fetch_tool_result`, each inside its exact replay-safe input-shape constraints
- `web_search_tool_result` now has both a provider-owned replay path through Anthropic custom prompt/content/UI parts and a restricted legacy raw bridge path for exact user-role replay
- `web_fetch_tool_result` now has both a provider-owned replay path through Anthropic custom prompt/content/UI parts and a restricted legacy raw bridge path for exact user-role replay
- legacy raw Anthropic `tool_result` compatibility stays restricted to string `content` until the new request path can prove that non-string payloads preserve the original wire shape exactly
- execution-oriented Anthropic-native result replay now works through the provider-owned `anthropic.result.code_execution` path, while the legacy raw compatibility bridge still stays fallback-only for those block families
- provider-native execution file handles still stay outside the shared file model until a provider-native file-resolution step yields a real `GeneratedFile`
- `llm_dart_anthropic` now owns the typed provider-native files API for those execution file handles, including metadata lookup and bytes download through Anthropic-specific headers and beta flags
- future Anthropic-native result replay should expand through Anthropic-owned `CustomPromptPart` / `CustomContentPart` / `CustomUiPart` paths or other provider-owned representations, not by widening the common core tool-result model with Anthropic-only block typing

## D28. Event Completeness Follows Shared Stream Semantics, Not UI Chunk Exhaustiveness

- the current `TextStreamEvent` surface is already sufficient for parity with the reference provider stream layer
- UI transport markers such as `start`, `finish`, and `message-metadata` must stay out of the shared core event model
- shared `AbortEvent` remains the one narrow session-lifecycle exception because aborted-turn projection and local stop flows already need a first-class shared signal
- UI-facing tool lifecycle chunk names such as `tool-input-available` or `tool-output-available` should continue to project through `ToolCallEvent`, `ToolResultEvent`, `ToolInputErrorEvent`, and unified `ToolUiPart`
- typed per-tool UI part subclasses do not enter the Dart core model; `ToolUiPart` remains unified with `toolName` and lifecycle state as data
- `StepStartEvent` and `StepFinishEvent` remain valid shared Dart session semantics even though the reference UI stream locates step markers above the provider stream layer
- shared event-envelope serialization should use the canonical names `step-start` and `step-end`, while legacy `step-finish` remains decode-compatible during migration

## D29. `core/` Must Not Own Provider Catalog Implementations

- `core/` should only hold shared abstractions, generic registries, shared models, and compatibility exports
- provider-owned default catalogs, preconfigured provider profiles, and provider-family lookup tables should live in provider packages or internal `src/` modules
- temporary public import paths under `lib/core/*` may remain as compatibility re-exports during migration, but they should no longer be the implementation home

## D30. Remaining Public Dio Injection Is Compatibility-Only

- the stable root builder surface should promote `TransportClient`, not `Dio`
- `HttpConfig.dioClient(Dio)` has been removed from the stable builder API
- if a temporary raw-Dio migration shim is ever reintroduced, it must stay outside the main builder contract
- new docs, examples, and migrated code should use `transportClient(TransportClient)` instead of teaching raw `Dio` injection
- if raw Dio injection must survive temporarily, it should move behind a compatibility-oriented surface instead of remaining a first-class stable API
- no new stable root or core APIs should accept transport-implementation types such as `Dio`, `DioException`, `FormData`, `MultipartFile`, or `CancelToken`

## D31. The Root `AI` Facade Should Be The OpenAI-Family Convenience Entry

- the stable `AI` facade should expose direct constructors for OpenAI-family profiles such as OpenRouter, DeepSeek, Groq, xAI, and Phind
- those convenience constructors should build the refactored `llm_dart_openai` package entry with a frozen profile, not route through legacy provider factories
- facade convenience and legacy compatibility routing are separate concerns
- adding a family constructor to `AI` does not imply that `LLMBuilder.build()` or the old provider subclasses should switch to the new path for that provider automatically

## D32. OpenAI-Family Legacy Routing Must Remain Subset-Audited

- Phind must stay out of the compatibility resolver until the refactored `llm_dart_openai` package has both a usable package mainline and an explicit bridge-safe subset for that provider
- the initial OpenAI-family chat-completions mainline now exists, but that alone is not sufficient to enable automatic legacy routing
- DeepSeek now has a narrow audited compatibility subset for `deepseek-chat`,
  including namespaced `providerOptions.deepseek` request options, while
  `deepseek-reasoner` and old flat DeepSeek-specific legacy extensions still
  remain fallback-only
- OpenRouter now has a narrow audited plain-chat compatibility subset, while search-shaped requests and OpenRouter DeepSeek R1 traffic still remain fallback-only
- Groq now has a narrow audited text-and-function-tool compatibility subset, while tool replay, multimodal traffic, and ignored legacy extras still remain fallback-only
- xAI now has an audited text subset plus an audited legacy live-search migration subset, while prompt-side tool replay, provider-native search semantics beyond shared citations, and unsupported search shapes still remain fallback-only
- Phind has now been re-audited and still remains outside the compatibility resolver because its legacy request and response protocol is not a plain chat-completions shape
- each provider still needs an explicit bridge-safe subset audit before automatic routing is enabled or expanded
- the root `AI` facade may move ahead of compatibility routing, but the compatibility resolver must remain conservative

## D33. Search Request Controls Stay Provider-Owned While Shared Citations Stay Common

- the shared core keeps only provider-agnostic citation and source models such as `SourceReference`, `SourceContentPart`, `SourceEvent`, and `SourceUiPart`
- search request controls must not widen the shared OpenAI-family or core option surfaces
- provider-specific search behavior should enter through provider-owned typed options, provider-owned native tools, or provider-owned profile/request shaping
- richer provider-native search payloads stay in provider-owned `CustomPromptPart` / `CustomContentPart` / `CustomEvent` / `CustomUiPart` paths
- legacy builder fields such as `webSearchEnabled` and `webSearchConfig` remain compatibility-only migration inputs, not the design basis for the new primary API

## D34. OpenRouter And xAI Search Stay Provider-Owned In Different Ways

- OpenRouter search in the new primary API is profile-owned or model-owned shaping, not a shared invocation-option surface
- the first stable OpenRouter search contract should model only explicit online-model routing; legacy helpers such as `searchPrompt`, `maxSearchResults`, and `useOnlineShortcut` remain compatibility-only until a tested wire contract exists
- xAI chat live search in the new primary API is a provider-owned invocation option that encodes to xAI `search_parameters`
- legacy `liveSearch`, `webSearchEnabled`, and `webSearchConfig` remain compatibility-only migration inputs rather than stable primary API fields
- future xAI provider-defined search tools such as web search or X search must stay in a separate provider-native tool API instead of being merged into the chat live-search options bag

## D35. Legacy Preset Factory Helpers Should Deprecate Once A Stable Chat Facade Exists

- the repository should keep one honest base compatibility constructor per legacy provider family while the old root-package provider surface still matters
- extra preset helpers such as chat/reasoning/vision/code convenience constructors should become deprecated once the stable `AI.*(...).chatModel(...)` replacement already exists
- deprecation should not be applied to old helper surfaces that still have no stable package-owned replacement yet
- new examples and new docs should stop presenting deprecated preset helpers as recommended API

## D36. Old Root Compatibility APIs Stay Out Of Routine Maintenance Releases

- deprecated compatibility APIs should keep working throughout the `0.x` line
- the old root-package compatibility surface should not be removed in routine
  maintenance releases
- removal should happen only after a migration guide, updated examples, and explicit release-note coverage exist
- deprecation pressure belongs in `0.x`; hard removal belongs only in an
  explicit breaking prerelease or later stable breaking release

## D37. Bridge-Incompatible Provider-Native Result Blocks Need Migration-Oriented Messaging

- fallback-only provider-native result families should not fail with generic unsupported wording when the repository already knows their migration boundary
- if a provider-owned replay path already exists, compatibility guidance should point users at that provider-owned path and also state that the raw legacy bridge still falls back
- if no provider-owned replay path exists yet, compatibility guidance should tell users to keep the request on the old provider path
- this messaging rule is documentation and diagnostics policy; it does not widen the bridge allowlist by itself

## D38. Generic Cross-Layer Errors Use A Typed `ModelError` Envelope

- generic shared error channels such as `ErrorEvent.error`, `ChatState.error`, snapshot error state, and UI metadata error lists must use a typed `ModelError` envelope instead of raw `Object` payloads
- `ModelError` should keep one small stable shape: `kind`, `message`, optional `code`, optional `statusCode`, optional `isRetryable`, optional JSON-safe `details`, and optional `originalType`
- provider top-level error payloads should normalize to `kind: provider`
- transport exceptions and transport-level error chunks should normalize to `kind: transport`
- `FormatException` and similar local parsing/validation failures should normalize to `kind: validation`
- stream-ordering and reconstruction failures should normalize to `kind: stream`
- decoders must stay backward compatible with legacy raw string or map error payloads by normalizing them during decode
- `ToolInputErrorEvent` remains a separate dedicated event and is not absorbed into the generic error envelope

## D39. Flutter Tool Continuation Waits For Whole-Step Completion

- `TextStreamEvent` remains unchanged; tool continuation is a Flutter session concern, not a new shared event family
- `DefaultChatSession` must not continue the next assistant turn after only the first individual tool update when the current assistant step still has unresolved work
- client-executed tool calls continue only after all pending local tool outputs for the current step have been provided
- provider-executed approval responses continue only after the current step no longer waits for other approvals or client-side tool outputs
- mixed approval outcomes must be decided from the whole step state, not only from the most recent approval click
- future convenience helpers such as automatic local tool callbacks belong in `llm_dart_chat` above the current session boundary, while Flutter-only adapters stay in `llm_dart_flutter`

## D40. Automatic Local Tool Execution Stays Out Of `llm_dart_core`

- execute-style tool convenience such as `onToolCall` must stay in `llm_dart_chat`, not in `llm_dart_core`
- the callback may observe a client-executed tool call and optionally return a local tool output or local tool error result
- automatic local tool execution must reuse the existing `addToolOutput` continuation path instead of introducing a second protocol
- provider-executed tools stay out of this convenience surface
- callback failures should become tool error results for the current tool call instead of escalating into generic chat-session errors
- approval remains a gating step for client-executed tools; automatic local execution can only start after approval has been granted

## D41. Step Lifecycle Maturity Must Live Above `TextStreamEvent`

- the remaining maturity gap versus `repo-ref/ai` is not missing shared core event families
- `TextStreamEvent` remains the raw shared provider-stream boundary and should not grow UI transport markers or richer orchestration callbacks
- the current `LanguageModel.generate/stream` plus `generateText` / `streamText` helpers remain single-step provider-call abstractions
- if `llm_dart` later adds step lifecycle hooks such as `onStepStart`, `onStepFinish`, or final aggregated completion callbacks, those must land in a higher-level multi-step runner above the existing event model instead of changing the meaning of the current low-level helpers
- that callback layer should build `StepResult`-style snapshots from existing common models such as content parts, tool calls/results, sources, files, finish metadata, usage, warnings, and provider metadata
- Flutter chat/session APIs must stay independent from that future step-lifecycle callback layer
- provider-native capabilities must remain provider-owned even after such lifecycle hooks exist; callbacks are not a new excuse to widen the common request or event model

## D42. Chat Runtime Alignment Adopts Transport Request Customization, Not React Store APIs

- `llm_dart_chat` should adopt request-side transport maturity where it is
  genuinely shared runtime infrastructure:
  - explicit transport request triggers
  - JSON-safe request metadata
  - `HttpChatTransport` request customization hooks for send and reconnect
- those hooks belong to the transport/session boundary and must not serialize
  typed provider invocation options into the generic HTTP chat protocol
- `ChatSession` must not adopt generic local message-store mutation APIs such
  as `setMessages`
- React/UI-framework store subscription ergonomics remain adapter concerns and
  stay out of the shared Dart runtime
- callback-heavy continuation policy copied from `repo-ref/ai`
  `sendAutomaticallyWhen` should not enter `llm_dart_chat` unless a concrete
  Dart-side requirement is proven later

## D43. Root `chat.dart` Exposes Pure Dart Chat Runtime, Not Flutter Adapters

- the root package may expose a focused `package:llm_dart/chat.dart` entrypoint
  as a thin convenience shell over `llm_dart_chat`
- that entrypoint may also re-export `core.dart`, `transport.dart`, and the
  stable `AI` facade so pure Dart chat applications do not need a second root
  import
- the root `chat.dart` entrypoint must not re-export `llm_dart_flutter`,
  `ChatController`, or other Flutter-only adapter types
- `llm_dart_flutter` remains the only Flutter-specific package entrypoint
- `llm_dart.dart` should not absorb `chat.dart` back into the broad root barrel
  when that would reintroduce ambiguous exports or weaken the focused-entrypoint
  boundary
- docs should recommend `package:llm_dart/chat.dart` as the focused pure Dart
  chat-app import

## D44. Root `legacy.dart` Is The Explicit Compatibility Shell

- the root package may expose `package:llm_dart/legacy.dart` as the explicit
  compatibility import target for builder-era and legacy broad-surface code
- `legacy.dart` should own its broad compatibility export list explicitly
  before `llm_dart.dart` shrinks, so root-barrel slimming does not implicitly
  narrow the compatibility shell
- modern code should prefer focused entrypoints such as `ai.dart`, `chat.dart`,
  `openai.dart`, `google.dart`, `anthropic.dart`, `core.dart`, and
  `transport.dart`
- `legacy.dart` must not become the place where new stable model APIs grow
- the long-term goal is that `legacy.dart`, not `llm_dart.dart`, carries the
  explicit weight of compatibility expectations

## D45. Transient UI Data Stays Above Persisted `ChatUiMessage` State

- the remaining worthwhile chat-runtime gap versus `repo-ref/ai` is
  transport/session support for transient `data-*` delivery, not more shared
  core event types
- persisted UI data should continue to use `DataUiPart<T>` inside
  `ChatUiMessage.parts`
- transient UI data now lands at the `ChatUiStreamChunk` / `ChatSession` /
  transport layer rather than in `TextStreamEvent`
- the framework-neutral delivery hook is a session/controller side-channel
  stream, not a Flutter-specific callback contract
- transient UI data must not enter prompt history, persisted message parts,
  reconnect replay, or snapshots by default
- do not add a `transient` flag directly to `DataUiPart<T>` because that would
  blur the boundary between durable message state and non-persistent runtime
  notifications

## D46. Examples Must Not Teach The Broad Root Barrel By Default

- examples that demonstrate modern stable usage should prefer focused
  entrypoints such as `ai.dart`, `chat.dart`, `core.dart`, `openai.dart`,
  `google.dart`, and `anthropic.dart`
- examples that intentionally demonstrate builder-era or compatibility flows
  should prefer `package:llm_dart/legacy.dart`
- the broad `package:llm_dart/llm_dart.dart` barrel may remain public during
  migration, but examples should stop treating it as the default import path
- this boundary exists so future root-barrel slimming can happen without
  example code quietly reintroducing broad-surface expectations

## D47. Root `llm_dart.dart` Is Now The Modern Default Entrypoint

- after `legacy.dart` became an explicit compatibility shell with its own
  export list, `package:llm_dart/llm_dart.dart` should shrink to a thin modern
  default entrypoint
- in the current breaking round, that root barrel now re-exports the same
  stable surface as `package:llm_dart/ai.dart`
- builder-era compatibility APIs such as `ai()`, `createProvider(...)`,
  `LLMBuilder`, legacy models, and compatibility utilities should no longer be
  exported from the default root barrel
- those compatibility expectations now belong behind
  `package:llm_dart/legacy.dart`

## D48. `ai.dart` Remains An Explicit Alias Of The Root Modern Surface

- `package:llm_dart/llm_dart.dart` is the default documented import for modern
  onboarding and general stable usage
- `package:llm_dart/ai.dart` remains a public, stable, explicit alias of that
  same modern surface
- docs, examples, and tests must not imply that `ai.dart` exposes a broader or
  semantically different stable API than the root modern entrypoint
- teams may still choose `ai.dart` when they prefer a named import that makes
  AI ownership explicit
- compatibility growth must continue to land in `package:llm_dart/legacy.dart`,
  not in either modern entrypoint

## D49. `llm_dart_core` Must Stop Depending On `llm_dart_transport`

- the current `llm_dart_core <-> llm_dart_transport` package cycle is a
  temporary architecture violation, not an accepted steady state
- `llm_dart_core` must not keep importing or re-exporting
  `llm_dart_transport`
- shared request-lifecycle primitives such as cancellation must move to a
  placement that restores one-way dependency direction
- do not solve this by adding another tiny public workspace package only for
  cancellation; the medium-grained package strategy still stands
- `llm_dart_transport` may continue depending on `llm_dart_core` for shared
  model and codec types

## D50. `llm_dart_community` Must Not Depend On Root Compatibility Surfaces

- `llm_dart_community` may depend on `llm_dart_core` and
  `llm_dart_transport`
- `llm_dart_community` must not depend on the root `llm_dart` package or on
  root-local compatibility builders as an implementation layer
- current compatibility-era Ollama and ElevenLabs behavior should stay rooted in
  the root compatibility shell until their provider-owned code is actually
  decoupled from root-local legacy types and utilities
- do not move Ollama or ElevenLabs into `llm_dart_community` through a blind
  file relocation that would either invert dependency direction or duplicate
  broad compatibility APIs
