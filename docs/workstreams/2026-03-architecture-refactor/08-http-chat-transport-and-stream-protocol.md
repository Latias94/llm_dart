# HTTP Chat Transport And Stream Protocol

## Goal

`llm_dart_flutter` now has a stable direct-model path:

- `ChatSession`
- `ChatTransport`
- `ChatUiAccumulator`
- `TextStreamEvent`

The remaining gap is the remote-backend path.

The goal of this document is to define a versioned HTTP transport contract that:

- works for Flutter chat applications
- supports persistence and reconnect
- does not force provider details into the Flutter API
- does not pollute `TextStreamEvent` with transport-only protocol concerns

## 1. Core Boundary

There are now three different layers that must stay separate:

1. model invocation
2. chat-session transport
3. UI projection

That means:

- `GenerateTextRequest` and `CallOptions` belong to model invocation
- `HttpChatTransport` belongs to the chat-session transport layer
- `ChatUiAccumulator` belongs to UI projection

The most important consequence is:

- `HttpChatTransport` must not simply serialize `GenerateTextRequest` as-is
- `TextStreamEvent` must not become the wire protocol for every chat-transport concern

## 2. Why `CallOptions` Must Not Be Serialized Directly

`CallOptions` is the right abstraction for local model invocation, but it is not the right abstraction for a generic remote chat protocol.

Reasons:

- `CallOptions.providerOptions` is typed runtime data, not a guaranteed JSON-safe transport payload
- `CallOptions.headers` means request headers for the provider call, which is not the same thing as headers for the app backend request
- `CallOptions.timeout` means model invocation timing policy, which may be server-owned rather than client-owned

Therefore:

- direct transport should keep using `GenerateTextOptions` + `CallOptions`
- HTTP transport should define its own JSON-safe request envelope
- if remote provider-specific tuning is supported later, it should use a separate JSON-safe transport field, not direct serialization of typed `ProviderInvocationOptions`

## 3. Recommended Request Envelope

The HTTP request body should be an explicit versioned artifact.

Recommended top-level shape:

```json
{
  "schemaVersion": "2026-03-1",
  "kind": "chat-transport-request",
  "data": {
    "chatId": "chat-123",
    "prompt": {
      "schemaVersion": "2026-03-1",
      "kind": "prompt-history",
      "data": { "...": "..." }
    },
    "generateOptions": {
      "maxOutputTokens": 512,
      "temperature": 0.2,
      "topP": 0.95,
      "topK": 40,
      "stopSequences": ["DONE"]
    },
    "metadata": {
      "clientRequestId": "req-123"
    }
  }
}
```

Rules:

- `prompt` should reuse the prompt-history artifact produced by `PromptJsonCodec`
- `generateOptions` should contain only JSON-safe capability settings
- backend request headers for auth, tracing, locale, or tenancy should stay in actual HTTP headers
- backend-specific extra request payload should stay under a JSON-safe `metadata` or future transport-specific extension field

Phase-1 recommendation:

- do not put generic provider-specific remote options into the first HTTP transport contract
- keep the first generic request envelope provider-neutral
- if an application needs provider-specific remote tuning immediately, let the backend own that contract explicitly instead of pretending the generic transport already solved it

For reconnect, define a second envelope instead of overloading the original request:

```json
{
  "schemaVersion": "2026-03-1",
  "kind": "http-chat-transport-reconnect-request",
  "data": {
    "chatId": "chat-123",
    "resumeToken": "opaque-resume-token"
  }
}
```

Rules:

- reconnect requests should stay transport-specific
- reconnect requests should not repeat prompt history
- the server remains responsible for validating whether the token still maps to an in-flight stream

## 4. Recommended Stream Chunk Envelope

The streaming response should also use a versioned envelope.

Recommended top-level chunk shape:

```json
{
  "schemaVersion": "2026-03-1",
  "kind": "chat-transport-chunk",
  "data": {
    "type": "event",
    "event": { "...": "..." }
  }
}
```

Recommended chunk types:

- `start`
- `event`
- `data-part`
- `checkpoint`
- `finish`
- `abort`
- `error`
- `keepalive`

### `start`

Used for transport-level session metadata.

Recommended fields:

- `requestId`
- `messageId`
- `resumeToken` optional

This is transport state, not model output.

### `event`

Carries one serialized `TextStreamEvent`.

Rules:

- this is one of the two chunk types that should normally be forwarded into `DefaultChatSession`
- the serialized event should represent core stream semantics only
- a future `TextStreamEventJsonCodec` should own this mapping explicitly

### `data-part`

Carries one serialized `DataUiPart<Object?>`.

Rules:

- this is the UI-only companion to `event`, not a new `TextStreamEvent`
- `DefaultChatSession` should merge it into the current assistant message
- `DataUiPart.id` should enable stable upsert by `key + id`
- when `id` is missing, the data part should remain append-only
- data parts must never be written into prompt history

### `checkpoint`

Used for reconnect support.

Recommended fields:

- opaque `resumeToken`
- optional `cursor`

Rules:

- `HttpChatTransport` should store the latest checkpoint internally per active chat
- `DefaultChatSession` does not need to see checkpoint chunks directly

### `finish`

Signals that the transport stream itself is complete.

Rules:

- it does not replace `FinishEvent`
- the backend should still emit a terminal `FinishEvent` inside an `event` chunk for model completion semantics
- the transport `finish` chunk only says the wire stream is closed cleanly

### `abort`

Signals that the backend intentionally aborted the active stream.

Rules:

- the transport may convert this into a local terminal failure or a synthetic aborted finish path
- this should remain a transport concern first, not a new required core event

### `error`

Used when the stream fails before a valid terminal model event can be delivered.

Recommended fields:

- `code`
- `message`
- optional JSON-safe `details`

Mapping rule:

- `HttpChatTransport` should surface this as an `ErrorEvent` to the session layer

### `keepalive`

Used only to keep the HTTP stream active.

Rules:

- should be ignored by session and UI layers

## 5. Why We Should Not Copy the Full UI Chunk Protocol Into Core

The Vercel AI SDK UI chunk protocol is useful as a reference, but we should not promote its whole chunk vocabulary into `TextStreamEvent`.

Reasons:

- `llm_dart_core` already has a reusable `TextStreamEvent -> ChatUiMessage` projection layer
- direct transport and HTTP transport should share the same session and projection logic
- message-start, message-finish, metadata-patch, abort, and reconnect markers are transport concerns, not stable cross-provider model semantics
- copying the UI chunk set into core would make direct-mode and HTTP-mode boundaries less clear again

Recommended rule:

- keep `TextStreamEvent` focused on model stream semantics
- let `HttpChatTransport` consume extra transport chunks internally
- add new core events only when they represent real cross-provider model behavior

## 6. Reconnect Model

Recommended reconnect flow:

1. the original stream emits `checkpoint` chunks with an opaque `resumeToken`
2. `HttpChatTransport` stores the latest token for the active `chatId`
3. `reconnect(chatId)` sends a reconnect request carrying that token
4. the backend either:
   - resumes the active stream, or
   - reports that no active stream exists and returns `null`

Phase-1 recommendation:

- reconnect should resume only in-flight streams
- `HttpChatTransport` should keep a local replay buffer for already delivered `ChatTransportChunk` items from the current assistant turn
- `DefaultChatSession.resume()` should remove the partial assistant UI message and rebuild that assistant turn from replay plus the resumed tail
- do not make reconnect responsible for replaying the entire chat history
- full history replay still belongs to snapshot persistence and history loading

Why the replay buffer is necessary:

- `ChatUiAccumulator` intentionally hydrates tool indexes from a seed UI message, but it does not restore active text or reasoning stream IDs
- resuming directly from a partially rendered UI message would therefore fail if the resumed stream starts with `text-delta` or `reasoning-delta`
- replaying the current assistant turn keeps reconnect transport-local without expanding `TextStreamEvent`

## 7. Implementation Direction

The phase-1 implementation should follow this order:

1. define a `TextStreamEventJsonCodec`
2. define `HttpChatTransport` request and chunk codecs
3. implement SSE or NDJSON decoding in `HttpChatTransport`
4. keep checkpoint, keepalive, start, and finish chunks transport-internal
5. store the latest resume token and current assistant-turn replay buffer inside `HttpChatTransport`
6. let `reconnect(chatId)` replay buffered `ChatTransportChunk` items before forwarding the resumed tail
7. let `DefaultChatSession.resume()` rebuild the assistant turn from replay instead of trying to continue from a partial UI snapshot

## 8. Deferred Question

The main unresolved question is whether the generic HTTP transport should later expose provider-specific remote options.

Current recommendation:

- not in phase 1
- if needed later, use a separate JSON-safe namespaced transport field
- do not serialize typed `ProviderInvocationOptions` across the HTTP boundary directly

## Conclusions

- `CallOptions` is frozen for local model invocation, not for remote transport serialization
- `HttpChatTransport` needs a separate versioned request and chunk protocol
- `TextStreamEvent` should remain the common runtime stream model
- reconnect should be implemented through transport checkpoints plus transport-local current-turn replay, not by expanding the core event model
