# README And Example Audit

## Goal

Record where the repository still teaches or demonstrates the legacy
compatibility path, and separate healthy compatibility disclosure from real
migration drag.

## Audit Result

The current state is mixed, but the direction is clear:

- the top-level `README.md` is already modern-first
- workspace package READMEs under `packages/` are already modern-first
- the main remaining migration drag is in `example/` and some example-level
  READMEs that still teach `legacy.dart` and `ai().*.build()`

That means the next highest-value deprecation-preparation work is not another
policy note.

It is example migration.

## Counts

Current repository-wide audit baseline after the latest
`example/03_advanced_features` multimodal rewrite:

- `16` files still import `package:llm_dart/legacy.dart`
- `22` files still contain direct `ai()` usage

Legacy imports inside `example/` are concentrated in:

- `example/02_core_features` - `2` files
- `example/03_advanced_features` - `5` files
- `example/04_providers` - `6` files
- `example/06_mcp_integration` - `3` files
- `example/01_getting_started` - `0` files

`example/02_core_features` is now effectively reduced to two explicit
compatibility appendix files:

- `capability_factory_methods.dart`
- `provider_specific_builders.dart`

The stable-first and boundary-clarifying rewrite passes are now complete for
these `example/02_core_features` files:

- `embeddings.dart`
- `audio_processing.dart`
- `image_generation.dart`
- `enhanced_tool_calling.dart`
- `error_handling.dart`
- `assistants.dart`
- `file_management.dart`
- `content_moderation.dart`
- `model_listing.dart`
- `cancellation_demo.dart`
- `message_builder_cache.dart`

Those examples now use modern model constructors plus shared helpers instead of
the legacy builder surface, or they now present provider-owned compatibility
surfaces explicitly as boundaries instead of pretending they are stable shared
abstractions.

Two additional cleanup results matter for the deprecation plan:

- `cancellation_demo.dart` no longer teaches `ai().buildModelListing()` for
  remote model discovery
- `message_builder_cache.dart` now uses narrow chat/tool/Anthropic typed
  imports instead of the broad `legacy.dart` barrel

The first stable-first rewrite slice is also now complete in
`example/03_advanced_features` for:

- `batch_processing.dart`
- `semantic_search.dart`
- `performance_optimization.dart`
- `multi_modal.dart`

Those files now keep batch orchestration, retrieval indexing, caching,
streaming, and context trimming in app-owned code built on:

- `LanguageModel`
- `EmbeddingModel`
- `generateTextCall(...)`
- `streamTextCall(...)`
- `embed(...)`
- `embedMany(...)`

The remaining legacy-heavy `example/03_advanced_features` files are now:

- `http_configuration.dart`
- `layered_http_config.dart`
- `timeout_configuration.dart`
- `realtime_audio.dart`
- `custom_providers.dart`

## Healthy Legacy Disclosure

The following documentation posture is already good enough and should mostly be
kept:

### 1. Top-Level README

`README.md` already:

- presents `AI.<provider>(...).chatModel(...)` as the primary direction
- treats `legacy.dart` as an explicit compatibility shell
- explains that old root provider surfaces and `ai()` are compatibility APIs

That is the right posture for the root documentation.

It may need tightening later, but it is not the main blocker.

### 2. Workspace Package READMEs

The package READMEs under `packages/` are already aligned with the modern
package graph:

- `llm_dart_core`
- `llm_dart_transport`
- `llm_dart_chat`
- `llm_dart_flutter`
- `llm_dart_community`

These READMEs are not currently the main source of legacy drift.

## Real Hotspots

### 1. Example Files Still Teaching Builder-Era Flows

The largest hotspot is the example tree itself.

Many example files still import:

- `package:llm_dart/legacy.dart`
- `ai()`
- `build()`
- `buildAudio()`
- `buildImageGeneration()`
- `buildEmbedding()`
- `buildModelListing()`

This is a real product problem because users often copy examples before they
read architecture notes.

### 2. Example README Files Still Showing Legacy Code

The main remaining direct legacy README hotspots are now especially in:

- `example/04_providers/elevenlabs/README.md`
- `example/04_providers/ollama/README.md`

These are exactly the places where users look for task-specific setup, so they
carry more migration weight than a generic architecture explanation.

### 3. Mixed Examples That Are Acceptable For Now

Some examples intentionally remain compatibility-oriented because the modern
replacement is not yet complete or not yet documented well enough.

Those examples should not be removed blindly.

They should instead be:

- labeled clearly as compatibility examples
- separated from default modern examples
- revisited only after the corresponding modern recipe exists

## Recommended Rewrite Order

The best remaining migration order is:

1. finish the remaining app-facing residue in `example/03_advanced_features`
   (`realtime_audio.dart`, `custom_providers.dart`)
2. `example/04_providers` README hotspots
3. classify the remaining `example/03_advanced_features`
   HTTP/configuration files as keep-frozen appendix material or rewrite them
   into a clearer transport recipe
4. `example/06_mcp_integration`

Rationale:

- `02_core_features` is now mostly modern-first outside the two explicit
  compatibility appendix files
- `03_advanced_features` is now partially modernized, so the next value is in
  finishing the remaining app-facing residue before treating transport-wiring
  examples as a separate appendix decision
- provider README snippets strongly influence copy-paste usage
- MCP examples are narrower and lower-volume

## Immediate Implication

The repository is not blocked on more architecture work.

It is blocked on converting the highest-traffic teaching surface from:

- legacy builder demonstrations

to:

- modern model constructors
- shared helper functions
- explicit compatibility appendices only where truly needed

That means the next honest implementation slice is no longer another
`02_core_features` rewrite. It is the remaining advanced/provider example
layer.
