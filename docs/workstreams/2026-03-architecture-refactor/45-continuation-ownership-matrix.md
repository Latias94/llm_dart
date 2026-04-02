# Continuation Ownership Matrix

## Goal

This note freezes where multi-step continuation should live after the first
shared `GenerateTextRunner` slice landed.

The unresolved question is:

> Once a step ends with tool calls, approval requests, or other continuation
> signals, which layer should own the next move?

This matters because `repo-ref/ai` owns a broader loop in one JavaScript
runtime, while `llm_dart` is intentionally split across:

- `llm_dart_core`
- provider packages
- `llm_dart_flutter`
- app-owned orchestration

If we do not freeze this now, the new runner will quickly become another
coupling sink.

## Frozen Conclusion

- the shared runner owns only declared common function-tool continuation with
  an app-supplied executor
- if no shared executor is supplied, the runner stops honestly and returns the
  current step result
- approval-gated continuation stays outside the shared runner
- provider-executed built-in tool continuation stays provider-owned
- dynamic or schema-less tool continuation stays provider-owned or app-owned
- Flutter chat convenience stays in `llm_dart_flutter` and must reuse the same
  shared prompt/message primitives instead of inventing a second protocol

## 1. Why The Reference SDK Looks Broader

The reference SDK already owns a broad loop surface in one place:

- `stopWhen`
- `prepareStep`
- server-side `execute`
- approval-aware stop conditions
- deferred or dynamic tool handling

That is a coherent design there because the SDK controls the server-side tool
runtime and its surrounding orchestration contract.

`llm_dart` should copy the layering lesson, not the exact breadth:

- keep the low-level provider calls honest
- keep the shared runner narrow
- keep provider-native or session-native continuation where it actually belongs

## 2. Ownership Matrix

## Shared Runner

The shared runner owns only this continuation family:

- declared common function tools
- shared `FunctionToolDefinition`
- replayable assistant tool-call output through shared prompt/content models
- app-supplied execution through `functionToolExecutor`
- continuation by emitting shared `ToolPromptMessage` results

Why this is safe:

- the declaration shape is already frozen in `llm_dart_core`
- the result shape is still plain shared tool output
- no provider-native storage, files, or admin APIs are required
- the loop can be expressed entirely through shared prompt replay

## Caller-Owned Manual Stop

If the runner reaches `FinishReason.toolCalls` but no
`functionToolExecutor` exists, the shared runner should stop and return the
current run result.

Why:

- this preserves the honesty of the runner contract
- some applications want step snapshots and callbacks without automatic
  continuation
- the caller can still inspect `toolCalls` and continue through another layer
  if needed

## Provider-Owned Continuation

The shared runner should not own continuation for:

- provider-executed built-in tools
- provider-defined tool families that require provider file handles, stored
  responses, or execution environments
- provider-defined result payloads that do not map cleanly to plain shared tool
  output

Examples:

- OpenAI computer-use or provider-hosted workflows
- Anthropic MCP or execution-oriented native tools
- provider-native search tools whose lifecycle is not just "tool call in,
  JSON result out"

Why:

- the execution lifecycle is provider-shaped
- the replay path often needs provider-native data
- the tool family may depend on provider-owned APIs outside text generation

## Provider Or Session Owned Approval Flows

The shared runner should not own approval-gated continuation in v1.

That includes:

- tool approval requests that need an explicit user or policy response
- mixed steps where one tool waits for approval and another waits for local
  output
- provider-native approval protocols that are not reducible to one common
  runner callback

Ownership rule:

- provider packages own provider-specific approval wire details
- `llm_dart_chat` owns chat-session continuation timing for interactive
  approval and local tool output flows
- non-Flutter apps may implement approval handling above the shared runner, but
  not inside it

## Dynamic Or Schema-Less Tools

Dynamic tools should stay outside the shared runner for now.

That includes:

- schema-less MCP tools
- runtime-defined dynamic tools
- tool families whose stable input shape is not known at compile time

Why:

- the current shared tool boundary is intentionally object-schema-based
- dynamic-tool support would widen typing, replay, validation, and UI
  expectations together
- the reference SDK needs extra type-narrowing and UI vocabulary for this case,
  which is not a good phase-1 Dart core tradeoff

## Flutter Session Convenience

`llm_dart_chat` may continue to offer local convenience above the shared
runner boundary, such as:

- local tool registries
- automatic client-side tool callbacks
- step-completion logic that waits for all local outputs or approvals

`llm_dart_flutter` may then wrap that runtime with `ValueNotifier`-style UI
adapters when a Flutter app wants widget-facing state integration.

But that convenience must not:

- widen `TextStreamEvent`
- widen the shared function-tool definition model
- turn provider-native tool families into fake shared function tools

## 3. Promotion Criteria For Future Shared Runner Expansion

A continuation family may move into the shared runner later only if all of the
following become true:

1. the request-side declaration shape is already stable across providers
2. the step replay path fits the current shared prompt/content/result models
3. no provider-owned file, store, admin, or approval side channel is required
4. failure and completion semantics map cleanly to shared tool results and
   finish reasons
5. at least two provider families benefit without widening shared core event or
   UI vocabularies

If one of these conditions fails, the feature should remain provider-owned or
session-owned.

## 4. What This Means For The Current API

The current API direction should stay:

- `generateText` and `streamText` remain single-step helpers
- `GenerateTextRunner` remains the narrow shared multi-step layer
- `functionToolExecutor` stays explicit and app-supplied
- `maxSteps` remains a small guardrail, not a general policy engine
- there is still no shared `prepareStep`
- there is still no shared provider-built-in execute callback

## 5. What This Means For Provider Packages

Provider packages may still add richer orchestration, but they should do so
through provider-owned surfaces, for example:

- typed provider invocation options
- provider-owned helper APIs
- provider-owned higher-level runners if a provider family truly needs them
- provider-namespaced custom parts and metadata for replayable output

They should not push provider-native continuation semantics back into
`llm_dart_core` just because the reference SDK can express them in one runtime.

## 6. Recommended Next Step

The next runner-facing design question should be narrower:

- should the shared runner later add streaming orchestration
- should it add a constrained `prepareStep`-style mutation hook
- should it keep the current "stop honestly when unsupported continuation is
  reached" policy

Those are real shared-runner questions.

Approval-heavy flows, provider-built-in execution, and dynamic-tool families
are not the next shared-runner target.

## Conclusion

The ownership rule is now frozen:

- shared runner for common function-tool continuation only
- provider packages for provider-native continuation
- Flutter session for chat-oriented interactive continuation timing
- app-owned orchestration for everything else

That keeps the new runner useful without letting it become the next place where
all provider-specific complexity leaks back together.
