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
- the root README now points at the post-closure roadmap
- the highest-visibility package and example guides now consistently distinguish
  `llm_dart.dart`, `legacy.dart`, and compatibility-oriented builder material

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
- the runtime-observation boundary is now also re-audited more explicitly:
  transient data stays on side channels, step-finish stays reader-level, and
  reconnect stays transport-owned
- a shared renderer registry is now also explicitly deferred until repeated app
  integrations show the same composition pain

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
- lightweight enforcement now exists through
  `tool/check_workspace_dependency_guards.dart`, CI, and `melos analyze`
- root-package containment is now also enforced through
  `tool/check_root_package_boundary_guards.dart`, CI, and `melos analyze`
- the remaining Anthropic compatibility `request_builder.dart` has now also
  been re-audited and intentionally kept as one provider-local request codec,
  with no symmetry-only helper split kept as active debt
- the root Google image compatibility module has now had provider-local
  request/response shaping extracted into `google_image_support.dart`, keeping
  the public compatibility API stable while separating shell dispatch from
  codec logic
- the root ElevenLabs audio compatibility module now also keeps request
  shaping, voice mapping, and speech-to-text normalization in a dedicated
  `elevenlabs_audio_support.dart`, leaving the capability file focused on
  fallback routing and client dispatch
- the root ElevenLabs provider shell now also keeps bridge eligibility, codec
  translation, and bridge response normalization in a dedicated
  `elevenlabs_audio_bridge_support.dart`, leaving `shell_support.dart`
  focused on provider wiring and bridge-versus-fallback routing
- the root Ollama fallback chat path has now also been split into facade,
  request builder, stream parser, and response wrapper files, keeping the
  bridge-versus-fallback shell clearer without changing compatibility behavior
- the root OpenAI image compatibility module now also keeps generation/edit/
  variation request shaping and response parsing in a dedicated
  `openai_image_support.dart`, leaving the capability file focused on endpoint
  orchestration
- the root OpenAI assistants compatibility module now also keeps query
  shaping, clone/import request construction, assistant filtering, export
  shaping, and tool JSON parsing in a dedicated
  `openai_assistant_support.dart`, leaving `assistants.dart` focused on API
  orchestration
- the root Anthropic compatibility adapter now also keeps request planning,
  cache-policy merging, provider-options validation, and role-aware prompt
  conversion in a dedicated `anthropic_compat_support.dart`, leaving
  `anthropic_compat_adapter.dart` focused on bridge delegation
- the root OpenAI moderation compatibility module now also keeps request
  shaping, analysis/report helpers, and batch statistics logic in a dedicated
  `openai_moderation_support.dart`, leaving `moderation.dart` focused on
  endpoint orchestration
- the root OpenAI compatibility provider shell now also keeps capability-set
  policy and audio convenience helpers in `openai_provider_support.dart`,
  leaving `provider_compat.dart` more focused on capability wiring and
  delegation

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

- Google streamed TTS has now been re-triaged more precisely and remains
  deferred as a future provider-owned utility cluster rather than active
  migration debt
- OpenRouter has now been re-confirmed as an audited online-model subset case;
  broader search mapping remains deferred until a stronger wire contract exists
- xAI has now been re-confirmed as an audited live-search subset case; any
  broader tool, replay, or compatibility growth remains deferred until a
  narrower provider-owned contract is identified
- the selective-provider-expansion track is now closed for this phase, with
  deferred items explicitly documented as future provider-owned policy work
