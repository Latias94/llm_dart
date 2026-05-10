# llm_dart_transport

Shared transport abstractions and Dio-based transport helpers for `llm_dart`.

## What This Package Owns

This package owns transport-level concerns that should not live in providers,
chat runtime code, or Flutter adapters:

- transport request/response abstractions
- transport exceptions and diagnostics
- retry helpers for transport operations
- request middleware for custom fetch-style hooks
- Dio client configuration and factory helpers
- SSE and UTF-8 decoding utilities
- JSON object response decoding and log sanitization
- small HTTP body utilities such as multipart/form-data encoding

## Dependencies

This package depends on:

- `llm_dart_provider`
- `dio`
- `logging`

That dependency direction is intentional:

- shared contracts stay in `llm_dart_provider`
- transport implementations build on those contracts
- higher layers such as `llm_dart_chat` depend on transport, not the other way
  around

## What This Package Does Not Own

This package does not own:

- provider-specific request shaping or feature policy
- chat/session state
- Flutter controller/widget logic
- provider-specific custom parts or message mappers

Use:

- provider packages for provider-native behavior
- `llm_dart_chat` for session/runtime orchestration
- `llm_dart_flutter` for Flutter adapter behavior

## Typical Consumers

Use `llm_dart_transport` when you are:

- implementing a provider client on top of Dio
- building multipart upload requests for provider-owned file or audio
  endpoints
- building an HTTP/SSE boundary below provider or runtime code
- writing transport-level diagnostics, retry helpers, or request middleware

## Platform Notes

The main `package:llm_dart_transport/llm_dart_transport.dart` entrypoint is
intended to stay Flutter Web-safe. IO-specific Dio adapter setup is selected
through conditional imports, and browser builds use the web adapter path.

Advanced HTTP options such as proxy configuration, custom certificates, and
SSL verification bypass are only available on `dart:io` platforms. On Web,
those options are reported as unsupported because the browser owns that network
stack.

Use `package:llm_dart_transport/dio_io.dart` only from IO-only code. It exports
`package:dio/io.dart` directly and must not be imported by Flutter Web targets.

## Request Hooks, Retry, And Diagnostics

`DioTransportClient` accepts an injected `Dio`, optional diagnostics, and a
transport retry policy. A single request can override retry count with
`TransportRequest.maxRetries`; provider calls expose the same idea through
`CallOptions.maxRetries`.

Use `MiddlewareTransportClient` when you want a provider-agnostic equivalent of
a custom `fetch`: add headers, rewrite requests, observe responses, or map
errors without depending on Dio interceptors.

```dart
final events = <TransportDiagnosticsEvent>[];

final transport = MiddlewareTransportClient(
  inner: DioTransportClient(
    dio: myDio,
    diagnostics: CallbackTransportDiagnostics(events.add),
    diagnosticsOptions: const TransportDiagnosticsOptions(
      includeHeaders: true,
    ),
  ),
  middlewares: [
    TransportMiddleware(
      onRequest: (request) => request.copyWith(
        headers: {
          ...request.headers,
          'x-client-trace-id': 'trace-1',
        },
      ),
    ),
  ],
);
```

If you only need the chat/session layer, start with `llm_dart_chat` instead of
this package directly.
