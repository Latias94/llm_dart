# Milestones

## M1 - Gap Rebaseline

Goals:

- restate the current architecture using present-day code rather than older
  migration assumptions
- freeze which remaining differences versus `repo-ref/ai` are still real

Acceptance criteria:

- the current package graph is written down accurately
- deliberate differences are explicitly named
- the next priorities are feature-driven rather than symmetry-driven

Current status:

- the package graph is now re-baselined after the post-closure priority phase
- the next meaningful gap is now identified as streamed runner maturity rather
  than provider package or event-surface expansion
- `llm_dart_core` concentration is now explicitly tracked as an internal
  boundary-hardening topic, not an automatic package-splitting mandate
- the current event and UI chunk layering is now also re-audited against the
  latest `repo-ref/ai` structure, confirming that `llm_dart` already has the
  same three-layer shape through `TextStreamEvent`, `ChatUiStreamChunk`, and
  accumulated `ChatUiMessage` state
- the transport-neutral `TextStreamEvent -> ChatUiStreamChunk` projection now
  also lives in `llm_dart_core`, keeping the middle-layer mapping aligned with
  the shared UI ownership model instead of only the HTTP server adapter
- `readChatUiStream(...)` now also exposes a narrow additive `stepEvents`
  stream for `StepStartEvent` and `StepFinishEvent` boundaries, improving
  direct reader ergonomics without reopening callback-heavy facades or growing
  `ChatSession`
- `readChatUiStream(...)` now also supports additive metadata and data-part
  validation hooks at the reader layer, covering one of the remaining honest
  gaps versus `repo-ref/ai` without widening shared events or growing
  session/controller lifecycle APIs
- `DefaultChatSession` and `ChatController` diagnostics ownership is now also
  frozen more explicitly: durable state stays in `ChatState`, runtime-only
  app signals stay in `transientDataParts`, direct stream observation and
  validation stay in the reader, and reconnect diagnostics stay transport-owned
- transport and provider diagnostics ownership is now also re-frozen more
  explicitly: common warnings/finish/response identity stay in shared
  result/event/message layers, provider-native detail stays in
  `ProviderMetadata`, and retry/timeout/reconnect tracing stays
  transport-owned
- the remaining meaningful differences are now classified as higher-layer
  reader, validation, or transport-diagnostic questions rather than missing
  shared event families

## M2 - Streamed Runner Productization Decision

Goals:

- decide which higher-level streamed orchestration features belong in shared
  core
- keep provider-specific continuation and approval semantics out of the shared
  runner unless a real cross-provider subset appears

Acceptance criteria:

- the next shared streamed-runner subset is frozen
- deferred features are named explicitly rather than left ambiguous
- any implementation work has a documented boundary before code changes begin

Current status:

- `StreamTextRunner` already provides narrow multi-step stitched streaming plus
  `stepStream` and final `result`
- the current-phase audit now also confirms that the next truthful shared
  subset still stops at the current boundary: no shared `prepareStep`, no
  shared retry/model fallback, and no richer shared stop policy yet

## M3 - `llm_dart_core` Internal Boundary Hardening

Goals:

- keep `llm_dart_core` from becoming the new internal monolith
- clarify internal ownership without premature package fragmentation

Acceptance criteria:

- internal sublayers are documented
- export ownership is classified
- future split triggers are explicit

Current status:

- the internal `llm_dart_core` sublayers are now documented as foundation,
  model/capability, runner, stream/UI, and serialization ownership groups
- future split triggers are now explicit instead of implied by file count alone
- `llm_dart_core` now also exposes additive focused entrypoints for foundation,
  model, UI, and serialization imports without splitting the package
- the focused entrypoints are now proven by real adopters in both
  `llm_dart_transport` and `llm_dart_chat`, not only by isolated compile tests
- package-level README guidance now exists for `llm_dart_core`,
  `llm_dart_transport`, and `llm_dart_community`
- `ChatUiAccumulator` is now internally split across tool, text/reasoning,
  metadata, output, hydration, and data-part support while keeping the same
  public API and shared event surface

## M4 - Root And Package Ownership Clarity

Goals:

- keep the root package understandable as both modern facade and compatibility
  host
- make leaf package ownership easier to follow

Acceptance criteria:

- package-level documentation is improved where needed
- the next root-slimming steps are documented without speculative breakage

Current status:

- the current root role is now re-audited after the latest package moves
- focused provider root shells are now explicitly recognized as narrow and
  honest again
- the root package is now classified as clear enough for the current stage: a
  modern convenience facade plus an explicit compatibility host
- a product-facing migration matrix now exists for routing common app and
  Flutter tasks between the stable shared path, provider-owned options/helpers,
  and explicit compatibility appendices

## M5 - Freeze Review And Next Route

Goals:

- close the current phase with explicit freeze decisions instead of leaving
  “maybe refactor later” ambiguity
- distinguish honest large files from real mixed-boundary hotspots
- state the next route as product evidence rather than structural symmetry

Acceptance criteria:

- the remaining honest hotspots are named explicitly
- reopen triggers are written down
- deferred work is deliberate instead of implied
- the next route after this phase is clear

Current status:

- the remaining large files are now classified as either honest boundaries or
  already-addressed seams rather than automatic split targets
- the main frozen areas are now explicit: shared runner scope, shared event
  surface, OpenAI text request-path structure, package-count symmetry, and
  legacy removal
- session/controller diagnostics widening is now also explicitly frozen unless
  repeated real integrations prove that `ChatState`, `transientDataParts`,
  reader helpers, and transport-owned recovery are still insufficient
- shared request/response diagnostics widening is now also explicitly frozen
  unless repeated real integrations prove that current result fields,
  `ProviderMetadata`, raw chunks, and transport diagnostics are still
  insufficient
- public examples are now also being tightened around the same freeze rule:
  stable shared-model paths first, provider-owned or compatibility boundaries
  second, without reopening package-count or event-surface debates
- a provider-native helper investment audit now also exists so future product
  work can choose additive provider-owned helpers before reopening shared-core
  or package-boundary debates
- the first post-audit provider-owned helper is now landed through the
  OpenAI-profile `OpenAIModerationClient`, proving that safety product value can
  move out of broad compatibility shells without inventing a shared moderation
  abstraction
- OpenAI hosted-file lifecycle now also has a focused OpenAI-profile
  `OpenAIFilesClient`, moving upload/list/retrieve/download/delete out of the
  broad compatibility shell while keeping remote file management provider-owned
- `llm_dart_community` now also exposes an Ollama local `catalog()` helper,
  proving that installed-model pickers and local diagnostics can move out of
  compatibility shells without being mislabeled as a shared model registry
- `llm_dart_community` now also exposes an ElevenLabs `voices()` helper, moving
  voice-picker catalog data into a narrow provider-owned modern surface while
  keeping realtime, cloning, and admin flows outside the shared media contract
- Anthropic file lifecycle is now complete on the focused package path through
  `Anthropic.files()`, so upload/list/metadata/download/delete no longer force
  app code through the root compatibility shell
- reopen triggers are now written down so future refactors can be justified by
  product evidence, repeated bugs, or repeated duplication
- this phase now ends with a clearer architectural rule: keep the shared
  interface small and honest, keep provider-native value provider-owned, and
  avoid symmetry-driven package or API expansion

## M6 - Provider Capability Discovery Direction

Goals:

- define the modern capability discovery direction after the structural
  refactor phase
- keep app-facing capability checks model-centric rather than provider-level
- preserve provider-native feature visibility without widening shared core
- keep the root legacy capability registry as compatibility infrastructure

Acceptance criteria:

- the modern capability discovery unit is defined
- provider-native surfacing channels are documented
- legacy `LLMCapability` placement is explicit
- the first additive implementation slices are ordered

Current status:

- the design now defines capability discovery as a model-centric,
  additive, descriptive layer
- shared feature flags are separated from provider-owned feature descriptors
- provider-native settings, invocation options, metadata, custom parts, and
  native APIs remain the approved surfacing channels
- the next implementation route is additive: core descriptor types first,
  provider-owned describers next, optional marker interfaces after that, and
  Flutter examples last
- the additive core descriptor types and optional marker interface now exist in
  `llm_dart_core` without changing any existing model interface contract
- the first provider-owned describers now exist in `llm_dart_openai`, reusing
  the existing OpenAI-family route and capability helpers for concrete model
  profiles
- provider-owned describers now also exist in `llm_dart_google` and
  `llm_dart_anthropic`, so the model-centric capability layer is now proven
  across OpenAI, Google, and Anthropic rather than only one provider family
- selective community-provider capability profile adoption now also exists in
  `llm_dart_community` for Ollama chat/embeddings and ElevenLabs
  speech/transcription, with app-facing guidance that keeps Ollama
  model-family hints explicit as `inferred` rather than overstating them as
  hard guarantees
- direct model-instance adoption now exists across `llm_dart_openai`,
  `llm_dart_google`, and `llm_dart_anthropic`, where modern provider models
  expose `capabilityProfile` through the optional marker interface without
  widening shared model contracts
- capability-gated examples now exist both as a pure Dart app-facing example
  and as a Flutter Material control demo, showing shared affordance gating,
  provider-native badges, and fallback recommendations
- the workstream is now effectively closed at the active implementation level:
  the remaining unchecked items are explicit deferred-policy triggers rather
  than unfinished architectural slices
