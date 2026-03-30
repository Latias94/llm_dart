# Anthropic Execution Replay Contract

## Goal

This document freezes the recommended payload contract and capability boundary for Anthropic execution-oriented provider-native result replay.

It exists to answer one specific migration question:

> If we later make Anthropic execution results replayable, what exactly should be preserved in core state, what should stay provider-owned, and what should not be normalized prematurely?

## 1. Reference Findings From `repo-ref/ai`

After comparing our codebase with `repo-ref/ai`, three reference signals are clear.

### 1. Execution Output Stays Inside One Tool Family

The reference Anthropic UI examples render code execution through one tool invocation family:

- tool name: `code_execution`
- one shared tool state machine
- execution-specific branching happens inside provider-owned input/output payloads

That means the correct lesson is not to create many new shared event families.

### 2. The Output Schema Is Strongly Provider-Owned

The reference Anthropic provider keeps execution output as a discriminated union of provider-owned result variants such as:

- `code_execution_result`
- `encrypted_code_execution_result`
- `bash_code_execution_result`
- `bash_code_execution_tool_result_error`
- `text_editor_code_execution_view_result`
- `text_editor_code_execution_create_result`
- `text_editor_code_execution_str_replace_result`
- `text_editor_code_execution_tool_result_error`

Those variants are versioned provider detail, not stable cross-provider semantics.

### 3. Downloadable File Handles Stay Provider-Specific

The reference examples download code-execution output files through Anthropic file APIs using provider file IDs.

That matters because a provider file ID is not yet a common generated file object.

It is only a provider-native file handle.

## 2. Current `llm_dart` Status

The current shared architecture already has the right generic building blocks:

- `ToolResultEvent`
- `ToolUiPart`
- `CustomEvent`
- `CustomContentPart`
- `CustomUiPart`
- `GeneratedFile`
- provider metadata on prompt, result, stream, and UI layers

What is still missing is a frozen Anthropic-owned replay contract for execution result blocks.

Today:

- decode recognizes Anthropic execution result block families
- generic tool result content and events can carry the JSON-safe output
- replay-safe provider-owned custom parts now also exist for execution families through `anthropic.result.code_execution`
- legacy raw compatibility still keeps execution result blocks on fallback
- provider-native file handles can now be resolved through the typed Anthropic files API in `llm_dart_anthropic`

## 3. Core Boundary

The shared core should continue to own only the concepts that are already generic enough:

- tool invocation state
- tool output success vs error
- approval request / denial
- generic files when an actual `GeneratedFile` exists
- custom provider-owned payload channels

The shared core should not absorb:

- Anthropic execution subtype enums
- Anthropic file ID handles
- Anthropic execution transcript schemas
- Anthropic text-editor patch schemas

That data is still provider-owned.

## 4. Canonical Replay Kind

For the current Anthropic execution family, use one canonical provider-owned replay kind:

- `anthropic.result.code_execution`

Do not create separate persisted kinds for:

- `code_execution_tool_result`
- `bash_code_execution_tool_result`
- `text_editor_code_execution_tool_result`

Why one kind is better:

- the tool family is still `code_execution`
- Flutter renderers can branch once on the custom kind and then inspect the provider-owned payload
- prompt reconstruction only needs one stable replay path
- the exact Anthropic wire family can still be preserved inside the payload

The payload should therefore preserve block identity as data, not as the custom kind name.

## 5. Canonical Payload Shape

Recommended serialized payload:

```json
{
  "schema": "anthropic.execution.result.v1",
  "replayRole": "tool",
  "toolCallId": "srvtoolu_x",
  "toolName": "code_execution",
  "blockType": "bash_code_execution_tool_result",
  "block": {
    "type": "bash_code_execution_tool_result",
    "tool_use_id": "srvtoolu_x",
    "content": {
      "type": "bash_code_execution_result",
      "stdout": "done",
      "stderr": "",
      "return_code": 0,
      "content": [
        {
          "type": "bash_code_execution_output",
          "file_id": "file_123"
        }
      ]
    }
  }
}
```

Required rules:

- `block` is the replay source of truth
- `block` must preserve the exact Anthropic raw block shape
- `blockType` must match `block.type`
- `toolName` stays `code_execution`
- request re-encoding must depend on `block`, not on any UI summary

The payload should stay minimal on purpose.

Do not duplicate normalized summaries into the serialized replay payload unless replay or persistence proves that they are required.

## 6. UI Projection Rule

UI-friendly normalization should be computed by provider-owned helpers, not stored as the canonical replay payload.

That means:

- keep the persisted payload small and replay-faithful
- let `llm_dart_anthropic` offer helper parsers or view models for Flutter rendering
- keep generic Flutter widgets unaware of Anthropic execution subtypes

Recommended direction:

- generic UI still renders `ToolUiPart`
- provider-specific renderers may additionally inspect `CustomUiPart(kind: "anthropic.result.code_execution")`
- the custom UI part should be treated as the richer replay and rendering channel

## 7. File Handle Rule

Do not automatically convert Anthropic execution output file IDs into common `GeneratedFile` objects.

Reason:

- file IDs do not carry bytes
- file IDs do not carry stable download URIs
- file IDs do not carry guaranteed media types or filenames

Therefore:

- provider file IDs stay inside the provider-owned custom payload
- optional provider metadata may also repeat file-handle hints when useful
- actual `GeneratedFile` projection should happen only after an explicit provider-native file-resolution step

This keeps the core file model honest.

## 8. Capability Matrix

| Anthropic raw block family | Canonical custom kind | Generic `ToolResultEvent` / `ToolUiPart` | Common `FileEvent` projection | Legacy raw bridge | Notes |
| --- | --- | --- | --- | --- | --- |
| `code_execution_tool_result` with `code_execution_result` | `anthropic.result.code_execution` | yes | no, unless later resolved into a real file payload | fallback | preserve exact raw block |
| `code_execution_tool_result` with `encrypted_code_execution_result` | `anthropic.result.code_execution` | yes | no | fallback | encrypted stdout is provider-owned replay detail |
| `bash_code_execution_tool_result` with `bash_code_execution_result` | `anthropic.result.code_execution` | yes | no, file IDs stay provider-owned | fallback | downloads require Anthropic file APIs |
| `bash_code_execution_tool_result` with `bash_code_execution_tool_result_error` | `anthropic.result.code_execution` | yes | no | fallback | error subtype stays provider-owned |
| `text_editor_code_execution_tool_result` with `view` / `create` / `str_replace` / `error` result shapes | `anthropic.result.code_execution` | yes | no | fallback | editor patch payload stays provider-owned |

## 9. Dependency Direction

This contract reinforces the package dependency direction:

- `llm_dart_core` owns shared tool, file, and custom-part semantics
- `llm_dart_flutter` owns session persistence and prompt reconstruction
- `llm_dart_anthropic` owns execution payload parsing, replay encoding, and provider-native files APIs
- Anthropic file downloads remain provider-native APIs, not core abstractions

This is especially important because the file-resolution path will likely need provider-specific request headers, beta flags, and metadata handling.

## 10. Implementation Order

Recommended order:

1. freeze this payload contract
2. add typed provider-owned payload helpers in `llm_dart_anthropic`
3. emit `CustomContentPart` / `CustomEvent` / `CustomUiPart` with `anthropic.result.code_execution`
4. teach Anthropic request encoding to accept `CustomPromptPart(kind: "anthropic.result.code_execution")`
5. add session replay tests
6. add provider-native file-resolution helpers without promoting them into the shared file model
7. only then revisit legacy raw bridge policy

Current status:

- steps 1, 2, 3, 4, 5, and 6 are now implemented
- step 7 remains intentionally deferred

## 11. Review Rule

When reviewing an execution replay change, ask:

> Are we preserving exact Anthropic replay state, or are we only storing a UI-friendly summary that looks right but cannot drive the next request safely?

If the answer is “only a UI-friendly summary”, the replay design is still incomplete.
