# Chat UI Stream Migration

Date: 2026-05-14
Status: decided

## Decision

Keep `ChatUiStreamChunk` as the stable chat/session stream protocol for this
breaking line and document the transport split instead of renaming the chunk
family again.

The frozen layers are:

- provider model-call stream: `LanguageModelStreamEvent`
- AI runtime full stream: `TextStreamEvent`
- chat/session UI stream: `ChatUiStreamChunk`
- HTTP wire stream: `HttpChatTransportChunk`

`ChatUiStreamChunk` is the in-process UI/session protocol. It carries message
start, metadata patches, runtime events, persistent data parts, transient data
parts, and message finish markers. `HttpChatTransportChunk` is a wire protocol
for HTTP/SSE transport concerns such as handshake, checkpoints, abort, errors,
and keep-alive frames.

## Migration Rule

Old chat-transport consumers should migrate by responsibility:

- If the code reads in-process chat/session chunks, consume
  `Stream<ChatUiStreamChunk>` and `ChatUiStreamReader`.
- If the code implements an HTTP backend or SSE client, use
  `HttpChatTransportServerAdapter` and `HttpChatTransportChunkJsonCodec`.
- If the code renders model/runtime events directly, consume
  `TextStreamEvent` from `streamText(...)` or use
  `streamText(...).chatUiStream(...)` through the streaming result facade that
  exposes a projection helper.
- Do not add chat status, reconnect checkpoints, or HTTP keep-alive markers to
  `TextStreamEvent`; those belong above the runtime stream.

## Compatibility Note

`ChatTransportChunk` is not the long-term in-process type name. The current
architecture distinguishes reusable UI/session chunks from HTTP transport wire
chunks. That makes the runtime stream reusable by CLI, server, chat, and
Flutter consumers without letting transport lifecycle markers leak into model
events.

## Validation

`llm_dart_chat` direct transport now consumes `streamText(...)` and projects
runtime events into `ChatUiStreamChunk`. HTTP transport keeps its own
`HttpChatTransportChunk` codec and server adapter for wire frames.
