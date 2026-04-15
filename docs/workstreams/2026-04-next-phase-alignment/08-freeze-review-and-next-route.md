# Freeze Review And Next Route

## Goal

Close the current architecture-heavy phase honestly.

This note records:

- what is now structurally good enough
- what should stay frozen unless real pressure appears
- which large files are still large but architecturally honest
- which conditions should reopen a frozen hotspot
- what the next route should be after this phase

## Context

As of 2026-04-15, the repository has already completed the highest-value
structural work in this phase:

- the package graph is one-way and materially cleaner
- `llm_dart_core` now has explicit internal ownership groups and focused
  entrypoints
- `ChatUiAccumulator` has been split by projection responsibility without
  widening the shared event surface
- OpenAI text generation now follows a much clearer request / response / stream
  / internal-support shape
- OpenAI non-text models now reuse a small internal shell instead of repeating
  the same transport and validation scaffolding

That means the remaining question is no longer “what else can be split?”.

The remaining question is:

> what should now stay put until product evidence, repeated bugs, or repeated
> duplication prove that another refactor is worth the cost?

## What Is Structurally Good Enough Now

### 1. The Package Split Is Already Near The Right Granularity

The current package graph is already close to the right long-term shape for
`llm_dart`:

- `llm_dart_core` as the shared specification and runtime foundation
- `llm_dart_transport`, `llm_dart_chat`, and `llm_dart_flutter` as focused app
  and transport layers
- provider-owned packages for provider-specific behavior
- the root `llm_dart` package as a convenience facade plus compatibility host

The next phase should **not** chase package-count parity with `repo-ref/ai`.

### 2. The Unified Interface Boundary Is Clear Enough

The shared surface should continue to unify only the stable cross-provider
subset:

- prompts, messages, and streamed text events
- tool invocation at the shared semantic level
- structured output where the model contract is genuinely cross-provider
- common UI reconstruction and hydration behavior needed by Flutter chat apps

Provider-native capabilities should remain provider-owned unless at least two
providers expose the same behavior with similar semantics.

That keeps one of `llm_dart`'s core strengths intact:

- one coherent shared interface for the common path
- deliberate escape hatches for provider-native value

### 3. The OpenAI Text Path Is Now Clear Enough

Both OpenAI text request paths now converge on the same internal structure:

- thin top-level request assembly
- prompt / replay encoding
- request support helpers
- response decoding
- stream decoding

This is now much closer to the architectural honesty of `repo-ref/ai` without
copying its package layout literally.

### 4. `llm_dart_core` Is No Longer Carrying The Same Hotspot Risk

The most mixed `llm_dart_core` UI seam has already been narrowed:

- tool lifecycle projection
- text and reasoning lanes
- metadata projection
- output projection
- seed hydration
- data-part upsert behavior

remain behind one public facade while no longer living inline in a single
implementation file.

So the remaining concentration in `llm_dart_core` is now much more honest than
it was at the start of this phase.

## What Should Stay Frozen Unless Bugs Appear

The following areas should now stay frozen by default:

### 1. Shared Streamed Runner Scope

Keep the current boundary:

- no shared `prepareStep`
- no shared retry / model fallback orchestration
- no richer shared stop-policy layer

These additions should reopen only with repeated cross-provider product demand.

### 2. Shared Event Surface Completeness

Do not widen the shared event model just to mirror provider-native transport
details or `repo-ref/ai` internals.

The current event surface is good enough for common streaming, UI projection,
and chat restoration flows.

### 3. OpenAI Text Request-Path Structure

The OpenAI Chat Completions and Responses text request paths are now in a good
enough state. They should stay frozen unless:

- a bug repeatedly crosses the same internal boundary
- duplicated request-shaping logic starts growing again
- a new OpenAI text feature forces a genuinely different request family

### 4. Package-Count Symmetry With `repo-ref/ai`

Do not introduce extra published packages only to imitate:

- `@ai-sdk/provider`
- `@ai-sdk/provider-utils`
- narrower provider-internal folders as published Dart packages

The current internal support extraction is sufficient.

### 5. Legacy Compatibility Removal

Do not remove root compatibility or legacy surfaces only because newer focused
entrypoints now exist.

Legacy removal should reopen only after:

- a deliberate deprecation plan exists
- examples and package docs migrate first
- downstream breakage cost is understood

## Large Files That Are Still Large But Honest

As of 2026-04-15, several files are still large. Large size alone is not enough
reason to split them.

### OpenAI

- `packages/llm_dart_openai/lib/src/openai_responses_stream_decoder.dart`
  - about 604 lines
  - still one stream-decoding boundary
- `packages/llm_dart_openai/lib/src/openai_streaming_support.dart`
  - about 587 lines
  - still one shared incremental parsing infrastructure boundary
- `packages/llm_dart_openai/lib/src/openai_responses_support.dart`
  - about 541 lines
  - still one Responses compatibility and payload-support boundary
- `packages/llm_dart_openai/lib/src/openai_responses_prompt_encoder.dart`
  - about 515 lines
  - still one prompt and replay encoding boundary
- `packages/llm_dart_openai/lib/src/openai_native_tools.dart`
  - about 445 lines
  - still one provider-native tools boundary

### Core

- `packages/llm_dart_core/lib/src/model/output_spec.dart`
  - about 944 lines
  - still one structured-output specification boundary
- `packages/llm_dart_core/lib/src/serialization/text_stream_event_json_codec.dart`
  - about 641 lines
  - still one event JSON codec boundary
- `packages/llm_dart_core/lib/src/serialization/chat_ui_json_codec.dart`
  - about 464 lines
  - still one UI JSON codec boundary
- `packages/llm_dart_core/lib/src/model/generate_text_result_accumulator.dart`
  - about 395 lines
  - still one streamed-result accumulation boundary
- `packages/llm_dart_core/lib/src/common/partial_json.dart`
  - about 394 lines
  - still one partial-JSON parsing boundary

These files should be watched, not automatically split.

## Reopen Triggers

A frozen hotspot should reopen only when at least one of the following becomes
true:

1. the same file or boundary causes repeated bug-fix churn
2. the same logic is copied across at least two provider or capability paths
3. a new public API becomes hard to explain without leaking internal coupling
4. Flutter chat integration needs a simpler or more stable app-facing seam
5. a deprecation plan exists and the compatibility surface becomes net-negative

If none of these triggers appears, the default decision should be to leave the
boundary alone.

## Next Route After This Phase

The next route should be product evidence, not structural symmetry.

### Priority 1: App-Facing Value

Prefer new work only when it improves a real app integration path, such as:

- clearer Flutter chat integration seams
- more stable message hydration and restore behavior
- better capability discovery for app code choosing between models

### Priority 2: Provider-Native Value Without Polluting Shared Core

If provider-specific features keep growing, the next work should improve how
they are exposed and documented while keeping them provider-owned.

That could include:

- clearer provider-owned option groups
- more explicit provider capability docs
- better provider-native helper APIs that do not widen shared contracts

### Priority 3: Deliberate Deprecation, Not Accidental Deletion

If the root facade or older entrypoints become redundant, the next step should
be a documented deprecation track, not silent removal.

## Bottom Line

This phase is now structurally close to done.

The most important result is not another code split.

The most important result is a clearer rule:

> keep the shared interface small and honest, keep provider-native value
> provider-owned, and reopen architecture only when product evidence justifies
> the cost.
