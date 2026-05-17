# AI SDK-Inspired Architecture Rewrite

## Why This Workstream Exists

The current repository has already absorbed several durable lessons from
`repo-ref/ai`: provider contracts, AI runtime orchestration, transport,
framework-neutral chat, Flutter adapters, focused provider packages, and a
thin root facade now exist as separate ownership areas.

The remaining problem is not the package graph. The remaining problem is that
some semantic boundaries are still transitional:

- provider lookup is still factory-map based instead of provider-object based
- OpenAI-compatible provider profile policy is still concentrated in shared
  OpenAI-family resolver code
- user-facing prompt ergonomics and provider-facing prompt contracts are still
  mostly the same layer
- prompt input can still carry `ProviderMetadata`, even though metadata is
  documented as output-side provider observation
- AI runtime and provider serialization still duplicate JSON and projection
  helpers
- root legacy compatibility is still large enough to influence architecture
  decisions
- provider replay behavior is valuable but not yet isolated from ordinary
  input customization

This workstream is the next fearless breaking line. It uses the mature design
shape of Vercel's AI SDK as a reference architecture while preserving the Dart
library's own strengths.

## Goal

Deliver a deeper architecture rewrite that makes the semantic layers as clear
as the package layers:

- `llm_dart_ai` owns user-facing prompt shapes, prompt normalization, runtime
  validation, tool-loop continuation, output parsing, and result facades
- `llm_dart_provider` owns provider-facing model contracts and normalized
  provider prompt/data contracts only
- provider packages own provider wire codecs, typed provider options,
  provider-native replay, model profiles, and native helper clients
- shared implementation helpers move into a stable utility boundary only when
  duplication proves the boundary is real
- root `llm_dart` remains a modern convenience facade, while legacy
  compatibility gets an explicit removal or relocation plan

## Reference Lessons From `repo-ref/ai`

The reference repository is useful for boundaries, not for literal package
parity:

- user prompts are normalized into provider-facing prompts before model calls
- provider model methods are implementation-facing `do*` methods
- output metadata can be replayed as input provider options, but that conversion
  is explicit and owned by runtime helpers
- provider utilities are extracted around repeated provider implementation
  needs such as JSON, media, schema, request, stream, and error helpers
- provider-native features stay provider-owned instead of being flattened into
  weak common abstractions

## What To Preserve

The rewrite must keep the Dart-specific value that already exists:

- unified model-first runtime helpers across providers
- typed provider model settings and invocation options
- typed prompt-part options for provider-specific input controls
- model capability profiles
- OpenAI-family profiles for OpenRouter, DeepSeek, Groq, xAI, Phind, and
  future compatible providers
- provider-owned helper clients for files, moderation, images, speech,
  transcription, voices, catalogs, and provider product APIs
- framework-neutral chat runtime and Flutter adapters that do not depend on
  concrete provider packages

## Scope

This workstream should:

- introduce a user-facing prompt layer in `llm_dart_ai`
- normalize user prompts into provider-facing `PromptMessage` values
- add validation for missing tool results and invalid prompt transitions
- remove ordinary input-side use of `ProviderMetadata` from prompt parts
- define an explicit replay bridge from output metadata to provider prompt
  options where provider continuation requires it
- consolidate duplicated serialization and projection helpers
- decide whether the stable helper boundary is package-private or a published
  `llm_dart_provider_utils`
- sequence root legacy deletion, relocation, or final freezing
- update examples and migration docs around the new modern surface

## Non-Goals

This workstream should not:

- copy the Vercel AI SDK package count or TypeScript type patterns
- reopen the already completed provider/runtime/transport package split
- remove provider-native product features
- force every provider-specific option into shared common options
- publish a provider-utils package before its public contract is proven
- keep compatibility shims that obscure the new ownership boundary

## Success Criteria

The workstream is complete only when:

- user-facing generation helpers no longer require provider-facing prompt
  construction for common use cases
- provider-facing prompts no longer expose `ProviderMetadata` as ordinary
  input customization
- provider replay metadata is converted through explicit runtime/provider-owned
  replay helpers
- duplicated serialization helpers are consolidated behind one ownership
  boundary
- provider packages remain independent of AI runtime, chat, Flutter, root, and
  legacy compatibility
- root legacy surfaces have an explicit removal, relocation, or freeze outcome
- guard tooling prevents the old couplings from returning

## 2026-05 Provider/Registry Rebaseline

This workstream is reopened for the next fearless breaking line after the
prompt, metadata, utility, and root-legacy passes reached M7.

The new rebaseline keeps the completed package split and focuses on the
remaining object-model gap:

- add a first-class provider contract in `llm_dart_provider`
- replace or adapt `ModelRegistry` so dynamic lookup registers provider
  instances rather than independent per-capability factory maps
- make OpenAI-compatible provider profiles less centralized while preserving
  shared wire-code reuse
- standardize typed provider option composition, conflict detection, and
  profile-specific rejection
- keep `llm_dart_core` as a compatibility shell, not a new architecture owner

The detailed rebaseline is tracked in
[`08-provider-registry-and-openai-family-rebaseline.md`](08-provider-registry-and-openai-family-rebaseline.md).

## Documents

- [01-initial-gap-audit.md](01-initial-gap-audit.md)
  - Current gaps discovered after comparing the source with `repo-ref/ai`.
- [02-target-architecture.md](02-target-architecture.md)
  - Target semantic layers, package ownership, and deliberate Dart differences.
- [03-first-slice-plan.md](03-first-slice-plan.md)
  - Suggested first implementation slices and validation gates.
- [04-provider-utility-audit.md](04-provider-utility-audit.md)
  - M5 utility ownership audit and provider-utils publication decision.
- [05-root-legacy-export-inventory.md](05-root-legacy-export-inventory.md)
  - M6 legacy barrel export inventory and freeze policy.
- [06-example-compatibility-audit.md](06-example-compatibility-audit.md)
  - M6 example compatibility allowlist audit and default-path cleanup.
- [07-chat-input-boundary.md](07-chat-input-boundary.md)
  - Chat input closure note: new user input uses `UserModelMessage`, while
    chat history, transport payloads, and snapshots retain provider-facing
    `PromptMessage` replay state.
- [08-provider-registry-and-openai-family-rebaseline.md](08-provider-registry-and-openai-family-rebaseline.md)
  - New fearless rebaseline for first-class provider objects, provider-object
    registry lookup, OpenAI-family decoupling, typed option composition, and
    `llm_dart_core` posture.
- [09-openai-family-option-resolver.md](09-openai-family-option-resolver.md)
  - M9 implementation note for moving OpenAI-family option policy into a
    resolver strategy boundary while preserving shared wire-code reuse.
- [10-openai-family-facet-support.md](10-openai-family-facet-support.md)
  - M11 implementation note for profile-specific OpenAI-family model facet
    reporting in `ProviderRegistry`.
- [11-openai-family-capability-policy.md](11-openai-family-capability-policy.md)
  - M12 implementation note for moving OpenAI-family capability description
    policy behind a profile-owned seam.
- [MILESTONES.md](MILESTONES.md)
  - Milestones, acceptance criteria, and status tracking.
- [TODO.md](TODO.md)
  - Executable checklist for the workstream.
