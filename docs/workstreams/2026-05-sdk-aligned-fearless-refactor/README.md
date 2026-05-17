# SDK-Aligned Fearless Refactor

## Why This Workstream Exists

The current package split already moved `llm_dart` closer to the layered shape
used by `repo-ref/ai`: provider contracts, AI runtime orchestration, transport,
chat, Flutter adapters, provider packages, and a root facade are now visible as
separate ownership areas.

The remaining risk is not lack of packages. The remaining risk is contract
ambiguity:

- provider contracts still expose user-facing names such as `generate` and
  `stream`, which makes direct provider calls look equivalent to AI runtime
  orchestration
- input-side provider customization can still be confused with output-side
  provider metadata
- provider packages can drift back toward runtime or UI dependencies when
  projection helpers are convenient
- shared generation options do not yet fully match the durable cross-provider
  knobs that modern LLM APIs now expect
- root and compatibility surfaces can still hide implementation ownership if
  release pressure is allowed to define the architecture

This workstream is the fearless breaking pass that tightens those boundaries.
It uses `repo-ref/ai` as a mature architecture reference, while deliberately
preserving the Dart-specific value in `llm_dart`.

## Goal

Deliver a breaking architecture line that is aligned with the stable lessons of
the Vercel AI SDK without copying it literally:

- provider specifications describe model capability and wire-neutral call
  semantics
- AI runtime packages own user-facing orchestration such as `generateText`,
  `streamText`, object generation, tool loops, stop policy, and result facades
- transport packages own HTTP, SSE, cancellation, retry, diagnostics, and
  multipart behavior
- chat and Flutter packages adapt runtime results without owning provider
  contracts
- provider packages implement model contracts and retain their native strengths
- the root package is a facade and explicit compatibility bridge, not an
  implementation home

## Reference Lessons From `repo-ref/ai`

The reference repository is useful because its architecture separates the
problem into durable layers:

- AI functions call model specifications instead of concrete providers
- model specifications use implementation-facing methods such as `doGenerate`
  and `doStream` so direct user calls naturally flow through runtime helpers
- user-facing prompts, model messages, language-model messages, and
  provider-specific wire messages are separate message layers
- provider options carry input-side provider customization
- provider metadata carries output-side provider observations and replay data
- provider implementations translate stable model contracts into provider wire
  formats
- provider utilities exist only when repeated provider implementation needs
  justify a stable helper boundary

The reference repository should not be copied package-for-package. TypeScript
type utilities, web stream conventions, and package count are not goals for
this Dart library.

## What To Keep From `llm_dart`

The refactor must preserve the features that make this library distinct:

- a unified Dart interface that works across providers
- typed provider model options and invocation options where Dart can offer
  better discoverability than untyped maps
- capability profiles for model-centric feature discovery
- provider-native helper clients for lifecycle, catalogs, files, moderation,
  voices, image editing, and other provider-specific product features
- OpenAI-family profiles for OpenRouter, DeepSeek, Groq, xAI, Phind, and other
  compatible providers
- framework-neutral chat/runtime packages and Flutter adapters that stay
  independent from concrete provider packages

## Target Architecture

The target architecture has these ownership rules:

- `llm_dart_provider`
  - owns stable provider-facing specifications, prompt/content contracts,
    model request/result shapes, stream events, usage, warnings, provider
    options, provider metadata, provider references, file data, and tool output
    contracts
  - must not depend on AI runtime, transport implementations, chat, Flutter,
    root, or concrete providers
- `llm_dart_ai`
  - owns user-facing text/object generation helpers, multi-step tool loops,
    stop policy, output parsing, result facades, UI projection, and shared
    runtime codecs
  - depends on provider specifications, not concrete provider packages
- `llm_dart_transport`
  - owns transport primitives and adapters
  - can be used by provider packages without pulling in AI runtime or root
    surfaces
- `llm_dart_chat`
  - owns framework-neutral chat session runtime and chat transport adapters
  - depends on AI/runtime contracts, not concrete providers
- `llm_dart_flutter`
  - owns Flutter controllers and widgets
  - depends on chat/runtime packages, not concrete providers
- provider packages
  - implement provider model contracts
  - may depend on provider specifications and transport
  - must not depend on AI runtime, chat, Flutter, root, or core compatibility
    packages at runtime
- root `llm_dart`
  - exports a modern convenience facade
  - hosts explicit compatibility bridges only when migration requires it
  - must not regain implementation ownership

## Core Breaking Decisions

This workstream should make these decisions explicit and enforceable:

- rename provider implementation methods from user-facing `generate`/`stream`
  style names to implementation-facing `doGenerate`/`doStream` style names, or
  an equally explicit Dart equivalent
- keep `generateText`/`streamText` and tool-loop orchestration in
  `llm_dart_ai`
- move input-side provider customization into typed provider options, with a
  raw escape hatch only where necessary
- keep `ProviderMetadata` for response-side metadata, observability, provider
  raw details, and replay information
- complete shared `GenerateTextOptions` coverage for durable model knobs such
  as presence penalty, frequency penalty, seed, reasoning, raw chunk inclusion,
  and any other shared option that is stable across providers
- keep provider-native product features provider-owned instead of forcing them
  into lowest-common-denominator shared abstractions
- enforce dependency direction with guards rather than relying on review memory

## Non-Goals

This workstream should not:

- copy `repo-ref/ai` package count or TypeScript-specific helper patterns
- remove provider-native functionality just because it is not provider-neutral
- promote every provider feature into common shared interfaces
- keep legacy builder-era APIs as first-class design inputs
- publish a new public utility package before repeated provider code proves a
  stable helper boundary
- preserve compatibility shims that obscure ownership after the breaking line
  has a documented migration path

## Success Criteria

The workstream is complete only when:

- provider contracts use implementation-facing method names and are no longer
  confused with user-facing AI functions
- provider packages have no runtime dependency on `llm_dart_ai`, chat, Flutter,
  root, or core compatibility packages
- user-facing generation helpers and multi-step orchestration live in
  `llm_dart_ai`
- provider options and provider metadata have separate, documented semantics
- shared generation options include the mature cross-provider knobs needed by
  current LLM APIs
- dependency guards reject boundary regressions
- migration documentation explains the breaking API changes with before/after
  examples
- package-local analysis and tests pass for provider, AI runtime, transport,
  chat, Flutter, root, and migrated provider packages

## Related Workstreams

- [`../2026-05-provider-ai-runtime-split/README.md`](../2026-05-provider-ai-runtime-split/README.md)
  - established the first provider/runtime split and target package graph
- [`../2026-05-modern-unified-interface/README.md`](../2026-05-modern-unified-interface/README.md)
  - made model-first APIs and modern helpers the preferred user surface
- [`../2026-05-fearless-refactor-wave-2/README.md`](../2026-05-fearless-refactor-wave-2/README.md)
  - froze the post-alpha order for release gates, legacy containment, and
    provider utility extraction criteria

## Documents

- [GOAL.md](GOAL.md)
  - Canonical goal text for this refactor.
- [TODO.md](TODO.md)
  - Executable checklist for the refactor.
- [MILESTONES.md](MILESTONES.md)
  - Milestones, acceptance criteria, and exit gates.
- [01-boundaries-and-migration.md](01-boundaries-and-migration.md)
  - Frozen provider/runtime/metadata boundaries and breaking migration recipes.
- [02-root-compatibility-freeze.md](02-root-compatibility-freeze.md)
  - Root facade, focused entrypoint, and legacy bridge retention policy.
- [03-runtime-ownership-audit.md](03-runtime-ownership-audit.md)
  - Runtime, object generation, UI projection, and codec ownership audit.
- [04-provider-utils-policy.md](04-provider-utils-policy.md)
  - Provider utility extraction deferral and provider-native helper policy.
- [05-package-graph-audit.md](05-package-graph-audit.md)
  - Runtime dependency policy and provider package graph audit.
- [06-completion-audit.md](06-completion-audit.md)
  - Final goal-to-evidence audit and validation command record.
- [07-structured-output-module-boundary.md](07-structured-output-module-boundary.md)
  - Post-closure structured output module split aligned with the reference
    output strategy and event shape.
- [08-text-call-result-runner-boundary.md](08-text-call-result-runner-boundary.md)
  - Text call result facade and runner glue split aligned with the reference
    text generation result layers.
- [09-stream-text-result-cancellation-boundary.md](09-stream-text-result-cancellation-boundary.md)
  - Stream text result facade and provider cancellation support split from the
    stream run loop.
- [10-generate-text-runner-support-boundary.md](10-generate-text-runner-support-boundary.md)
  - Generate text runner support split into public facade, tool execution, and
    prompt replay modules.
- [11-generate-text-result-accumulator-boundary.md](11-generate-text-result-accumulator-boundary.md)
  - Generate text result accumulator split into content buffering, tool
    projection, and lifecycle modules.
- [12-stream-text-runner-lifecycle-boundary.md](12-stream-text-runner-lifecycle-boundary.md)
  - Stream text runner lifecycle split into event emission, run state, and
    finish/error/abort closure modules.
- [release-readiness-report.txt](release-readiness-report.txt)
  - Full release-readiness gate result, including consumer smoke, publish
    dry-run, and pub.dev version availability.
