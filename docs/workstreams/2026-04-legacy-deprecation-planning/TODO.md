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
- [ ] Rewrite the highest-traffic example slices so modern APIs become the
  default copy-paste path
- [ ] Write short task-oriented migration recipes for the most common builder
  jobs before considering wider builder deprecation

## First Deprecation Wave Preparation

- [ ] Confirm the full list of already-deprecated preset helper aliases and
  group them into one migration note per provider family
- [ ] Confirm the modern replacements for deprecated builder web-search helpers
- [ ] Decide whether `ai()` should become soft-deprecated only after the
  migration recipes land
- [ ] Decide whether `createProvider(...)` should remain as a frozen generic
  compatibility helper or move deeper into soft-deprecation

## Breaking-Window Preparation

- [ ] Draft the future breaking-window removal candidate list
- [ ] Prepare changelog and migration-note templates for removals
- [ ] Define which compatibility tests must remain until each removal lands

## Explicitly Deferred

- [ ] Deprecate `LLMBuilder` before common task-oriented migration recipes exist
- [ ] Remove `legacy.dart` before the builder and root-provider migration story
  is complete
- [ ] Remove broad root provider constructors before the first leaf-removal
  window lands
