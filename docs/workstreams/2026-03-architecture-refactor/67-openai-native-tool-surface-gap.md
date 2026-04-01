# OpenAI Native Tool Surface Gap

## Purpose

This note narrows the remaining OpenAI Responses gap after the persistence subset landed.

The main question is no longer whether `store` or `conversation` belong in the shared core.

The next question is:

- which OpenAI-native tool families should `llm_dart_openai` expose as first-class provider-owned surfaces, and which ones should remain intentionally absent?

## Current `llm_dart_openai` Surface

The current public OpenAI-native tool declaration surface now includes:

- `OpenAIWebSearchTool`
- `OpenAIFileSearchTool`
- `OpenAIComputerUseTool`
- `OpenAIImageGenerationTool`
- `OpenAIMcpTool`
- `OpenAICodeInterpreterTool`

The current Responses codec also already handles some provider-originated output
families on decode or replay:

- `mcp_approval_request`
- `mcp_call`
- approval-response request replay
- unknown or less-modeled output items through `CustomContentPart` /
  `CustomEvent`

That means the package already has:

- provider-owned request-side declaration for the highest-value built-in subset
- provider-owned decode projection for richer OpenAI output items
- provider-owned replay for MCP approval responses

What it still does **not** have is the broader declaration and replay matrix
that exists in `repo-ref/ai`.

## What The Reference Exposes

`repo-ref/ai` currently models a much broader OpenAI Responses tool surface, including:

- `web_search`
- `web_search_preview`
- `file_search`
- `code_interpreter`
- `image_generation`
- `mcp`
- `local_shell`
- `shell`
- `apply_patch`
- `tool_search`
- provider-defined custom tool names

The reference also contains exact replay branches for several of those tool families when `store` is `true` versus `false`.

## Gap Classification

Not all of that should be copied directly.

The gap is best split into three groups.

### Group A: Selective Request-Side Provider Surface

The highest-value request-side provider surface has now already landed:

- `code_interpreter`

Why:

- it is clearly OpenAI-native
- it has obvious user-facing value
- it does not require widening the shared tool model
- it fits the existing provider-owned tool-entry direction

### Group B: Provider-Owned Output And Projection Helpers

These are not reasons to widen `TextStreamEvent`, and they now already justify
provider-owned helpers in `llm_dart_openai`:

- `image_generation_call`
- `response.image_generation_call.partial_image`
- `mcp_list_tools`

Why:

- the raw provider data is already visible or preservable
- the missing piece was ergonomic projection for Flutter or app code
- they fit better as provider-owned helper APIs than as new shared-core events

### Group C: Advanced Execution-Oriented Tool Families

These should stay provider-owned and probably remain deferred unless a concrete product need appears:

- `local_shell`
- `shell`
- `apply_patch`
- `tool_search`
- arbitrary custom OpenAI tool families

Why:

- they introduce execution-heavy replay policy
- they need exact provider-owned input/output contracts
- they do not map cleanly to the current shared Dart tool surface
- they are much closer to an agent runtime than to a normal chat SDK baseline

### Group D: Decode-Only Is Sufficient For Now

For some Responses output item families, decode-only projection is enough at the current stage:

- OpenAI-owned output items that can remain `CustomContentPart`
- OpenAI-owned stream items that can remain `CustomEvent`

That gives Flutter and app code visibility without forcing premature replay or shared abstractions.

## Recommended Direction

The next OpenAI tool step should follow this sequence:

1. decide which OpenAI-native tool families are actually part of the stable provider package surface
2. add typed provider-owned declaration APIs only for those selected families
3. add exact replay branches only after the declaration surface exists and preserved metadata is proven sufficient
4. keep advanced execution-oriented tool families out of the shared core and out of the default migration critical path

## What Should Not Happen

The project should not:

- copy the full `repo-ref/ai` tool matrix into Dart just for parity
- widen shared `ToolChoice` for OpenAI-native tool forcing
- add shared replay contracts for shell-like or patch-like tool families
- treat advanced agent-runtime tools as mandatory for the baseline Flutter chat integration

## Practical Near-Term Recommendation

The next OpenAI-specific decision is now narrower:

- whether the remaining advanced hosted execution families should simply stay
  deferred until a concrete product need appears
- or whether a future product need justifies one more provider-owned helper
  layer on top of already-decoded hosted-tool outputs

Either way is still better than cloning the reference package's shell, patch,
or tool-search execution surface.

## Bottom Line

The remaining OpenAI gap is no longer basic persistence policy, and it is no
longer just "should we add `image_generation` or `mcp`?"

The next gap is now mostly:

- a conscious decision to keep the remaining execution-heavy hosted-tool
  families out of scope for the stable package surface
- or a very narrow provider-owned helper addition if a concrete app needs one

That should still be solved selectively, not by mirroring every OpenAI
Responses tool family from `repo-ref/ai`.
