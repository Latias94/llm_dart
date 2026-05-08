# Provider And AI Runtime Split

## Why This Workstream Exists

The previous architecture workstreams made the package graph healthier and
closed many boundary debates. The repository is now ready for a more deliberate
breaking refactor instead of another compatibility-preserving cleanup pass.

The current transitional shape still has two large pressure points:

- `llm_dart_core` carries provider specifications, model runners, structured
  output helpers, UI projection, and serialization in one package.
- the root `llm_dart` package still hosts a large legacy and compatibility tail
  through local builders, models, providers, and utility code.

This workstream turns the next refactor into an explicit product and package
architecture change.

## Goal

Move `llm_dart` toward a medium-grained architecture inspired by
`repo-ref/ai`:

- stable provider specifications
- AI runtime orchestration
- transport
- pure Dart chat runtime
- Flutter adapters
- provider-owned packages
- a thin root facade

The goal is not package-count parity with the reference repository. The goal is
ownership clarity while preserving Dart-specific strengths:

- typed provider model settings and invocation options
- model-centric capability profiles
- provider-native helpers for lifecycle, catalog, policy, and edit workflows
- OpenAI-family profiles for OpenRouter, DeepSeek, Groq, xAI, Phind, and other
  compatible providers

This architecture workstream is now in release-hardening handoff. The active
follow-up phase is:

- [`../2026-05-alpha-release-hardening/README.md`](../2026-05-alpha-release-hardening/README.md)
  - turns the completed breaking architecture split into a publishable
    `0.11.0-alpha.x` line through release gates, package metadata audits, clean
    consumer smoke validation, and publish sequencing

## Target Package Direction

Long-term package ownership should move toward:

- `llm_dart_provider`
  - stable model and provider specifications
  - prompt, content, stream, tool, provider option, provider metadata, file data,
    and provider reference contracts
- `llm_dart_provider_utils`
  - provider implementation helpers that do not own transport implementations
  - JSON normalization, provider-reference resolution, media-type helpers,
    schema helpers, warning helpers, and codec support
- `llm_dart_ai`
  - high-level generation runtime
  - multi-step text orchestration, tool execution loops, output parsing, stop
    policy, and stream result facades
- `llm_dart_transport`
  - HTTP, SSE, retry, cancellation, diagnostics, multipart, and Dio adapters
- `llm_dart_chat`
  - framework-neutral chat session and transport runtime
- `llm_dart_flutter`
  - Flutter-specific controllers and widgets
- provider packages
  - OpenAI, Anthropic, Google, community providers, and future providers
- root `llm_dart`
  - modern convenience facade plus explicit compatibility bridge while legacy
    removal is staged

## Scope

This workstream should:

- define the breaking target package graph
- split provider specification contracts away from AI runtime helpers
- move high-level generation orchestration out of the provider spec layer
- redesign shared file and tool-result data structures where the current shape
  mixes provider detail with shared semantics
- define how root compatibility code exits or becomes explicitly legacy-owned
- keep provider-native product value provider-owned instead of forcing it into
  common abstractions

## Non-Goals

This workstream should not:

- copy every package from `repo-ref/ai`
- widen shared stream events merely for reference parity
- move provider-native tools, files, moderation, voices, catalogs, or image
  editing into a common provider-neutral abstraction
- make `llm_dart_flutter` depend on concrete provider packages
- preserve legacy builder-era APIs as first-class design inputs
- introduce new public packages before their ownership and migration path are
  written down

## Success Criteria

The workstream is complete only when:

- the target package graph is documented and enforced by guard tooling
- provider spec contracts are separated from AI runtime orchestration
- provider packages implement the new spec layer without depending on the root
  package
- AI runtime helpers depend on provider specs rather than provider
  implementations
- the root package is a facade or explicit compatibility host, not an
  implementation dumping ground
- file data, provider references, provider options, provider metadata, and
  tool outputs have clear shared versus provider-owned boundaries
- migration documentation exists for modern apps and compatibility users

## Documents

- [00-priority-map.md](00-priority-map.md)
  - Ordered priorities for the breaking refactor.
- [01-reference-architecture-map.md](01-reference-architecture-map.md)
  - Useful lessons from `repo-ref/ai` and deliberate Dart differences.
- [02-target-package-graph.md](02-target-package-graph.md)
  - Target package ownership and dependency direction.
- [03-core-decomposition-plan.md](03-core-decomposition-plan.md)
  - How current `llm_dart_core` responsibilities should split.
- [04-data-structure-redesign.md](04-data-structure-redesign.md)
  - Shared file, provider reference, provider option, and tool output redesign.
- [05-root-legacy-exit-plan.md](05-root-legacy-exit-plan.md)
  - Root package and legacy compatibility exit strategy.
- [06-breaking-changelog-and-migration-matrix.md](06-breaking-changelog-and-migration-matrix.md)
  - Breaking changelog draft and migration matrix for the current slice.
- [07-release-readiness-checklist.md](07-release-readiness-checklist.md)
  - Release validation, publish dry-run expectations, and manual publishing
    checklist for the breaking preview.
- [MILESTONES.md](MILESTONES.md)
  - Milestones and acceptance criteria.
- [TODO.md](TODO.md)
  - Executable checklist.
