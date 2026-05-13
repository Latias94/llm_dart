# Runner Helper Migration Path

Date: 2026-05-13
Status: decided

## Decision

`runTextGeneration(...)` and `streamTextRun(...)` remain public advanced
runtime result facades for this breaking line.

They are not the primary teaching path. The primary app-facing text runtime is:

- `generateTextCall(...)` and `streamTextCall(...)` for normal app text calls
  with rich final result access and optional structured output
- `generateText(...)` and `streamText(...)` for raw runtime result/event shapes
  when callers do not need the call-result facade
- `LanguageModel.doGenerate(...)` and `LanguageModel.doStream(...)` only for
  provider implementations, provider tests, and intentional low-level adapters

`GenerateTextRunner` and `StreamTextRunner` stay public for now because they
are still useful when callers want object-style configuration or direct runner
construction. They should be treated as advanced runtime shapes rather than the
recommended app surface.

## Why Not Remove Them Now

Removing the runner helpers immediately would force users who need step-level
observation to choose between:

- `streamText(...)`, which intentionally returns only `Stream<TextStreamEvent>`
- `streamTextCall(...)`, which focuses on text/output result ergonomics
- building their own runner wrapper around internal code

That would make the architecture cleaner on paper but worse for real tool-loop
and tracing users. The Vercel AI SDK reference keeps primary helpers ergonomic
while still exposing result and stream shapes that carry step information. In
Dart today, `runTextGeneration(...)` and `streamTextRun(...)` are that advanced
escape hatch.

## Migration Rule

Do not describe `generateText(...)` or `streamText(...)` as single provider
calls. They now route through the AI runtime and can perform multi-step tool
continuation.

Use this wording instead:

- `generateTextCall(...)` / `streamTextCall(...)`: recommended app-facing
  text/result facade
- `generateText(...)` / `streamText(...)`: primary runtime helper returning
  raw final result or raw full-stream events
- `runTextGeneration(...)` / `streamTextRun(...)`: advanced runtime helper
  when the caller needs `GenerateTextRunResult`, `StreamTextRunResult`,
  `stepStream`, or direct runner telemetry
- `LanguageModel.doGenerate(...)` / `doStream(...)`: provider-contract calls

## Future Exit Criteria

The runner helpers can become private or deprecated only after the primary
runtime result surface can cover the same advanced use cases:

- non-streaming callers can obtain the full `GenerateTextRunResult`
- streaming callers can obtain a `StreamTextRunResult` or equivalent run result
  without switching to runner-named APIs
- examples and migration docs no longer need runner names to teach tool-loop
  tracing or step inspection
- chat and UI projection consume the primary runtime path without duplicating
  provider accumulation

Until then, keeping the helpers public is the more honest API.

## Validation

This slice is documentation and migration-surface alignment only. It updates
release-facing docs so they match the current runtime behavior.
