# Backend Reference Adapter And Protocol Ownership

## Goal

The HTTP chat transport protocol must be reusable from both sides of the wire:

- Flutter clients consume it through `HttpChatTransport`
- Dart backends may want to emit the same protocol directly

The reference point from `repo-ref/ai` is useful here:

- keep JSON-to-SSE encoding as a thin transport helper
- keep higher-level runtime chunk projection separate from raw SSE framing

The Dart design must keep that benefit without forcing a Dart backend to depend
on Flutter.

## Problem

The first implementation placed the HTTP chat transport request/chunk protocol in
`llm_dart_flutter`, because that was where the client transport lived.

That was acceptable for the client-side implementation, but it created the wrong
ownership for backend reuse:

- a Dart backend encoder in `llm_dart_flutter` would force server code to depend
  on the Flutter SDK
- that violates the frozen dependency direction:
  `llm_dart_core <- llm_dart_transport <- provider packages <- facade / flutter`
- it also blurs the boundary between:
  - Flutter session/client concerns
  - pure transport protocol concerns

## Decision

The ownership is now frozen as follows:

- `llm_dart_transport` owns the HTTP chat transport wire protocol:
  - `HttpChatTransportStreamProtocol`
  - request/reconnect payloads
  - wire chunk types
  - request/chunk JSON codecs
- `llm_dart_transport` also owns the Dart backend reference helpers:
  - `HttpChatTransportSseEncoder`
  - `HttpChatTransportServerAdapter`
- `llm_dart_chat` keeps:
  - `HttpChatTransport`
  - session/runtime consumption of `ChatUiStreamChunk`
  - compatibility re-exports of the protocol types for existing client/runtime
    imports
- `llm_dart_flutter` keeps:
  - transitive Flutter-facing re-exports
  - adapter-layer conveniences above the shared runtime

This means the protocol is now transport-owned, while the shared chat runtime
stays pure Dart and Flutter remains strictly the adapter layer.

## Implemented Surface

### `HttpChatTransportSseEncoder`

Low-level SSE helper:

- encodes a JSON object as `data: ...\n\n`
- encodes a transport chunk through `HttpChatTransportChunkJsonCodec`
- optionally appends `data: [DONE]\n\n`

This is the Dart equivalent of the thin JSON-to-SSE layer in `repo-ref/ai`,
without importing UI/session concerns into the encoder itself.

### `HttpChatTransportServerAdapter`

Reference backend helper above the raw encoder:

- `wrapEventStream(...)`
  - converts `Stream<TextStreamEvent>` into runtime `ChatUiStreamChunk`
- `encodeUiChunkStream(...)`
  - converts runtime `ChatUiStreamChunk` into HTTP wire chunks
- `encodeEventStream(...)`
  - convenience bridge from `TextStreamEvent` to wire chunks
- `encodeUiSseStream(...)`
  - runtime chunks directly to SSE bytes
- `encodeEventSseStream(...)`
  - text stream events directly to SSE bytes

## Mapping Rules

### 1. Model Events Stay Model Events

`TextStreamEvent` remains model semantics.

That means:

- `TextStartEvent`, `TextDeltaEvent`, `ToolCallEvent`, `FinishEvent`,
  `AbortEvent`, and others are encoded as `event` chunks
- transport-native `abort`, `error`, `checkpoint`, and `keepalive` remain
  low-level `HttpChatTransportChunk` concepts

The reference adapter does **not** silently remap model `AbortEvent` into the
transport `abort` chunk type.

If a backend wants transport-native abort/error/checkpoint behavior, it should
emit low-level transport chunks explicitly.

### 2. Runtime Chunks Stay Separate From Wire Chunks

The stable layering remains:

1. `TextStreamEvent`
2. `ChatUiStreamChunk`
3. `HttpChatTransportChunk`
4. SSE bytes

This keeps the runtime/session projection model independent from HTTP wire
details such as resume tokens and keepalive frames.

### 3. v2 Mapping

For `ui-message-stream-v2`, the adapter emits:

- optional `transport-start`
- `message-start`
- `message-metadata`
- `event`
- `data-part`
- `message-finish`
- terminal `finish`

Special rule:

- if a runtime `message-start` has metadata but no message ID, it degrades to
  `message-metadata` in v2 instead of inventing a synthetic ID

### 4. v1 Downgrade

For legacy `event-stream-v1`, the adapter intentionally collapses or drops
v2-only semantics:

- `message-start` collapses into legacy `start`
- `message-metadata` has no dedicated v1 representation and is dropped
- `message-finish` has no dedicated v1 representation and is dropped
- `event`, `data-part`, and terminal `finish` remain

This downgrade is intentionally lossy.

That is acceptable because v1 is now a compatibility protocol, not the primary
stream contract.

## Example

```dart
import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_transport/llm_dart_transport.dart';

Future<Stream<List<int>>> buildChatResponse(LanguageModel model) async {
  final adapter = HttpChatTransportServerAdapter();

  final eventStream = model.stream(
    GenerateTextRequest(
      prompt: [
        UserPromptMessage.text('Summarize the release notes.'),
      ],
    ),
  );

  return adapter.encodeEventSseStream(
    eventStream: eventStream,
    requestId: 'req-1',
    messageId: 'assistant-1',
    resumeToken: 'resume-1',
    messageMetadata: const {
      'serverOwned': true,
    },
    finalMessageMetadata: const {
      'persisted': true,
    },
    includeDoneFrame: true,
  );
}
```

Typical HTTP response headers should still be backend/framework-owned:

- `content-type: text/event-stream`
- `cache-control: no-cache`
- `connection: keep-alive` when applicable for the chosen server stack

## Consequences

- Dart backends can now reuse the protocol and reference adapter without
  pulling in Flutter
- `llm_dart_chat` keeps the client/runtime focus instead of growing backend
  responsibilities
- `llm_dart_flutter` keeps only adapter-layer responsibilities
- future backend-framework helpers should wrap `llm_dart_transport`, not widen
  either `llm_dart_chat` or `llm_dart_flutter`

This is a boundary correction, not a new abstraction tier.
