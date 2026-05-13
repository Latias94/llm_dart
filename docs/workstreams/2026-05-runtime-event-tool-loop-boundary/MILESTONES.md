# Milestones

## M0: Workstream Opened

Status: complete

Acceptance criteria:

- workstream directory exists
- canonical goal is recorded
- reference and gap audit is recorded
- target runtime surface draft is recorded

## M1: Boundary Decision Freeze

Status: pending

Acceptance criteria:

- final provider model-call event name is chosen
- final AI runtime full-stream event name is chosen
- event ownership rules are documented
- public migration story for `TextStreamEvent` is documented
- first implementation slice is selected

Recommended decision:

- provider owns model-call stream events
- AI runtime owns full generation-run events
- providers must not emit runtime step events
- `generateText(...)` and `streamText(...)` become the primary app-facing
  multi-step runtime helpers

## M2: Provider Model-Call Stream

Status: pending

Acceptance criteria:

- provider contract exposes only model-call stream parts
- focused providers compile against the new stream contract
- provider serialization tests cover the new vocabulary
- provider packages still do not depend on runtime, chat, Flutter, root, or
  legacy code

## M3: Unified Runtime Result Surface

Status: pending

Acceptance criteria:

- streaming result exposes one consistent set of event, text, output, element,
  step, final result, and UI projection accessors
- non-streaming result and streaming final result share the same step/result
  model
- `GenerateTextRunner` / `StreamTextRunner` duplication is removed or made
  private implementation detail
- structured output stays on `generateTextCall(...)` and `streamTextCall(...)`

## M4: Tool Loop Runtime

Status: pending

Acceptance criteria:

- local tool execution is centralized in `llm_dart_ai`
- tool lifecycle callbacks and result normalization are runtime-owned
- approval, denial, dynamic tool, provider-executed tool, input error, and
  preliminary output semantics are covered by tests
- prompt continuation remains replay-safe

## M5: Chat Runtime Integration

Status: pending

Acceptance criteria:

- `llm_dart_chat` direct transport no longer calls provider streams directly
  for the main runtime path
- chat consumes runtime UI projection or an agent wrapper
- chat state remains transport/persistence/UI focused
- manual tool outputs and approval responses keep ergonomic APIs

## M6: Release Readiness

Status: pending

Acceptance criteria:

- migration docs and examples are updated
- boundary guards cover the new ownership rules
- affected package tests pass
- consumer smoke passes
- publish dry-runs pass
