# Phase Closure Status

## Goal

Record why the `2026-04-next-phase-alignment` workstream is now effectively
closed, what was actually achieved, what remains deliberately deferred, and
what should happen next only if real product pressure appears.

This note is not another design proposal.

It is the closure statement for the current phase.

## Closure Decision

As of 2026-04-17, the active, non-deferred goals of this workstream are
complete.

What remains open in `TODO.md` is intentionally deferred policy, not active
architecture debt.

That means the default decision after this document should be:

- do not reopen this phase just to keep refactoring
- do not chase further symmetry with `repo-ref/ai`
- do not expand shared abstractions without new evidence

## What This Phase Actually Finished

### 1. The Repository Boundary Model Is Now Clear Enough

The repository now has a stable high-level layering:

- `llm_dart_core` for shared specifications, result models, runner utilities,
  UI projection, and serialization
- `llm_dart_transport` for transport and protocol mechanics
- `llm_dart_chat` for framework-neutral session orchestration
- `llm_dart_flutter` for Flutter-facing adapters
- provider-owned packages for provider-specific request shaping, parsing,
  metadata, custom parts, and native APIs
- the root `llm_dart` package as a convenience facade plus compatibility host

This is already the important structural lesson from `repo-ref/ai` in a
Dart-first form.

### 2. Shared Core Concentration Was Hardened Without Premature Splitting

This phase did not split `llm_dart_core` into a pile of smaller published
packages.

Instead, it completed the more honest work:

- documented internal ownership groups
- added focused non-breaking entrypoints
- extracted repeated serialization support
- split the heaviest UI accumulator seam by projection responsibility

That means core concentration is now much more deliberate and much less
monolithic than before.

### 3. OpenAI Internal Structure Was Brought To A Truthful Steady State

The OpenAI family now has a much cleaner internal architecture:

- request encoding is separated from response decoding
- stream decoding is separated from request shaping
- repeated incremental parsing state is shared internally
- non-text models reuse a smaller support shell

This gives `llm_dart_openai` a clearer request / response / stream / support
shape without copying the reference repository's package granularity.

### 4. Capability Discovery Is Now A Proven Cross-Provider Pattern

The phase started by freezing a model-centric capability direction.

It now ends with that direction implemented and validated across the major
provider families:

- additive core capability descriptor types
- optional `CapabilityDescribedModel`
- provider-owned describers in `llm_dart_openai`
- provider-owned describers in `llm_dart_google`
- provider-owned describers in `llm_dart_anthropic`
- direct model-instance `capabilityProfile` exposure in those providers
- pure Dart and Flutter examples for capability-gated UI affordances

This is an important closure point:

- capability discovery is no longer only a design note
- it is no longer only an OpenAI proof of concept
- it is now a stable architectural pattern for the repository

### 5. Flutter And App-Facing Integration Guidance Is Stronger

This phase also completed the missing app-facing examples needed to make the
new capability boundary credible in real use:

- pure Dart capability-gated selection and fallback example
- Flutter Material capability-gated control demo
- provider-aware badges and fallback recommendations

That means the architecture is now validated not only at provider and core
layers, but also at the app-facing integration layer.

### 6. The Remaining Stream, Reader, And Diagnostics Questions Are Now Frozen

The late-phase follow-up audits also closed the last honest structural
questions that still looked tempting after the larger refactor work landed:

- the event/UI/message layering was re-audited against the latest
  `repo-ref/ai` and confirmed to already have the same three-layer shape
- the transport-neutral `TextStreamEvent -> ChatUiStreamChunk` projector now
  lives in shared core instead of only the HTTP adapter
- `readChatUiStream(...)` now has narrow additive step observation and
  validation hooks without widening shared events or growing session APIs
- `DefaultChatSession` and `ChatController` diagnostics ownership is now
  explicitly frozen below another lifecycle facade
- transport and provider diagnostics ownership is now explicitly frozen, so
  retry/timeout/reconnect tracing stays transport-owned while shared
  warnings/finish/response identity stay in shared result/event/message layers

This matters because it closes the last remaining "maybe add another shared
helper" pressure points without reopening the repository boundary model.

## What Stays Deliberately Deferred

The remaining unchecked TODO items are deliberate deferrals:

### 1. Shared Runner Expansion

Do not widen the shared runner with:

- `prepareStep`
- retry orchestration
- model fallback orchestration
- richer shared stop policy

unless repeated cross-provider product pressure appears.

### 2. More Package Splitting

Do not split more packages just because files are smaller in
`repo-ref/ai`.

Internal support extraction has already carried this phase far enough.

### 3. Legacy Removal

Do not remove compatibility surfaces without:

- a deliberate deprecation plan
- migrated examples and docs
- explicit downstream breakage acceptance

## Frozen Rules After Closure

The following rules should now be treated as the default architecture policy:

### 1. Keep The Shared Interface Small And Honest

Shared contracts should only cover the genuinely cross-provider subset.

Do not promote provider-specific behavior into shared core just because it is
useful for one provider.

### 2. Keep Provider-Native Value Provider-Owned

Provider-native value should continue to surface through:

- typed model settings
- typed invocation options
- provider metadata
- custom parts and custom events
- provider-native helper APIs

### 3. Keep Capability Discovery Descriptive, Not Authoritative

Capability profiles should answer:

- what the library believes about a concrete model
- what app code can use for UI or routing decisions

They should not be treated as a hard network guarantee.

Provider codecs still own final validation, warnings, and request rejection.

### 4. Prefer Reopen Triggers Over Refactor Momentum

Another refactor should happen only when at least one of these becomes true:

1. repeated bug-fix churn crosses the same boundary
2. repeated duplication reappears across providers
3. a new public API cannot be explained without leaking coupling
4. Flutter or app-facing integration needs a clearer stable seam
5. a deliberate deprecation plan makes old compatibility net-negative

If none of these is true, the boundary should remain closed.

### 5. Keep Diagnostics Layered By Ownership

Diagnostics should now stay split by the layer that actually owns them:

- common call diagnostics in shared result and stream models
- UI-facing merged metadata in `ChatUiMessage`
- reader-only observation and validation at the reader layer
- retry, timeout, request tracing, and reconnect inside transport
- provider-native detail in `ProviderMetadata` and provider-owned APIs

Do not collapse those into a new shared diagnostics facade unless repeated real
integrations prove one more cross-provider shape is actually needed.

## Recommended Next Route

After this closure point, the next route should be conservative.

### Good Next Work

- deliberate deprecation planning for legacy surfaces
- targeted provider-native improvements with real product demand
- app-facing documentation and migration clarity
- selective community-provider capability profile adoption only when it adds
  real user value

### Bad Next Work

- reopening this phase only because more symmetry is possible
- creating extra packages to imitate reference repository layout
- widening shared contracts before two providers actually justify them
- deleting compatibility layers just because modern layers now exist

## Bottom Line

This workstream is now closed in the way a healthy architecture phase should
close:

- the important boundaries are clearer
- the highest-value structural debt is reduced
- the next capability layer is implemented, not only designed
- the remaining open items are explicit policy deferrals, not vague debt

The correct default now is stability.

Reopen architecture only when product evidence justifies the cost.
