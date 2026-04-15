# `llm_dart_core` Boundary Map

## Goal

Prevent `llm_dart_core` from silently becoming the new internal monolith while
still avoiding premature package fragmentation.

This note freezes the intended internal sublayers of `llm_dart_core` and
clarifies which other packages should depend on which parts conceptually.

## Why This Matters Now

As of 2026-04-15, `llm_dart_core` is structurally healthy as a package, but it
already exports several different concern clusters:

- `common/` - 10 files
- `model/` - 20 files
- `serialization/` - 6 files
- `ui/` - 8 files
- `prompt/`, `stream/`, `tool/`, and `content/` - smaller but foundational
  layers

That concentration is not automatically wrong, but it does mean the package now
needs an explicit internal map.

## Frozen Internal Sublayers

`llm_dart_core` should now be read as four sublayers plus one shared
foundation:

### 1. Shared Foundation

This is the small, reusable contract floor:

- warnings and errors
- usage and provider metadata
- provider invocation/model options
- request cancellation
- JSON schema
- prompt and content primitives
- tool definitions

Representative files:

- `src/common/*`
- `src/prompt/prompt_message.dart`
- `src/content/content_part.dart`
- `src/tool/tool_definition.dart`

### 2. Model Specification And Capability Layer

This layer defines the stable shared provider-facing model contracts and the
lowest shared capability helpers:

- `LanguageModel`
- `EmbeddingModel`
- `ImageModel`
- `SpeechModel`
- `TranscriptionModel`
- single-step shared helper functions such as `embed(...)`,
  `generateImage(...)`, `generateSpeech(...)`, `transcribe(...)`,
  `generateText(...)`, and `streamText(...)`
- shared response-format and output-spec contracts

Representative files:

- `src/model/language_model.dart`
- `src/model/embedding_model.dart`
- `src/model/image_model.dart`
- `src/model/speech_model.dart`
- `src/model/transcription_model.dart`
- `src/model/output_spec.dart`
- `src/model/response_format.dart`
- `src/model/embed.dart`
- `src/model/generate_image.dart`
- `src/model/generate_speech.dart`
- `src/model/transcribe.dart`
- `src/model/text_call.dart`

### 3. Runner And Step-Orchestration Layer

This layer sits above one-shot model calls and owns the truthful shared
multi-step subset:

- `GenerateTextRunner`
- `StreamTextRunner`
- step results and run results
- runner callback types

Representative files:

- `src/model/generate_text_runner.dart`
- `src/model/stream_text_runner.dart`
- `src/model/generate_text_run_result.dart`
- `src/model/generate_text_step_result.dart`
- `src/model/generate_text_step_start_event.dart`

This layer is still intentionally narrow:

- shared common function-tool continuation only
- no provider-native continuation
- no approval-safe continuation
- no shared `prepareStep`
- no shared retry/model-switch policy

### 4. Stream And UI Projection Layer

This layer owns the shared projection model above raw provider generation:

- `TextStreamEvent`
- `ChatUiMessage` / `ChatUiPart`
- `ChatUiStreamChunk`
- `ChatMessageMapper`
- shared accumulators

Representative files:

- `src/stream/text_stream_event.dart`
- `src/ui/chat_ui_message.dart`
- `src/ui/chat_ui_stream_chunk.dart`
- `src/ui/chat_message_mapper.dart`
- `src/ui/chat_ui_accumulator.dart`
- `src/ui/chat_ui_accumulator_data_support.dart`
- `src/ui/chat_ui_accumulator_hydration_support.dart`
- `src/ui/chat_ui_accumulator_metadata_support.dart`
- `src/ui/chat_ui_accumulator_output_support.dart`
- `src/ui/chat_ui_accumulator_text_support.dart`
- `src/ui/chat_ui_accumulator_tool_support.dart`
- `src/ui/chat_ui_stream_accumulator.dart`

This layer is shared, but it is not a license to move provider-owned rendering
or richer session logic into `llm_dart_core`.

### 5. Serialization Boundary

This layer owns wire-safe codecs for the shared contracts:

- prompt JSON codecs
- chat UI JSON codecs
- text stream event JSON codecs
- shared JSON codec support for metadata, usage, files, sources, warnings, and
  errors
- serialization protocol markers

Representative files:

- `src/serialization/prompt_json_codec.dart`
- `src/serialization/chat_ui_json_codec.dart`
- `src/serialization/text_stream_event_json_codec.dart`
- `src/serialization/serialization_json_support.dart`
- `src/serialization/serialization_protocol.dart`

## Ownership Rules For Other Packages

### Provider Packages

Provider packages should primarily depend on:

- shared foundation
- model specification and capability layer
- raw stream events

They should treat shared UI and serialization exports as optional support
surfaces, not as the default place to put provider-specific projection logic.

### `llm_dart_transport`

`llm_dart_transport` may depend on:

- shared foundation
- raw stream events
- serialization codecs
- shared UI chunks where the HTTP chat protocol requires them

It should not become a second shared runner or session layer.

### `llm_dart_chat`

`llm_dart_chat` is the main consumer of:

- stream events
- shared UI message/chunk types
- serialization for snapshots and transport protocols
- shared runners only when a future chat/runtime feature actually needs them

It remains the runtime/session owner above `llm_dart_core`.

### `llm_dart_flutter`

`llm_dart_flutter` should continue to build on:

- `llm_dart_chat`
- shared UI models from `llm_dart_core`

It should not become a provider-feature host or a transport protocol owner.

## Export Classification

The public `llm_dart_core.dart` barrel is still acceptable, but its exports
should now be understood in these groups:

- foundation contracts
- model specifications and capability helpers
- runner and step orchestration
- stream/UI projection
- serialization codecs

This classification is enough for the current phase without adding more public
entrypoints yet.

## What We Should Not Do Yet

Do not split `llm_dart_core` into new published packages just because the
reference repository has:

- `@ai-sdk/provider`
- `@ai-sdk/provider-utils`
- additional higher-level helper modules

The Dart repository still does not have the package-pressure evidence for that
move.

## Future Split Triggers

A future split out of `llm_dart_core` is justified only if at least one of
these becomes true:

1. external provider packages outside this repository need a narrow stable
   specification package
2. multiple packages need shared provider-implementation helpers but should not
   depend on the whole core barrel
3. UI/serialization and runner/capability changes begin to couple repeatedly in
   a way that the current package cannot isolate internally

## Immediate Consequence

The next package-boundary work should not be another package split.

It should be:

- package-level documentation that explains these ownership groups
- continued discipline about which packages consume UI versus runtime versus
  transport pieces

## Bottom Line

`llm_dart_core` is still the right package boundary for now.

What it needs next is not fragmentation.

What it needs next is an explicit internal map so future changes do not slowly
collapse specification, runtime, UI, and serialization concerns back into one
implicit blob.
