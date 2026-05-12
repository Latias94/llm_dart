# Initial Gap Audit

Date: 2026-05-12

This audit records the current source state after comparing `llm_dart` with the
architecture lessons from `repo-ref/ai`.

## Already Strong

The package graph is broadly correct:

- provider-facing language contracts use `doGenerate` and `doStream`
- non-text provider contracts use implementation-facing `do*` methods
- `llm_dart_ai` owns generation helpers, multi-step runners, stream
  accumulation, structured output, and UI projection
- provider packages depend on `llm_dart_provider` and `llm_dart_transport`, not
  root, chat, Flutter, or AI runtime in production code
- root entrypoints are guarded as facade barrels
- `llm_dart_core` is guarded as a compatibility shell

Local guard validation passed on 2026-05-12:

- `dart run tool/check_workspace_dependency_guards.dart`
- `dart run tool/check_root_package_boundary_guards.dart`
- `dart run tool/check_core_compatibility_shell_guard.dart`
- `dart run tool/check_test_legacy_import_guards.dart`

## Gap 1 - User Prompt And Provider Prompt Are Still The Same Layer

Current source:

- `llm_dart_ai` generation helpers accept `List<PromptMessage>`
- `PromptMessage` lives in `llm_dart_provider`
- provider codecs consume the same shape directly

Reference direction:

- user-facing prompt messages are owned by the AI runtime layer
- runtime normalization converts user prompts to provider-facing prompt messages
- provider codecs only consume normalized provider prompts

Risk:

- adding ergonomic prompt features changes provider contracts
- provider codecs become responsible for user-level validation
- missing tool-result validation and prompt cleanup remain spread across
  runtime/provider logic

Recommendation:

- add `ModelMessage` or an equivalent user prompt shape in `llm_dart_ai`
- keep `PromptMessage` as provider-facing data
- normalize and validate before constructing `GenerateTextRequest`

## Gap 2 - Prompt Parts Still Expose ProviderMetadata Input

Current source:

- `PromptPart.providerMetadata` still exists
- generated output metadata is replayed back into prompt parts
- some provider codecs inspect prompt metadata for provider-native replay

Reference direction:

- input-side provider customization is `providerOptions`
- output-side provider observation is `providerMetadata`
- replay from output metadata to input options is explicit

Risk:

- users can treat output metadata as request configuration
- provider codecs must support two meanings for the same field
- typed provider options lose authority as the input customization mechanism

Recommendation:

- remove ordinary `providerMetadata` from prompt part constructors in the
  breaking line
- introduce explicit replay option shapes where OpenAI, Google, Anthropic, or
  other providers need provider-native continuation
- keep output metadata on result content and stream events

## Gap 3 - Serialization Helpers Are Duplicated

Current source:

- `llm_dart_provider` owns a `SerializationJsonSupport`
- `llm_dart_ai` has a separate mostly duplicated helper

Reference direction:

- shared implementation helpers live behind a utility boundary only when they
  are reused by multiple layers or providers

Risk:

- subtle codec behavior drifts between provider and AI runtime
- future provider prompt options and tool output serialization will need double
  maintenance

Recommendation:

- pick one serialization ownership boundary
- prefer provider-owned serialization for provider contracts
- make AI runtime use the provider-owned helpers or extract a deliberate
  utility package if more shared helpers are added

## Gap 4 - Provider Utilities Are Emerging But Not Yet Named

Current source:

- providers repeat JSON guards, media-type normalization, provider-reference
  resolution, request shaping, stream parsing, and metadata helpers
- transport owns HTTP/SSE primitives, but provider codec helpers remain
  scattered

Reference direction:

- provider-utils contains repeated implementation helpers, not runtime
  orchestration

Risk:

- repeated provider code grows independently
- utility extraction can happen too late and become a breaking refactor inside
  provider packages
- utility extraction can also happen too early and create unstable public API

Recommendation:

- start with package-private helper consolidation where possible
- publish `llm_dart_provider_utils` only after at least two provider packages
  need the same stable helper contract
- keep transport implementations out of provider-utils

## Gap 5 - Root Legacy Compatibility Still Has Architectural Gravity

Current source:

- `legacy.dart` still exports broad builder-era compatibility
- root still hosts compatibility providers, models, builders, and adapters
- guard tooling prevents new root implementation drift, but the old surface is
  still large

Reference direction:

- root is a convenience facade, not an implementation host

Risk:

- compatibility behavior can keep influencing new architecture decisions
- examples/tests can accidentally preserve old design assumptions
- maintenance cost remains high after the modern API is ready

Recommendation:

- define the earliest breaking window for deletion or relocation
- keep only explicit migration imports while the bridge exists
- update docs to make modern model-first APIs the default path
