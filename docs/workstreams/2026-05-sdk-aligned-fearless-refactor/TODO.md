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

## Structured Output Module Boundary Follow-Up

- [x] Compare structured output against `repo-ref/ai` output strategy,
  structured output event, and object generation runner seams
- [x] Keep `output_spec.dart` as the public facade while moving strategy,
  JSON support, runner glue, and stream result replay into focused modules
- [x] Preserve existing `OutputSpec`, `generateOutput`, `streamOutput`,
  `generateObject`, and `streamObject` behavior
- [x] Add a focused regression test for deeply immutable JSON partial output
- [x] Document the post-closure module boundary and changelog note

## Text Call Result Runner Follow-Up

- [x] Compare text call shape against `repo-ref/ai` generate text result,
  stream text result, generate text runner, and stream text runner seams
- [x] Keep `text_call.dart` as the public facade while moving result facades
  and runner glue into focused modules
- [x] Preserve existing `GenerateTextCallResult`, `StreamTextCallResult`,
  `generateTextCall`, and `streamTextCall` behavior
- [x] Verify raw and structured text call focused tests after the split
- [x] Document the result/runner module split and changelog note

## Stream Text Result Cancellation Follow-Up

- [x] Compare stream text shape against `repo-ref/ai` stream text result,
  stream text runner, and event lifecycle seams
- [x] Keep `stream_text_runner.dart` as the public facade while moving the
  stream result facade and cancellation support into focused modules
- [x] Preserve existing `StreamTextRunResult`, `StreamTextRunner`, and
  `streamTextRun` behavior
- [x] Verify stream runner focused tests covering raw events, tool steps,
  cancellation, errors, result accessors, and UI projection
- [x] Document the stream result/cancellation module split and changelog note

## Generate Text Runner Support Follow-Up

- [x] Compare runner support shape against `repo-ref/ai` tool execution,
  tool execution events, and response/prompt replay seams
- [x] Keep `GenerateTextRunnerSupport` as the public facade while moving tool
  execution and prompt replay into focused modules
- [x] Preserve existing public tool execution typedefs, event types, result
  types, and runner behavior
- [x] Verify non-streaming and streaming runner focused tests after the split
- [x] Document the runner support module split and changelog note

## Generate Text Result Accumulator Follow-Up

- [x] Compare accumulator shape against `repo-ref/ai` stream event and result
  projection layers
- [x] Keep `GenerateTextResultAccumulator` as the public facade while moving
  content buffering, tool projection, and lifecycle state into focused modules
- [x] Preserve `collectGenerateTextResult`, stream runner, text call, and object
  output behavior
- [x] Add focused regression tests for tool input decoding, metadata merge, and
  denied output ordering
- [x] Document the accumulator module split and changelog note

## Stream Text Runner Lifecycle Follow-Up

- [x] Compare stream runner shape against `repo-ref/ai` stream text and
  language model call lifecycle layers
- [x] Keep `StreamTextRunner`, `streamTextRun`, and `streamText` as the public
  stream runtime seam while moving event emission, run state, and lifecycle
  closure into focused modules
- [x] Preserve stream event order, `onChunk`, `onStepFinish`, `onFinish`,
  cancellation, error, and step stream behavior
- [x] Add a focused regression test for cancellation before provider streaming
- [x] Document the stream runner lifecycle split and changelog note

## Generate Text Runner Lifecycle Follow-Up

- [x] Compare non-streaming runner shape against `repo-ref/ai` generate text
  lifecycle layers
- [x] Keep `GenerateTextRunner`, `runTextGeneration`, and `generateText` as the
  public non-streaming runtime seam while moving active run state and lifecycle
  closure into focused modules
- [x] Preserve callback ordering, cancellation, error, tool continuation, and
  stop policy behavior
- [x] Add a focused regression test for cancellation before provider generation
- [x] Document the generate text runner lifecycle split and changelog note

## Output Runner Lifecycle Follow-Up

- [x] Compare output runner shape against `repo-ref/ai` generate-object and
  stream-object lifecycle layers
- [x] Keep `generateOutput`, `streamOutput`, `streamOutputResult`,
  `generateObject`, and `streamObject` as the public structured output runtime
  seam while moving parse lifecycle and stream partial projection into focused
  modules
- [x] Preserve response format injection, response format conflict rejection,
  final parse error wrapping, text event forwarding, partial output
  suppression, and element event behavior
- [x] Add a focused regression test for duplicate partial output suppression
- [x] Document the output runner lifecycle split and changelog note

## Output Spec Strategy Follow-Up

- [x] Compare output strategy shape against `repo-ref/ai` output-strategy,
  generate-object, stream-object, and parse/validate layers
- [x] Keep `output_spec_strategy.dart` as the public compatibility facade while
  moving each concrete output strategy into an output-type-owned module
- [x] Preserve `OutputSpec`, `TextOutputSpec`, `JsonOutputSpec`,
  `ObjectOutputSpec`, `ArrayOutputSpec`, and `ChoiceOutputSpec` public exports
- [x] Preserve final parse, partial parse, object schema validation, choice
  normalization, and array element event behavior
- [x] Verify focused `llm_dart_ai` and `llm_dart_core` output/text call tests
  after the split
- [x] Document the output spec strategy split and changelog note

## Output Foundation JSON Follow-Up

- [x] Compare structured output support shape against `repo-ref/ai`
  parse/validate, output strategy, stream object, and stream result layers
- [x] Keep `output_spec_foundation.dart` and `output_spec_json.dart` as
  compatibility facades while moving support responsibilities into focused
  modules
- [x] Preserve decoder typedefs, context/result/event types, JSON text decode,
  object coercion, JSON freeze/equality, schema validation, choice
  normalization, and usage diagnostics behavior
- [x] Verify focused `llm_dart_ai` and `llm_dart_core` output/text call tests
  after the split
- [x] Document the output foundation/JSON support split and changelog note

## OpenAI Language Model Orchestration Follow-Up

- [x] Compare OpenAI provider model shape against `repo-ref/ai` Responses and
  Chat language model adapter layers
- [x] Keep `OpenAILanguageModel` as the public provider adapter while moving
  route-aware request encoding, transport request construction, generate
  response decoding, and stream chunk decoding into focused modules
- [x] Preserve route selection, warnings, headers, timeout, retries,
  cancellation, raw chunk forwarding, generate decoding, and streaming error
  behavior
- [x] Verify focused OpenAI language model, Chat Completions mainline,
  Responses codec, Responses stream codec, and Responses lifecycle tests
- [x] Document the OpenAI language model orchestration split and changelog note

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
