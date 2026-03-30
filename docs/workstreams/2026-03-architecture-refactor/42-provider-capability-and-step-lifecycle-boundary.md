# Provider Capability And Step Lifecycle Boundary

## Goal

This note answers the next architectural question that appears after the event
audit:

> After comparing our design with `repo-ref/ai`, what is still missing from the
> architecture, and where should that missing complexity live?

The short answer is:

- the remaining maturity gap is not "more core event types"
- it is clearer provider-capability placement and a cleaner step-lifecycle API

## 1. What `repo-ref/ai` Actually Gets Right

After the current event and UI audit, the most useful lessons from the
reference codebase are not its exact TypeScript unions or package granularity.

The useful lessons are:

- keep the common model surface small
- keep provider-native features provider-owned
- expose richer orchestration through step-level APIs above the raw provider
  stream

This is why the reference feels mature:

- common text generation stays unified
- provider-native features still have explicit homes
- step callbacks and step results give applications a better orchestration hook
  than raw stream chunks alone

## 2. What We Should Copy Versus Not Copy

## Copy

- the separation between common model semantics and provider-native APIs
- the idea that richer lifecycle hooks can live above the raw stream boundary
- the rule that UI transport vocabulary must not automatically widen the shared
  provider stream model

## Do Not Copy Directly

- TypeScript-specific `tool-{name}` UI part unions
- schema-heavy UI-message validation in `llm_dart_core`
- the full UI chunk vocabulary as shared core events
- the very fine package split of the reference repository

Those patterns are useful in the reference stack, but they are not the best fit
for a Dart-first library that also wants clean Flutter integration.

## 3. Unified Capability Surface That Should Stay Stable

The current stable unified surface is already large enough for the primary
cross-provider use cases.

Keep unified:

- `LanguageModel`, `EmbeddingModel`, `ImageModel`, `SpeechModel`,
  `TranscriptionModel`
- `generateText`, `streamText`, `embed`, `embedMany`, `generateImage`,
  `generateSpeech`, `transcribe`
- shared prompt/content/stream/UI families for text, reasoning, reasoning
  files, tools, approvals, sources, files, and provider-namespaced custom parts
- shared `CallOptions`, `ProviderModelOptions`, and
  `ProviderInvocationOptions`
- Flutter chat/session boundaries such as `ChatSession`, `ChatTransport`, and
  `ChatUiMessage`

This means the common surface should keep owning:

- prompt replay
- tool-call and tool-result semantics
- shared streamed message semantics
- finish metadata, usage, warnings, and typed generic errors
- Flutter-friendly message and session projection

## 4. Provider-Native Capability Surface That Must Stay Provider-Owned

The following capability families should still stay outside the stable shared
spec:

- stored response CRUD and other provider-side conversation management APIs
- provider-native files, assistants, moderation, and admin APIs
- Anthropic MCP connector and provider-owned execution lifecycle APIs
- built-in provider tool families whose request, approval, or result semantics
  do not normalize cleanly
- provider-native search request controls
- provider-specific model catalogs, beta flags, and experimental toggles

The rule is simple:

- if a feature is provider-shaped, lifecycle-heavy, or only stable for one
  provider family, it should not enter the common core request model just
  because the reference SDK exposes it somewhere

## 5. Where Provider-Specific Features Should Go

The existing five-channel placement rule remains correct, but the reference
comparison makes the review rule sharper.

## 1. Typed Model Settings

Use for stable default behavior configured when a model instance is created.

Examples:

- OpenAI default Responses or chat-completions routing behavior
- Anthropic default thinking configuration
- Google default safety or modality configuration
- OpenRouter online-model shaping

## 2. Typed Invocation Options

Use for per-call provider controls.

Examples:

- OpenAI `previous_response_id`
- xAI `search_parameters`
- Anthropic call-scoped reasoning budget
- Google call-scoped modality or candidate options

## 3. Provider Metadata

Use for provider-owned returned detail that does not justify a shared top-level
field.

Examples:

- service tier
- provider status
- trace identifiers
- safety ratings
- cache metadata

## 4. Custom Parts And Custom Events

Use for provider-native output blocks that must survive rendering, replay, or
transport.

Examples:

- OpenAI Responses-specific replay blocks
- Anthropic execution result families
- Google grounding or provider-owned explanation blocks

## 5. Provider-Native APIs

Use for capabilities that are too provider-shaped to normalize honestly.

Examples:

- provider-native files APIs
- response store APIs
- MCP connector management
- provider-side moderation or admin endpoints

## 6. Built-In Provider Tools Need A Stricter Rule

The reference codebase makes one danger very visible:

- a provider-native tool family can look deceptively similar to common function
  tools while still having a very different lifecycle

For `llm_dart`, built-in provider tools should follow this stricter split:

### Shared Function Tools

Keep in the common request model only when the shape is truly common:

- declared function name
- object-rooted JSON schema
- model emits tool call input
- caller or provider produces tool result

### Provider-Native Tool Families

Keep provider-owned when any of the following is true:

- the provider owns the execution environment
- approval semantics are provider-specific
- result blocks are provider-native and not plain JSON tool output
- the tool also needs provider file handles, stored responses, or native
  lifecycle APIs

Examples:

- OpenAI computer-use or provider-built workflows
- Anthropic MCP and execution-oriented result families
- provider-defined search tools that are not just "shared citations out"

Those should use provider-native options or APIs plus custom parts and metadata,
not common `FunctionToolDefinition`.

## 7. Event Verdict After The Reference Comparison

The current event audit still holds:

- `TextStreamEvent` is already large enough for shared provider-stream
  semantics
- the remaining difference with `repo-ref/ai` is mostly lifecycle and callback
  ergonomics, not missing shared event families

That means:

- do not add more core event types to mirror UI transport chunk names
- do not add typed per-tool UI part subclasses to Dart core
- do not widen shared tool result types with provider-native execution payload
  variants

The current common event families already cover:

- text
- reasoning
- reasoning files
- tool input
- malformed tool input
- tool call
- tool result
- approval request
- denied output
- sources
- files
- finish and error semantics

## 8. The Real Missing Maturity Feature: Step Lifecycle APIs

The most useful thing that the reference still has above us is not another
event family.

It is a cleaner step-lifecycle surface:

- step start hooks
- step finish hooks
- richer synthesized step results
- final aggregated result hooks

That should not be solved by widening `TextStreamEvent`.

Instead, if we add that capability, it should live above the raw provider
stream, for example as optional orchestration callbacks around `generateText`
and `streamText` or in a dedicated higher-level runner.

Recommended direction:

- keep `TextStreamEvent` as the raw shared provider-stream boundary
- synthesize `StepResult`-style snapshots from existing events and request
  context
- expose optional lifecycle callbacks above that layer when the API is designed

Those synthesized step results should be built from existing common models such
as:

- replayable content parts
- shared tool calls and tool results
- sources and files
- finish reason and raw finish reason
- usage
- warnings
- response metadata
- provider metadata

## 9. What This Means For Flutter

Flutter chat integration should continue to center on:

- `ChatSession`
- `ChatTransport`
- `ChatUiMessage`
- `ToolUiPart`
- `DataUiPart`

It should not depend on future step-lifecycle callback APIs.

Why:

- Flutter chat UIs care about rendered message state and continuation flow
- step callbacks are more useful for orchestration, tracing, analytics, and
  advanced server-side control
- `DefaultChatSession` can keep projecting the existing stream model into UI
  state without needing a second orchestration abstraction

## 10. Recommended Next Implementation Slice

The next breaking-round implementation slice should be:

1. design a small `StepResult`-style shared model above the existing event
   surface
2. design optional step lifecycle callbacks above `generateText` and
   `streamText`
3. keep Flutter session APIs and provider stream codecs independent from that
   callback layer
4. keep provider-native capabilities provider-owned instead of using step
   callbacks as a new escape hatch

This is the correct next place to add maturity without re-coupling the core.

## Conclusion

After comparing our current architecture with `repo-ref/ai`, the conclusion is
stable:

- our shared event model is already sufficient
- our provider-capability placement model is already directionally correct
- the next meaningful improvement is a step-lifecycle API above the raw stream
  boundary
- the wrong move would be copying UI chunk exhaustiveness or provider-native
  tool families into the common core
