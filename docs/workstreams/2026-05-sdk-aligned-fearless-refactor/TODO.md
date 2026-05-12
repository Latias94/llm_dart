# TODO

## Workstream Setup

- [x] Create the SDK-aligned fearless refactor workstream scaffold
- [x] Capture the reference lessons from `repo-ref/ai`
- [x] Capture the Dart-specific value that must be preserved
- [x] Define the target ownership boundaries
- [x] Define the canonical goal text

## Architecture Freeze

- [x] Re-audit current package graph against the target ownership rules
- [x] List every runtime dependency from provider packages to AI/runtime/UI/root
  packages
- [x] Decide final Dart naming for provider implementation methods:
  `doGenerate`/`doStream` or a similarly explicit Dart convention
- [x] Freeze provider option versus provider metadata semantics
- [x] Freeze which compatibility APIs remain in root for the next breaking line
- [x] Freeze whether `llm_dart_provider_utils` stays internal or becomes a
  public package

## Provider Contract Hardening

- [x] Rename `LanguageModel.generate` to implementation-facing generation
  method naming
- [x] Rename `LanguageModel.stream` to implementation-facing stream method
  naming
- [x] Update all current language provider implementations to the hardened
  contract
- [x] Update AI runtime runners to call the hardened provider methods
- [x] Add a workspace guard that rejects old `LanguageModel.generate` and
  `LanguageModel.stream` method names in package `lib/` code
- [x] Add contract tests that prove direct provider contracts stay
  orchestration-free
- [x] Add migration notes for old direct `model.generate` and `model.stream`
  users

## Runtime Ownership Consolidation

- [x] Keep `generateText`, `streamText`, object generation, and tool-loop
  orchestration in `llm_dart_ai`
- [x] Ensure provider packages do not need runtime helpers for production code
- [x] Move remaining shared UI projection helpers out of provider packages or
  make them provider-owned without runtime dependency
- [x] Keep chat/UI JSON codecs in runtime or chat layers, not provider
  specifications
- [x] Add tests for single-step, multi-step, streaming, tool-result replay, and
  structured output behavior through the AI runtime

## Provider Options And Metadata

- [x] Define the canonical typed provider options shape in
  `llm_dart_provider`
- [x] Keep raw provider option escape hatches scoped and namespaced
- [x] Remove input-side provider identity or request customization from
  `ProviderMetadata`
- [x] Keep response-side raw metadata, response identifiers, and replay details
  in `ProviderMetadata`
- [x] Add tests proving provider options round-trip into provider
  implementations without polluting response metadata
- [x] Add migration recipes for any old metadata-driven request configuration

## Shared Generation Options

- [x] Add `presencePenalty`
- [x] Add `frequencyPenalty`
- [x] Add `seed`
- [x] Add shared `reasoning` configuration with provider-default and explicit
  effort levels
- [x] Add `includeRawChunks` for streaming calls where provider adapters can
  expose raw events
- [x] Review whether headers, abort/cancellation, and response format ownership
  remain in the right data structures
- [x] Add provider mapping warnings for unsupported shared options
- [x] Add tests for unsupported, coerced, and provider-native option mappings

## Provider Package Decoupling

- [x] Remove production `llm_dart_ai` dependency from the Anthropic provider
  package
- [x] Remove production `llm_dart_ai` dependency from the OpenAI provider
  package
- [x] Remove production `llm_dart_ai` dependency from the Google
  provider packages
- [x] Audit Ollama, ElevenLabs, and OpenAI-compatible provider packages for the
  same dependency boundary
- [x] Move reusable provider implementation helpers behind internal helpers
  until two or more providers prove a stable public utility contract
- [x] Preserve provider-owned helper clients and typed options during the
  decoupling
- [x] Add dependency guards that reject provider package runtime dependencies on
  `llm_dart_ai`, chat, Flutter, root, or core compatibility packages

## Root And Compatibility Cleanup

- [x] Keep root `llm_dart` as a facade over focused packages
- [x] Keep legacy imports explicit and migration-oriented
- [x] Remove compatibility shims whose migration replacement is documented and
  available
- [x] Reject new implementation classes in root and `llm_dart_core`
- [x] Update examples to prefer focused packages and the modern facade
- [x] Add before/after migration examples for the breaking API changes

## Validation

- [x] Run workspace dependency guards
- [x] Run root and core boundary guards
- [x] Run package analysis for `llm_dart_provider`
- [x] Run package analysis and tests for `llm_dart_ai`
- [x] Run package analysis and tests for `llm_dart_transport`
- [x] Run package analysis and tests for `llm_dart_chat`
- [x] Run package analysis and tests for `llm_dart_core`
- [x] Run package analysis and tests for `llm_dart_test`
- [x] Run package analysis and tests for provider packages touched by the
  contract rename
- [x] Run root package analysis and compatibility tests
- [x] Run Flutter adapter analysis and tests if chat/runtime contracts changed
- [x] Run clean consumer smoke tests for modern focused imports and root facade
- [x] Run full release readiness gate with consumer smoke, workspace publish
  dry-run, and pub.dev target-version availability preflight
- [x] Update changelog and migration guide before release handoff
