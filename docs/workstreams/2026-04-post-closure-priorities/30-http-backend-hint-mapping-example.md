# 30 HTTP Backend Hint Mapping Example

## Why This Note Exists

The previous slice froze an important boundary:

- `HttpChatTransport` should stay generic
- typed provider invocation options should stay direct-transport or
  backend-owned concerns

That decision needed one concrete example so Flutter and chat-app users can
copy the pattern without widening the transport envelope.

## Scope

This slice adds a runnable, API-key-free example:

- `packages/llm_dart_chat/example/http_backend_hint_mapping.dart`

It also updates the package and example READMEs that point users toward
chat-runtime and Flutter integration patterns.

## Example Shape

The example is intentionally pure Dart and in-process:

1. the client creates a `DefaultChatSession`
2. the session uses `HttpChatTransport`
3. `prepareSendMessagesRequest` adds app-owned JSON metadata such as
   `providerProfile`
4. an in-process backend decodes `HttpChatTransportRequestPayload`
5. the backend maps metadata to a provider-specific execution plan
6. the backend streams response chunks through `HttpChatTransportServerAdapter`

The backend does not call a real provider. Instead, it prints the mapped plan
and echoes the plan through message metadata and data parts.

That keeps the example deterministic while documenting the intended ownership
boundary.

## Decision Reinforced

The example reinforces that:

- shared `GenerateTextOptions` can travel through the HTTP envelope
- app-owned JSON metadata can travel through the HTTP envelope
- typed provider options should not be serialized directly by the generic
  transport
- backend code should translate app hints into concrete provider options

## Why This Is Useful For Flutter

Flutter apps frequently need a backend for:

- API key protection
- audit logging
- compliance
- provider routing
- request policy enforcement

This example shows how Flutter can still use the same `ChatSession`,
`ChatController`, and `HttpChatTransport` runtime stack without pushing provider
wire details into the mobile client.

## Acceptance Criteria

This slice is complete when:

- the example runs without provider credentials
- the example demonstrates `prepareSendMessagesRequest`
- the backend decodes `HttpChatTransportRequestPayload`
- the backend emits SSE frames through `HttpChatTransportServerAdapter`
- public docs point to the example from both chat-runtime and use-case guides

## Bottom Line

This is a practical companion to the transport-boundary decision.

It gives users a copyable pattern for backend-owned provider-specific behavior
without turning `HttpChatTransport` into a provider-specific options bus.
