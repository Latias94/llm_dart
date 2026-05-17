# Architecture Blueprint

## Summary

The provider/runtime/chat boundary work is already complete enough to be a
foundation, not a new target. The next fearless refactor wave should not reopen
the event split or package graph unless new alpha feedback proves a concrete
defect.

The useful `repo-ref/ai` lesson for the next wave is not package-count parity.
It is stronger ownership discipline:

- provider contracts stay small and stable
- AI runtime owns orchestration and full-run results
- chat consumes runtime/UI streams instead of becoming a second runtime
- provider-native features stay provider-owned
- shared utilities are extracted only after repeated, stable duplication

## Current State From Source Review

### Already In The Right Shape

The workspace already has the target dependency direction:

- `llm_dart_provider` owns provider-facing contracts and has no runtime
  dependency.
- `llm_dart_ai` depends on provider contracts and owns generation helpers,
  prompt normalization, tool loops, stream accumulation, structured output,
  and UI projection.
- `llm_dart_transport` owns Dio/SSE/HTTP primitives and does not own model
  orchestration.
- provider packages depend on `llm_dart_provider` and
  `llm_dart_transport`, not on AI runtime, chat, Flutter, root, or
  compatibility packages.
- `llm_dart_chat` consumes `llm_dart_ai`.
- `llm_dart_flutter` sits above chat.
- root `llm_dart` is a facade.
- `llm_dart_core` is a compatibility shell, not the real core.

This means the next wave should be selective. Broad package splitting would add
churn without improving the main architecture.

### Confirmed Durable Decisions

The following decisions should be treated as frozen unless alpha feedback
provides contrary evidence:

- `LanguageModelStreamEvent` is the provider model-call stream contract.
- `TextStreamEvent` is the AI runtime full-stream contract.
- `ModelMessage` is the app-facing prompt layer.
- `PromptMessage` is the advanced provider-facing prompt layer.
- `generateText(...)` and `streamText(...)` are the primary app-facing runtime
  helpers.
- `runTextGeneration(...)` and `streamTextRun(...)` are advanced run/step
  facades, not the default app path.
- typed provider options are the primary provider-specific input mechanism.
- `ProviderMetadata` is output observation and replay data, not request
  customization.
- chat state and persistence are separate from language-model runtime
  ownership.

## What To Preserve

### Dart-Native Provider Options

Do not replace typed provider options with a global untyped options map.

Typed options are one of the Dart library's strongest differences from the
TypeScript reference because they give discoverability, autocomplete, and
compile-time boundaries while still allowing provider-specific power.

The policy should stay:

- shared model behavior goes into shared request options only after repeated
  provider support is clear
- provider-specific behavior goes into provider-owned typed options
- very new provider API fields may use provider-owned raw fields
- raw fields must not live on root shared request types
- raw fields must define merge and conflict behavior inside the provider
  package

### Provider-Native Product Surfaces

Do not force files, assistants, responses lifecycle, moderation, voices,
catalogs, server tools, or code execution into shared APIs because one provider
supports them.

Keep them provider-owned until at least three providers expose the same durable
product shape with compatible semantics.

### Capability Profiles

Capability profiles are valuable for Dart apps because they allow UI gating and
runtime checks without flattening provider differences into weak shared enums.

Keep capability profiles as descriptive metadata. Avoid turning every profile
field into a mandatory shared model method.

## Next Breaking Line Candidates

### Candidate A - Root And Core Exit Strategy

Problem:

- root is now a facade and compatibility host
- `llm_dart_core` is a compatibility shell
- both names can still pull users back toward old mental models

Recommended posture:

- do not delete them before alpha feedback
- keep guards that prevent new implementation ownership
- collect import evidence from examples, docs, tests, and consumer feedback
- schedule removal or deprecation only when replacements are documented

Breaking work that can be planned later:

- remove or hard-deprecate root legacy entrypoints
- remove broad builder-era compatibility exports
- decide whether `llm_dart_core` remains a permanent migration package or exits
  in a major release

### Candidate B - Provider Utilities Evidence Pass

Problem:

- provider packages repeat some JSON, media, schema, provider-reference, and
  stream helper patterns
- extracting too early would create a public helper API before the stable shape
  is known

Recommended posture:

- first inventory duplication across OpenAI, Anthropic, Google, Ollama, and
  ElevenLabs
- classify each duplicate as provider-local, test-only, internal shared, or
  public utility candidate
- publish `llm_dart_provider_utils` only after at least two provider packages
  need the same stable helper contract

Good first extraction candidates:

- JSON-safe validation helpers
- media-type detection and normalization
- provider-reference resolution
- schema normalization
- warning construction helpers

Bad extraction candidates:

- transport clients
- provider-native lifecycle clients
- generic provider base classes
- broad request execution frameworks
- shared stream codecs that hide provider-native event semantics

### Candidate C - Provider Internal Directory Governance

Problem:

- provider packages have good boundary separation, but internal file layout is
  not consistent across packages
- OpenAI is especially broad because it covers chat completions, responses,
  files, assistants, image, speech, transcription, moderation, and compatible
  provider profiles

Recommended posture:

- do not split files just to make them smaller
- introduce a provider-internal directory convention when a provider package is
  next touched for real feature or bug work
- keep public barrels narrow
- keep request, stream, result, options, profile, and product-client
  responsibilities visible in paths

Suggested convention for large providers:

- `src/chat/`
- `src/responses/`
- `src/embedding/`
- `src/image/`
- `src/speech/`
- `src/transcription/`
- `src/files/`
- `src/moderation/`
- `src/profiles/`
- `src/internal/`

This should be applied incrementally. A whole-package path rewrite should wait
until there is a release-window reason because it can create unnecessary merge
and review noise.

### Candidate D - Modern Surface Documentation And Examples

Problem:

- source boundaries are stronger than the public story in some examples and
  docs
- users may still discover provider-facing prompt shapes or compatibility
  imports before the app-facing API

Recommended posture:

- default all common examples to `ModelMessage`, `generateText(...)`, and
  `streamText(...)`
- describe `PromptMessage` as an advanced provider-contract escape hatch
- document typed provider options beside provider examples
- keep migration recipes explicit for users coming from builder-era APIs

This is a high-value wave because it reduces support cost without destabilizing
the implementation.

## Recommended Order

1. Finish alpha handoff and post-publish smoke.
2. Record alpha feedback against concrete categories: release blocker,
   migration gap, docs gap, provider feature gap, or future refactor.
3. Improve docs/examples for the modern surface before removing compatibility
   trunks.
4. Inventory provider helper duplication and decide whether any utility
   extraction is justified.
5. Plan root/core deprecation or removal only after replacements and feedback
   are clear.
6. Apply provider internal directory governance opportunistically during
   provider feature or bug work.

## Stop Rules

Stop and re-evaluate if a proposed second-wave task:

- changes provider contracts to support one provider-specific feature
- adds runtime, chat, Flutter, or root dependencies to provider packages
- adds implementation code to root or `llm_dart_core`
- creates `llm_dart_provider_utils` with unstable or provider-native behavior
- duplicates an already completed runtime event split
- removes compatibility APIs before replacement docs and alpha feedback exist

## First Implementation Recommendation

The next implementation milestone should be documentation and evidence, not a
large code move:

1. add a modern-surface example/docs audit
2. add a provider helper duplication inventory
3. classify root/core compatibility usage

Only after those three artifacts exist should the wave choose a code-removal or
utility-extraction milestone.
