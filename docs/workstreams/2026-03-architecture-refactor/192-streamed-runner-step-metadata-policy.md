# Streamed Runner Step Metadata Policy

## Purpose

This note closes the remaining runner question around streamed multi-step
orchestration:

- does the shared core need richer step-start and step-finish metadata now
- or should the current small runner callbacks and UI/runtime chunk layers stay
  the main step-observability surface

## Current Shared Surface

The current shared surface already splits step visibility across two layers on
purpose.

### Runner-Facing Step Observability

For orchestration-aware code, the shared runner already exposes:

- `GenerateTextStepStartEvent`
  - `stepNumber`
  - `providerId`
  - `modelId`
  - `request`
  - `previousSteps`
- `GenerateTextStepResult`
  - final accumulated step snapshot
- `StreamTextRunResult.stepStream`
  - replay-safe completed step snapshots

That is already enough for:

- tracing
- logging
- step-level analytics
- app-owned orchestration decisions outside `prepareStep`

### Event/UI Step Observability

At the raw streamed-event and chat-runtime layers, the shared contract also
already has:

- `StepStartEvent(stepId?)`
- `StepFinishEvent(stepId?)`
- `ChatUiStreamChunk`
- `ChatUiStreamReader.stepFinishStream`

That layer is intentionally lighter.

It exists to mark boundaries in event and UI flows, not to become a second
full runner callback model.

## What The Current Code Actually Shows

The current repository does not show evidence that richer shared step metadata
is needed yet.

Today:

- direct uses of `onStepStart`, `onStepFinish`, `stepStream`, and
  `GenerateTextStepStartEvent` are effectively confined to focused core tests
- no shared production path currently depends on extra step lifecycle fields in
  the raw `TextStreamEvent` stream
- the chat-runtime layer already consumes step boundaries through
  `StepStartEvent` / `StepFinishEvent` and projects them into UI state without
  asking for broader runner metadata

So the pressure for richer shared metadata is not implementation-proven.

## Why The Shared Core Should Stay Small

Adding richer step-start or step-finish payloads now would likely create
duplication across layers.

If the shared core widened step metadata, it would overlap with information
that already exists elsewhere:

- `GenerateTextStepStartEvent.request`
- `GenerateTextStepResult`
- `GenerateTextRunResult.steps`
- future UI/runtime chunk metadata
- app-owned logging/tracing context

That would make it easier to accidentally create two half-overlapping step
contracts:

- one in runner callbacks and step snapshots
- one in raw streamed events or UI-oriented step markers

This refactor should avoid that split.

## Why Richer Metadata Belongs Elsewhere If It Is Ever Needed

If later integrations need richer step detail, the next question is *which
layer* actually needs it.

Possible future homes are more honest than widening the shared event core:

- UI/runtime chunk metadata if the need is chat-session or transport-facing
- app-owned tracing objects if the need is observability only
- a later constrained runner hook if the need is orchestration-specific

Those are much better fits than turning `StepStartEvent` and `StepFinishEvent`
into generic metadata bags.

## Boundary Decision

The current shared step boundary is enough for now.

The frozen rule is:

- keep `GenerateTextStepStartEvent` small
- keep `GenerateTextStepResult` as the main completed-step snapshot
- keep raw `StepStartEvent` / `StepFinishEvent` light and boundary-oriented
- do not add richer shared step-start or step-finish metadata in this round

## Reopen Threshold

This question should only reopen if real usage shows that the current split is
not enough.

Valid pressure signals would look like:

- at least two concrete shared call paths both needing the same missing step
  metadata
- repeated app or backend code reconstructing the same step summary from
  runner callbacks and UI streams
- a proven need that cannot be met cleanly by `GenerateTextStepStartEvent`,
  `stepStream`, or the UI/runtime chunk layer

Absent those signals, adding more shared step metadata would mostly increase
surface area without clarifying ownership.

## TODO Consequence

The workstream should therefore:

- close the open TODO about richer shared step-start and step-finish metadata
- treat any later richer step metadata as a demand-driven UI/runtime or
  orchestration question, not current shared-core migration debt

## Bottom Line

The streamed runner is already observability-capable enough at the shared-core
layer.

The next maturity work should not be more shared step metadata by default.

If richer step detail is ever justified, it should land in the specific layer
that needs it rather than being pushed into the shared core prematurely.
