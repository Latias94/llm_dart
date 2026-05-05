# TODO

## Workstream Setup

- [x] Create the provider and AI runtime split workstream scaffold
- [x] Document the target package graph
- [x] Document reference lessons and deliberate Dart differences
- [x] Document current `llm_dart_core` decomposition direction
- [x] Document file, provider-reference, provider-option, and tool-output
  redesign direction
- [x] Document root and legacy exit strategy

## Architecture Contract

- [x] Decide final package names for provider spec and AI runtime
- [ ] Decide whether `llm_dart_provider_utils` is public in the first breaking
  preview or starts as package-private helper code
- [ ] Decide whether UI contracts remain inside the provider/spec package for
  the first breaking preview or move to a dedicated UI package later
- [ ] Update workspace dependency guard policy for the target graph
- [ ] Update root boundary guard policy for the target graph

## Provider Spec Split

- [x] Create `packages/llm_dart_provider`
- [x] Move initial provider-facing foundation contracts into
  `llm_dart_provider`
- [x] Move prompt, content, tool, provider metadata, and model error contracts
  into `llm_dart_provider`
- [x] Move finish reason, response format, and text stream contracts into
  `llm_dart_provider`
- [x] Move `CallOptions` and provider-level cancellation contracts into
  `llm_dart_provider`
- [x] Move provider-facing model interfaces into `llm_dart_provider`
- [x] Redesign `CallOptions` and cancellation ownership before moving
  `LanguageModel`
- [x] Keep compatibility re-exports in `llm_dart_core` for migrated provider
  contracts while migration is in progress
- [ ] Update provider packages to depend on `llm_dart_provider`

## AI Runtime Split

- [ ] Create `packages/llm_dart_ai`
- [ ] Move generation helpers into `llm_dart_ai`
- [ ] Move multi-step runners into `llm_dart_ai`
- [ ] Move structured output helpers into `llm_dart_ai`
- [ ] Keep provider packages independent from `llm_dart_ai`

## Data Structure Upgrade

- [ ] Add `ProviderReference`
- [ ] Add sealed `FileData`
- [ ] Replace nullable `uri`/`bytes` prompt file shape with `FileData`
- [ ] Add explicit `ToolOutput` variants
- [ ] Migrate OpenAI file prompt encoding to provider references where
  applicable
- [ ] Migrate Anthropic file prompt encoding to provider references where
  applicable
- [ ] Migrate Google file prompt encoding to the new file data shape
- [ ] Add migration recipes for old file and tool-result shapes

## Provider Package Migration

- [ ] Migrate `llm_dart_openai`
- [ ] Migrate `llm_dart_anthropic`
- [ ] Migrate `llm_dart_google`
- [ ] Migrate `llm_dart_community`
- [ ] Preserve provider-owned typed options
- [x] Preserve model capability profiles
- [ ] Preserve OpenAI-family profiles
- [ ] Preserve provider-native helper clients

## Root And Legacy

- [ ] Stop adding new implementation ownership to root package legacy areas
- [ ] Decide whether to keep `legacy.dart` in root or move it to
  `llm_dart_legacy`
- [ ] Update examples to prefer focused modern entrypoints
- [ ] Update compatibility examples to import the explicit legacy surface
- [ ] Remove root dependencies only after implementation ownership moves make
  removal truthful

## Validation

- [x] Run workspace dependency guards for the first provider-spec split slice
- [x] Run root boundary guards for the first provider-spec split slice
- [x] Run package analysis after provider-spec migration slices
- [x] Run focused provider/core tests after provider-spec migration slices
- [x] Update publish dry-run tooling for the new provider package and root
  staging validation
- [ ] Prepare breaking changelog and migration matrix
