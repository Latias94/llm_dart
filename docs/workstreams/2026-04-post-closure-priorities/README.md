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
- [TODO.md](TODO.md)
  - Open follow-up tasks for this phase.
- [MILESTONES.md](MILESTONES.md)
  - Phase milestones, checkpoints, and acceptance criteria.
