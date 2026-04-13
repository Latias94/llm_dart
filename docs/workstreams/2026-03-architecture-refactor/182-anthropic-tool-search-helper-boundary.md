# 182 Anthropic Tool-Search Helper Boundary

## Why This Decision Exists

One small Anthropic question remained open after the replay and tool-entry work:

- should Anthropic add extra provider-owned custom helpers for user-defined
  tool-search flows
- or is the current native-tool plus replay surface already enough for now

This matters because Anthropic tool-search is more provider-shaped than the
shared function-tool contract, but that does not automatically mean every
provider-shaped convenience should become a public helper.

## What Was Reviewed

Current Anthropic package-owned surfaces already include:

- provider-owned native tool declarations through `AnthropicTools`
- provider-owned `deferredToolNames`
- replayable `anthropic.result.tool_search` custom payloads
- request re-encoding support for `tool_search_tool_result`

Relevant files:

- `packages/llm_dart_anthropic/lib/src/anthropic_tools.dart`
- `packages/llm_dart_anthropic/lib/src/anthropic_options.dart`
- `packages/llm_dart_anthropic/lib/src/anthropic_messages_codec.dart`
- `packages/llm_dart_anthropic/lib/src/anthropic_result_codec.dart`
- `packages/llm_dart_anthropic/lib/src/anthropic_stream_codec.dart`

## Current Reality

Anthropic already has the important provider-owned building blocks for
tool-search flows:

- declaring tool-search native tools
- marking common function tools with `defer_loading`
- replaying tool-search results through `anthropic.result.tool_search`

That means the package already supports the core architectural contract needed
for:

- tool-search-enabled request shaping
- replay-safe follow-up turns
- Flutter or UI rendering through provider-owned custom parts/events

## Frozen Decision

Anthropic should **not** add extra provider-owned custom tool-reference helpers
for now.

The current provider-owned surface is enough:

- native tool declarations
- `deferredToolNames`
- replayable tool-search result payloads

Any extra helper above that would currently be convenience sugar rather than a
new architecture boundary.

## Why This Is Better

### 1. The real wire contract is already covered

The important provider-specific part is not missing anymore:

- the request can declare tool-search native tools
- the request can defer-loading selected common function tools
- the response can round-trip tool-search results safely

That is the structural work that mattered.

### 2. A helper would likely encode one product style too early

A custom helper would need to decide things like:

- how apps identify referenceable tools
- whether helpers target regex only, bm25 only, or both
- whether helper output is UI-oriented, request-oriented, or replay-oriented

Those are still app-specific choices, not stable package contracts.

### 3. It keeps Anthropic provider extras narrow

This repository is trying to avoid recreating a “provider convenience bus” in
the new package layout. The current typed native-tool and replay surfaces are
enough without adding another layer of opinionated wrappers.

## Allowed Current Surface

The intended current Anthropic tool-search path is:

- declare `AnthropicTools.toolSearchRegex20251119()` or
  `AnthropicTools.toolSearchBm2520251119()`
- optionally set `deferredToolNames`
- consume and replay `anthropic.result.tool_search` as needed

That remains the provider-owned modern surface.

## If We Revisit This Later

A future Anthropic tool-search helper should land only if:

- repeated real app usage shows the same orchestration pattern above the current
  primitives
- the helper would add stable value beyond declarations plus replay payloads
- the helper stays provider-owned and does not widen shared core contracts

## Non-Goals

This decision does not:

- remove current tool-search support
- remove `deferredToolNames`
- reduce replay fidelity for `tool_search_tool_result`
- rule out a future helper forever

## Conclusion

Anthropic tool-search is now frozen as:

- provider-owned declarations and replay payloads are enough
- no extra custom tool-reference helper is needed yet

That keeps the provider package narrower and avoids adding convenience APIs
before a stable product pattern is proven.
