# UI Transport Transient Data Boundary

## Goal

This document freezes the boundary after comparing our chat runtime with the
`repo-ref/ai` UI message stream design and records the current implementation:

> The worthwhile adoption was not a new `TextStreamEvent` family.
> It was an explicit transport/session path for transient `data-*` updates that
> reach the UI without becoming persisted message state, and that path is now
> implemented in the current breaking round.

## 1. Current `llm_dart` Status

The current runtime already has a stable persisted UI-data path:

- `DataUiPart<T>` is part of `ChatUiMessage.parts`
- `ChatUiAccumulator` upserts persisted data parts by `key` plus optional `id`
- `ChatSession.addDataPart(...)` supports local UI-only data ingress
- `HttpChatTransport` serializes `data-part` chunks and replays them during
  reconnect recovery
- snapshots keep data parts, prompt history does not

This is a good baseline for replayable UI state such as:

- progress cards that should remain visible in the assistant message
- retrieved side panels that should survive reconnect
- persistent structured assistant-side annotations

## 2. What `repo-ref/ai` Adds On Top

The reference UI stream also supports transient `data-*` chunks:

- they are delivered to the UI stream consumer
- they can trigger `onData`-style callbacks immediately
- they do not become durable message state
- they do not need to be replayed as part of the final assistant message

That distinction is useful for chat applications that want short-lived UI
signals such as:

- tool execution heartbeats
- upload progress pulses
- temporary search-status banners
- optimistic local hints
- ephemeral moderation or policy notices

## 3. Gap Assessment

This is **not** a shared model-stream gap.

It is also **not** a gap in the persisted `ChatUiMessage` data model.

The actual gap is narrower:

- `llm_dart` already had persisted UI data parts
- `llm_dart` now also has an explicit non-persistent transient UI-data channel
  above `ChatUiMessage`

That means the remaining worthwhile adoption target belongs to:

- `ChatUiStreamChunk`
- `ChatSession` / `ChatController`
- `HttpChatTransport` v2 chunk serialization

It does **not** belong to:

- `TextStreamEvent`
- `GenerateTextResult`
- prompt history
- persisted `ChatUiMessage.parts`

## 4. Recommended Boundary

### 1. Keep `DataUiPart<T>` Persisted

`DataUiPart<T>` should remain the durable message-state representation.

Do not add a `transient` flag directly to `DataUiPart<T>`, because that would
mix two different meanings into one type:

- persisted message content
- non-persistent runtime notifications

That ambiguity would make snapshot, reconnect, and serializer behavior much
harder to reason about.

### 2. Add Transient Delivery At The Chunk Layer

If the runtime adopts this feature, it should land as one of:

- a dedicated transient UI-data chunk above `ChatUiMessage`
- or a `transient` flag on the transport/session chunk representation, not on
  the persisted part model

The essential rule is:

- transient UI data is delivered through the stream
- persisted UI data is stored in the message

### 3. Transient Data Must Not Pollute Replay By Default

If transient UI data is introduced, the default rules should be:

- do not append it into `ChatUiMessage.parts`
- do not store it in `ChatSessionSnapshot`
- do not replay it on reconnect by default
- do not convert it into prompt history

If an app wants durability, it should send a normal persisted `DataUiPart<T>`
instead.

### 4. The UI Needs A First-Class Delivery Hook

Transient data is only useful if application code can observe it directly.

`llm_dart_chat` now provides an explicit delivery path through:

- `ChatSession.transientDataParts`
- `ChatController.transientDataParts`

The shared runtime still does not force Flutter-specific widget patterns, and
the delivery hook remains framework-neutral.

## 5. Recommended Implementation Order

The breaking-round implementation followed this order:

1. freeze the chunk shape and wire semantics
2. add a framework-neutral transient-data delivery hook in `llm_dart_chat`
3. extend the HTTP v2 chunk codec without changing `TextStreamEvent`
4. verify that reconnect replay excludes transient data by default
5. add session, transport, and projection tests for persistent vs transient
   data

## 6. Current Implementation Summary

The implemented transient path now works as follows:

- `ChatUiTransientDataPartChunk<T>` carries non-persistent UI data above
  `ChatUiMessage`
- `ChatUiStreamAccumulator` ignores transient chunks for persisted message
  projection
- `DefaultChatSession` forwards transient data through
  `transientDataParts` without storing it in session snapshots or prompt
  history
- HTTP `ui-message-stream-v2` can encode `transient-data-part` chunks
- reconnect replay still excludes transient data by default

## 7. Non-Goals

The following should remain out of scope:

- adding `DataEvent` to `TextStreamEvent`
- adding more model-stream event types just to mirror UI chunk names
- storing transient data inside prompt history
- widening `ChatUiMessage.parts` with a mixed persistent/transient contract
- copying the full `repo-ref/ai` client callback surface into Dart

## 8. Conclusion

The event model itself is now mature enough.

The remaining worthwhile gap versus `repo-ref/ai` is a transport/session
ergonomics gap:

- persisted UI data is already covered
- transient UI data is now implemented as the narrow transport/session
  improvement
- that improvement should stay above `TextStreamEvent`
- that improvement should stay outside persisted `ChatUiMessage` state by
  default
