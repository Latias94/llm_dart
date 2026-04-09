# 143. Root Cancellation Dio Decoupling

## Question

Can the root compatibility-facing cancellation helper keep its old user-facing
 behavior while dropping a direct root-layer `dio` import?

## What Was Reviewed

- `lib/core/cancellation.dart`
- `packages/llm_dart_transport/lib/src/http/dio_cancellation_adapter.dart`
- `test/core/cancellation_test.dart`
- `packages/llm_dart_transport/test/dio_cancellation_adapter_test.dart`

## Change

Yes.

The raw Dio cancellation inspection now lives in the transport package:

- `isDioCancellationError(...)`
- `getDioCancellationReason(...)`

The root `CancellationHelper` keeps the same user-facing behavior:

- it still recognizes `CancelledError`
- it still recognizes `TransportCancelledException`
- it still tolerates raw Dio cancellation exceptions that leak through

But it no longer imports `dio` directly.

## Why This Matters

This is a small slice, but it is exactly the kind of dependency cleanup that
the architecture needs:

- transport-specific error inspection belongs in the transport layer
- the root compatibility-facing helper should consume that lower-layer helper,
  not own the transport-library knowledge itself
- root `dio` removal will still require larger compatibility/provider moves,
  but this shrinks one more direct root coupling point now

## Scope Boundary

This does **not** remove the root package's runtime dependency on `dio` yet.

It only removes one direct root implementation seam:

- raw Dio cancellation detection inside `lib/core/cancellation.dart`

The broader root dependency exit still depends on moving more transport-heavy
compatibility/provider code out of the root package.
