# 154 Shared postTextStream Helper

## Why

After the recent compatibility HTTP cleanup, several root-hosted provider
clients still repeated the same streaming request shell:

- `dio.post(...)` with `ResponseType.stream`,
- bind `TransportCancellation`,
- validate the success status,
- decode the response body into UTF-8 text chunks,
- catch `DioException` and map provider errors.

This pattern still existed in multiple root clients such as:

- DeepSeek
- Groq
- xAI
- Ollama

The mechanics were shared even though provider semantics still differed.

## Decision

Add a shared `HttpResponseHandler.postTextStream(...)` helper for the mechanics
only, while keeping provider semantics injectable through parameters.

The helper owns:

- POST stream request dispatch,
- request/payload logging,
- shared success-status validation,
- UTF-8 text-stream decoding,
- default or provider-specific Dio exception mapping.

It does not own:

- provider request shaping,
- provider-native stream parsing,
- provider-specific follow-up semantics after chunk decoding.

## What Changed

- Added `HttpResponseHandler.postTextStream(...)`.
- Migrated these root-hosted provider clients to the shared helper:
  - `DeepSeekClient`
  - `GroqClient`
  - `XAIClient`
  - `OllamaClient`
- While migrating Ollama, also removed its duplicated root-local JSON parsing by
  reusing the shared `HttpResponseHandler.parseJsonResponse(...)`.

## Architectural Effect

This further tightens the root compatibility shell around explicit helper
composition:

- shared HTTP mechanics live in one helper,
- provider-specific error semantics remain injectable,
- provider clients keep ownership of their own API-level meanings.

This is closer to the `repo-ref/ai` layering lesson we want:

- composition over root superclass inheritance,
- smaller helper seams,
- fewer provider-local copies of the same HTTP plumbing.
