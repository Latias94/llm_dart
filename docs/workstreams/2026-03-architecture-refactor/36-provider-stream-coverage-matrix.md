# Provider Stream Coverage Matrix

## Why This Note Exists

The `TextStreamEvent` surface is now frozen as the shared model-stream boundary.

That leaves one practical question:

> Do we still have meaningful provider stream gaps, or do we mainly need better coverage for the existing event families?

The answer is the second one. The remaining work is test coverage and clearer ownership, not more core event types.

## Reference Boundary From `repo-ref/ai`

The Vercel AI SDK remains a useful reference, but its layering is important:

- provider/model stream chunks carry model semantics such as text deltas, reasoning, tool input, tool results, sources, and finish metadata
- UI stream chunks additionally carry transport and UI lifecycle markers such as `start`, `finish`, `message-metadata`, `data-*`, and step-oriented message shaping

For Dart, we keep the same split in spirit:

- `TextStreamEvent` stays for cross-provider model semantics
- `ChatUiMessage`, `ChatUiAccumulator`, and `ChatTransportChunk` own UI/session/transport shaping
- `StepStartEvent` and `StepFinishEvent` stay session-owned boundaries, not provider-decoder output

## Shared Event Families

| Family | OpenAI Responses | OpenAI-family chat completions | Anthropic stream codec | Google stream codec | Ownership |
| --- | --- | --- | --- | --- | --- |
| `ResponseMetadataEvent` | Yes | Yes | Yes | Yes | Shared provider/model stream |
| `Text*` | Yes | Yes | Yes | Yes | Shared provider/model stream |
| `Reasoning*` | Yes | Yes | Yes | Yes | Shared provider/model stream |
| `ToolInput*` | Yes | Yes | Yes | Yes | Shared provider/model stream |
| `ToolCallEvent` | Yes | Yes | Yes | Yes | Shared provider/model stream |
| `ToolResultEvent` | Yes | Partial via MCP/provider-executed flows | Yes | Yes | Shared provider/model stream |
| `ToolApprovalRequestEvent` | Yes | No | No | No | Shared event family, provider-specific support |
| `SourceEvent` | Yes | Yes | Yes | Yes | Shared provider/model stream |
| `FileEvent` | No | No | No | Yes | Shared provider/model stream where supported |
| `ReasoningFileEvent` | No | No | No | Yes | Shared provider/model stream where supported |
| `CustomEvent` | Yes | No | Yes | No | Provider-owned replay / custom model semantics |
| `ErrorEvent` | Yes | Yes | Yes | Language-model wrapper | Shared terminal/error semantics |
| `FinishEvent` | Yes | Yes | Yes | Yes | Shared provider/model stream |
| `StepStartEvent` / `StepFinishEvent` | No | No | No | No | Session/UI boundary |
| `ToolOutputDeniedEvent` | No | No | No | No | Runtime/UI policy boundary |
| `DataUiPart` ingress | No | No | No | No | Transport/UI boundary |

## Testing Policy

The correct coverage split is:

- provider-owned codec tests for provider/model stream decoding
- session tests for synthetic step boundaries and assistant-message continuation
- transport tests for reconnect envelopes, raw event envelopes, and `DataUiPart` chunks
- compatibility-route tests for legacy bridge allowlists and rejection messaging

That means we should not try to force `repo-ref/ai` UI chunk markers back into provider codec tests.

## Coverage Status After This Pass

- Anthropic already had direct stream codec tests for text, reasoning, tool input, tool results, provider-owned custom replay, sources, errors, and finish
- Google already had direct stream codec tests for text, reasoning, sources, files, reasoning files, tools, and finish
- OpenAI now also has direct codec-level stream coverage for:
  - Responses API text, reasoning, function-call deltas, MCP approval/result flows, sources, custom items, failure handling, and finish metadata
  - chat-completions text, reasoning, tool-call accumulation, malformed tool input, xAI citations, error payloads, and finish metadata

## Conclusion

Provider stream coverage is now strong enough to keep the current boundary frozen:

1. do not add more shared core event types
2. keep step/data/message-lifecycle shaping above the provider stream layer
3. grow provider support by mapping new provider-native behavior into existing families first
4. add new event types only when a stable cross-provider model semantic truly appears
