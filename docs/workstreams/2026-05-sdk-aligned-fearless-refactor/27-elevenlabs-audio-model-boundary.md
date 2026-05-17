# ElevenLabs Audio Model Boundary

Date: 2026-05-17

## Reference

This slice continues alignment with the mature provider adapter shape from
`repo-ref/ai`, especially:

- `repo-ref/ai/packages/provider-utils/src/post-to-api.ts`
- `repo-ref/ai/packages/openai/src/openai-speech-model.ts`
- `repo-ref/ai/packages/openai/src/openai-transcription-model.ts`

The reference keeps provider model adapters thin over provider option
resolution, request body construction, HTTP dispatch, and response decoding.
ElevenLabs is provider-native in this Dart library rather than a direct
reference adapter in the Vercel AI SDK, so the refactor applies the same module
shape while preserving ElevenLabs-specific speech and transcription features.

## Problem

`packages/llm_dart_elevenlabs/lib/src/elevenlabs_speech_model.dart` mixed
several independent reasons to change:

- speech settings resolution
- speech provider option resolution
- speech option validation
- voice ID fallback
- output-format normalization
- JSON request body construction
- text-to-speech URI and header construction
- timeout, retry, cancellation, and response type projection
- bytes response decoding
- media-type fallback
- response metadata and ElevenLabs provider metadata construction

`packages/llm_dart_elevenlabs/lib/src/elevenlabs_transcription_model.dart`
had the same problem for transcription:

- transcription settings resolution
- transcription provider option resolution
- num-speaker validation
- multipart field construction
- speech-to-text URI and header construction
- timeout, retry, cancellation, and response type projection
- JSON response coercion
- word segment projection
- body metadata and response-header metadata merging

The public adapters were useful seams, but their implementations were shallow:
request, transport, and response changes all required editing the model
entrypoints.

## Decision

Keep `ElevenLabsSpeechModel` and `ElevenLabsTranscriptionModel` as the public
provider adapters and split internal orchestration:

- `elevenlabs_speech_model_request.dart`
  - settings resolution
  - provider option resolution
  - speech option validation
  - voice ID fallback
  - output-format normalization
  - JSON request body construction
- `elevenlabs_speech_model_transport.dart`
  - default header construction
  - text-to-speech URI construction
  - speech `TransportRequest` construction
  - timeout, retry, cancellation, and response type projection
- `elevenlabs_speech_model_response.dart`
  - bytes response coercion
  - media-type fallback
  - response metadata and provider metadata construction
- `elevenlabs_transcription_model_request.dart`
  - settings resolution
  - provider option resolution
  - transcription option validation
  - multipart body construction
- `elevenlabs_transcription_model_transport.dart`
  - default header construction
  - speech-to-text URI construction
  - transcription `TransportRequest` construction
  - timeout, retry, cancellation, and response type projection
- `elevenlabs_transcription_model_response.dart`
  - JSON response coercion
  - text validation
  - word segment projection
  - response metadata and provider metadata construction
- `elevenlabs_speech_model.dart` and
  `elevenlabs_transcription_model.dart`
  - public constructor and model fields
  - capability profile reporting
  - model orchestration

This brings ElevenLabs audio adapters into the same internal shape as the
OpenAI, Google, Anthropic, Ollama, and Google image/speech adapter splits.

## Behavior Contract

The refactor preserves these contracts:

- `ElevenLabsSpeechModel` constructor, fields, `providerId`,
  `capabilityProfile`, `defaultHeaders`, and `doGenerate` remain available.
- `ElevenLabsTranscriptionModel` constructor, fields, `providerId`,
  `capabilityProfile`, `defaultHeaders`, and `doGenerate` remain available.
- settings and provider option resolution still reject mismatched option types.
- speech ratio, seed, request ID, and pronunciation dictionary validations are
  unchanged.
- speech request voice fallback still prefers request voice, then configured
  default voice ID, then the package default voice ID.
- speech output-format aliases, query parameters, JSON body shape, headers,
  timeout, max retries, cancellation, and bytes response type are unchanged.
- speech bytes decoding still accepts `Uint8List`, `List<int>`, and integer
  lists, rejects invalid byte lists, and requires non-empty audio.
- speech media type still prefers response `content-type` and falls back from
  normalized output format.
- transcription num-speaker validation is unchanged.
- transcription multipart field order, filename inference, media type fallback,
  query parameters, headers, timeout, max retries, cancellation, and JSON
  response type are unchanged.
- transcription response decoding still requires non-empty text, projects word
  segments, infers duration from the final segment, and merges header metadata
  with body metadata.

## Benefits

Locality improves because ElevenLabs request validation/body construction,
transport projection, and response decoding now change in separate modules.

Leverage improves because both ElevenLabs public adapters remain small
provider model entrypoints over deeper provider-native audio modules. The
package keeps its typed options and voice catalog surface without forcing
ElevenLabs-specific behavior into shared audio contracts.
