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

Current example migration baseline after the
`example/03_advanced_features` transport rewrite, the Ollama provider-example
modernization, the stable rewrite of
`example/04_providers/others/openai_compatible.dart`, and the OpenAI Responses
appendix narrowing, plus the final provider-example cleanup pass for
Anthropic file handling, Google TTS, ElevenLabs audio, and the MCP bridge
rewrite for stdio and HTTP examples:

- `2` example Dart files still import `package:llm_dart/legacy.dart`
- `2` example Dart files still contain direct `ai()` usage

Legacy imports inside `example/` are now concentrated in:

- `example/01_getting_started` - `0` files
- `example/02_core_features` - `2` files
- `example/03_advanced_features` - `0` files
- `example/04_providers` - `0` files

Direct `ai()` usage inside `example/` is now concentrated in:

- `example/01_getting_started` - `0` files
- `example/02_core_features` - `2` files
- `example/03_advanced_features` - `0` files
- `example/04_providers` - `0` files

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

Another meaningful reduction is now also complete in
`example/04_providers/others`:

- `openai_compatible.dart` no longer teaches `legacy.dart`, `ai()`, or
  builder-era preset helpers
- the example now separates stable OpenAI-family profile facades from
  provider-owned extension points such as DeepSeek reasoning, xAI live search,
  and OpenRouter online-model routing
- the example now shows explicit custom OpenAI-family endpoint wiring through a
  local `OpenAIProfile` instead of pretending that every compatible endpoint
  deserves a new shared global facade
- the directory README now documents that custom-compatible endpoints should
  stay explicit until they have an audited stable boundary

Another meaningful reduction is now also complete in
`example/04_providers/openai`:

- `responses_api.dart` and `build_openai_responses_demo.dart` no longer depend
  on the broad `legacy.dart` barrel
- both files now keep stable app-facing generation on
  `AI.openai(...).chatModel(...)`
- the raw response lifecycle appendix now drops to the narrower
  `package:llm_dart/providers/openai/openai.dart` compatibility surface instead
  of teaching `ai().openai()...buildOpenAIResponses()` as the default entry
  path
- the OpenAI provider README now frames `buildOpenAIResponses()` as frozen
  migration ergonomics rather than as target architecture

Another meaningful provider-example reduction is now also complete across the
last remaining `example/04_providers` hotspots:

- `anthropic/file_handling.dart` no longer depends on the broad `legacy.dart`
  barrel and now uses focused Anthropic/chat/file imports while still keeping
  the provider-owned file lifecycle boundary explicit
- `google/google_tts_example.dart` no longer depends on `legacy.dart` or
  `ai()` and now uses stable `AI.google(...).speechModel(...)` for one-shot
  speech while keeping streamed PCM output and voice discovery on the
  compatibility appendix
- `elevenlabs/audio_capabilities.dart` no longer depends on `legacy.dart` or
  `ai()` and now uses the shared `llm_dart_community` speech/transcription
  models for stable app-facing media flows while keeping voice catalogs,
  convenience helpers, streaming, and realtime flags on the provider-owned
  compatibility surface
- the Google and ElevenLabs provider READMEs now also explain these hybrid
  boundaries directly instead of presenting the examples as fully
  compatibility-oriented by default

Another meaningful reduction is now also complete in
`example/06_mcp_integration`:

- `stdio_examples/llm_client.dart`, `http_examples/llm_client.dart`, and
  `http_examples/simple_stream_client.dart` no longer depend on
  `legacy.dart` or `ai()`
- `shared/mcp_tool_bridge.dart` now owns MCP schema conversion, tool-input
  decoding, and `CallToolResult` normalization instead of repeating that logic
  inside each sample
- the non-streaming MCP examples now use `AI.openai(...).chatModel(...)` plus
  `core.runTextGeneration(...)`
- the streaming MCP example now uses `core.streamTextRun(...)` and the shared
  text/tool event model instead of hand-written `ToolCallAggregator`
  orchestration
- the MCP README set now documents the stable layering explicitly:
  AI facade -> core runner -> MCP bridge -> transport/client

Another narrow cleanup is now also complete in the last non-appendix
residue outside those frozen compatibility examples:

- `example/01_getting_started/basic_configuration.dart` no longer depends on
  the broad `legacy.dart` barrel just to catch error types and now uses the
  focused public `core/llm_error.dart` import instead
- `example/02_core_features/capability_detection.dart` no longer depends on
  the broad `legacy.dart` barrel and now uses focused compatibility imports
  for capability declarations and registry metadata while still keeping actual
  execution on the stable `AI.*(...).chatModel(...)` facade

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
- `example/04_providers/others/README.md` now also leads with stable profile
  facades plus explicit custom-compatible endpoint wiring instead of treating
  OpenAI-compatible as a generic transitional bucket

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

1. decide whether the low-volume `example/01_getting_started` and
   `example/02_core_features` compatibility residue should stay as explicit
   appendix material or be narrowed further
2. write short task-oriented migration recipes for the frozen builder jobs
   that still appear in those appendix examples

Rationale:

- `02_core_features` is now mostly modern-first outside the two explicit
  compatibility appendix files
- `01_getting_started` no longer has any broad `legacy.dart` import residue
- `03_advanced_features` is now fully modern-first, including the transport
  configuration examples
- the Ollama provider examples no longer need the broad legacy builder shell
  for runtime tuning or reasoning demonstrations
- the mixed OpenAI-family example in `example/04_providers/others` is now
  stable-first and no longer hides provider boundaries behind builder presets
- the OpenAI Responses appendix files now also avoid the broad compatibility
  barrel and teach a narrower provider-owned compatibility boundary instead
- the remaining `example/04_providers` Anthropic, Google, and ElevenLabs
  hotspots now also avoid `legacy.dart` and `ai()` while still documenting
  honest provider-owned appendix boundaries
- the largest known provider README hotspots have now been reduced to
  provider-entrypoint compatibility disclosures instead of direct
  `legacy.dart` teaching
- `06_mcp_integration` is now also stable-first and no longer teaches the
  legacy builder shell

## Immediate Implication

The repository is not blocked on more architecture work.

The next honest implementation slice is no longer the advanced example layer.

It is now:

- deciding how much explicit compatibility residue should remain in the two
  frozen appendix files under `example/02_core_features`
- writing short migration recipes for the remaining frozen builder jobs before
  any wider deprecation wave
