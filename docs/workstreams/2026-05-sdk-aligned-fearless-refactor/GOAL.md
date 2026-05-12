# Goal

## Canonical Goal Text

Complete a breaking, SDK-aligned architecture refactor of `llm_dart` that uses
the mature layering lessons from `repo-ref/ai` while preserving Dart-first
strengths. Provider specifications must describe model capability and
wire-neutral request/result semantics through implementation-facing contracts.
User-facing orchestration such as `generateText`, `streamText`, object
generation, tool loops, stop policy, UI projection, and result facades must live
in `llm_dart_ai`. Input-side provider customization must use typed provider
options, while provider metadata must remain output-side observation and replay
data. Concrete provider packages must retain provider-native helper clients and
typed options, but must not depend on runtime, chat, Flutter, root, or core
compatibility packages at runtime. The root package must become a modern facade
and explicit compatibility bridge only. The refactor is complete when guards,
tests, migration docs, examples, changelog, and clean consumer smoke validation
prove the new boundaries.

## Completion Definition

This goal is complete only when:

- provider contracts are implementation-facing and orchestration-free
- runtime orchestration is centralized in `llm_dart_ai`
- provider packages have no runtime dependency on AI/runtime/UI/root layers
- provider options and provider metadata are separate by contract and tests
- shared generation options cover modern durable LLM knobs
- provider-native functionality remains available in provider-owned surfaces
- root and core compatibility surfaces cannot regain implementation ownership
- migration docs and release gates are updated for the breaking line
