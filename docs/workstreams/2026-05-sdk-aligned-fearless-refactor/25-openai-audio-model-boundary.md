# OpenAI Audio Model Boundary

Date: 2026-05-17

## Reference

This slice continues alignment with the `repo-ref/ai` OpenAI speech and
transcription adapters, especially:

- `repo-ref/ai/packages/openai/src/speech/openai-speech-model.ts`
- `repo-ref/ai/packages/openai/src/speech/openai-speech-model-options.ts`
- `repo-ref/ai/packages/openai/src/transcription/openai-transcription-model.ts`
- `repo-ref/ai/packages/openai/src/transcription/openai-transcription-model-options.ts`

The reference keeps the speech and transcription models as provider-facing
adapters while separating option parsing, request construction, transport
projection, and response decoding. The Dart implementation keeps the
provider-facing audio models stable and moves audio-specific orchestration
behind focused internal modules.

## Problem

`packages/llm_dart_openai/lib/src/openai_speech_model.dart` and
`packages/llm_dart_openai/lib/src/openai_transcription_model.dart` each mixed
multiple independent reasons to change:

- OpenAI-family model settings resolution
- OpenAI provider option resolution
- speech output-format validation and fallback
- speech language warning behavior
- speech speed validation
- speech request body construction
- speech bytes response decoding and media-type inference
- transcription temperature validation
- transcription response-format selection and timestamp compatibility rules
- transcription multipart body construction and filename inference
- transcription response-type projection
- transcription JSON and plain-text response decoding
- transcription language normalization and provider metadata construction

The public provider seams were useful, but the implementations were shallow:
request validation, body construction, transport projection, and response
decoding all required editing the model entrypoints.

## Decision

Keep `OpenAISpeechModel` and `OpenAITranscriptionModel` as the public provider
adapters and split internal orchestration:

- `openai_speech_model_request.dart`
  - settings resolution
  - provider option resolution
  - speed validation
  - output-format fallback and warnings
  - request body construction
- `openai_speech_model_transport.dart`
  - speech route URI resolution
  - default and per-call header merging
  - `TransportRequest` construction
  - timeout, retry, cancellation, and response-type projection
- `openai_speech_model_response.dart`
  - bytes response coercion
  - response media-type inference
  - response metadata construction
- `openai_transcription_model_request.dart`
  - settings resolution
  - provider option resolution
  - temperature validation
  - response-format selection
  - timestamp compatibility validation
  - multipart body construction
  - filename inference
- `openai_transcription_model_transport.dart`
  - transcription route URI resolution
  - default and per-call header merging
  - `TransportRequest` construction
  - accept and response-type projection
- `openai_transcription_model_response.dart`
  - JSON and plain-text response decoding
  - segment and word projection
  - language normalization
  - provider metadata construction
  - response metadata construction
- `openai_speech_model.dart`
  - public constructor and model fields
  - capability profile reporting
  - speech orchestration
- `openai_transcription_model.dart`
  - public constructor and model fields
  - capability profile reporting
  - transcription orchestration

## Behavior Contract

The refactor preserves these contracts:

- `OpenAISpeechModel` constructor, fields, `providerId`, `capabilityProfile`,
  `speechUri`, `defaultHeaders`, and `doGenerate` remain available.
- `OpenAITranscriptionModel` constructor, fields, `providerId`,
  `capabilityProfile`, `transcriptionUri`, `defaultHeaders`, and `doGenerate`
  remain available.
- speech settings and provider option resolution still reject mismatched
  options.
- speech output format still defaults to `mp3`, unsupported output formats
  still fall back with a warning, unsupported language selection still warns,
  and `speed` still validates between `0.25` and `4.0`.
- speech request URI, headers, timeout, max retries, cancellation, response
  type, body, media-type fallback, and byte decoding are unchanged.
- transcription settings and provider option resolution still reject mismatched
  options.
- transcription `temperature` validation and timestamp granularity rules are
  unchanged.
- transcription multipart field order, filename inference, response-format
  selection, accept header mapping, response type mapping, JSON decoding, plain
  text decoding, segment projection, language normalization, and provider
  metadata are unchanged.

## Benefits

Locality improves because speech and transcription request validation, request
body construction, transport projection, and response decoding now change in
separate modules.

Leverage improves because the OpenAI audio adapters remain small provider
entrypoints over deeper request/transport/response seams, which matches the
architecture already used for the image and embedding adapters.
