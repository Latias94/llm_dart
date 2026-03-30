# Execution Result And Event Boundary

## Goal

This document defines the recommended next workstream after the Anthropic retrieval-result replay slice.

The immediate question is not whether we can decode more provider-native result blocks. The real question is whether execution-oriented result families should become replayable at all, and if so, which parts belong in the common core versus provider-owned layers.

## Current Status

The provider-owned replay path described in this document is now implemented for Anthropic execution result families.

Typed provider-owned execution helper models and the provider-native files API are now also implemented.

What remains intentionally conservative:

- legacy raw execution result blocks still do not enter the compatibility bridge
- provider-native file handles still do not auto-promote into common `GeneratedFile` values
- renderer-level UI conveniences can still evolve without widening the shared event model

## 1. Why This Should Be The Next Design Slice

The retrieval result families are now in a stable state:

- `web_search_tool_result` has a provider-owned replay path
- `web_fetch_tool_result` has a provider-owned replay path
- both block families now also have a restricted legacy raw bridge path when their exact replay-safe wire shape is preserved

That closes the low-risk retrieval branch.

The remaining Anthropic-native result families are materially different:

- `code_execution_tool_result`
- `bash_code_execution_tool_result`
- `text_editor_code_execution_tool_result`

These are not just richer `tool_result` payloads. They mix several concerns:

- execution output
- approval and denial state
- generated files
- editor operations or patches
- potentially long-running or streamed provider-native state

Because those concerns cross event, UI, replay, and session-restore boundaries, widening the compatibility bridge first would be the wrong order.

## 2. Current Core Building Blocks

The current shared architecture already has useful primitives:

- `ToolApprovalRequestEvent`
- `ToolOutputDeniedEvent`
- `FileEvent`
- `GeneratedFile`
- `CustomEvent`
- `CustomContentPart`
- `CustomUiPart`
- part-level and event-level `ProviderMetadata`

This is important because it means the next design slice does not start from zero.

What the current architecture still needed at design time was one stable provider-owned execution replay contract.

## 3. Recommendation

The recommended next move is:

1. do not widen the common `ToolResultPromptPart` model with Anthropic execution-specific block families
2. do not allow raw legacy execution result blocks into the compatibility bridge yet
3. define one provider-owned execution replay shape first
4. only promote common abstractions when multiple providers justify them

This keeps the shared core honest.

The Vercel AI SDK is a useful reference here, but we should not mirror its full UI chunk vocabulary into `TextStreamEvent`.

The correct lesson is narrower:

- keep common model events for stable cross-provider semantics
- keep transport and UI detail out of the model stream when it is not truly shared
- use provider-owned custom parts for renderable provider-native output that must remain replayable

## 4. Proposed Boundary

### Shared Core Should Continue To Own

- approval request semantics
- approval denial semantics
- generated file payloads
- generic text output
- generic reasoning output

These concepts already have cross-provider evidence or clear product value for Flutter applications.

### Provider-Owned Anthropic Layer Should Own

- exact execution result block identity
- execution-session identifiers
- editor patch payloads
- provider-native execution transcripts
- any fields required only for Anthropic request re-encoding

Recommended namespace direction:

- one canonical execution replay kind: `anthropic.result.code_execution`
- preserve the exact Anthropic wire family in payload data such as `blockType`

The naming can still change, but the ownership boundary should not.

## 5. Event Model Guidance

Do not immediately add new common `TextStreamEvent` variants just because Anthropic exposes new execution block families.

Use this test first:

1. is the concept cross-provider?
2. is it required for application logic rather than only provider replay?
3. can Flutter applications render or act on it without understanding Anthropic-specific wire detail?

If the answer is no, keep it provider-owned through `CustomEvent` and `CustomUiPart`.

Examples:

- console output deltas should stay provider-owned unless another provider proves the same concept in a compatible shape
- text-editor patch previews should stay provider-owned
- execution checkpoint IDs should stay provider-owned

Examples that can stay shared:

- approval requested
- output denied
- generated files

## 6. Flutter Integration Direction

For Flutter chat applications, the stable integration contract should be:

- common UI renderers handle shared parts and events
- provider-owned custom renderers handle execution-specific visualizations
- prompt reconstruction must preserve provider-owned execution payloads exactly when replay is promised

This is better than pushing execution-specific branches into every shared Flutter widget.

The session layer should therefore keep one generic custom-part persistence path and let provider packages supply higher-level helpers or renderer adapters.

## 7. Recommended Delivery Order

1. freeze this boundary in docs before more bridge work
2. design the provider-owned execution replay payload shape
3. design the UI projection and session-restore path for that payload shape
4. only then decide whether any legacy raw execution blocks are safe to bridge
5. only after real multi-provider evidence appears, evaluate new common event families

## 8. Review Rule

When a new execution-oriented provider-native block is proposed for replay, ask:

> Is the feature primarily a shared application semantic, or is it provider-owned execution state that only Anthropic currently understands?

If it is provider-owned execution state, keep it out of the common core first.

That is the recommended path for this refactor round.
