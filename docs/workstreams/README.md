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
  - Active planning workstream that inventories the remaining legacy root
    surface, defines deprecation policy and release windows, and sequences the
    migration away from compatibility-era helpers without dropping provider
    value or breaking users by surprise.
- [2026-05-provider-ai-runtime-split](2026-05-provider-ai-runtime-split/README.md)
  - Architecture-complete breaking-refactor workstream that split provider
    specifications from AI runtime orchestration, redesigned shared file/tool
    data boundaries, and moved the root package toward a thin facade while
    preserving typed provider options, capability profiles, provider-native
    helpers, and OpenAI-family profiles.
- [2026-05-alpha-release-hardening](2026-05-alpha-release-hardening/README.md)
  - Active release-hardening workstream that turns the completed architecture
    split into a publishable `0.11.0-alpha.x` line through repeatable guards,
    package tests, clean consumer smoke, publish dry-runs, and publish-order
    validation.
- [2026-05-modern-unified-interface](2026-05-modern-unified-interface/README.md)
  - Closed product-interface workstream that made the model-first API,
    dynamic model selection, object generation, and modern examples the
    preferred surface before compatibility builders.
- [2026-05-fearless-refactor-wave-2](2026-05-fearless-refactor-wave-2/README.md)
  - Active post-alpha planning workstream that freezes the second-wave order
    for alpha handoff, release gates, legacy/root/core containment, and
    evidence-based `llm_dart_provider_utils` extraction.
- [2026-05-ai-sdk-inspired-architecture-rewrite](2026-05-ai-sdk-inspired-architecture-rewrite/README.md)
  - Active fearless architecture rewrite workstream that turns the remaining
    semantic gaps versus `repo-ref/ai` into an implementation plan: user prompt
    normalization, metadata/options separation, provider utility
    consolidation, and root legacy exit.
- [2026-05-root-legacy-prompt-options-breaking-line](2026-05-root-legacy-prompt-options-breaking-line/README.md)
  - Active next breaking-line workstream for deleting or relocating root legacy
    implementation ownership, converging app-facing prompts on `llm_dart_ai`,
    removing ordinary request-side metadata inputs, and freezing provider
    options plus structured-result direction before a stable public line.
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
