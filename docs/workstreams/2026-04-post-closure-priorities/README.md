# 2026-04 Post-Closure Priorities

## Background

The `2026-03-architecture-refactor` workstream is now closed as an
architecture-freeze and migration-closure phase.

That earlier phase answered the biggest structural questions:

- which interfaces should stay unified
- which provider features should stay provider-owned
- how the workspace should be split
- how Flutter-facing chat runtime boundaries should look
- which migration debts are real, and which should be deferred on purpose

The follow-up work is therefore narrower. The goal is no longer to keep
re-opening architecture. The goal is to turn the frozen boundaries into a
smaller, implementation-ready roadmap.

## Starting Point

As of 2026-04-13, the repository already has a much healthier baseline:

- workspace packages now follow a one-way dependency graph centered on
  `llm_dart_core` and `llm_dart_transport`
- `llm_dart_chat` and `llm_dart_flutter` already own the shared session/runtime
  split instead of mixing that logic into providers
- OpenAI and Google already expose provider-owned custom-part helpers and
  message-mapper helpers for richer UI rendering without widening shared models
- `llm_dart_community` remains one package on purpose, instead of copying the
  reference repository's finer package granularity
- the long tail of OpenAI-compatible providers is now mostly a policy question,
  not an active architecture blocker

## What We Still Borrow From `repo-ref/ai`

We should keep borrowing the reference repository's layering ideas:

- shared model contracts stay small and provider-neutral
- provider-specific capabilities stay provider-owned
- UI/runtime helpers sit above raw generation streams
- public guidance clearly distinguishes stable APIs from compatibility APIs

## What We Intentionally Keep Different

We should also keep the places where `llm_dart` intentionally diverges:

- do not copy the reference repository's package count
- keep a single `llm_dart_community` package for the current community-provider
  scope
- keep `llm_dart_chat` framework-neutral and let `llm_dart_flutter` stay thin
- keep the root package as a temporary compatibility shell until at least
  `1.0.0`, instead of forcing a premature removal pass

## Priority Tracks

### P0 - Public Boundary Alignment

The architecture is mostly frozen, but the top-level guidance still needs a
more explicit post-closure story:

- which imports are the default modern path
- which imports are compatibility-only
- which provider-owned helpers are the right choice for richer Flutter UIs
- which residual provider APIs remain intentionally outside the shared surface

### P1 - Provider UI Extension Contract

The next high-value design task is not more core events. It is a clearer
contract for how Flutter and other UI layers consume provider-owned custom
parts, summaries, and metadata.

This should keep:

- shared `ChatUiMessage` / `ChatUiPart` stable
- provider-owned custom part parsing inside provider packages
- richer message mapping outside `llm_dart_core`
- any later registry or composition helper additive and app-oriented

### P1 - Dependency And Compatibility Guardrails

The workspace dependency graph is in a good shape now. The next step is to make
that shape harder to accidentally regress:

- freeze which packages may depend on which other packages
- freeze where third-party runtime dependencies are allowed
- freeze the root package as a compatibility and facade layer, not a new modern
  implementation home

### P2 - Selective Provider Expansion

After the boundary work above is stable, the next provider-specific questions
can be re-triaged with a narrower lens:

- Google streamed TTS maturity
- any broader OpenRouter search mapping
- any xAI subset beyond the audited live-search path
- any provider-specific UI/render helpers justified by real repeated use

## Non-Goals

This phase should explicitly avoid:

- re-opening the frozen shared event model without concrete pressure
- splitting packages just to mirror `repo-ref/ai`
- extracting helpers for provider-family symmetry alone
- broadening the root compatibility layer with new modern implementation logic

## Document Index

- [00-priority-map.md](00-priority-map.md)
  - High-level priority ordering, why each item matters, and what should not be
    done next.
- [01-provider-ui-extension-contract.md](01-provider-ui-extension-contract.md)
  - Provider-owned custom part, summary, and message-mapper contract for
    Flutter and other UI layers.
- [02-dependency-direction-and-compatibility-guardrails.md](02-dependency-direction-and-compatibility-guardrails.md)
  - Verified package dependency direction, runtime dependency policy, and root
    compatibility-shell guardrails.
- [03-chat-runtime-observation-and-reconnect-policy.md](03-chat-runtime-observation-and-reconnect-policy.md)
  - Transient data, step-finish observation, final message patching, and
    transport-owned reconnect boundaries.
- [04-app-owned-renderer-registry-policy.md](04-app-owned-renderer-registry-policy.md)
  - Why a shared renderer registry is still deferred and what a future
    app-owned additive helper would need to look like.
- [05-google-streamed-tts-retriage.md](05-google-streamed-tts-retriage.md)
  - Why Google streamed TTS remains deferred, and how it should be split into
    narrower future provider-owned utility candidates if revisited.
- [06-openrouter-and-xai-retriage.md](06-openrouter-and-xai-retriage.md)
  - Why the audited OpenRouter online subset and xAI live-search subset are
    enough for this refactor round, and what would justify reopening them
    later.
- [07-event-surface-revalidation.md](07-event-surface-revalidation.md)
  - Why the current `repo-ref/ai` event/UI stream split still does not justify
    widening the shared `TextStreamEvent` model.
- [08-anthropic-request-builder-boundary-audit.md](08-anthropic-request-builder-boundary-audit.md)
  - Why the remaining Anthropic compatibility request builder stays one
    provider-local codec for now instead of being split again for symmetry.
- [09-google-image-compat-support-extraction.md](09-google-image-compat-support-extraction.md)
  - Google image compatibility support extraction that separates request and
    response shaping from the root compatibility image shell.
- [10-elevenlabs-audio-compat-support-extraction.md](10-elevenlabs-audio-compat-support-extraction.md)
  - ElevenLabs audio compatibility support extraction that localizes request
    shaping, response normalization, and STT fallback details.
- [11-ollama-chat-compat-thinning.md](11-ollama-chat-compat-thinning.md)
  - Ollama chat compatibility thinning that splits request shaping, stream
    parsing, and response wrapping out of the fallback chat shell.
- [12-openai-image-compat-support-extraction.md](12-openai-image-compat-support-extraction.md)
  - OpenAI image compatibility support extraction that localizes generation,
    edit, variation, and response parsing logic.
- [13-elevenlabs-shell-bridge-thinning.md](13-elevenlabs-shell-bridge-thinning.md)
  - ElevenLabs shell bridge thinning that separates bridge eligibility, codec
    translation, and response normalization from fallback orchestration.
- [14-openai-assistants-support-extraction.md](14-openai-assistants-support-extraction.md)
  - OpenAI assistants support extraction that separates API orchestration from
    local assistant utility shaping and parsing.
- [15-anthropic-compat-adapter-thinning.md](15-anthropic-compat-adapter-thinning.md)
  - Anthropic compatibility adapter thinning that separates request planning
    and role-aware prompt conversion from the bridge adapter shell.
- [16-openai-moderation-support-extraction.md](16-openai-moderation-support-extraction.md)
  - OpenAI moderation support extraction that separates moderation endpoint
    orchestration from local analysis and reporting helpers.
- [17-openai-provider-shell-support-thinning.md](17-openai-provider-shell-support-thinning.md)
  - OpenAI provider shell support thinning that moves capability policy and
    audio convenience helpers out of the root compatibility shell.
- [18-openai-completion-support-extraction.md](18-openai-completion-support-extraction.md)
  - OpenAI completion support extraction that separates completion endpoint
    orchestration from request parsing, presets, retry, batch, and token
    helpers.
- [19-openai-responses-support-extraction.md](19-openai-responses-support-extraction.md)
  - OpenAI Responses support extraction that separates non-streaming lifecycle
    and stateful-conversation orchestration from the public facade.
- [20-anthropic-chat-stream-support-extraction.md](20-anthropic-chat-stream-support-extraction.md)
  - Anthropic chat stream support extraction that separates SSE framing,
    stream event semantics, tool-use aggregation, and error mapping from the
    parser facade.
- [21-google-chat-message-codec-extraction.md](21-google-chat-message-codec-extraction.md)
  - Google chat message codec extraction that separates message, tool, and
    tool-choice payload encoding from request-body and generation-config
    shaping.
- [22-anthropic-prompt-cache-models-extraction.md](22-anthropic-prompt-cache-models-extraction.md)
  - Anthropic prompt-cache models extraction that separates message-builder
    cache helpers from the model-listing capability while preserving the
    legacy models export path.
- [23-anthropic-file-models-extraction.md](23-anthropic-file-models-extraction.md)
  - Anthropic file models extraction that separates Files API data models from
    the capability module while preserving the legacy files export path.
- [24-architecture-foundation-closeout-review.md](24-architecture-foundation-closeout-review.md)
  - Closeout review that classifies the remaining large compatibility files
    and recommends switching from size-driven slicing to feature-driven
    refactors.
- [25-openai-compat-stream-facade-alignment.md](25-openai-compat-stream-facade-alignment.md)
  - OpenAI compatibility stream-facade alignment that extracts duplicated
    stream orchestration out of `chat.dart` and `responses.dart` while keeping
    request builders and parsers separate.
- [TODO.md](TODO.md)
  - Open follow-up tasks for this phase.
- [MILESTONES.md](MILESTONES.md)
  - Phase milestones, checkpoints, and acceptance criteria.
