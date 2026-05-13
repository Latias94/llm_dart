# Goal

## Canonical Goal Text

Complete the next intentional breaking architecture line by splitting
provider model-call streaming from AI runtime full-stream orchestration, then
freezing one Dart-native v2 runtime surface for generation results, tool loops,
structured output, UI projection, and chat transport.

The work should use `repo-ref/ai` as the mature reference for boundaries:
provider calls are one layer, full text generation runs are another layer,
tool execution is runtime-owned, UI message projection is derived from the
runtime full stream, and chat transport talks to runtime or agent abstractions
instead of directly owning provider stream semantics.

The Dart library must keep its own strengths: a unified model interface,
focused provider packages, typed provider options, provider-native helpers,
explicit replay options, `ModelMessage` app ergonomics, and minimal dependency
weight. Breaking changes are allowed when they remove duplicated ownership or
make the long-term public surface clearer.

## Completion Definition

This goal is complete only when:

- provider-facing stream contracts no longer own runtime step lifecycle events
- `llm_dart_ai` owns a full generation-run event stream with explicit run,
  step, model-call, tool, finish, abort, and error semantics
- `generateText(...)` and `streamText(...)` are the primary app-facing runtime
  helpers rather than thin provider-call wrappers
- `generateTextCall(...)` and `streamTextCall(...)` remain the primary combined
  text and structured-output result facades
- `GenerateTextRunner` and `StreamTextRunner` either become implementation
  details or are removed in favor of the unified runtime result surface
- stream result objects expose consistent `eventStream`, `textStream`,
  `partialOutputStream`, `elementStream`, `steps`, final result, usage, output,
  and UI projection accessors where applicable
- local tool execution is centralized in `llm_dart_ai` with lifecycle
  callbacks, execution result normalization, provider-executed tool handling,
  and replay-safe prompt continuation
- dynamic tools, tool input errors, approval requests/responses, denied
  outputs, and preliminary outputs have one documented event model
- `llm_dart_chat` direct transport consumes the AI runtime or an agent wrapper
  instead of directly calling `LanguageModel.doStream(...)`
- provider packages remain free of runtime, chat, Flutter, root, and legacy
  dependencies in production code
- migration docs, examples, guards, targeted package tests, chat tests, provider
  smoke tests, consumer smoke, and publish dry-runs prove the new boundary
