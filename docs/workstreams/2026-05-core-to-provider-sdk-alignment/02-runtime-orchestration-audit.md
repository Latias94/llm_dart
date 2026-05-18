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

Implemented tool-loop continuation slice:

- Replaced the runner-facing `null` / empty list / non-empty list convention
  with explicit `GenerateTextToolContinuation` values.
- `stop` now represents natural stop conditions: missing executor, provider
  approval waiting, or no actionable client tool calls.
- `continueWithExecutions` now represents continuation, including the
  important case where the model already returned matching tool result parts
  and no local execution is needed.
- Kept the legacy support helper behavior for callers that still use
  `executeFunctionTools`, but moved synchronous and streaming runners onto the
  explicit continuation seam.
- Added a shared `GenerateTextLoopContinuation` helper so stop-condition
  evaluation and prompt replay are one runtime seam instead of duplicated in
  both runners.

Implemented result facade parity slice:

- Added step-level static and dynamic projections for tool calls and tool
  results, matching the reference distinction between schema-owned tools and
  dynamic tool surfaces.
- Changed text run result facades to aggregate generated files, sources, tool
  calls, tool results, and warnings across all steps while preserving final-step
  semantics for text, reasoning text, finish reason, response metadata, and
  provider metadata.
- Added streaming run result futures for static/dynamic tool calls,
  static/dynamic tool results, and warnings so streaming and non-streaming
  facades expose the same result views.
- Kept tool approval requests as a current-step view because they represent
  pending approval state rather than a historical projection.

Implemented structured output stream parity slice:

- Kept `OutputSpec` as the parsing and partial-output strategy seam while
  aligning the stream event vocabulary with the reference object-stream model:
  text events, partial output, element output, finish, final parsed result, and
  final parse error now have explicit events.
- Split raw text completion from final structured parsing in
  `StreamOutputResult`. `text`, `finishReason`, `usage`, response metadata,
  provider metadata, and warnings now resolve from the raw text result even when
  the final structured output fails validation.
- Kept `result` and `output` as the schema-validated structured result views;
  they fail with validation `ModelError` when final parsing or schema decoding
  fails.
- Updated `streamTextCall(... outputSpec)` to preserve raw text result
  compatibility while keeping parsed output on its own future.

Implemented UI/chat transport ownership slice:

- Compared Dart chat transport code against the reference UI message stream and
  transport split in `repo-ref/ai`.
- Kept UI message projection in `llm_dart_ai` and framework-neutral chat
  transport adapters in `llm_dart_chat`.
- Kept HTTP chat wire request/chunk codecs in `llm_dart_chat` because the
  chunk protocol currently carries `TextStreamEvent` and `ChatUiStreamChunk`
  concepts; moving those codecs to `llm_dart_transport` would force transport
  to depend on runtime/UI packages and contradict the current package graph.
- Replaced the monolithic HTTP chat transport protocol implementation with
  focused modules for stream protocol selection, request payloads, request JSON
  codec, wire chunks, chunk JSON codec, and SSE framing.
- Kept `HttpChatTransportServerAdapter` as the typed bridge from runtime/UI
  chunks to HTTP transport chunks, and kept `HttpChatTransportSseEncoder` as a
  thin JSON-to-SSE framing helper.
- Preserved the public `http_chat_transport_protocol.dart` export surface and a
  compatibility barrel for the old implementation file while making internal
  implementation files depend on the narrower modules directly.
- Added direct AI-runtime contract coverage for text-event to UI-chunk
  projection, `ChatUiJsonCodec` message serialization, and
  `ChatMessageMapper` render-summary projection so UI serialization ownership
  is tested in `llm_dart_ai` rather than only through chat transports.

Next runtime candidates:

- Add an explicit `prepareStep` hook if real callers need per-step model,
  tool-choice, active-tools, or options overrides.
- Promote tool approval policy into a first-class runtime seam instead of
  treating approvals only as a natural stop condition.
- Split provider approval waiting, automatic denial, and user approval response
  replay into their own module once the public approval policy is designed.
- Audit response-message projection parity once UI message ownership is settled.
