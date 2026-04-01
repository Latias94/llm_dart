# 2026-03 Architecture Refactor

## Background

`llm_dart` already supports a broad set of providers, but its core abstractions are becoming too heavy:

- `LLMConfig.extensions` and `ChatMessage.extensions` now carry too many provider-specific concerns.
- `ChatCapability`, `AudioCapability`, `ImageGenerationCapability`, and similar interfaces are mixed with concrete provider behavior.
- `LLMBuilder`, `capability.dart`, and `chat_models.dart` have gradually turned into bus files.
- OpenAI, OpenAI-compatible providers, DeepSeek, xAI, Groq, and Phind contain repeated code and conditional branching.
- Flutter integration is still too close to direct provider calls and lacks a real chat-focused message and session layer.

This workstream is not about a file-moving refactor. It is about defining stable boundaries first, and then rewriting against those boundaries.

## Questions This Workstream Must Answer

1. Which interfaces should actually be unified, and which capabilities should stay provider-specific?
2. How should we borrow the layering ideas from the Vercel AI SDK without copying its package granularity?
3. What should the Dart-specific best-practice boundaries be?
4. Which APIs should be exposed to make Flutter chat applications easy to integrate?
5. How do we sequence a breaking refactor without turning it into an uncontrolled rewrite?

## Document Index

- [00-current-architecture-audit.md](00-current-architecture-audit.md)
  - Current repository audit, quantified problem signals, and the mapping to the target architecture.
- [01-design-principles.md](01-design-principles.md)
  - Design goals, non-goals, layering rules, and Dart-specific constraints.
- [02-unified-api-and-boundaries.md](02-unified-api-and-boundaries.md)
  - Unified API scope, stable boundaries, message models, and provider feature handling.
- [03-package-and-module-split.md](03-package-and-module-split.md)
  - Recommended workspace and package split, plus package-internal module boundaries.
- [04-flutter-chat-integration.md](04-flutter-chat-integration.md)
  - Chat session, transport, and UI-facing design for Flutter applications.
- [05-migration-strategy.md](05-migration-strategy.md)
  - Migration phases, compatibility strategy, risk control, and validation.
- [06-dependencies-and-provider-features.md](06-dependencies-and-provider-features.md)
  - Third-party dependency policy, package dependency direction, and the provider feature support model.
- [07-serialization-and-metadata-conventions.md](07-serialization-and-metadata-conventions.md)
  - Provider metadata namespace rules, custom kind naming, and the versioned serialization protocol.
- [08-http-chat-transport-and-stream-protocol.md](08-http-chat-transport-and-stream-protocol.md)
  - Request/stream protocol design for `HttpChatTransport`, reconnect checkpoints, and the transport boundary above `TextStreamEvent`.
- [09-event-and-ui-projection-gap-analysis.md](09-event-and-ui-projection-gap-analysis.md)
  - Comparison with the Vercel AI SDK UI stream design, plus recommendations for event completeness and UI projection boundaries.
- [10-malformed-tool-input-design.md](10-malformed-tool-input-design.md)
  - Dedicated design note for separating malformed tool input from tool execution failure without over-expanding the UI state machine.
- [11-anthropic-migration-plan.md](11-anthropic-migration-plan.md)
  - Anthropic-specific migration slicing, module layout, and feature-placement rules for the new package.
- [12-tool-definition-boundary.md](12-tool-definition-boundary.md)
  - Frozen boundary for common function tools, `ToolChoice`, and provider-native tool placement.
- [13-provider-native-tool-entry.md](13-provider-native-tool-entry.md)
  - Typed entry rules for Google and Anthropic native tools without widening the common core.
- [14-provider-replay-fidelity-policy.md](14-provider-replay-fidelity-policy.md)
  - Frozen replay policy for OpenAI, Anthropic, and the shared provider boundary.
- [15-legacy-compatibility-facade.md](15-legacy-compatibility-facade.md)
  - Frozen strategy for compatibility provider subclasses, conservative chat routing, automatic fallback, and legacy stream event projection.
- [16-anthropic-provider-native-result-replay.md](16-anthropic-provider-native-result-replay.md)
  - Frozen boundary for Anthropic provider-native result replay, exact re-encoding requirements, and the recommended provider-owned custom-part path for future expansion.
- [17-execution-result-and-event-boundary.md](17-execution-result-and-event-boundary.md)
  - Recommended next-step design for execution-oriented provider-native result replay, event boundaries, and Flutter-facing UI projection.
- [18-anthropic-execution-replay-contract.md](18-anthropic-execution-replay-contract.md)
  - Canonical payload contract for Anthropic execution replay, file-handle rules, and capability matrix.
- [19-anthropic-provider-native-files-api.md](19-anthropic-provider-native-files-api.md)
  - Frozen provider-owned files API for Anthropic execution file handles, download boundaries, and Flutter integration guidance.
- [20-event-completeness-audit.md](20-event-completeness-audit.md)
  - Audit of current `TextStreamEvent` completeness versus `repo-ref/ai`, plus the frozen boundary between shared events and UI transport chunks.
- [21-residual-dio-public-surface.md](21-residual-dio-public-surface.md)
  - Audit of the remaining root-level `dio` public API exposure, plus the recommended exit path for deprecated custom-Dio injection.
- [22-openai-family-facade-and-legacy-routing.md](22-openai-family-facade-and-legacy-routing.md)
  - Boundary between the new OpenAI-family facade constructors and the still-conservative legacy compatibility routing.
- [23-deepseek-legacy-compatibility-audit.md](23-deepseek-legacy-compatibility-audit.md)
  - First provider-specific bridge-safe-subset audit for an OpenAI-family compatibility route after the new chat-completions mainline landed.
- [24-openrouter-legacy-compatibility-audit.md](24-openrouter-legacy-compatibility-audit.md)
  - OpenRouter-specific compatibility audit for the plain chat subset versus the still-fallback search-shaped legacy surface.
- [25-groq-legacy-compatibility-audit.md](25-groq-legacy-compatibility-audit.md)
  - Groq-specific compatibility audit for the text-and-tool-definition subset versus the still-fallback tool-replay, multimodal, and ignored-extra legacy surface.
- [26-xai-legacy-compatibility-audit.md](26-xai-legacy-compatibility-audit.md)
  - xAI-specific compatibility audit for the text subset, the audited legacy live-search migration subset, and the still-fallback tool-replay/multimodal legacy surface.
- [27-phind-legacy-compatibility-audit.md](27-phind-legacy-compatibility-audit.md)
  - Phind-specific audit that freezes the current facade-only status and records why no legacy bridge-safe subset should be assumed yet.
- [28-provider-owned-search-boundary.md](28-provider-owned-search-boundary.md)
  - Frozen boundary for provider-owned search request options, shared source projection, and provider-native search replay/UI rendering.
- [29-openrouter-search-options-design.md](29-openrouter-search-options-design.md)
  - Frozen OpenRouter search design that keeps search as profile-owned model shaping instead of widening shared OpenAI-family invocation options.
- [30-xai-live-search-options-design.md](30-xai-live-search-options-design.md)
  - Frozen xAI live-search design that separates chat `search_parameters` from future provider-defined search tools.
- [33-legacy-factory-entrypoint-deprecations.md](33-legacy-factory-entrypoint-deprecations.md)
  - Frozen deprecation scope for compatibility-only preset factory helpers once the stable `AI` facade replacement already exists.
- [34-legacy-api-removal-window.md](34-legacy-api-removal-window.md)
  - Frozen removal window for the old root-package compatibility APIs, with the earliest removal point set no earlier than `1.0.0`.
- [35-bridge-incompatible-provider-result-migration-guidance.md](35-bridge-incompatible-provider-result-migration-guidance.md)
  - Frozen migration wording for provider-native result families that still stay outside the legacy bridge allowlist.
- [36-provider-stream-coverage-matrix.md](36-provider-stream-coverage-matrix.md)
  - Frozen matrix for which shared stream event families belong in provider codecs versus session or transport layers, using `repo-ref/ai` only as a layering reference.
- [37-prompt-normalization-contract.md](37-prompt-normalization-contract.md)
  - Frozen replay-safe prompt subset and the provider-owned normalization gaps for multimodal input, approval flows, and assistant reasoning replay.
- [38-migration-guide.md](38-migration-guide.md)
  - Practical migration guide from the old root-package compatibility surface to the stable model API.
- [39-error-model-design.md](39-error-model-design.md)
  - Typed cross-layer error envelope design for stream events, transport, Flutter session state, and persistence.
- [40-flutter-tool-orchestration-boundary.md](40-flutter-tool-orchestration-boundary.md)
  - Frozen session-layer rule for batching tool outputs and approval-driven continuation without widening shared events.
- [41-local-tool-execution-convenience.md](41-local-tool-execution-convenience.md)
  - Frozen boundary for `onToolCall`-style local tool execution convenience in `llm_dart_flutter`.
- [42-provider-capability-and-step-lifecycle-boundary.md](42-provider-capability-and-step-lifecycle-boundary.md)
  - Frozen conclusion that the remaining maturity gap versus `repo-ref/ai` is step-lifecycle orchestration above the raw stream boundary, not more shared core events or wider provider abstractions.
- [43-single-step-calls-vs-multi-step-runner.md](43-single-step-calls-vs-multi-step-runner.md)
  - Frozen boundary between the current single-step model helpers and the higher-level shared multi-step orchestration runner.
- [44-step-result-and-runner-api-design.md](44-step-result-and-runner-api-design.md)
  - Concrete API direction for `GenerateTextStepResult`, runner callbacks, and the intentionally narrow shared runner scope.
- [45-continuation-ownership-matrix.md](45-continuation-ownership-matrix.md)
  - Frozen ownership matrix for shared runner continuation versus provider-native, approval-gated, dynamic, and Flutter-session orchestration.
- [46-runner-stop-policy-and-mutation-hooks.md](46-runner-stop-policy-and-mutation-hooks.md)
  - Frozen boundary for `maxSteps`, future `stopWhen`-style policies, `prepareStep`, streaming orchestration, and app-owned retry/model-switch logic.
- [47-provider-tool-and-continuation-matrix.md](47-provider-tool-and-continuation-matrix.md)
  - Audited provider matrix for tool declaration, provider-native continuation, approval handling, warning-based downgrade rules, and shared-runner ineligibility.
- [48-provider-owned-native-tool-selection-design.md](48-provider-owned-native-tool-selection-design.md)
  - Frozen design for provider-owned native-tool forcing/selection without widening shared `ToolChoice`, including Anthropic-first and Google-model-gated constraints.
- [49-google-mixed-tool-migration-design.md](49-google-mixed-tool-migration-design.md)
  - Frozen migration design for Gemini 3 mixed built-in/function tools, provider-owned server-side tool-context circulation, and the remaining Google-owned policy gaps after the first mixed-tool subset landed.
- [50-repo-ref-structure-gap-review.md](50-repo-ref-structure-gap-review.md)
  - Consolidated review of what is already structurally aligned with `repo-ref/ai`, which differences are deliberate, and which structural gaps still remain worth addressing.
- [51-shared-structured-output-boundary.md](51-shared-structured-output-boundary.md)
  - Recommended direction for closing the structured-generation gap through a shared output-specification layer rather than freezing provider-owned `responseFormat` as the long-term API.
- [52-structured-output-result-surface.md](52-structured-output-result-surface.md)
  - Incremental streamed structured-output result surface that adds dedicated partial-output, element, and final-output access without redefining `streamText(...)`.
- [53-main-text-call-result-layer.md](53-main-text-call-result-layer.md)
  - Additive main text-call result layer that exposes richer shared result surfaces without redefining the low-level helpers.
- [54-main-text-api-naming-freeze.md](54-main-text-api-naming-freeze.md)
  - Frozen naming decision that keeps `generateText(...)` / `streamText(...)` as low-level helpers and promotes `generateTextCall(...)` / `streamTextCall(...)` as the app-facing text API.
- [55-shared-capability-helper-parity.md](55-shared-capability-helper-parity.md)
  - Frozen capability-helper direction that adds shared `embed(...)`, `embedMany(...)`, `generateImage(...)`, `generateSpeech(...)`, and `transcribe(...)` entrypoints without copying the full internal complexity of `repo-ref/ai`.
- [56-anthropic-status-reconciliation.md](56-anthropic-status-reconciliation.md)
  - Status reconciliation for the Anthropic workstream, including which TODO items are already implemented and which replay-policy gaps actually remain.
- [57-google-compatibility-modality-status.md](57-google-compatibility-modality-status.md)
  - Status reconciliation for the Google compatibility modality slice, including which multimodal bridge shapes are already covered and which legacy output limits remain intentional.
- [58-openai-chat-migration-status.md](58-openai-chat-migration-status.md)
  - Status reconciliation for the OpenAI-family chat migration, including the narrowed chat-completions request-shaping and assistant-replay gaps plus the still-open Responses-first compatibility policy question.
- [59-openai-provider-owned-input-hints.md](59-openai-provider-owned-input-hints.md)
  - Frozen provider-owned OpenAI prompt-hint contract for `fileId` and `imageDetail` without widening the shared prompt model.
- [60-openai-assistant-replay-alignment.md](60-openai-assistant-replay-alignment.md)
  - Audit of which OpenAI assistant replay warning-drops are intentionally aligned with `repo-ref/ai` and which remaining gaps are still provider-owned.
- [61-openai-responses-persistence-policy.md](61-openai-responses-persistence-policy.md)
  - Frozen conclusion that `store`, `conversation`, and `item_reference` belong to OpenAI-owned Responses persistence policy rather than the shared core.
- [62-openai-logprobs-alignment.md](62-openai-logprobs-alignment.md)
  - Frozen conclusion that OpenAI `logprobs` belongs to typed provider options plus provider metadata, not the shared core.
- [63-openai-chat-system-message-mode.md](63-openai-chat-system-message-mode.md)
  - Frozen conclusion that OpenAI chat-completions `system/developer/remove` shaping belongs to provider-owned request encoding, not the shared prompt model.
- [64-openai-chat-reasoning-compatibility.md](64-openai-chat-reasoning-compatibility.md)
  - Frozen conclusion that OpenAI chat-completions reasoning-model compatibility belongs to provider-owned request encoding and capability gating, not the shared text-generation spec.
- [DECISIONS.md](DECISIONS.md)
  - Architecture decisions that are currently frozen.
- [TODO.md](TODO.md)
  - Executable task list.
- [MILESTONES.md](MILESTONES.md)
  - Phase milestones and acceptance criteria.
- [OPEN_QUESTIONS.md](OPEN_QUESTIONS.md)
  - Decisions that are not yet fully closed.

## Current Summary

### Layers That Should Be Unified

- Text generation model interfaces
- Embedding model interfaces
- Image generation model interfaces
- Speech generation and transcription model interfaces
- UI-facing chat message models
- Stream event models

### Layers That Should Not Be Forced Into the Stable Unified Spec

- Stateful OpenAI Responses API features
- Anthropic MCP connector
- Provider-native file, assistant, moderation, and admin APIs
- Provider-specific model catalogs, beta features, and experimental parameters

### Recommended Overall Direction

- Borrow the Vercel AI SDK split of spec layer, shared utility layer, provider adapters, and UI layer.
- Do not copy its one-package-per-provider publishing strategy.
- Build an internal workspace first, then decide later which packages should be published separately.
- Let the root `AI` facade expose the OpenAI-family providers as convenience constructors, while keeping legacy compatibility routing as a separate concern.
- Keep search typed APIs provider-owned: OpenRouter through model/profile shaping, xAI through provider-owned invocation options, and shared core only on sources/citations.
- Keep richer provider-native replay contracts provider-owned as well, using custom parts and provider metadata instead of widening shared tool-result models.
- Get the text generation path and the Flutter chat path right first, and migrate everything else afterward.
- Prioritize the remaining real structural gaps over package-count parity with the reference: shared structured generation, carefully-scoped streamed orchestration, capability-module parity, and the intentionally thin remote chat protocol.

### Remaining Structural Gaps Versus `repo-ref/ai`

- Shared structured output now exists in `llm_dart_core` through `OutputSpec`, `generateOutput(...)`, `streamOutput(...)`, and `streamOutputResult(...)`, and the additive main-call layer now also exists through `generateTextCall(...)` and `streamTextCall(...)`; legacy compatibility `jsonSchema` now also routes through the shared `responseFormat` path, streamed structured output now has dedicated `partialOutputStream`, `elementStream<T>()`, and final `output/result` surfaces above the raw event stream, and the naming direction is now frozen: the additive call layer is the app-facing text API while the original helper names remain the low-level raw layer.
- The shared runner is intentionally narrow and non-streaming; the reference still has a more mature streamed multi-step orchestration loop.
- Shared capability helper parity now also exists in `llm_dart_core` through `embed(...)`, `embedMany(...)`, `generateImage(...)`, `generateSpeech(...)`, and `transcribe(...)`; embedding, image, and speech migrations now already exist across the OpenAI-family and Google providers through `OpenAI.embeddingModel(...)`, `OpenAI.imageModel(...)`, `OpenAI.speechModel(...)`, `Google.embeddingModel(...)`, `Google.imageModel(...)`, and `Google.speechModel(...)`, and the OpenAI family now also has package-owned `transcriptionModel(...)` migrations. The remaining gap is now Google provider-owned streamed TTS, the still-intentionally thin legacy multimodal-output projection, and the still-unfrozen question of whether embeddings later need shared chunk-splitting policy above the raw model interface; Anthropic is now mostly down to optional custom tool-reference helpers and provider-owned selection, not a replay-policy tail or a separate non-text model migration track.
- OpenAI-family chat migration is closer to the reference now that the chat-completions path accepts user image/audio/PDF file inputs, the Responses-first compatibility route again covers the common user image/file subset, and the OpenAI chat path now aligns on provider-owned reasoning-model compatibility such as `reasoningEffort`, `maxCompletionTokens`, `forceReasoning`, `max_completion_tokens` mapping, and `serviceTier` validation; the main remaining OpenAI-owned gap is now the still-unexposed Responses persistence policy around `store`, `conversation`, and `item_reference`, while assistant replay remains intentionally conservative on the chat-completions path.
- OpenAI provider-owned `logprobs` handling is now aligned with `repo-ref/ai` through typed `OpenAIGenerateTextOptions.logprobs`, Responses-side automatic `include/top_logprobs` encoding, and text-part / stream-event provider metadata decode, without widening the shared text-generation contract.
- OpenAI chat-completions request shaping now also aligns better with the reference through provider-owned `systemMessageMode`, including OpenAI reasoning-model defaulting to `developer` without widening the shared prompt model.
- The remote chat protocol is thinner than the reference `ui-message-stream` layer, which is acceptable for now but still a conscious structural gap.

### Current Audit Signals

- The current `lib/` directory contains 134 source files, and `providers/` alone accounts for 96 of them.
- `LLMBuilder`, `capability.dart`, and `chat_models.dart` have already become bus files.
- `extensions/getExtension/extension` related entry points appear 258 times in `lib/`, which means string-based extensions have already become a primary design path.
- `dio` appears 70 times across `lib/packages/test/example`, which shows that transport details have already leaked into too many layers.

## Recommended Phase-1 Freeze Items

The following items should be frozen before deeper implementation work continues:

1. Unified interface boundaries
2. Prompt, UI message, and stream event data structures
3. How provider-specific features are represented
4. Workspace package boundaries
5. The minimal Flutter `ChatSession` and `ChatTransport` API
6. Third-party dependency policy and inter-package dependency direction
7. Assistant replay fidelity, including reasoning files and prompt-part metadata preservation

These freeze points are expanded in the documents in this directory.
