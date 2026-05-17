# Milestones

## M0 - Architecture Decision Freeze

Goals:

- freeze this workstream as the controlling plan for the breaking refactor
- decide final provider implementation method naming
- decide provider options versus provider metadata semantics
- decide which compatibility surfaces are intentionally kept for the breaking
  line

Acceptance criteria:

- target ownership rules are documented
- non-goals are explicit
- related workstreams are linked
- open decisions have owners or review gates

Exit gate:

- no implementation slice starts until provider/runtime/root boundaries are
  written down and accepted.

## M1 - Provider Contract Hardening

Goals:

- make provider model contracts clearly implementation-facing
- prevent provider contracts from being mistaken for user-facing AI functions
- keep provider specifications free from runtime orchestration

Acceptance criteria:

- `LanguageModel` generation and streaming methods use implementation-facing
  names
- all provider packages compile against the hardened contract
- AI runtime runners call the new provider method names
- direct provider contract tests cover request/result behavior without tool-loop
  orchestration
- migration notes explain old direct-call replacements

Exit gate:

- dependency guards and provider package tests pass after the contract rename.

## M2 - AI Runtime Consolidation

Goals:

- keep user-facing generation helpers in `llm_dart_ai`
- centralize multi-step tool orchestration and structured output behavior
- prevent provider packages from depending on runtime or UI helpers

Acceptance criteria:

- `generateText`, `streamText`, object generation, and tool loops live in
  `llm_dart_ai`
- provider packages do not have production dependencies on `llm_dart_ai`
- chat/UI projection helpers are runtime-owned, chat-owned, or provider-owned
  without reverse dependencies
- focused runtime tests cover single-step, multi-step, streaming, structured
  output, and tool continuation flows

Exit gate:

- runtime package tests pass and provider package dependency guards reject
  runtime/UI dependencies.

## M3 - Provider Options And Metadata Boundary

Goals:

- make input-side customization explicit through provider options
- reserve provider metadata for output-side observations and replay details
- preserve typed provider-native options

Acceptance criteria:

- shared provider option contracts are documented
- typed provider options remain provider-owned where the feature is not shared
- raw option escape hatches are namespaced
- `ProviderMetadata` no longer carries request configuration
- tests cover option mapping, unsupported option warnings, and metadata output
  shape

Exit gate:

- migration recipes exist for old metadata-driven request configuration.

## M4 - Shared Generation Option Completion

Goals:

- fill durable shared LLM knobs that modern providers commonly expose
- map unsupported or partially supported options predictably
- avoid moving provider-specific features into the shared contract too early

Acceptance criteria:

- shared options include presence penalty, frequency penalty, seed, reasoning,
  and raw chunk inclusion where applicable
- unsupported shared options produce warnings or clear errors according to the
  provider contract
- reasoning configuration has provider-default behavior and explicit effort
  levels
- tests cover native support, coercion, and unsupported mappings

Exit gate:

- at least OpenAI, Anthropic, Google, and one OpenAI-compatible profile have
  audited mappings or documented non-support.

## M5 - Provider Package Decoupling

Goals:

- keep concrete providers as provider contract implementations
- preserve provider-native product features
- remove runtime/UI/root dependencies from provider packages

Acceptance criteria:

- OpenAI, Anthropic, Google, Ollama, ElevenLabs, and OpenAI-compatible packages
  have no production dependency on `llm_dart_ai`, chat, Flutter, root, or core
  compatibility packages
- provider-owned helper clients remain available
- repeated provider helper duplication is either accepted locally or promoted
  only after the `llm_dart_provider_utils` criteria are met
- dependency guards enforce the package graph

Exit gate:

- package-local tests and workspace dependency guards pass.

## M6 - Root, Legacy, And Migration Hardening

Goals:

- keep root as a facade and explicit compatibility bridge
- remove obsolete compatibility APIs when migration paths are documented
- make the breaking line understandable for existing users

Acceptance criteria:

- root does not own new implementations
- `llm_dart_core` remains compatibility-only or has a documented removal path
- examples prefer modern focused entrypoints
- migration docs include before/after code for provider calls, runtime helpers,
  provider options, metadata, and imports
- changelog calls out all breaking changes

Exit gate:

- clean consumer smoke tests pass for focused package imports, modern root
  facade imports, and any explicitly retained legacy imports.

## M7 - Release Readiness

Goals:

- prove the refactor with repeatable validation
- make the breaking release line publishable
- keep future regressions blocked by tooling

Acceptance criteria:

- workspace dependency guards pass
- root and core boundary guards pass
- package analysis and tests pass for touched packages
- Flutter adapter validation passes if runtime/chat contracts changed
- publish dry-run and consumer smoke instructions are updated
- release notes explain the migration strategy

Exit gate:

- the breaking line is ready for maintainer release decision with no hidden
  architecture exceptions.

## M8 - Post-Closure Structured Output Deepening

Goals:

- align `llm_dart_ai` structured output internals with the reference output
  strategy and stream event shape
- keep the existing `OutputSpec` public seam stable
- improve locality for JSON parsing, strategy selection, runner glue, and
  stream result replay

Acceptance criteria:

- `output_spec.dart` is a facade over focused structured output modules
- JSON helper functions remain internal rather than becoming public utility
  contracts
- `generateOutput`, `streamOutput`, `generateObject`, and `streamObject`
  keep their current behavior
- focused tests cover preserved structured output behavior and immutable JSON
  partial output

Exit gate:

- `llm_dart_ai` focused tests, `llm_dart_core` compatibility tests, package
  analysis, workspace analysis, and whitespace checks pass after the split.

## M9 - Post-Closure Text Call Result Runner Split

Goals:

- align text call internals with the reference generate/stream text
  result-versus-runner split
- keep `text_call.dart` as the stable public seam
- improve locality for result facade behavior and runner dispatch

Acceptance criteria:

- text call result facades live outside the runner glue module
- `generateTextCall` and `streamTextCall` keep their current public behavior
- raw stream collection and structured output adaptation remain covered by
  focused text call tests
- `llm_dart_core` compatibility exports continue to resolve the same names

Exit gate:

- `llm_dart_ai` text call tests, structured output tests, core compatibility
  tests, package analysis, workspace analysis, and whitespace checks pass.

## M10 - Post-Closure Stream Text Result Cancellation Split

Goals:

- align stream text internals with the reference stream result and event
  lifecycle split
- keep `stream_text_runner.dart` as the stable public stream run seam
- improve locality for stream result accessors and provider cancellation
  plumbing

Acceptance criteria:

- `StreamTextRunResult` lives outside the stream run loop implementation
- provider cancellation stream support lives outside the stream run loop
  implementation
- `streamTextRun` and `streamText` keep their current event ordering and final
  result behavior
- `llm_dart_core` compatibility exports continue to resolve the same stream
  runner names

Exit gate:

- stream runner focused tests, language model stream boundary tests, core
  compatibility stream runner tests, package analysis, workspace analysis, and
  whitespace checks pass.

## M11 - Post-Closure Generate Text Runner Support Split

Goals:

- align runner support internals with the reference tool execution and prompt
  replay layers
- keep `GenerateTextRunnerSupport` as the stable public support seam
- improve locality for tool execution lifecycle, tool result projection, and
  continuation prompt replay

Acceptance criteria:

- public runner support typedefs and tool execution types remain exported
- tool execution logic lives outside the public support facade
- prompt replay logic lives outside the public support facade
- `GenerateTextRunner` and `StreamTextRunner` keep their current tool-loop
  behavior
- `llm_dart_core` compatibility exports continue to resolve the same public
  tool execution types

Exit gate:

- non-streaming runner tests, streaming runner tests, core compatibility tests,
  package analysis, workspace analysis, and whitespace checks pass.

## M12 - Post-Closure Generate Text Result Accumulator Split

Goals:

- align stream result projection internals with the reference stream event and
  result facade layers
- keep `GenerateTextResultAccumulator` as the stable public result collection
  seam
- improve locality for content buffering, tool event projection, and lifecycle
  result state

Acceptance criteria:

- content buffering lives outside the public accumulator facade
- streamed tool input state and tool output projection live outside the public
  accumulator facade
- warnings, response metadata, finish state, provider metadata, usage, and
  streamed errors live outside the public accumulator facade
- `collectGenerateTextResult`, raw stream text calls, object output collection,
  and stream runners keep their current behavior
- `llm_dart_core` compatibility exports continue to resolve the same
  accumulator names

Exit gate:

- accumulator focused tests, text runner tests, text call tests, core
  compatibility tests, package analysis, workspace analysis, and whitespace
  checks pass.

## M13 - Post-Closure Stream Text Runner Lifecycle Split

Goals:

- align stream runner internals with the reference stream text and language
  model call lifecycle layers
- keep `StreamTextRunner` as the stable public stream runtime seam
- improve locality for event emission, active run state, and finish/error/abort
  closure

Acceptance criteria:

- stream event emission and `onChunk` dispatch live outside the main runner loop
- active request, active accumulator, active step number, and open-step state
  live outside the main runner loop
- step finish, successful run finish, abort finish, and error failure closure
  live outside the main runner loop
- stream event order and result behavior stay unchanged for single-step, tool
  continuation, cancellation, and error paths
- `llm_dart_core` compatibility exports continue to resolve the same stream
  runner names

Exit gate:

- stream runner focused tests, core compatibility stream runner tests, package
  analysis, workspace analysis, and whitespace checks pass.

## M14 - Post-Closure Generate Text Runner Lifecycle Split

Goals:

- align non-streaming runner internals with the reference generate text
  lifecycle layers
- keep `GenerateTextRunner` as the stable public non-streaming runtime seam
- improve locality for active run state, step finish, successful finish,
  abort finish, and error callback closure

Acceptance criteria:

- active request, active result, active step number, and previous step ledger
  live outside the main runner loop
- step finish, successful run finish, abort finish, and error callback wrapping
  live outside the main runner loop
- runner callback ordering and result behavior stay unchanged for single-step,
  tool continuation, cancellation, and error paths
- `llm_dart_core` compatibility exports continue to resolve the same runner
  names

Exit gate:

- generate runner focused tests, text call tests, core compatibility generate
  runner tests, package analysis, workspace analysis, and whitespace checks
  pass.

## M15 - Post-Closure Output Runner Lifecycle Split

Goals:

- align structured output runner internals with the reference generate-object
  and stream-object lifecycle layers
- keep output runner public entrypoints as the stable structured output runtime
  seam
- improve locality for response format injection, final parse/error handling,
  and streaming partial projection

Acceptance criteria:

- response format conflict validation and injection live outside the public
  output runner module
- structured output context construction, final parse result construction, and
  validation error diagnostics live outside the public output runner module
- streaming partial parse, duplicate suppression, and element projection live
  outside the public output runner module
- `generateOutput`, `streamOutput`, `streamOutputResult`, `generateObject`, and
  `streamObject` behavior stays unchanged

Exit gate:

- output focused tests, text call tests, generate/stream runner tests, core
  compatibility tests, package analysis, workspace analysis, and whitespace
  checks pass.

## M16 - Post-Closure Output Spec Strategy Split

Goals:

- align concrete output strategy ownership with the reference output strategy
  layer
- keep the `OutputSpec` family available through the stable public output spec
  facade
- improve locality for text, JSON, object, array, and choice parse behavior

Acceptance criteria:

- the base `OutputSpec<T>` interface lives outside concrete strategy
  implementations
- each concrete output strategy lives in an output-type-owned module
- response format, final parse, partial parse, validation, and element event
  behavior stay unchanged for each output type
- `generateOutput`, `streamOutput`, `generateObject`, and `streamObject`
  behavior stays unchanged through the output runner facade
- `llm_dart_core` compatibility exports continue to resolve the same output
  spec names

Exit gate:

- focused output spec tests, text call tests, core compatibility tests, package
  analysis, workspace analysis, and whitespace checks pass.

## M17 - Post-Closure Output Foundation JSON Split

Goals:

- align structured output support ownership with the reference parse,
  validation, stream event, and result facade layers
- keep `output_spec_foundation.dart` and `output_spec_json.dart` as stable
  compatibility facades
- improve locality for output support types, JSON parsing, validation, value
  handling, and diagnostics

Acceptance criteria:

- decoder typedefs, structured output context, output result, and output stream
  events live in focused modules
- JSON text decoding, object coercion, JSON value freeze/equality, schema and
  choice validation, and usage diagnostics live in focused modules
- the existing public `llm_dart_ai` and `llm_dart_core` output names continue
  to resolve
- JSON parse error messages, partial output behavior, diagnostics, and output
  runner behavior stay unchanged

Exit gate:

- focused output spec tests, text call tests, core compatibility tests, package
  analysis, workspace analysis, and whitespace checks pass.

## M18 - Post-Closure OpenAI Language Model Orchestration Split

Goals:

- align OpenAI provider adapter orchestration with the reference Responses and
  Chat language model layers
- keep `OpenAILanguageModel` as the stable provider-facing model adapter
- improve locality for request encoding dispatch, transport projection,
  non-streaming response decode, and stream chunk decode

Acceptance criteria:

- Responses and Chat Completions request encoding dispatch live outside the
  main model adapter
- transport request URI, headers, call options, and response type projection
  live outside the main model adapter
- route-aware generate response decoding lives outside the main model adapter
- route-aware stream chunk decoding and raw chunk forwarding live outside the
  main model adapter
- existing OpenAI-family route selection, warning, request, response, stream,
  timeout, retry, cancellation, and error behavior stays unchanged

Exit gate:

- focused OpenAI language model, Chat Completions, Responses codec, Responses
  stream codec, Responses lifecycle tests, package analysis, workspace
  analysis, and whitespace checks pass.

## M19 - Post-Closure Google Language Model Orchestration Split

Goals:

- align Google provider adapter orchestration with the reference Google
  language model, message conversion, tool preparation, and HTTP dispatch
  layers
- keep `GoogleLanguageModel` as the stable provider-facing model adapter
- improve locality for request preparation, transport projection,
  non-streaming response decode, stream chunk decode, and stream finish
  emission

Acceptance criteria:

- provider option resolution and GenerateContent request encoding live outside
  the main model adapter
- generate/stream route URI, headers, call options, and response type
  projection live outside the main model adapter
- generate response decoding lives outside the main model adapter
- stream chunk decoding, raw chunk forwarding, stream state creation, and
  finish event emission live outside the main model adapter
- existing Google request, warning, response, stream, timeout, retry,
  cancellation, and error behavior stays unchanged

Exit gate:

- focused Google language model, GenerateContent codec, stream codec, result
  codec tests, package analysis, workspace analysis, and whitespace checks pass.

## M20 - Post-Closure Anthropic Language Model Orchestration Split

Goals:

- align Anthropic provider adapter orchestration with the reference Anthropic
  language model, prompt conversion, tool preparation, and HTTP dispatch layers
- keep `AnthropicLanguageModel` as the stable provider-facing model adapter
- improve locality for request preparation, beta/header transport projection,
  non-streaming response decode, stream chunk decode, and token-count decode

Acceptance criteria:

- provider option resolution and Messages request encoding live outside the
  main model adapter
- token-count request encoding and token-count response decoding live outside
  the main model adapter
- messages/count-tokens route URI, headers, beta features, call options, and
  response type projection live outside the main model adapter
- generate response decoding lives outside the main model adapter
- stream chunk decoding, raw chunk forwarding, and stream state creation live
  outside the main model adapter
- existing Anthropic request, warning, beta/header, response, stream,
  token-count, timeout, retry, cancellation, and error behavior stays unchanged

Exit gate:

- focused Anthropic language model, Messages codec, stream codec, result codec,
  request option policy, fixture contract tests, package analysis, workspace
  analysis, and whitespace checks pass.

## M21 - Post-Closure Google Embedding Model Boundary Split

Goals:

- align Google embedding provider adapter orchestration with the reference
  Google embedding model and provider-utils HTTP dispatch layers
- keep `GoogleEmbeddingModel` as the stable provider-facing embedding adapter
- improve locality for provider option resolution, single/batch request
  construction, transport projection, and response decoding

Acceptance criteria:

- provider option and settings resolution live outside the main embedding model
  adapter
- single and batch embedding request body construction live outside the main
  embedding model adapter
- `embedContent` and `batchEmbedContents` URI, header, call option, and
  response type projection live outside the main embedding model adapter
- single and batch embedding response decoding, usage metadata, and response
  metadata construction live outside the main embedding model adapter
- existing Google embedding provider options, single/batch wire shape,
  timeout, retry, cancellation, response metadata, and usage behavior stay
  unchanged

Exit gate:

- focused Google embedding model and model describer tests, package analysis,
  workspace analysis, and whitespace checks pass.

## M22 - Post-Closure OpenAI Embedding Model Boundary Split

Goals:

- align OpenAI embedding provider adapter orchestration with the reference
  OpenAI embedding model and provider-utils HTTP dispatch layers
- keep `OpenAIEmbeddingModel` as the stable provider-facing embedding adapter
- improve locality for settings/provider option resolution, request
  validation, transport projection, and response decoding

Acceptance criteria:

- settings and provider option resolution live outside the main embedding model
  adapter
- max embeddings validation and request body construction live outside the main
  embedding model adapter
- embeddings URI, default/per-call headers, call options, and response type
  projection live outside the main embedding model adapter
- indexed response sorting, embedding value validation, usage metadata, and
  response metadata construction live outside the main embedding model adapter
- existing OpenAI embedding provider options, request body, max embeddings
  behavior, timeout, retry, cancellation, response metadata, and usage behavior
  stay unchanged

Exit gate:

- focused OpenAI embedding model, model describer, and entrypoint tests,
  package analysis, workspace analysis, and whitespace checks pass.

## M23 - Post-Closure Ollama Embedding Model Boundary Split

Goals:

- align Ollama embedding provider adapter orchestration with the embedding
  adapter pattern established from the reference Google/OpenAI embedding models
  and provider-utils HTTP dispatch layers
- keep `OllamaEmbeddingModel` as the stable provider-facing embedding adapter
- improve locality for settings resolution, request validation, transport
  projection, response decoding, and provider metadata projection

Acceptance criteria:

- settings resolution lives outside the main embedding model adapter
- empty input, unsupported dimensions, and unsupported provider options
  validation live outside the main embedding model adapter
- request body construction lives outside the main embedding model adapter
- embedding URI, default/per-call headers, call options, and response type
  projection live outside the main embedding model adapter
- embedding response decoding, response metadata, and Ollama provider metadata
  construction live outside the main embedding model adapter
- existing Ollama embedding request body, validation ordering, timeout, retry,
  cancellation, response metadata, and provider metadata behavior stay unchanged

Exit gate:

- focused Ollama embedding model and model describer tests, package analysis,
  workspace analysis, and whitespace checks pass.

## M24 - Post-Closure Google Image Model Boundary Split

Goals:

- align Google image provider adapter orchestration with the reference Google
  image model and provider-utils HTTP dispatch layers
- keep `GoogleImageModel` as the stable provider-facing image adapter
- improve locality for Imagen/Gemini request validation, request body
  construction, transport projection, and response decoding

Acceptance criteria:

- settings and provider option resolution live outside the main image model
  adapter
- Imagen/Gemini image model detection, max image count resolution, and
  generation/edit validation live outside the main image model adapter
- Imagen generation and Gemini generation/edit request body construction live
  outside the main image model adapter
- `predict` and `generateContent` URI, header, call option, and response type
  projection live outside the main image model adapter
- Imagen and Gemini response decoding, usage metadata, response metadata, and
  Google provider metadata construction live outside the main image model
  adapter
- existing Google image provider options, request body, edit/variation helpers,
  timeout, retry, cancellation, response metadata, usage, provider metadata,
  and validation behavior stay unchanged

Exit gate:

- focused Google image model and model describer tests, package analysis,
  workspace analysis, and whitespace checks pass.

## M25 - Post-Closure OpenAI Image Model Boundary Split

Goals:

- align OpenAI image provider adapter orchestration with the reference OpenAI
  image model and provider-utils HTTP dispatch layers
- keep `OpenAIImageModel` as the stable provider-facing image adapter
- improve locality for generation/edit request validation, JSON body
  construction, multipart body construction, transport projection, and response
  decoding

Acceptance criteria:

- settings and provider option resolution live outside the main image model
  adapter
- max images per call and response-format policy live outside the main image
  model adapter
- generation and edit validation live outside the main image model adapter
- generation JSON request body construction and edit multipart body
  construction live outside the main image model adapter
- generation and edit URI, default/per-call headers, call options, and response
  type projection live outside the main image model adapter
- image response decoding, usage metadata, per-image token distribution,
  response metadata, and OpenAI provider metadata construction live outside the
  main image model adapter
- existing OpenAI image provider options, generation/edit wire shape, multipart
  field order, timeout, retry, cancellation, response metadata, usage, provider
  metadata, and validation behavior stay unchanged

Exit gate:

- focused OpenAI image model, model describer, and entrypoint tests, package
  analysis, workspace analysis, and whitespace checks pass.

## M26 - Post-Closure OpenAI Audio Model Boundary Split

Goals:

- align OpenAI speech and transcription provider adapter orchestration with
  the reference OpenAI speech/transcription models and provider-utils HTTP
  dispatch layers
- keep `OpenAISpeechModel` and `OpenAITranscriptionModel` as stable
  provider-facing audio adapters
- improve locality for provider option validation, request body construction,
  transport projection, and response/provider metadata decoding

Acceptance criteria:

- speech settings resolution, provider option resolution, speed validation,
  output-format fallback, language warnings, and request body construction
  live outside the main speech model adapter
- speech URI, default/per-call headers, call options, and response type
  projection live outside the main speech model adapter
- speech bytes decoding, media-type fallback, and response metadata
  construction live outside the main speech model adapter
- transcription settings resolution, provider option resolution, temperature
  validation, response-format selection, timestamp validation, multipart body
  construction, and filename inference live outside the main transcription
  model adapter
- transcription URI, default/per-call headers, accept header, call options, and
  response type projection live outside the main transcription model adapter
- transcription JSON/plain-text response decoding, segment/word projection,
  language normalization, response metadata, and OpenAI provider metadata live
  outside the main transcription model adapter
- existing OpenAI audio request, warning, validation, timeout, retry,
  cancellation, response metadata, and provider metadata behavior stays
  unchanged

Exit gate:

- focused OpenAI speech model, transcription model, model describer, and
  entrypoint tests, package analysis, workspace analysis, and whitespace
  checks pass.

## M27 - Post-Closure Google Speech Model Boundary Split

Goals:

- align Google speech provider adapter orchestration with the reference Google
  provider adapter and provider-utils HTTP dispatch layers
- keep `GoogleSpeechModel` as the stable provider-facing speech adapter
- improve locality for provider option validation, request body construction,
  transport projection, and response/provider metadata decoding

Acceptance criteria:

- settings and provider option resolution live outside the main speech model
  adapter
- single-speaker versus multi-speaker validation lives outside the main speech
  model adapter
- `generateContent` request body construction and speech voice config
  construction live outside the main speech model adapter
- `generateContent` URI, headers, call options, and response type projection
  live outside the main speech model adapter
- speech JSON response coercion, inline audio aggregation, response metadata,
  and Google provider metadata construction live outside the main speech model
  adapter
- existing Google speech request, default voice, multi-speaker provider
  options, timeout, retry, cancellation, response metadata, and provider
  metadata behavior stays unchanged

Exit gate:

- focused Google speech model and model describer tests, package analysis,
  workspace analysis, and whitespace checks pass.

## M28 - Post-Closure ElevenLabs Audio Model Boundary Split

Goals:

- align ElevenLabs speech and transcription provider adapter orchestration with
  the reference provider adapter and provider-utils HTTP dispatch layers
- keep `ElevenLabsSpeechModel` and `ElevenLabsTranscriptionModel` as stable
  provider-facing audio adapters
- improve locality for provider option validation, request body construction,
  transport projection, and response/provider metadata decoding

Acceptance criteria:

- speech settings resolution, provider option resolution, voice fallback,
  option validation, output-format normalization, and request body construction
  live outside the main speech model adapter
- speech URI, default/per-call headers, call options, and response type
  projection live outside the main speech model adapter
- speech bytes decoding, media-type fallback, response metadata, and
  ElevenLabs provider metadata live outside the main speech model adapter
- transcription settings resolution, provider option resolution, option
  validation, and multipart body construction live outside the main
  transcription model adapter
- transcription URI, default/per-call headers, call options, and response type
  projection live outside the main transcription model adapter
- transcription JSON response coercion, text validation, segment projection,
  response metadata, and provider metadata live outside the main transcription
  model adapter
- existing ElevenLabs audio request, validation, timeout, retry, cancellation,
  response metadata, and provider metadata behavior stays unchanged

Exit gate:

- focused ElevenLabs speech model, transcription model, model describer, and
  entrypoint tests, package analysis, workspace analysis, and whitespace
  checks pass.

## M29 - Post-Closure Ollama Language Model Boundary Split

Goals:

- align Ollama language provider adapter orchestration with the reference
  language adapter and provider-utils HTTP dispatch layers
- keep `OllamaLanguageModel` as the stable provider-facing chat adapter
- improve locality for request preparation, transport projection,
  non-streaming response decoding, and stream lifecycle handling

Acceptance criteria:

- settings resolution, request codec construction, and generate/stream request
  preparation live outside the main language model adapter
- `/api/chat` URI, default/per-call headers, call options, and response type
  projection live outside the main language model adapter
- response codec construction and non-streaming response decoding live outside
  the main language model adapter
- stream codec construction, start-event emission, byte stream decoding
  dispatch, and transport error projection live outside the main language
  model adapter
- existing Ollama chat request encoding, generate response decoding, stream
  ordering, raw chunk forwarding, timeout, retry, cancellation, and provider
  option validation behavior stays unchanged

Exit gate:

- focused Ollama language model, chat request codec, model describer, and
  entrypoint tests, package analysis, workspace analysis, and whitespace
  checks pass.
