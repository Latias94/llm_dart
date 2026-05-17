# Milestones

## M1 - Direction Freeze

Goals:

- freeze the purpose of this rewrite
- confirm that the existing package graph remains the base
- define which semantic boundaries change first

Acceptance criteria:

- README, gap audit, target architecture, first-slice plan, TODO, and milestones
  exist
- non-goals explicitly prevent package-count parity with `repo-ref/ai`
- prior completed workstreams are treated as inputs, not reopened debates

Current status:

- scaffold created

## M2 - User Prompt Layer

Goals:

- introduce user-facing prompt data in `llm_dart_ai`
- normalize user prompts into provider-facing `PromptMessage`
- keep provider-facing prompt contracts stable and implementation-oriented

Acceptance criteria:

- common runtime helpers accept the new user prompt shape
- provider codecs still consume normalized provider prompts
- direct provider prompt entrypoints are marked advanced or transitional
- prompt normalization is covered by tests

Current status:

- complete; `ModelMessage` is the user-facing prompt layer, provider-facing
  `PromptMessage` remains an explicit advanced path, runtime helper
  `messages:` inputs normalize into provider prompts, and prompt normalization
  tests have landed.
- chat input is now aligned with the same boundary: `ChatInput` carries
  user-authored `UserModelMessage` values, while chat transport payloads and
  snapshots keep provider-facing `PromptMessage` replay state.

## M3 - Runtime Prompt Validation

Goals:

- centralize user-prompt validation before provider calls
- catch missing tool results and invalid prompt transitions in AI runtime

Acceptance criteria:

- missing client-executed tool results fail before provider codecs run
- provider-executed tool calls are handled explicitly
- tool approval and denial semantics have tests
- provider codecs do not duplicate user-level validation

Current status:

- core complete; AI runtime validates prompt ordering, missing client tool
  results, provider-executed tool calls, and tool approval responses before
  provider calls, with root integration tests proving OpenAI, Google, and
  Anthropic codecs receive normalized prompts

## M4 - Metadata/Options Boundary

Goals:

- remove ordinary request-side `ProviderMetadata` usage
- keep output metadata as observation/replay data
- convert replay metadata through explicit provider-owned options

Acceptance criteria:

- prompt input customization uses provider options
- provider replay behavior remains tested
- request codecs do not read metadata as general request configuration
- guard tooling catches regressions

Current status:

- complete for the first replay-boundary pass; shared replay prompt options are
  available in the provider foundation, AI runtime continuations now carry
  replay metadata through those options, OpenAI Responses, Google, and
  Anthropic code execution replay accept both new replay options and legacy
  prompt metadata, and guard tooling covers the approved request-side replay
  helpers.

## M5 - Provider Utility Consolidation

Goals:

- consolidate duplicated serialization/projection helpers
- decide whether to publish `llm_dart_provider_utils`

Acceptance criteria:

- duplicated AI/provider JSON helper code is removed
- repeated provider helper code has one documented owner
- no utility package is published without a stable public contract

Current status:

- complete for the first utility consolidation pass; duplicated
  `SerializationJsonSupport` has been removed from `llm_dart_ai`,
  provider metadata namespace extraction is owned by
  `ProviderMetadata.namespace()`, OpenAI Responses and Google GenerateContent
  no longer carry duplicate namespace helpers, and the audit records that
  `llm_dart_provider_utils` should not be published until a stable
  provider-agnostic implementation contract is proven.

## M6 - Root Legacy Exit

Goals:

- classify root legacy exports
- delete, relocate, or freeze compatibility surfaces
- keep modern model-first APIs as the default public guidance

Acceptance criteria:

- every legacy export has a migration decision
- non-migration examples avoid `legacy.dart`
- root remains a facade under guard tooling

Current status:

- complete for the first root legacy exit pass; `legacy.dart` exports are
  inventoried with freeze, relocate-later, and delete-later decisions, the root
  package boundary guard freezes the legacy barrel directives, the
  delete-later `CompatWebSearchPresets` leaf has been removed, migration docs
  cover that removal, and example guards plus README cleanup keep
  compatibility APIs out of the default example path.

## M7 - Release Readiness

Goals:

- turn the architecture rewrite into a releasable breaking line

Acceptance criteria:

- guards pass
- focused package tests pass
- root compatibility tests reflect the final legacy decision
- migration docs and breaking changelog are ready
- publish dry-runs pass for affected packages

Current status:

- complete; the full release readiness gate passed on 2026-05-12, including
  workspace guards, analysis, workspace tests, package tests, consumer smoke,
  publish dry-run, and pub version availability checks. See
  `07-release-readiness-report.md`.

## M8 - Provider Object Model

Goals:

- add a first-class provider object contract to `llm_dart_provider`
- keep Dart capability facets explicit instead of copying TypeScript optional
  methods literally
- decide the compatibility posture for `ModelRegistry`

Acceptance criteria:

- provider facades can implement shared provider and model-facet contracts
- dynamic lookup can register provider instances rather than independent
  per-capability factories
- unsupported provider and unsupported model-kind errors are precise
- current model registry behavior is either migrated, adapted, or removed with
  migration notes

Current status:

- complete for the first provider-object pass; the provider foundation now has
  shared `Provider` capability interfaces, `ModelReference`, and a
  provider-object `ProviderRegistry` with focused tests. OpenAI-family,
  Anthropic, Google, Ollama, and ElevenLabs facades implement the relevant
  capability facets. `ModelRegistry` is retained as a low-level compatibility
  factory registry, with migration guidance pointing new dynamic lookup code to
  `ProviderRegistry`.

## M9 - OpenAI-Family Decoupling

Goals:

- preserve shared OpenAI-compatible transport and codec reuse
- move profile-specific option and model-id policy out of one central resolver
- keep OpenRouter, DeepSeek, xAI, and future compatible-provider options typed
  and provider-owned

Acceptance criteria:

- wrong-provider options fail before request encoding
- shared OpenAI options are limited to shared wire behavior
- profile-specific request shaping is owned by profile or provider strategies
- OpenAI-family route selection remains an implementation detail below the
  provider registry

Current status:

- complete for the first option-policy pass; OpenAI-family model-settings,
  invocation-options, shared response-format merging, wrong-provider rejection,
  and OpenRouter request-model-id shaping now live behind
  `openAIFamilyOptionResolverFor(profile)`. See
  `09-openai-family-option-resolver.md` for verification and remaining
  capability-reporting risk.

## M10 - Compatibility, Guards, And Migration

Goals:

- keep `llm_dart_core` frozen or give it a documented exit path
- update root facade guidance around provider-object registry usage
- add guard and test coverage for the new boundaries
- prepare migration docs for the breaking line

Acceptance criteria:

- no new architecture ownership is added to `llm_dart_core`
- provider packages remain independent from AI runtime, root, chat, Flutter, and
  compatibility barrels
- typed provider option precedence and conflict rules are documented and tested
- migration docs cover provider registry changes and the final `ModelRegistry`
  outcome

Current status:

- complete; root provider guidance and examples now teach
  `ProviderRegistry`, `llm_dart_core` remains a frozen compatibility shell,
  workspace/root/core boundary guards passed, and focused tests cover provider
  registry lookup plus OpenAI-family route/profile behavior.

## M11 - Profile-Specific Facet Reporting

Goals:

- close the OpenAI-family class-level capability reporting risk
- keep shared OpenAI-compatible wire-code reuse
- make `ProviderRegistry` respect provider-declared model facet support

Acceptance criteria:

- OpenAI-family compatible providers do not appear in unsupported non-text
  provider lists
- unsupported profile/model-kind lookups fail before model construction
- custom providers can declare narrower facet support than their concrete class
  methods imply
- migration notes document the more precise provider lists

Current status:

- complete; `ProviderModelFacetSupport` gives provider facades a narrow
  registry-facing facet declaration, `ProviderRegistry` respects it, OpenAI
  advertises all current OpenAI model facets, and OpenRouter, DeepSeek, Groq,
  xAI, and Phind conservatively advertise language-only support. See
  `10-openai-family-facet-support.md`.

## M12 - OpenAI-Family Capability Policy

Goals:

- move OpenAI-family capability description details behind a profile policy
- keep the public describer shape stable
- keep OpenAI-family capability confidence and provider-feature rules in one
  seam

Acceptance criteria:

- `openai_model_describer.dart` delegates family-specific capability policy
  instead of owning it inline
- OpenAI, OpenRouter, DeepSeek, and xAI capability descriptions remain covered
  by tests
- capability confidence differences are asserted in tests
- migration and change notes mention the new policy seam

Current status:

- complete; `openAIFamilyCapabilityPolicyFor(profile)` now owns the
  family-specific capability decisions for OpenAI, OpenRouter, DeepSeek, and
  xAI, while `openai_model_describer.dart` stays the public assembly point.
  See `11-openai-family-capability-policy.md`.
