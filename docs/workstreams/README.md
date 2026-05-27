# Workstreams

- [2026-03-architecture-refactor](2026-03-architecture-refactor/README.md)
  - Closed architectural refactor phase that established the package split,
    shared capability surface, chat/runtime layering, and the frozen boundary
    against copying `repo-ref/ai` literally.
- [2026-04-post-closure-priorities](2026-04-post-closure-priorities/README.md)
  - Closed follow-up phase that aligned public guidance, dependency guardrails,
    provider-owned UI mapping, and Flutter chat/runtime validation.
- [2026-04-next-phase-alignment](2026-04-next-phase-alignment/README.md)
  - Closed next-phase planning workstream that re-baselined the remaining
    worthwhile gaps versus `repo-ref/ai`, completed model-centric capability
    discovery, and ended with an explicit closure/freeze decision.
- [2026-04-legacy-deprecation-planning](2026-04-legacy-deprecation-planning/README.md)
  - Closed historical planning workstream that inventoried the legacy root
    surface, defined deprecation policy and release windows, and prepared the
    first conservative breaking-preview removal slice. Current root legacy
    classification now lives in the Wave 3 architecture workstream.
- [2026-05-provider-ai-runtime-split](2026-05-provider-ai-runtime-split/README.md)
  - Architecture-complete breaking-refactor workstream that split provider
    specifications from AI runtime orchestration, redesigned shared file/tool
    data boundaries, and moved the root package toward a thin facade while
    preserving typed provider options, capability profiles, provider-native
    helpers, and OpenAI-family profiles.
- [2026-05-alpha-release-hardening](2026-05-alpha-release-hardening/README.md)
  - Closed local release-hardening workstream that turned the completed
    architecture split into a publishable `0.11.0-alpha.x` line through
    repeatable guards, package tests, clean consumer smoke, publish dry-runs,
    and publish-order validation; actual `pub publish` remains an explicit
    maintainer-approved external step.
- [2026-05-modern-unified-interface](2026-05-modern-unified-interface/README.md)
  - Closed product-interface workstream that made the model-first API,
    dynamic model selection, object generation, and modern examples the
    preferred surface before compatibility builders.
- [2026-05-fearless-refactor-wave-2](2026-05-fearless-refactor-wave-2/README.md)
  - Active post-alpha planning workstream that freezes the second-wave order
    for alpha handoff, release gates, legacy/root/core containment, and
    evidence-based `llm_dart_provider_utils` extraction; currently waiting on
    the maintainer release posture decision for `0.11.0-alpha.1`.
- [2026-05-fearless-refactor-wave-3](2026-05-fearless-refactor-wave-3/DESIGN.md)
  - Closed post-local-hardening refactor workstream that deepened chat session
    turn lifecycle, OpenAI-family option compatibility, provider fixture
    parity, serialization protocol families, and root legacy classification
    while preserving public behavior.
- [2026-05-core-seam-fearless-refactor](2026-05-core-seam-fearless-refactor/DESIGN.md)
  - Closed breaking architecture workstream that deepened the remaining core
    module interfaces across app-facing text generation requests, error
    taxonomy, stream vocabulary composition, provider descriptors, provider
    call execution, and app/provider-authoring entrypoints.
- [2026-05-remaining-boundary-fearless-refactor](2026-05-remaining-boundary-fearless-refactor/DESIGN.md)
  - Closed breaking architecture workstream for the remaining boundary
    candidates after the core seam refactor: provider codec contracts,
    capability enforcement, non-text request seams, chat transport protocol,
    provider options policy, and serialization registry posture.
- [2026-05-pre-release-boundary-freeze](2026-05-pre-release-boundary-freeze/DESIGN.md)
  - Closed pre-release boundary-freeze workstream for release ledger evidence,
    provider fixture coverage, app facade export contract, HTTP chat transport
    protocol policy, and OpenAI Responses projection ownership indexing.
- [2026-05-provider-implementation-kit-and-codec-boundaries](2026-05-provider-implementation-kit-and-codec-boundaries/README.md)
  - Active provider-internal architecture workstream that reduces large codec,
    request-builder, stream-parser, replay, and native-helper hotspots while
    keeping provider-native features provider-owned and delaying any public
    provider utility package until repeated stable duplication proves it.
- [2026-05-provider-options-seam-deepening](2026-05-provider-options-seam-deepening/README.md)
  - Closed provider-contract refactor that deepened the `llm_dart_provider`
    provider options seam by separating JSON bag transport, typed invocation
    options, prompt/tool options, replay options, and resolver policy while
    preserving the stable public provider contract.
- [2026-05-openai-family-policy-hub-split](2026-05-openai-family-policy-hub-split/README.md)
  - Closed provider-internal refactor that split the OpenAI family policy
    hub and compatibility bag monolith into feature-local modules while
    preserving typed options, profile-specific behavior, and the public
    `llm_dart_openai` facade.
- [2026-05-provider-fixture-contracts](2026-05-provider-fixture-contracts/README.md)
  - Active provider-owned fixture and golden contract workstream for request
    encoding, stream event projection, tool replay, and provider metadata.
- [2026-05-anthropic-fixture-contracts](2026-05-anthropic-fixture-contracts/README.md)
  - Active second-provider fixture baseline that applies the provider-local
    golden contract convention to Anthropic request encoding, replay, stream
    projection, reasoning, beta features, and provider metadata.
- [2026-05-ai-sdk-inspired-architecture-rewrite](2026-05-ai-sdk-inspired-architecture-rewrite/README.md)
  - Active fearless architecture rewrite workstream. Earlier phases completed
    user prompt normalization, metadata/options separation, provider utility
    consolidation, and root legacy exit; the reopened phase now tracks the
    provider-object registry, OpenAI-family decoupling, typed option policy,
    and the historical `llm_dart_core` posture.
- [2026-05-root-legacy-prompt-options-breaking-line](2026-05-root-legacy-prompt-options-breaking-line/README.md)
  - Closed breaking-line workstream that removed root legacy implementation
    ownership, converged app-facing prompts on `llm_dart_ai`, removed ordinary
    request-side metadata inputs, and froze provider options plus
    structured-result direction before a stable public line.
- [2026-05-runtime-event-tool-loop-boundary](2026-05-runtime-event-tool-loop-boundary/README.md)
  - Active next breaking architecture line for splitting provider model-call
    streaming from AI runtime full-stream orchestration, then freezing one
    Dart-native v2 surface for generation results, tool loops, structured
    output, UI projection, and chat transport.
- [2026-05-sdk-aligned-fearless-refactor](2026-05-sdk-aligned-fearless-refactor/README.md)
  - Closed breaking architecture workstream that turned the mature layering
    lessons from `repo-ref/ai` into enforceable Dart package boundaries while
    preserving `llm_dart` provider-native features, typed options, capability
    profiles, and the unified user-facing runtime.
- [2026-05-provider-contract-and-prompt-boundary-refactor](2026-05-provider-contract-and-prompt-boundary-refactor/README.md)
  - Active planning workstream for the next breaking boundary-hardening pass:
    non-text provider contracts use implementation-facing methods, prompt
    input customization moves out of `ProviderMetadata`, and root legacy
    compatibility stops shaping new architecture decisions.
- [2026-05-fearless-boundary-reset](2026-05-fearless-boundary-reset/DESIGN.md)
  - Closed fearless boundary-reset workstream that turned the Vercel AI SDK
    layering lessons into deeper Dart-native seams for OpenAI route/profile
    policy, provider transport execution, the removed `llm_dart_core` package,
    provider specification contracts, runtime stream vocabulary composition,
    and AI runtime helper request state.
