# 31 Flutter HTTP Backend Integration Example

## Why This Note Exists

The pure-Dart backend-hint example demonstrates the transport boundary well,
but Flutter users still benefit from seeing the same pattern through
`ChatController`.

This slice adds that controller-level example and a matching regression test.

## Scope

This slice adds:

- `packages/llm_dart_flutter/example/flutter_http_backend_integration.dart`
- `packages/llm_dart_flutter/test/http_chat_transport_controller_test.dart`

It also updates the relevant README entrypoints.

## Example Shape

The Flutter example keeps the same ownership model:

1. `ChatController` wraps a `DefaultChatSession`
2. the session uses `HttpChatTransport`
3. `prepareSendMessagesRequest` injects app-owned metadata such as
   `providerProfile`
4. an in-process backend decodes the HTTP transport payload
5. the backend maps metadata into a provider-specific execution plan
6. the backend streams UI chunks back through
   `HttpChatTransportServerAdapter`

The example intentionally stays console-style and `foundation`-only rather than
introducing widgets, so it can focus on transport ownership.

## Test Coverage

The added test verifies that:

- Flutter-side request preparation can inject backend routing hints
- the backend sees those hints in `HttpChatTransportRequestPayload`
- provider-specific execution planning remains backend-owned
- `ChatController` still receives a normal assistant message and final metadata

## Decision Reinforced

This example reinforces the same architecture boundary in a Flutter-specific
entrypoint:

- `ChatController` and `DefaultChatSession` own UI/runtime orchestration
- `HttpChatTransport` owns the generic transport envelope
- provider-specific invocation options remain backend-owned

## Bottom Line

Flutter integration now has a copyable `HttpChatTransport` example and a test
that demonstrates backend-owned provider routing without widening the generic
transport layer.
