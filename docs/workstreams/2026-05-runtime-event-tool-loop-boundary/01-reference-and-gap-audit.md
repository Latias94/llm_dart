# Reference And Gap Audit

Date: 2026-05-13

## Reference: `repo-ref/ai`

The mature reference separates five concerns that are still partly coupled in
`llm_dart`:

1. Provider/model call boundary
   - `stream-language-model-call.ts` standardizes prompt/tools, calls the
     provider, and returns model-call stream parts.
   - It has model-call lifecycle events separate from runtime step events.
2. Full runtime stream
   - `stream-text.ts` stitches one or more model-call streams into a full
     generation stream.
   - It injects `start`, `start-step`, `finish-step`, `finish`, `abort`, and
     `error` lifecycle parts.
3. Tool execution
   - `create-execute-tools-transformation.ts` forwards provider chunks and
     appends local tool results after the model call boundary.
   - `execute-tool-call.ts` centralizes execution callbacks, tool context,
     timeout, preliminary output, and error normalization.
4. Result facade
   - `StreamTextResult` exposes `fullStream`, `textStream`,
     `partialOutputStream`, `elementStream`, final output, steps, usage, and UI
     message projection from one object.
5. Chat/agent integration
   - `ToolLoopAgent` wraps reusable tool-loop settings.
   - `DirectChatTransport` streams through an agent/runtime result and then
     converts to UI message chunks.

The key architectural lesson is ownership, not implementation syntax:

- provider contracts should describe what the model produced
- runtime contracts should describe what the whole generation run did
- chat should consume UI/runtime streams instead of becoming a second runtime

## Current `llm_dart` Shape

Key source files:

- `packages/llm_dart_provider/lib/src/model/language_model.dart`
- `packages/llm_dart_provider/lib/src/stream/text_stream_event.dart`
- `packages/llm_dart_ai/lib/src/model/language_model.dart`
- `packages/llm_dart_ai/lib/src/model/generate_text_runner.dart`
- `packages/llm_dart_ai/lib/src/model/stream_text_runner.dart`
- `packages/llm_dart_ai/lib/src/model/text_call.dart`
- `packages/llm_dart_ai/lib/src/model/output_spec.dart`
- `packages/llm_dart_ai/lib/src/ui/chat_ui_accumulator.dart`
- `packages/llm_dart_chat/lib/src/default_chat_session.dart`
- `packages/llm_dart_chat/lib/src/direct_chat_transport.dart`

Current strengths:

- provider contracts are already separated from root, chat, Flutter, and
  concrete provider packages
- typed provider options and provider-owned replay options are preserved
- `ModelMessage` gives a Dart-friendly app prompt surface
- content parts already model text, reasoning, files, tools, approvals,
  sources, custom parts, metadata, and provider-executed tool signals
- structured output has `OutputSpec`, partial output, and element streaming
- chat UI projection and JSON codecs already exist outside provider packages

Current coupling:

- `TextStreamEvent` lives in `llm_dart_provider` but contains runtime-looking
  lifecycle events such as `StepStartEvent`, `StepFinishEvent`, and
  `AbortEvent`
- providers and runtime share one event vocabulary even though they have
  different ownership responsibilities
- `generateText(...)` and `streamText(...)` are thin provider-call wrappers,
  while multi-step tool loops live under `runTextGeneration(...)` and
  `streamTextRun(...)`
- `generateTextCall(...)` and `streamTextCall(...)` use the thin helpers, so
  structured output is not naturally on the same multi-step runtime path
- `GenerateTextRunner` and `StreamTextRunner` duplicate loop construction,
  prompt validation, tool continuation, callback handling, and result assembly
- stream accumulation, UI projection, and chat tool state each maintain their
  own partial tool input state machine
- `DirectChatTransport` calls `LanguageModel.doStream(...)` directly, so chat
  bypasses runtime tool-loop behavior
- tool execution is a single `GenerateTextFunctionToolExecutor` callback; it
  does not yet centralize start/end callbacks, tool input lifecycle callbacks,
  dynamic tool handling, approval continuation, tool context, runtime context,
  per-tool timeout, or preliminary output
- runtime stop behavior is mostly `maxSteps` plus finish reason, not a
  composable stop-condition model

## Gap Table

| Area | `repo-ref/ai` pattern | Current `llm_dart` state | Target |
| --- | --- | --- | --- |
| Provider stream | model-call stream parts | provider owns `TextStreamEvent` including runtime-like parts | provider owns model-call parts only |
| Runtime stream | full stream stitches steps/tools | runtime forwards provider events and accumulates results | runtime owns full generation-run events |
| Public helpers | `generateText` / `streamText` are runtime helpers | thin provider-call wrappers | primary multi-step app helpers |
| Structured output | integrated in text result | integrated in `text_call`, but based on thin helpers | integrated in unified runtime result |
| Tool execution | centralized transform/executor | runner callback plus chat callback | one runtime tool execution engine |
| Chat direct transport | calls agent/runtime result | calls provider stream directly | calls runtime or agent wrapper |
| UI projection | derived from full stream | exists, but not owned by result facade | streaming result exposes UI projection |
| Step metadata | explicit request/response include policy | step stores request; limited policy | explicit include policy |
| Stop control | stop conditions | `maxSteps` only | composable stop conditions |

## Recommended Next Breaking Line

Do the event/runtime split before adding more tool features.

Reasoning:

- adding dynamic tools, approval continuation, or richer callbacks on top of
  the current shared event vocabulary would deepen the provider/runtime/chat
  coupling
- chat direct transport cannot be made truly runtime-consistent until the
  runtime owns full-stream semantics
- structured output should sit on the final runtime result, not on a separate
  thin provider-call helper path
- provider-native features are easier to preserve when provider packages only
  emit model-call facts and runtime handles orchestration

The first implementation slice should be small but architectural:

1. freeze the event ownership vocabulary
2. add the new runtime full-stream result foundation in `llm_dart_ai`
3. make direct chat transport consume that runtime path
4. then migrate provider stream names and public helpers behind tests and
   migration docs
