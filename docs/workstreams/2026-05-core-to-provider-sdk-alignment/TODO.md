# TODO

## Workstream Setup

- [x] Create the core-to-provider SDK alignment workstream
- [x] Link prior AI SDK-inspired and SDK-aligned fearless refactor workstreams
- [x] Define target architecture and non-goals
- [x] Create initial audit and parity documents

## Core Contract Audit

- [x] Compare `llm_dart_provider` language contract against
  `repo-ref/ai/packages/provider/src/language-model/v4`
- [x] Compare embedding, image, speech, and transcription contracts against
  reference provider model contracts
- [x] Decide whether Dart needs explicit request metadata in provider-facing
  calls
- [x] Audit response metadata fields across model kinds
- [x] Audit usage and warning shapes across model kinds
- [x] Audit provider object and registry contracts
- [x] Document breaking decisions and migration notes

## Core Contract Implementation Slices

- [x] Normalize language response metadata to `ModelResponseMetadata`
- [x] Preserve `responseId`, `responseTimestamp`, and `responseModelId`
  compatibility aliases
- [x] Migrate provider stream metadata events to the unified wrapper
- [x] Migrate OpenAI, Google, Anthropic, and Ollama language result/stream
  codecs to write unified response metadata
- [x] Add provider contract coverage for language response metadata aliases and
  stream serialization
- [x] Add direct `EmbeddingModel` and `ImageModel` limit facts
- [x] Expand the common image request seam
- [x] Complete shared speech and transcription request fields
- [x] Normalize warning shape

## AI Runtime Audit

- [x] Compare `generateText` and `streamText` runtime shape against reference
  generate-text layers
- [x] Audit tool-loop continuation, missing tool result handling, approval
  flows, and stop conditions
- [x] Audit text result facades for reference step-level projections
- [x] Audit output parsing, partial output, and structured output events
- [x] Audit UI message projection, chat adapters, and serialization ownership
- [x] Decide whether runtime needs additional public error types
- [x] Add or update focused runtime tests for any discovered gaps

## Transport And Provider Implementation Helpers

- [x] Inventory repeated provider helper code after request/transport/response
  splits
- [x] Classify helpers as local, internal shared, or candidate public utility
- [x] Audit JSON response parsing and error normalization helpers
- [x] Audit media type, file data, base64, and multipart helper duplication
- [x] Audit stream helper duplication across SSE, NDJSON, and UTF-8 stream
  decoding
- [x] Decide whether `llm_dart_provider_utils` remains deferred or receives an
  internal-only predecessor

## Provider Parity Matrix

- [x] Complete OpenAI parity row
- [ ] Complete Google parity row
- [ ] Complete Anthropic parity row
- [ ] Complete Ollama parity row
- [ ] Complete ElevenLabs parity row
- [ ] Complete OpenAI-compatible provider family parity row
- [ ] Identify provider-specific gaps that should stay provider-owned
- [ ] Identify shared option gaps that belong in core contracts

## Provider Options And Metadata

- [ ] Audit typed provider option precedence rules for every provider
- [ ] Audit shared-option versus provider-option conflict behavior
- [ ] Audit provider metadata namespace consistency
- [ ] Audit replay metadata flow from output to prompt-part options
- [ ] Add guard coverage for any metadata/input regression gaps

## Compatibility And Migration

- [ ] Inventory root facade exports and compatibility exports
- [ ] Inventory `llm_dart_core` exports by owner package
- [ ] Decide final `ModelRegistry` posture: adapt, deprecate, or remove
- [ ] Decide final `llm_dart_core` posture: freeze, staged removal, or long
  compatibility shell
- [ ] Write before/after migration examples for the final breaking line
- [ ] Update example and consumer smoke expectations

## Validation

- [ ] Run workspace dependency guards
- [ ] Run root boundary guards
- [ ] Run core compatibility shell guard
- [ ] Run provider replay metadata guard
- [ ] Run transport boundary guard
- [ ] Run package analysis and focused tests for touched packages
- [ ] Run consumer smoke
- [ ] Run release readiness gate
