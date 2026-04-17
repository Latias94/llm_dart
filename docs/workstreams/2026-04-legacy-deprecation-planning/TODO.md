# TODO

## Workstream Setup

- [x] Create the legacy deprecation planning workstream scaffold
- [x] Inventory the main remaining legacy public surface groups
- [x] Freeze the initial deprecation policy and release rules
- [x] Write the first migration and removal sequencing plan
- [x] Write a concrete removal-readiness matrix for the main surface groups

## Migration Readiness Audit

- [x] Audit the root README and package READMEs for remaining legacy-first
  guidance
- [x] Audit examples for remaining `legacy.dart`, root provider-barrel, or
  builder-era imports
- [x] Rewrite the first stable-helper slice in `example/02_core_features`
  (`embeddings.dart`, `audio_processing.dart`, `image_generation.dart`)
- [x] Rewrite the second stable-helper slice in `example/02_core_features`
  (`enhanced_tool_calling.dart`, `error_handling.dart`)
- [x] Rewrite the third `example/02_core_features` slice so assistants and
  file management teach stable-first boundaries instead of fake unified
  capability examples
- [x] Rewrite the fourth `example/02_core_features` slice so moderation and
  model discovery separate app-owned policy/profile logic from provider-owned
  compatibility endpoints
- [x] Narrow the Anthropic prompt-caching appendix off the broad
  `legacy.dart` barrel onto focused typed imports
- [x] Reduce `example/02_core_features` legacy residue to the two explicit
  builder appendix files
- [x] Rewrite the first stable-first slice in `example/03_advanced_features`
  (`batch_processing.dart`, `semantic_search.dart`,
  `performance_optimization.dart`)
- [x] Rewrite `example/03_advanced_features/multi_modal.dart` onto stable
  prompt parts and shared media helpers
- [x] Rewrite `example/03_advanced_features/custom_providers.dart` onto the
  stable `LanguageModel` contract instead of `ChatCapability`
- [x] Reframe `example/03_advanced_features/realtime_audio.dart` as explicit
  ElevenLabs provider-owned appendix material without the broad legacy barrel
- [x] Reframe `example/03_advanced_features/README.md` so stable snippets lead
  and transport wiring has an explicit documented home
- [x] Reduce `example/03_advanced_features` legacy residue to the three HTTP
  configuration appendix files
- [x] Rewrite the remaining `example/03_advanced_features` HTTP
  configuration files (`http_configuration.dart`,
  `layered_http_config.dart`, `timeout_configuration.dart`) onto the stable
  transport recipe
- [x] Rewrite the ElevenLabs and Ollama provider READMEs so modern community
  surfaces lead and compatibility snippets no longer teach `legacy.dart`
  directly
- [x] Rewrite the Ollama provider runtime examples
  (`advanced_features.dart`, `thinking_example.dart`) onto the
  `llm_dart_community` surface with provider-owned runtime options
- [x] Rewrite the remaining highest-traffic example slices so modern APIs
  become the default copy-paste path
  (`google/google_tts_example.dart`,
  `anthropic/file_handling.dart`,
  `elevenlabs/audio_capabilities.dart`)
- [x] Rewrite `example/06_mcp_integration` onto shared core tool runners and
  a dedicated MCP bridge instead of legacy chat/tool orchestration
- [x] Narrow the final non-appendix example residue
  (`basic_configuration.dart`, `capability_detection.dart`) off the broad
  `legacy.dart` barrel
- [x] Write short task-oriented migration recipes for the most common builder
  jobs before considering wider builder deprecation

## First Deprecation Wave Preparation

- [x] Confirm the full list of already-deprecated preset helper aliases and
  group them into one migration note per provider family
- [x] Confirm the modern replacements for deprecated builder web-search helpers
- [x] Decide whether `ai()` should become soft-deprecated only after the
  migration recipes land
- [x] Decide whether `createProvider(...)` should remain as a frozen generic
  compatibility helper or move deeper into soft-deprecation

## Breaking-Window Preparation

- [x] Draft the future breaking-window removal candidate list
- [x] Prepare changelog and migration-note templates for removals
- [x] Define which compatibility tests must remain until each removal lands

## Breaking-Window Execution

- [x] Land the first conservative wave-1 branch slice:
  preset helper aliases, builder web-search helpers,
  `createProvider(..., extensions: ...)`, and `CancelToken`
- [x] Convert the branch-landed removals into final release notes / changelog
  text if this branch becomes the actual breaking release vehicle
- [x] Decide whether the branch-landed wave-1 removals should ship only in an
  explicit breaking release or remain deferred off non-breaking release lines

## Explicitly Deferred

- [ ] Deprecate `LLMBuilder` before common task-oriented migration recipes exist
- [ ] Remove `legacy.dart` before the builder and root-provider migration story
  is complete
- [ ] Remove broad root provider constructors before the first leaf-removal
  window lands
