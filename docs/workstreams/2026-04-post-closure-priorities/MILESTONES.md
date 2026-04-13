# Milestones

## M1 - Public Boundary Alignment

Goals:

- make the post-closure public story easy to understand from the root README
  and package READMEs
- keep the modern path, compatibility path, and provider-owned helper story
  consistent across docs and examples

Acceptance criteria:

- the root README points to the new post-closure roadmap
- package READMEs do not imply that compatibility shells are the preferred
  modern entrypoint
- at least the highest-visibility examples and guides consistently distinguish
  `llm_dart.dart`, `legacy.dart`, and provider-owned package entrypoints

Current status:

- the earlier architecture workstream is closed
- the new phase is now explicitly scoped
- the next documentation pass still needs to propagate that closure story into
  public guidance

## M2 - Provider UI Extension Contract

Goals:

- keep shared UI models stable while making provider-owned rich rendering
  easier to consume
- document a repeatable provider pattern for custom parts, summaries, and
  optional message mappers

Acceptance criteria:

- the shared layer still does not absorb provider-specific JSON or render logic
- OpenAI- and Google-style provider-owned helpers are documented as the
  reference pattern
- any later shared registry remains additive and app-oriented rather than a new
  core requirement

Current status:

- `llm_dart_flutter` already shows the shared `ChatMessageMapper` plus
  provider-owned helper composition path
- Google and OpenAI already expose provider-owned custom-part and message
  mapping helpers
- Anthropic does not need symmetry-only UI helper expansion yet

## M3 - Dependency Guardrails And Compatibility Containment

Goals:

- preserve the one-way workspace dependency direction
- keep transport concerns and third-party runtime dependencies localized
- keep the root package from regaining modern implementation weight

Acceptance criteria:

- package dependency rules are written down and easy to review
- runtime dependency ownership is explicit
- compatibility-only root areas are named so new modern work does not drift
  back into them

Current status:

- the current package graph is already much healthier than before
- implementation imports in `packages/` currently do not flow back into
  `package:llm_dart/...`
- the remaining work is now policy and enforcement, not a broad structural
  rewrite

## M4 - Selective Provider Expansion

Goals:

- revisit only the provider-specific expansions that still look justified after
  the boundary work is stable
- keep long-tail provider growth demand-driven instead of symmetry-driven

Acceptance criteria:

- each reopened provider-specific item has a concrete product or repeated
  integration reason
- no new shared-core widening is introduced only to support one provider
- deferred items stay explicitly deferred instead of becoming silent debt

Current status:

- Google streamed TTS still looks like the clearest provider-specific re-audit
  candidate
- OpenRouter and xAI broader expansion remain policy questions rather than
  active architecture blockers
