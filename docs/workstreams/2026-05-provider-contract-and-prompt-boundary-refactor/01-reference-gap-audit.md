# Reference Gap Audit

Date: 2026-05-12

This audit compares the current `llm_dart` source with the durable lessons from
`repo-ref/ai`. It intentionally focuses on architectural gaps that still matter
after the previous package split.

## Current Strengths

The current source already has several strong boundaries:

- `LanguageModel` exposes implementation-facing `doGenerate` and `doStream`
  methods.
- `llm_dart_ai` owns `generateText`, `streamText`, multi-step generation,
  structured output helpers, and stream result accumulation.
- provider packages depend on provider specs and transport, not AI runtime,
  chat, Flutter, root, or compatibility packages for production code.
- `ProviderInvocationOptions` exists as typed input-side provider
  customization.
- `ProviderMetadata` is documented as output-side provider-owned metadata.
- root entrypoints are guarded as facade barrels.
- `llm_dart_core` is guarded as a compatibility shell.

Evidence:

- `packages/llm_dart_provider/lib/src/model/language_model.dart`
- `packages/llm_dart_ai/lib/src/model/generate_text_runner.dart`
- `packages/llm_dart_ai/lib/src/model/stream_text_runner.dart`
- `packages/llm_dart_provider/lib/src/common/provider_options.dart`
- `packages/llm_dart_provider/lib/src/common/provider_metadata.dart`
- `tool/check_workspace_dependency_guards.dart`
- `tool/check_root_package_boundary_guards.dart`
- `tool/check_core_compatibility_shell_guard.dart`

## Gap 1 - Non-Text Model Contracts Still Use User-Facing Names

Current source:

- `EmbeddingModel.embed(EmbedRequest request)`
- `ImageModel.generate(ImageGenerationRequest request)`
- `SpeechModel.generateSpeech(SpeechGenerationRequest request)`
- `TranscriptionModel.transcribe(TranscriptionRequest request)`

Reference direction:

- `EmbeddingModelV4.doEmbed(...)`
- `ImageModelV4.doGenerate(...)`
- `SpeechModelV4.doGenerate(...)`
- `TranscriptionModelV4.doGenerate(...)`

Risk:

- direct provider calls look equivalent to runtime helpers
- future middleware or runtime behavior has no clear call boundary
- language model semantics are stricter than the rest of the model family

Recommendation:

- rename all non-text provider contract methods to implementation-facing names
- keep user-facing helpers in `llm_dart_ai`
- add guard patterns for old non-text method names

## Gap 2 - Prompt Parts Still Carry Input-Side ProviderMetadata

Current source:

- `PromptPart.providerMetadata`
- `TextPromptPart.providerMetadata`
- `FilePromptPart.providerMetadata`
- `ToolCallPromptPart.providerMetadata`
- `ToolResultPromptPart.providerMetadata`

Reference direction:

- prompt messages and prompt parts use input-side `providerOptions`
- provider metadata is returned by model outputs and stream parts

Risk:

- users can keep using metadata as request configuration
- provider codecs must inspect output-shaped data while building requests
- the documented metadata/options boundary is not enforced by type design

Recommendation:

- introduce an input-side provider part options mechanism
- migrate provider codecs to read input options
- keep output metadata on generated content, stream events, and UI projection

## Gap 3 - Anthropic Cache Control Uses ProviderMetadata As Request Input

Current source:

- `anthropic_messages_codec.dart` extracts `cache_control` from prompt
  `ProviderMetadata`
- this contradicts the documented rule that provider metadata is output-side

Reference direction:

- cache controls and native provider request controls are input-side provider
  options

Risk:

- the most concrete metadata/options violation remains in a high-value provider
- migration examples can accidentally teach users to use metadata for input
  controls

Recommendation:

- add provider-owned Anthropic prompt part options for cache control
- provide a temporary migration shim only if the breaking release policy
  requires it
- remove metadata-driven cache control from the breaking line

## Gap 4 - User Prompt And Provider Prompt Are The Same Layer

Current source:

- `PromptMessage` is used by user helpers, runtime replay, serialization, and
  provider codecs

Reference direction:

- user-facing prompt inputs are normalized into provider-facing prompt
  messages before provider calls

Risk:

- provider codecs become responsible for too much user-level normalization
- adding ergonomic prompt features risks changing provider contracts
- request replay and UI projection can become tangled with provider wire
  encoding

Recommendation:

- keep the existing provider prompt shape in `llm_dart_provider`
- add a future user prompt shape in `llm_dart_ai`
- centralize conversion and validation in AI runtime

## Gap 5 - Root Compatibility Surface Is Still Large

Current source:

- `lib/src/compatibility` contains a large migration bridge
- `lib/providers`, `lib/models`, and `lib/builder` remain exported from
  `lib/legacy.dart`

Reference direction:

- root should be a facade over modern packages, not an implementation host

Risk:

- compatibility code can continue shaping architecture decisions
- tests and examples can accidentally depend on legacy abstractions
- maintenance cost remains high even after package split

Recommendation:

- treat compatibility as a release-window bridge, not an ongoing design layer
- remove or move legacy surfaces after migration docs are complete
- strengthen guards against new implementation code in root compatibility paths
