# llm_dart_transport

Shared transport abstractions, HTTP chat protocol types, and Dio-based
transport helpers for `llm_dart`.

## What This Package Owns

This package owns transport-level concerns that should not live in providers,
chat runtime code, or Flutter adapters:

- transport request/response abstractions
- transport exceptions and diagnostics
- retry helpers for transport operations
- Dio client configuration and factory helpers
- SSE and UTF-8 decoding utilities
- JSON object response decoding and log sanitization
- `HttpChatTransport` protocol payload/chunk codecs and the server adapter

## Dependencies

This package depends on:

- `llm_dart_core`
- `dio`
- `logging`

That dependency direction is intentional:

- shared contracts stay in `llm_dart_core`
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
- building an HTTP/SSE transport boundary for server or client apps
- encoding or decoding `HttpChatTransport` requests and streamed chunks
- writing transport-level diagnostics or retry helpers

If you only need the chat/session layer, start with `llm_dart_chat` instead of
this package directly.
