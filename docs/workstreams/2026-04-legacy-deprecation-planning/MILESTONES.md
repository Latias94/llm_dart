# Milestones

## M1 - Legacy Surface Inventory

Goals:

- identify the remaining public legacy surface groups
- separate true migration rails from removable convenience aliases

Acceptance criteria:

- a repository-level inventory exists
- each main public legacy group has a current posture
- modern stable surfaces are explicitly excluded from the cleanup target

Current status:

- the initial inventory is now written down in
  `00-legacy-surface-inventory.md`
- the main surface groups are now classified as keep, freeze, or
  soft-deprecate

## M2 - Deprecation Policy Freeze

Goals:

- define the public status vocabulary for legacy cleanup
- freeze the release rules for annotation versus removal

Acceptance criteria:

- the status vocabulary is explicit
- no-removal patch policy is written down
- breaking-window prerequisites are documented

Current status:

- the initial deprecation policy is now written down in
  `01-deprecation-policy.md`
- the default rule is now clear: remove leaves before trunks

## M3 - Migration Sequence Decision

Goals:

- define the practical order for docs, deprecation, and removal
- avoid a sequence that strands users without a coherent migration rail

Acceptance criteria:

- the repository has a staged migration sequence
- builder posture is explicitly deferred until recipes are ready
- the first breaking window stays conservative

Current status:

- the initial sequence is now written down in `02-migration-sequence.md`
- the workstream now explicitly treats modern docs-first cleanup as the first
  real step

## M4 - Removal Readiness Freeze

Goals:

- map the main legacy surface groups to concrete next actions
- prevent future cleanup from becoming vague or ad hoc

Acceptance criteria:

- the main public symbols have a readiness posture
- blockers are named explicitly
- "keep", "deprecate", and "remove" are not conflated

Current status:

- the first readiness table is now written down in
  `03-removal-readiness-matrix.md`
- the repository now has a default answer for which symbols are first-breaking
  candidates and which are not

## M5 - Implementation Preparation

Goals:

- turn the planning phase into a concrete implementation queue
- decide what should happen in the next docs/code round

Acceptance criteria:

- examples and README usage audits are complete
- the first deprecation wave is scoped
- breaking-window candidates are backed by migration notes

Current status:

- the README and example audit is now complete in
  `04-readme-and-example-audit.md`
- the first stable-helper rewrite pass is now complete in
  `example/02_core_features` for embeddings, audio, and image generation
- the second stable-helper rewrite pass is now complete in
  `example/02_core_features` for enhanced tool calling and error handling
- the third rewrite pass is now complete in `example/02_core_features` for
  assistants and file management, reframing them as explicit provider
  boundaries instead of stable shared capability examples
- the fourth rewrite pass is now complete in `example/02_core_features` for
  content moderation and model discovery, separating provider-owned endpoints
  from app-owned policy and capability-profile usage
- the Anthropic prompt-caching appendix no longer depends on the broad
  `legacy.dart` barrel and now uses focused typed imports instead
- `example/02_core_features` is now effectively down to two explicit
  compatibility appendix files:
  `capability_factory_methods.dart` and `provider_specific_builders.dart`
- the first `example/03_advanced_features` stable-first slice is now complete
  for batch processing, semantic search, and performance optimization
- `example/03_advanced_features/multi_modal.dart` is now also aligned to
  stable prompt parts plus shared image/audio/file helpers
- `example/03_advanced_features/custom_providers.dart` now teaches stable
  `LanguageModel` composition instead of the old `ChatCapability` contract
- `example/03_advanced_features/realtime_audio.dart` now uses an explicit
  ElevenLabs provider-owned entrypoint and keeps realtime session orchestration
  separate from the current provider implementation boundary
- `example/03_advanced_features/http_configuration.dart`,
  `layered_http_config.dart`, and `timeout_configuration.dart` now also use
  the stable `AI.*(..., transport: ...)` plus transport-package recipe instead
  of the legacy builder HTTP shell
- `example/04_providers/ollama/advanced_features.dart` and
  `thinking_example.dart` now also use the modern `llm_dart_community`
  surface plus `OllamaGenerateTextOptions` instead of the legacy builder shell
- `example/04_providers/others/openai_compatible.dart` now also uses stable
  OpenAI-family profile facades, shared `generateTextCall(...)`, and explicit
  provider-owned extension points instead of `legacy.dart` plus builder-era
  preset helpers
- `example/04_providers/openai/responses_api.dart` and
  `build_openai_responses_demo.dart` now also keep stable generation on
  `AI.openai(...).chatModel(...)` and narrow raw response lifecycle examples to
  the provider-owned OpenAI compatibility surface instead of the broad
  `legacy.dart` barrel
- `example/04_providers/anthropic/file_handling.dart` now also avoids the
  broad `legacy.dart` barrel and uses focused Anthropic/chat/file imports while
  keeping provider-owned file lifecycle flows explicit
- `example/04_providers/google/google_tts_example.dart` now also avoids
  `legacy.dart` and `ai()` and teaches stable one-shot speech through
  `AI.google(...).speechModel(...)` while keeping streamed PCM output and voice
  discovery on the compatibility appendix
- `example/04_providers/elevenlabs/audio_capabilities.dart` now also avoids
  `legacy.dart` and `ai()` and teaches shared `llm_dart_community`
  speech/transcription models for stable app-facing media flows while keeping
  provider-owned voice catalogs, convenience helpers, streaming, and realtime
  boundary behavior explicit
- the ElevenLabs and Ollama provider READMEs now lead with community-package
  modern surfaces and use provider-specific entrypoints for compatibility
  boundaries instead of direct `legacy.dart` snippets
- `example/04_providers/others/README.md` now also documents stable profile
  facades plus explicit custom-compatible endpoint wiring instead of a broad
  transitional OpenAI-compatible bucket
- `example/04_providers/openai/README.md` now also frames
  `buildOpenAIResponses()` as frozen migration ergonomics rather than as the
  target architecture
- the Google and ElevenLabs provider READMEs now also document stable-first
  example boundaries plus explicit provider-owned appendices
- `example/06_mcp_integration` now also uses a dedicated MCP bridge plus the
  shared `runTextGeneration(...)` / `streamTextRun(...)` runners instead of
  the legacy builder shell and hand-written tool replay loops
- `example/01_getting_started/basic_configuration.dart` and
  `example/02_core_features/capability_detection.dart` now also avoid the
  broad `legacy.dart` barrel through focused public imports
- the meaningful example baseline is now `2` files with actual
  `legacy.dart` imports and `0` files with direct executable `ai()` usage
- the first task-oriented migration recipe set is now written down in
  `05-task-oriented-migration-recipes.md`, covering text generation,
  streaming tool runs, embeddings, image generation, audio, model listing,
  raw OpenAI responses, and provider-specific option migration
- the family-by-family migration note for already-deprecated preset helper
  aliases is now written down in
  `06-deprecated-preset-helper-aliases.md`
- the provider-owned replacement note for deprecated builder web-search
  helpers is now written down in
  `07-builder-web-search-replacements.md`
- the `ai()` posture is now explicitly decided in
  `08-ai-helper-posture.md`: soft-deprecate the alias, keep `LLMBuilder()`
  frozen as the actual compatibility builder trunk
- the `createProvider(...)` posture is now explicitly decided in
  `09-create-provider-posture.md`: keep the function frozen, keep
  `extensions` on the deprecation path
- the first conservative breaking-window proposal is now written down in
  `10-breaking-window-removal-candidates.md`
- the removal release-note and migration-note templates are now written down
  in `11-removal-release-note-templates.md`
- the compatibility test-retention plan for removals is now written down in
  `12-compatibility-test-retention.md`
- a concrete copy-ready wave-1 release-note and changelog draft now also
  exists in `13-wave-1-release-note-draft.md`, so the already-landed leaf
  removals can be shipped or deferred without inventing migration text later
- the execution decision for that branch-landed wave-1 slice is now also
  explicit in `14-wave-1-execution-decision.md`: ship only through a
  deliberate breaking release, otherwise keep the removals deferred off any
  non-breaking release line
- the first conservative wave-1 branch slice is now also landed in code:
  deprecated preset helper aliases removed, shared builder web-search helpers
  removed, `createProvider(..., extensions: ...)` reduced to
  `createProvider(...)`, and the deprecated `CancelToken` alias removed
- `example/03_advanced_features/README.md` now leads with stable snippets and
  now teaches stable transport recipes instead of the old builder HTTP shell
- the first-deprecation-wave documentation blockers are now materially smaller:
  preset helper aliases, builder web-search helpers, `ai()`, and
  `createProvider(...)` all now have explicit posture notes
- the example appendix residue is now narrower still: the two explicit
  compatibility appendix files use `LLMBuilder()` directly and `example/`
  no longer has executable `ai()` usage
- the next honest implementation slice is now clear: either execute the
  conservative wave-1 leaf removals in a breaking branch or deliberately defer
  them, but do not reopen the trunk-level architecture debate
