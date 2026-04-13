# OpenAI Hosted-Tool Future Policy Closure

## Purpose

This note closes the last two remaining OpenAI future-policy TODOs around:

- richer Responses hosted-tool or custom item-family replay
- whether advanced hosted-tool families should remain deferred

The question is not whether OpenAI has more hosted-tool surface in the
reference repository.

The question is whether that tail should remain active migration debt in this
repository now.

## Current State

The current OpenAI package already covers the high-value provider-owned subset:

- `web_search_preview`
- `file_search`
- `computer_use_preview`
- `image_generation`
- `mcp`
- `code_interpreter`

It also already covers the highest-value current output/helper surface:

- `image_generation_call`
- `response.image_generation_call.partial_image`
- `mcp_list_tools`
- `mcp_approval_request` / `mcp_call` continuation projection

That means the current modern OpenAI package already owns the practical subset
that matters for the present workstream.

## Why The Remaining Hosted-Tool Tail Should Close

What remains is the execution-heavy tail:

- `local_shell`
- `shell`
- `apply_patch`
- `tool_search`
- broader hosted-tool replay families
- broader custom item-family replay

Those are not missing shared-core foundations.

They are optional provider-owned expansions that should reopen only under
concrete product pressure.

Keeping them as active TODOs suggests they are still on the critical path.

That is no longer true.

## Closure Verdict

These remaining OpenAI hosted-tool questions should now close as active
migration debt.

They remain valid future provider-owned policy questions, but they are no
longer current blockers.

## Reopen Threshold

These questions should reopen only if:

- a concrete product need requires one of the deferred hosted-tool families
- the exact provider-owned wire contract is clear enough to model honestly
- the addition can stay provider-owned without widening shared tool, replay, or
  runner contracts

Absent that, the correct default remains restraint.

## TODO Consequence

The workstream should therefore:

- close the remaining OpenAI hosted-tool future-policy TODOs
- keep the current package boundary frozen around the already-landed practical
  subset

## Bottom Line

The remaining OpenAI hosted-tool tail is now policy backlog, not migration
backlog.

That is the right place for it.
