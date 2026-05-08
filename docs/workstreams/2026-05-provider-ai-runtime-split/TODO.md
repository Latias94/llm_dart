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
- [x] Decide whether `llm_dart_provider_utils` is public in the first breaking
  preview or starts as package-private helper code
- [x] Decide whether UI contracts remain inside the provider/spec package for
  the first breaking preview or move to a dedicated UI package later
- [x] Update workspace dependency guard policy for the target graph
- [x] Update root boundary guard policy for the target graph

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
- [x] Update provider packages to depend on `llm_dart_provider`

## AI Runtime Split

- [x] Create `packages/llm_dart_ai`
- [x] Move generation helpers into `llm_dart_ai`
- [x] Move multi-step runners into `llm_dart_ai`
- [x] Move structured output helpers into `llm_dart_ai`
- [x] Keep provider packages independent from `llm_dart_ai`

## Data Structure Upgrade

- [x] Add `ProviderReference`
- [x] Add sealed `FileData`
- [x] Add `FileData` compatibility accessors on nullable `uri`/`bytes` prompt
  and generated file shapes
- [x] Add explicit `ToolOutput` variants
- [x] Add `ToolOutput` compatibility accessors on old `output`/`isError` tool
  result shapes
- [x] Normalize tool-result internals to store only `ToolOutput`
- [x] Migrate OpenAI file prompt encoding to provider references where
  applicable
- [x] Migrate Anthropic file prompt encoding to provider references where
  applicable
- [x] Migrate Google file prompt encoding to the new file data shape
- [x] Add migration recipes for old file and tool-result shapes
- [x] Add JSON serialization coverage for new file and tool-output unions
- [x] Replace nullable `uri`/`bytes` prompt file storage with required
  `FileData` in the breaking API line
- [x] Remove input-side provider file identity from `ProviderMetadata`

## Provider Package Migration

- [x] Migrate `llm_dart_openai`
- [x] Migrate `llm_dart_anthropic`
- [x] Migrate `llm_dart_google`
- [x] Migrate `llm_dart_community`
- [x] Preserve provider-owned typed options
- [x] Preserve model capability profiles
- [x] Preserve OpenAI-family profiles
- [x] Preserve provider-native helper clients

## Root And Legacy

- [x] Move `llm_dart_transport` off `llm_dart_core` runtime dependency
- [x] Move `llm_dart_chat` off `llm_dart_core` runtime dependency
- [x] Move `llm_dart_flutter` off `llm_dart_core` runtime dependency
- [x] Stop adding new implementation ownership to root package legacy areas
- [x] Decide whether to keep `legacy.dart` in root or move it to
  `llm_dart_legacy`
- [x] Update examples to prefer focused modern entrypoints
- [x] Update compatibility examples to import the explicit legacy surface
- [x] Remove root runtime dependency on `llm_dart_core`; keep test/dev
  compatibility coverage for the core shell

## `llm_dart_core` Compatibility Shrink

- [x] Reduce `llm_dart_core.dart` to a pure compatibility barrel over the
  focused entrypoints
- [x] Move production compatibility consumers and helper-package code to
  focused `llm_dart_core` entrypoints
- [x] Keep test-only broad imports as legacy coverage for the compatibility
  barrel
- [x] Decide whether the published `llm_dart_core` package should remain a
  compatibility shell only after the breaking line, or eventually disappear
- [x] Add a guard that rejects new implementation ownership in
  `llm_dart_core/lib`
- [x] Add a guard that keeps `llm_dart_transport` on transport-owned public
  names
- [x] Add a guard that keeps foundational tests off the broad `legacy.dart`
  barrel

## Validation

- [x] Run workspace dependency guards for the first provider-spec split slice
- [x] Run root boundary guards for the first provider-spec split slice
- [x] Run core compatibility shell guard after shrinking `llm_dart_core`
- [x] Run transport boundary guard after shrinking cancellation ownership
- [x] Run foundational test legacy-import guard after shrinking test imports
- [x] Run package analysis after provider-spec migration slices
- [x] Run focused provider/core tests after provider-spec migration slices
- [x] Update publish dry-run tooling for the new provider package and root
  staging validation
- [x] Run AI runtime package analysis and tests
- [x] Run compatibility core analysis and tests after AI runtime extraction
- [x] Run Flutter adapter analysis and tests after toolchain recovery
- [x] Run MCP example dependency resolution, analysis, and no-key smoke test
- [x] Prepare breaking changelog and migration matrix
- [x] Run workspace publish dry-run after the root legacy cleanup slices
- [x] Document release readiness and publish stop conditions
- [x] Run clean Dart and Flutter consumer smoke validation for release imports
