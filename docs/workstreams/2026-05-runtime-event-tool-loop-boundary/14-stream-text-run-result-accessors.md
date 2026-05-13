# Stream Text Run Result Accessors

Date: 2026-05-13
Status: implemented

## What Landed

`StreamTextRunResult` now exposes the same final-result convenience fields that
callers already expect from the non-streaming run result and the text-call
facade:

- `usage` as an alias for `totalUsage`
- `content`
- `sources`
- `files`
- `toolCalls`
- `toolResults`
- `toolApprovalRequests`
- `responseId`
- `responseTimestamp`
- `responseModelId`
- `providerMetadata`

The existing `result`, `steps`, `lastStep`, `totalUsage`, `text`,
`reasoningText`, `finishReason`, and `rawFinishReason` accessors remain
unchanged.

## Why This Matters

The streaming runtime result should not force app code to await `result` just
to inspect common final fields. This slice narrows the ergonomic gap between
`StreamTextRunResult` and `StreamTextCallResult` while leaving the larger
result-foundation refactor for a later step.

## Validation

- `dart analyze packages/llm_dart_ai`
- `dart test packages/llm_dart_ai/test/stream_text_runner_test.dart`

## Remaining Work

The getter implementations are still duplicated across result facades. The
next consolidation step should introduce a shared internal result projection
foundation so future result types do not copy these future-forwarding getters.
