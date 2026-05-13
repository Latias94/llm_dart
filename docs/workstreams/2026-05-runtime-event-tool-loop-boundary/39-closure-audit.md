# Closure Audit

Date: 2026-05-14
Status: complete

## Objective Restated

Close the provider/runtime/chat three-layer architecture line so the next
breaking release has one defensible public shape:

- provider packages own one model-call stream only
- `llm_dart_ai` owns runtime full-stream orchestration, result facades,
  tool-loop execution, structured output, and UI projection
- `llm_dart_chat` owns session state, transport protocols, persistence, and
  manual user interaction around tool outputs and approvals
- migration docs, examples, guards, tests, consumer smoke, and publish dry-runs
  prove the boundary

## Prompt-To-Artifact Checklist

| Requirement | Evidence |
| --- | --- |
| Provider stream no longer owns runtime lifecycle | `LanguageModelStreamEvent` is the provider base; provider exports no longer expose runtime `TextStreamEvent` or runtime-only lifecycle events; provider stream codec tests passed. |
| AI runtime owns the full stream | `TextStreamEvent` lives in `llm_dart_ai`; runtime emits run, step, model-call, tool-result, abort, error, and finish events; AI runtime tests passed. |
| Primary app-facing runtime helpers are frozen | `generateText(...)` and `streamText(...)` route through runtime runners; `generateTextCall(...)` and `streamTextCall(...)` remain text/result facades; MCP examples now use `generateText(...)` and `streamText(...)`. |
| Runner-named helpers are no longer the teaching path | `29-runner-helper-migration-path.md` freezes them as advanced facades; migration docs and examples teach primary helpers first. |
| Tool loop is runtime-owned | `GenerateTextRunnerSupport` centralizes local tool execution and replay; runtime tests cover dynamic tools, input errors, approval stop, provider-executed calls, callbacks, stop conditions, and cancellation. |
| Runtime/tool context is decided | `36-runtime-context-deferral.md` records the Dart-native deferral and revisit criteria instead of freezing an untyped context bag. |
| Chat consumes runtime rather than provider streams | `DirectChatTransport` uses `streamText(...)`; `ChatRequestOptions` forwards local runtime tool-loop options; HTTP rejects local-only hooks. Chat tests passed. |
| UI stream protocol is stable or migrated | `37-chat-ui-stream-migration.md` freezes `ChatUiStreamChunk` for in-process chat/session streams and keeps `HttpChatTransportChunk` as the wire protocol. |
| Provider packages remain dependency-clean | `dart run tool/check_workspace_dependency_guards.dart` passed. |
| Provider metadata remains response/replay-only | `dart run tool/check_provider_replay_metadata_guards.dart` passed after narrowing the guard to prompt-part replay metadata. |
| Migration docs and examples are updated | `docs/migration/0.11-sdk-aligned.md` documents stream layers and runner helper roles; MCP examples use primary runtime helpers. |
| Release readiness is proven | `38-examples-and-release-readiness.md` records focused provider/runtime/chat tests, example analysis, direct consumer smoke, publish dry-run, and `git diff --check`. |

## Known Deferred Work

These are not blockers for this breaking line:

- public runtime/tool context, deferred until a Dart-native shape proves useful
  across step preparation, approval, tool execution, and telemetry
- dedicated tool-input callbacks, deferred because tool input is already
  observable through runtime stream events and `onChunk`
- public `Agent` / `ToolLoopAgent`, kept out of the first architecture slice
- preliminary tool outputs, left as future runtime policy because no Dart
  provider path currently proves the need for a public event shape

## Conclusion

The architecture line is complete for the next breaking release foundation.
Remaining work is future feature policy, provider-specific expansion, or
release packaging, not unresolved ownership coupling in this workstream.
