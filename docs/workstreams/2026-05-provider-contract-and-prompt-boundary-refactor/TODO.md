# TODO

## Setup

- [x] Create the provider contract and prompt boundary workstream
- [x] Record current gaps against `repo-ref/ai`
- [x] Define target non-text model contract names
- [x] Define provider options versus provider metadata boundary goals
- [x] Define legacy exit policy options

## Decision Freeze

- [x] Confirm `doEmbed` for embeddings
- [x] Confirm `doGenerate` for image generation
- [x] Confirm `doGenerate` for speech generation
- [x] Confirm `doGenerate` for transcription
- [x] Confirm prompt part input option type names
- [x] Confirm whether metadata input shims are removed immediately or
  deprecated for one alpha
- [x] Confirm root legacy exit option for this breaking line:
  keep legacy frozen as a short transition step, then prefer deletion in the
  next intentional breaking line unless user demand justifies a separate
  compatibility package

## Non-Text Contract Hardening

- [x] Rename `EmbeddingModel.embed` to `EmbeddingModel.doEmbed`
- [x] Rename `ImageModel.generate` to `ImageModel.doGenerate`
- [x] Rename `SpeechModel.generateSpeech` to `SpeechModel.doGenerate`
- [x] Rename `TranscriptionModel.transcribe` to
  `TranscriptionModel.doGenerate`
- [x] Update `llm_dart_ai` `embed` and `embedMany`
- [x] Update `llm_dart_ai` `generateImage`
- [x] Update `llm_dart_ai` `generateSpeech`
- [x] Update `llm_dart_ai` `transcribe`
- [x] Update OpenAI non-text model implementations
- [x] Update Google non-text model implementations
- [x] Update Ollama embedding implementation
- [x] Update ElevenLabs speech and transcription implementations
- [x] Update fake/test model implementations
- [x] Add guard patterns for old non-text contract methods
- [x] Add migration notes for direct non-text provider method users

## Prompt Options And Metadata Separation

- [x] Add input-side prompt part provider options type
- [x] Add provider-owned Anthropic prompt part options
- [x] Move Anthropic cache control request encoding off `ProviderMetadata`
- [x] Audit OpenAI prompt metadata request usage
- [x] Audit Google prompt metadata request usage
- [x] Decide replay-specific metadata-to-options adapters
- [x] Update prompt serialization for new part options
- [x] Add tests proving request metadata does not configure provider calls
- [x] Add before/after docs for prompt cache control migration

## User Prompt Layer

- [x] Decide whether this workstream introduces user-facing `ModelMessage`
  now or leaves it as a follow-up
- [x] Do not introduce `ModelMessage` in this workstream; keep it as a
  follow-up after the provider prompt boundary is stable
- [x] Keep provider-facing prompt contracts in `llm_dart_provider`
- [x] Follow-up: define the user prompt shape in `llm_dart_ai`
- [x] Follow-up: add normalization from user prompt shape to provider prompt
  shape
- [x] Follow-up: add validation for missing tool results during normalization

## Legacy Surface

- [x] Inventory root legacy exports still used by tests and examples
- [x] Remove non-migration examples that import `legacy.dart`
- [x] Add or update guards against new root provider implementation files
- [x] Decide whether legacy is deleted, moved, or frozen for this line
- [x] Follow-up: draft breaking changelog notes for removed legacy surfaces
- [x] Follow-up: delete legacy or move it out of root in the next intentional
  breaking line

## Validation

- [x] Run workspace dependency guards
- [x] Run root boundary guards
- [x] Run core compatibility shell guard
- [x] Run transport boundary guard
- [x] Run test legacy-import guard
- [x] Run example API guard
- [x] Run provider package tests
- [x] Run AI runtime tests
- [x] Run chat package tests if replay contracts changed
- [x] Run package analysis
- [x] Run Flutter tests if UI projection changed
- [x] Run root compatibility tests that remain in scope
- [x] Run full root test suite
- [x] Run `git diff --check`
- [x] Run clean consumer smoke
- [x] Run publish dry-run for affected packages

The full release readiness gate passes with `F:\SDKs\dart-sdk-3.11.6\bin\dart.exe`.
See `05-completion-audit.md` for the verification summary and the Dart child
process routing fix.
