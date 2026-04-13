# OpenAI Migration Closure Audit

## Purpose

This note closes the old broad OpenAI migration umbrella at the current
workstream scope.

The goal is not to claim total feature parity with `repo-ref/ai`.

The goal is to answer a narrower question honestly:

- is OpenAI still a real architecture blocker for the Dart refactor, or are the
  remaining items now mostly explicit provider-owned policy decisions?

## What Used To Keep The Umbrella Open

The umbrella originally stayed open because several meaningful OpenAI-family
gaps were still unresolved at the same time:

- chat-completions request shaping was behind the reference on multimodal user
  inputs and provider-owned reasoning compatibility
- Responses replay preserved metadata but did not yet expose the main OpenAI
  persistence levers
- the provider-owned built-in tool surface had not yet reached the practical
  high-value subset
- the root compatibility route still needed clearer boundaries versus the
  modern package-owned path

That is no longer the current state.

## Current Landed OpenAI Surface

The current migrated OpenAI path now already includes the pieces that matter
for the modern architecture:

- chat-completions and Responses live in `llm_dart_openai` as real provider-
  owned codecs instead of remaining mostly in the root compatibility shell
- both text paths now align on provider-owned reasoning-model compatibility,
  including `systemMessageMode`, `reasoningEffort`, `forceReasoning`, and
  `serviceTier` gating
- the Responses persistence subset now already exists through typed
  `previousResponseId`, `store`, `conversation`, and `item_reference` replay
  branching without widening the shared core
- the request-side built-in tool surface now already covers the practical
  provider-owned subset:
  - `web_search_preview`
  - `file_search`
  - `computer_use_preview`
  - `image_generation`
  - `mcp`
  - `code_interpreter`
- the provider-owned output/helper layer now already covers the highest-value
  custom payloads that current apps are likely to consume first:
  - `image_generation_call`
  - `response.image_generation_call.partial_image`
  - `mcp_list_tools`
  - `mcp_approval_request` / `mcp_call` continuation projection
- the root OpenAI compatibility provider is now mainly a conservative bridge
  and residual shell over the audited modern subset rather than the primary
  implementation home

## What Still Differs From `repo-ref/ai`

The reference still has a broader OpenAI-hosted tool and replay matrix.

The notable remaining differences are now mostly in the execution-heavy tail:

- `local_shell`
- `shell`
- `apply_patch`
- `tool_search`
- broader provider-defined custom item/tool families
- richer exact replay for more hosted-tool item families when OpenAI storage
  semantics are involved

Those differences are real, but they do not all deserve equal architectural
weight.

## Why The Remaining Gap No Longer Blocks Migration

The remaining OpenAI delta is now mostly one of three categories.

### 1. Provider-Owned Hosted Execution Policy

Execution-oriented hosted tools are not normal shared chat-sdk baseline
features.

They require exact provider-owned contracts for:

- request declaration
- streamed output parsing
- continuation and approval semantics
- replay when `store` is true versus false

That belongs in provider-owned policy, not in the shared core.

### 2. Provider-Owned Ergonomic Helpers

Some future additions may still be worthwhile, but they would be additive
OpenAI helpers rather than architecture blockers.

Examples:

- one more provider-owned projection helper for a high-value hosted-tool output
- one narrowly-scoped continuation helper for a proven app use case

That kind of work should reopen only on concrete demand.

### 3. Conservative Replay On Chat-Completions

Chat-completions assistant replay remains intentionally narrow.

That is mostly alignment, not drift:

- assistant text replay is supported
- common function tool-call replay is supported
- common tool-result replay is supported
- provider-executed or multimodal assistant replay remains warning-dropped

Keeping that boundary explicit is healthier than pretending the shared prompt
model should absorb richer OpenAI-native replay semantics.

## Closure Verdict

The old broad OpenAI migration umbrella should now be treated as complete for
the current refactor scope.

What remains open is no longer “finish OpenAI migration” in the structural
sense.

What remains open is:

- whether a future product need justifies any extra OpenAI-hosted tool family
- whether any extra OpenAI-owned output helper is worth exposing
- whether any richer replay branch is justified by a concrete OpenAI-native
  continuation workflow

Those are future policy questions, not mainline migration blockers.

## TODO Consequence

The workstream should therefore:

- close the broad OpenAI migration umbrella item in `TODO.md`
- keep only the explicit future-policy items around hosted tools and richer
  provider-owned replay/helpers
- avoid reopening OpenAI as a general architecture blocker unless a concrete
  hosted-tool use case proves the current provider-owned subset insufficient

## Bottom Line

OpenAI is no longer one of the main structural drifts versus `repo-ref/ai`.

The modern package-owned OpenAI surface is already broad enough for the current
library direction, while the remaining differences are now mostly deliberate
restraint around execution-heavy provider-native features.
