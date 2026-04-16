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

Current scoped audit baseline across code under `example`, `lib`, and
`packages` after the `example/03_advanced_features` transport rewrite and the
Ollama provider-example modernization:

- `13` Dart files still import `package:llm_dart/legacy.dart`
- `13` Dart files still contain direct `ai()` usage

Legacy imports inside `example/` are now concentrated in:

- `example/01_getting_started` - `1` file
- `example/02_core_features` - `3` files
- `example/03_advanced_features` - `0` files
- `example/04_providers` - `6` files
- `example/06_mcp_integration` - `3` files

Direct `ai()` usage inside `example/` is now concentrated in:

- `example/01_getting_started` - `0` files
- `example/02_core_features` - `2` files
- `example/03_advanced_features` - `0` files
- `example/04_providers` - `5` files
- `example/06_mcp_integration` - `3` files

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
- `custom_providers.dart`

Those files now keep batch orchestration, retrieval indexing, caching,
streaming, custom model composition, and context trimming in app-owned code
built on:

- `LanguageModel`
- `EmbeddingModel`
- `generateTextCall(...)`
- `streamTextCall(...)`
- `embed(...)`
- `embedMany(...)`

`realtime_audio.dart` is now also reframed as an honest provider-owned
boundary:

- no broad `legacy.dart` barrel
- no fake cross-provider realtime abstraction
- explicit ElevenLabs compatibility provider entrypoint
- app-owned local session/event orchestration shown separately from provider
  implementation status

The remaining `example/03_advanced_features` transport files are now also
modernized:

- `http_configuration.dart`
- `layered_http_config.dart`
- `timeout_configuration.dart`

Those files no longer depend on `legacy.dart` or `ai()`. They now teach the
real stable transport boundary:

- `AI.*(..., transport: ...)`
- `DioHttpClientConfig`
- `DioHttpClientFactory`
- `DioTransportClient`
- `CallOptions.timeout`

Another meaningful reduction is now complete in `example/04_providers/ollama`:

- `advanced_features.dart` now uses `community.Ollama(...).chatModel(...)`
  plus `OllamaGenerateTextOptions`
- `thinking_example.dart` now uses shared text/stream events plus
  Ollama-owned runtime options instead of the legacy builder shell
- the directory README now explains Ollama local runtime tuning as a modern
  community-surface pattern rather than as default compatibility material

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

The previously highest-value provider README hotspots were:

- `example/04_providers/elevenlabs/README.md`
- `example/04_providers/ollama/README.md`

Those are now resolved at the direct-snippet level:

- both READMEs now lead with the modern `llm_dart_community` path
- both compatibility snippets now use provider-specific entrypoints instead of
  teaching `legacy.dart` plus `ai().*.build()` directly
- `example/03_advanced_features/README.md` now also teaches stable transport
  recipes instead of the old builder HTTP shell

This matters because task-oriented provider READMEs carry more migration weight
than a generic architecture explanation.

### 3. Mixed Examples That Are Acceptable For Now

Some examples intentionally remain compatibility-oriented because the modern
replacement is not yet complete or not yet documented well enough.

Those examples should not be removed blindly.

They should instead be:

- labeled clearly as compatibility examples
- separated from default modern examples
- revisited only after the corresponding modern recipe exists

## Recommended Rewrite Order

The best remaining migration order is now:

1. rewrite the remaining legacy-heavy provider example files in
   `example/04_providers`
2. rewrite `example/06_mcp_integration`
3. decide whether the low-volume `example/01_getting_started` and
   `example/02_core_features` compatibility residue should stay as explicit
   appendix material or be narrowed further

Rationale:

- `02_core_features` is now mostly modern-first outside the two explicit
  compatibility appendix files
- `03_advanced_features` is now fully modern-first, including the transport
  configuration examples
- the Ollama provider examples no longer need the broad legacy builder shell
  for runtime tuning or reasoning demonstrations
- the largest known provider README hotspots have now been reduced to
  provider-entrypoint compatibility disclosures instead of direct
  `legacy.dart` teaching
- MCP examples are narrower and lower-volume

## Immediate Implication

The repository is not blocked on more architecture work.

The next honest implementation slice is no longer the advanced example layer.

It is now:

- provider example migration in `example/04_providers`
- MCP example migration in `example/06_mcp_integration`
- deciding how much explicit compatibility residue should remain in the
  lower-volume appendix files
