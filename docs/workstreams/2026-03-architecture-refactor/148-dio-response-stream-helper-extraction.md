# 148. Dio Response Stream Helper Extraction

## Goal

Reduce repeated streaming-response plumbing in root compatibility/provider
clients by moving the common Dio response-body extraction and UTF-8 text-stream
decoding logic into `llm_dart_transport`.

## Problem

Before this slice, multiple root clients repeated the same flow:

1. inspect Dio `response.data`
2. accept either `ResponseBody` or `Stream<List<int>>`
3. reject any other runtime type
4. run a `Utf8StreamDecoder` loop manually
5. flush trailing buffered bytes

That code was repeated across:

- root OpenAI compatibility client
- root Anthropic compatibility client
- root Google compatibility client
- residual root-local DeepSeek / Groq / xAI / Ollama clients

The duplication was transport plumbing, not provider-owned business logic.

## Decision

Move this logic into transport-owned helpers:

- `extractDioResponseByteStream(...)`
- `decodeDioResponseTextStream(...)`

Provider clients can still choose their own invalid-body error type through a
small factory callback, so this extraction does not force a new shared
root-facing error contract.

## What Changed

### Transport package

Added:

- `packages/llm_dart_transport/lib/src/http/dio_response_stream.dart`

Exported through:

- `packages/llm_dart_transport/lib/llm_dart_transport.dart`

Also adopted inside:

- `packages/llm_dart_transport/lib/src/http/dio_transport_client.dart`

### Root clients

The following clients now use the shared helper instead of duplicating the
byte-stream discrimination and UTF-8 decode loop:

- `lib/src/compatibility/providers/openai/client.dart`
- `lib/src/compatibility/providers/anthropic/client.dart`
- `lib/src/compatibility/providers/google/client.dart`
- `lib/providers/deepseek/client.dart`
- `lib/providers/groq/client.dart`
- `lib/providers/xai/client.dart`
- `lib/providers/ollama/client.dart`

## Why This Boundary Is Better

This is a better ownership split because:

- `ResponseBody` vs `Stream<List<int>>` handling is transport-level plumbing
- UTF-8 chunk rebuilding is transport-level plumbing
- provider clients should focus on request shaping, provider errors, and event
  projection
- `DioTransportClient` and provider clients now share the same response-body
  extraction logic instead of drifting separately

## Error-Boundary Note

The helper intentionally accepts an optional invalid-body error factory.

That keeps the layering honest:

- transport owns body extraction and text decoding
- callers still decide whether an invalid body should surface as
  `GenericError`, plain `Exception`, or the transport default

So this extraction reduces duplication without pretending all callers already
share one exact higher-level error policy.

## Validation

Validated with:

- `dart analyze`
- `dart analyze packages/llm_dart_transport`
- `dart test packages/llm_dart_transport/test`
- `dart test test/providers/openai/openai_provider_bridge_test.dart`
- `dart test test/providers/openai/openai_entrypoint_test.dart`
- `dart test test/legacy_compatibility_test.dart`
- `dart test test/providers/ollama/ollama_provider_bridge_test.dart test/providers/elevenlabs/elevenlabs_provider_bridge_test.dart test/core/cancellation_test.dart`
