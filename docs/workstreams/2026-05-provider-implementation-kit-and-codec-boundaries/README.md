# Provider Implementation Kit And Codec Boundaries

## Why This Workstream Exists

The provider/runtime/prompt/chat split is now release-ready locally. The next
architecture pressure is no longer the public package graph. It is the inside
of provider packages, where large codec and model files still mix request
encoding, response parsing, stream state machines, tool replay, provider-native
custom parts, and error mapping.

The reference `repo-ref/ai` repository is useful here because it keeps provider
contracts and runtime orchestration separate while also giving provider
implementations a focused utility layer. Its useful lesson is not package-count
parity. The useful lesson is smaller provider-owned modules plus narrow shared
helpers such as media-type detection, provider-reference resolution, schema
normalization, response handling, and streaming tool-call tracking.

This workstream applies that lesson to Dart without widening the unified API or
weakening provider-owned features.

## Goal

Create a provider implementation kit and codec boundary strategy that makes
provider packages easier to extend, test, and audit while preserving:

- the shared model-first API
- provider-owned typed options
- provider-native tools, files, catalogs, voices, lifecycle clients, and custom
  parts
- capability profiles and provider-specific feature discovery
- the hard dependency boundary where provider packages do not depend on
  `llm_dart_ai`, chat, Flutter, root, or compatibility packages

The workstream should reduce high-risk provider internals, not create a new
large abstraction that hides provider behavior.

## Scope

This workstream should:

- audit provider codec and model implementation hotspots
- split provider request builders, response decoders, stream parsers, tool
  replay helpers, and native custom-part projection into provider-owned modules
- identify repeated helpers that are stable enough for an internal provider
  implementation kit
- decide whether any helper duplication justifies a public
  `llm_dart_provider_utils` package after evidence exists
- add fixture and mock transport patterns that make provider behavior easier to
  test without network calls
- keep release readiness green after every slice

## Non-Goals

This workstream should not:

- change the public model-first runtime API by default
- remove root compatibility trunks such as `legacy.dart`, `LLMBuilder`, root
  provider constructors, or `createProvider(...)`
- publish `llm_dart_provider_utils` merely because the reference repository has
  a public `provider-utils` package
- turn OpenAI files, Anthropic files, Google files/caches, Ollama local catalog,
  ElevenLabs voices, moderation, assistants, or provider lifecycle APIs into
  provider-neutral abstractions without repeated product pressure
- introduce a shared base class that forces all providers into one request or
  streaming shape
- weaken provider package dependency guards

## Design Posture

Provider-owned complexity is acceptable when it reflects real provider
semantics. The target is not to make every provider file small. The target is
to keep each module honest about one reason to change:

- request builders change when provider request shapes change
- response decoders change when provider response payloads change
- stream parsers change when provider event protocols change
- replay helpers change when provider-native continuation semantics change
- public provider facades change when product APIs change
- shared helpers change only when multiple providers need the same stable
  non-transport contract

## Success Criteria

The workstream is complete when:

- the largest provider implementation hotspots have documented ownership
  boundaries
- at least the OpenAI Responses and one non-OpenAI provider codec have been
  split or explicitly retained with a written reason
- provider behavior is covered by fixture-based tests for request, response,
  stream, and replay behavior where applicable
- repeated helpers are either kept provider-local with rationale or moved into
  a named internal/public helper boundary
- no provider package gains a production dependency on AI runtime, chat,
  Flutter, root, or compatibility shells
- full release readiness passes after the implementation slices

## Documents

- [00-priority-map.md](00-priority-map.md)
  - Ordered priorities, stop conditions, and non-goals.
- [01-provider-codec-hotspot-audit.md](01-provider-codec-hotspot-audit.md)
  - First audit of provider implementation hotspots and reference lessons.
- [02-provider-implementation-kit-design.md](02-provider-implementation-kit-design.md)
  - Candidate helper boundaries and publication criteria.
- [MILESTONES.md](MILESTONES.md)
  - Milestones and acceptance criteria.
- [TODO.md](TODO.md)
  - Executable checklist for this workstream.
- [GOAL.md](GOAL.md)
  - Canonical goal statement for issue/PR planning.
