# Runtime Orchestration Audit

## Current Source Findings

`llm_dart_ai` owns the expected runtime layer:

- `generateText` and `streamText`
- non-streaming and streaming runner lifecycles
- tool execution and prompt replay
- stop conditions
- result accumulation
- structured output parsing and stream projection
- text call facades
- UI projection and chat UI stream helpers
- runtime JSON codecs

The previous SDK-aligned workstream already split many runtime modules into
focused implementation seams.

Additional findings from the `generateText` / `streamText` comparison:

- The Dart runtime already matches the reference split between app-facing
  helpers and lower-level run APIs.
- Tool execution, prompt replay, result accumulation, lifecycle callbacks, and
  stream event emission are separate modules instead of one large runner.
- `GenerateTextRunner` and `StreamTextRunner` still had duplicated step
  planning logic: max step enforcement, prompt validation, request
  construction, declared tool-name collection, and step-start event
  construction.
- Vercel AI SDK keeps per-step preparation as an explicit runtime concern
  (`prepareStep`, active tools, step messages, and per-step callbacks). Dart
  should keep typed provider options and Dart streams, but the same lesson
  applies: step preparation should be a single runtime seam shared by
  non-streaming and streaming paths.

## Reference Comparison Targets

Use these `repo-ref/ai` areas as comparison material:

- `packages/ai/src/generate-text`
- `packages/ai/src/generate-object`
- `packages/ai/src/stream-text`
- `packages/ai/src/ui`
- `packages/ai/src/ui-message-stream`
- `packages/ai/src/agent`
- `packages/ai/src/error`

The Dart runtime should preserve Dart stream conventions and typed provider
options rather than copying Web Streams or TypeScript generic utility types.

## Audit Questions

### Text Generation

- Are `generateText`, `streamText`, and lower-level run APIs clearly separated?
- Does every provider call flow through implementation-facing model methods?
- Are callbacks ordered and tested for cancellation, errors, tool continuation,
  and stop conditions?

### Tool Loop

- Is missing tool result handling explicit enough?
- Should tool approval become a first-class runtime seam or remain deferred?
- Are provider-executed tools and provider-defined tools represented cleanly
  enough for future providers?

### Stream Events

- Are provider stream events and runtime text stream events separated by a
  deliberate adapter?
- Are raw chunks consistently opt-in through `includeRawChunks`?
- Are denied output, abort, tool execution, and UI events runtime-owned only?

### Structured Output

- Are output specs still a deep module after the prior splits?
- Are parse errors and validation diagnostics precise enough?
- Do partial output and duplicate suppression semantics match the intended
  reference behavior?

### UI And Chat

- Does `llm_dart_chat` own chat session behavior rather than provider
  contracts?
- Does `llm_dart_flutter` depend on runtime/chat contracts rather than
  concrete providers?
- Are UI JSON codecs owned in runtime/chat layers, not provider packages?

## Proposed First Slice

After core contract audit, run a runtime event and tool-loop audit:

- map every runtime event type to its provider or runtime owner
- document any missing error type or tool-loop invariant
- add focused tests only for gaps found by the audit

Implemented first runtime slice:

- Added a shared `GenerateTextStepPlanner` for synchronous and streaming text
  runners.
- Centralized step request construction, start-event construction, prompt
  validation context, max-step checks, and declared tool-name discovery.
- Preserved public API and callback behavior while creating a seam that can
  grow into Dart's equivalent of reference `prepareStep`.

Next runtime candidates:

- Add an explicit `prepareStep` hook if real callers need per-step model,
  tool-choice, active-tools, or options overrides.
- Promote tool approval policy into a first-class runtime seam instead of
  treating approvals only as a natural stop condition.
- Audit result facades for parity with reference step-level projections:
  static/dynamic tool calls, static/dynamic tool results, warnings, files, and
  response messages.
