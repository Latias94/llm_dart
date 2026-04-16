# Reader Validation Hooks

## Goal

Add optional validation ergonomics to `ChatUiStreamReader` and
`readChatUiStream(...)` without reopening any of the frozen boundaries around:

- shared event growth
- callback-heavy read facades
- session or controller lifecycle expansion

## Why This Is The Right Next Slice

The current event gap audit already identified one honest remaining difference
versus `repo-ref/ai`:

- the reference UI stream processing layer performs metadata and data-part
  validation above the model stream

`llm_dart` did not need that behavior in shared core.

But there is now enough structure to support it at the reader layer:

- `TextStreamEvent`
- `ChatUiStreamChunk`
- `ChatUiStreamReader`
- `DefaultChatSession`

That makes the reader the correct home for additive validation hooks.

## Implemented Surface

`ChatUiStreamReader` and `readChatUiStream(...)` now accept two optional
validators:

- `messageMetadataValidator`
- `dataPartValidator`

### `messageMetadataValidator`

The metadata validator receives `ChatUiMessageMetadataValidationContext`, which
includes:

- `phase`
  - `start`
  - `patch`
  - `finish`
- `messageId`
- `currentMetadata`
- `patch`
- `nextMetadata`

The validator runs before the metadata patch is applied, using the merged
would-be metadata state.

This matches the real need better than validating only the raw patch.

### `dataPartValidator`

The data-part validator receives `ChatUiDataPartValidationContext`, which
includes:

- the current projected `message`
- the candidate `part`
- `isTransient`

The validator runs before:

- persistent `ChatUiDataPartChunk` projection
- transient `ChatUiTransientDataPartChunk` side-channel delivery

## Error Behavior

Validator failures intentionally use the existing error path.

If a validator throws:

- direct `applyChunk(...)` / `applyDataPart(...)` calls throw immediately
- `consume(...)` fails the reader through the existing `fail(...)` path
- `readChatUiStream(...)` surfaces that failure through the stream and `result`

No new reader-specific error envelope is introduced.

## Why This Does Not Reopen The Facade Freeze

This slice does not introduce:

- callback ordering contracts
- lifecycle callback APIs
- summary objects
- session-level validation APIs

It remains a narrow additive helper on the existing stream-first result-object
contract.

That keeps the earlier `readChatUiStream(...)` facade freeze intact.

## Why This Stays Out Of `ChatSession`

`DefaultChatSession` currently keeps using `ChatUiStreamReader` internally
without exposing reader-level observation or validation APIs directly.

That should stay true for now.

The current evidence still supports:

- reader = direct chunk-stream helper
- session = full conversation runtime

If session-level validation is ever needed later, it should be justified by
real application pressure rather than inferred from the reader helper.

## Bottom Line

This slice closes one of the remaining honest post-alignment opportunities:

- additive validation ergonomics above the shared UI chunk layer
- no shared event widening
- no session growth
- no callback-heavy facade
