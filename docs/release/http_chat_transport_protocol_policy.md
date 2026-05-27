# HTTP Chat Transport Protocol Policy

Status: frozen for alpha
Last updated: 2026-05-27

## Supported Protocols

`HttpChatTransportStreamProtocol` supports two wire protocols:

| Protocol | Wire value | Release posture |
| --- | --- | --- |
| `eventStreamV1` | `event-stream-v1` | Legacy compatibility. Decoded for old clients and available for server downgrade. |
| `uiMessageStreamV2` | `ui-message-stream-v2` | Default protocol for new send and reconnect requests. |

The code-level policy lives in
`HttpChatTransportProtocolPolicy`:

- `defaultStreamProtocol` is `uiMessageStreamV2`;
- `legacyRequestFallbackStreamProtocol` is `eventStreamV1`;
- `supportedStreamProtocols` is `[eventStreamV1, uiMessageStreamV2]`.

## Compatibility Rules

- New request payloads encode `streamProtocol`.
- Legacy request and reconnect payloads that omit `streamProtocol` decode as
  `eventStreamV1`.
- v2 streams may emit transport-start, message-start, message metadata,
  transient data, checkpoint, message-finish, and finish chunks.
- v1 server downgrade emits legacy start, persistent data, event, and finish
  chunks. Message metadata is not emitted as a v2-only chunk on v1.
- Transient data chunks are v2-only and are dropped during v1 server downgrade.
- Reconnectability is preserved only after checkpoint/resume-token state exists.
  Terminal finish, abort, status failure, or non-reconnectable stream failure
  clears resume state.

## Non-Goals

- No new protocol version is introduced in this freeze.
- Local runtime hooks remain non-serializable and are rejected by HTTP
  transport instead of silently crossing the wire.
- Provider-native options cross HTTP only through explicit JSON encoding.
