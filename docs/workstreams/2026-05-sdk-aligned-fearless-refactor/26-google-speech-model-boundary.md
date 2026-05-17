# Google Speech Model Boundary

Date: 2026-05-17

## Reference

This slice continues alignment with the `repo-ref/ai` Google provider adapter
shape, especially:

- `repo-ref/ai/packages/google/src/google-generative-ai-language-model.ts`
- `repo-ref/ai/packages/provider-utils/src/post-to-api.ts`

The reference keeps provider adapters as thin entrypoints over provider option
resolution, request body construction, HTTP dispatch, and response decoding.
Google text-to-speech in Dart uses the Gemini `generateContent` API rather than
a separate Vercel AI SDK speech adapter, so the refactor applies the same
adapter orchestration lesson while preserving the Dart package's provider-owned
speech feature.

## Problem

`packages/llm_dart_google/lib/src/google_speech_model.dart` mixed several
independent reasons to change:

- Google speech settings resolution
- Google speech provider option resolution
- single-speaker versus multi-speaker validation
- `generateContent` request body construction
- speech voice configuration construction
- route URI and header construction
- timeout, retry, cancellation, and response type projection
- JSON response coercion
- inline base64 audio aggregation
- response metadata and Google provider metadata construction

The public speech adapter seam was useful, but the implementation was shallow:
wire request changes, transport projection, and response decoding all required
editing the model entrypoint.

## Decision

Keep `GoogleSpeechModel` as the public provider adapter and split internal
orchestration:

- `google_speech_model_request.dart`
  - settings resolution
  - provider option resolution
  - single-speaker versus multi-speaker validation
  - `generateContent` request body construction
  - speech voice configuration construction
- `google_speech_model_transport.dart`
  - `generateContent` route URI resolution
  - request header merging
  - `TransportRequest` construction
  - timeout, retry, cancellation, and response type projection
- `google_speech_model_response.dart`
  - JSON object coercion
  - candidate validation
  - inline base64 audio aggregation
  - response metadata and Google provider metadata construction
- `google_speech_model.dart`
  - public constructor and model fields
  - capability profile reporting
  - speech generation orchestration

This completes the request/transport/response module shape for the Google
language, embedding, image, and speech adapters while keeping Google-specific
multi-speaker speech options provider-owned.

## Behavior Contract

The refactor preserves these contracts:

- `GoogleSpeechModel` constructor, fields, `providerId`, `capabilityProfile`,
  `generateContentUri`, and `doGenerate` remain available.
- settings and provider option resolution still reject mismatched option types.
- `request.voice` and `GoogleSpeechOptions.speakers` remain mutually
  exclusive.
- multi-speaker `speaker` and `voice` values must remain non-empty when
  multi-speaker mode is used.
- single-speaker generation still falls back to `settings.defaultVoice`.
- request body shape, `responseModalities: ['AUDIO']`, Google generation
  options, and stop sequences are unchanged.
- request URI, headers, timeout, max retries, cancellation, response type, and
  body behavior are unchanged.
- response decoding still requires at least one candidate and at least one
  audio payload.
- inline base64 audio chunks are still concatenated in candidate order.
- media type still falls back to `audio/pcm`.
- response metadata and Google provider metadata keep the same shape.

## Benefits

Locality improves because request validation/body construction, transport
projection, and response decoding now change in separate modules.

Leverage improves because `GoogleSpeechModel` remains a small provider model
entrypoint over deeper Google-specific adapters. The Google package now uses a
consistent adapter orchestration shape for language, embedding, image, and
speech models while keeping provider-native speech controls explicit.
