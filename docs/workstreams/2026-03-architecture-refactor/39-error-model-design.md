# Error Model Design

## Goal

The repository needs one stable cross-package error envelope for:

- shared stream errors
- Flutter session state
- UI message metadata
- snapshot persistence and restore

Without this, errors drift back into ad hoc `String`, `Map`, and `Exception` payloads that are hard to serialize, inspect, or render consistently.

## Scope

This design applies to the generic error channel only:

- `ErrorEvent.error`
- `ChatState.error`
- `ChatSessionSnapshot.error`
- `ChatUiMetadataKeys.errors`
- `ChatMessageMapper.errors`

It does **not** replace `ToolInputErrorEvent`.

Malformed tool input remains a dedicated event because tool identity, invalid input, and pre-execution failure semantics are already known there.

## Shared Type

The shared error envelope is:

```dart
enum ModelErrorKind {
  unknown,
  provider,
  transport,
  validation,
  stream,
}

final class ModelError {
  final ModelErrorKind kind;
  final String message;
  final String? code;
  final int? statusCode;
  final bool? isRetryable;
  final Object? details;
  final String? originalType;
}
```

## Why This Shape

This shape is intentionally small:

- `kind` gives stable high-level classification
- `message` is always renderable
- `code` keeps provider or transport-specific identifiers
- `statusCode` supports HTTP and gateway diagnostics
- `isRetryable` supports session and retry policy decisions
- `details` preserves structured provider or transport payloads
- `originalType` preserves runtime exception type information when the error started as a local exception

This keeps the Dart surface practical without copying the full class taxonomy from `repo-ref/ai`.

## Mapping Rules

## 1. Provider Error Payloads

Top-level provider error payloads should normalize into:

- `kind: provider`
- `code`: provider `type` or `code` field when available
- `message`: provider `message`
- `details`: the original JSON-safe provider payload

Examples:

- OpenAI failed response chunks
- Anthropic streamed `error` chunks
- future provider-native structured failure payloads

## 2. Transport Failures

Transport exceptions and transport-level error chunks should normalize into:

- `kind: transport`
- stable transport codes such as `transport-http`, `transport-timeout`, or `http-chat-transport-error`
- `statusCode` when the transport has one
- `isRetryable` when retryability is known
- `details` for URI, headers, response body, or backend error payloads

## 3. Validation Failures

Parsing and validation failures that already have explicit local meaning should normalize into:

- `kind: validation`

Examples:

- `FormatException`
- `ArgumentError`

## 4. Stream-State Failures

Local failures caused by invalid stream sequencing or state reconstruction should normalize into:

- `kind: stream`

Examples:

- out-of-sequence projection failures
- invalid replay state reconstruction

## 5. Unknown Runtime Failures

Anything that does not fit a stronger category should normalize into:

- `kind: unknown`

## Serialization Rules

`ModelError` is serialized explicitly as:

```json
{
  "kind": "transport",
  "message": "backend failed",
  "code": "transport_error",
  "statusCode": 503,
  "isRetryable": true,
  "details": { "...": "..." },
  "originalType": "TransportHttpException"
}
```

Rules:

- `details` must stay JSON-safe
- decoders must remain backward compatible with legacy raw string or map error payloads
- old snapshot or event payloads should be normalized during decode instead of rejected immediately

## Flutter Boundary

Flutter-facing state should expose typed errors directly:

- `ChatState.error` is `ModelError?`
- `ChatSessionSnapshot.error` is `ModelError?`
- `ChatUiMetadataKeys.errors` stores `List<ModelError>`
- `ChatMessageMapper.errors` returns `List<ModelError>`

This gives Flutter applications a stable render surface without forcing them to parse raw provider maps at widget level.

## Non-Goals

This design does not:

- add a large hierarchy of provider-specific error subclasses to `llm_dart_core`
- replace `ToolInputErrorEvent`
- force `generate()` and non-streaming provider calls to stop throwing exceptions immediately

The current phase only stabilizes the shared error envelope that already crosses stream, UI, and snapshot boundaries.
