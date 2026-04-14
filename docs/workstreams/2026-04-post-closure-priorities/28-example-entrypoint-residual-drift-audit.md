# 28 Example Entrypoint Residual Drift Audit

## Why This Note Exists

The previous documentation slice aligned the root and package READMEs with the
new mapper ownership and provider-owned composition helpers.

That still left one smaller question:

- do the layered `example/` READMEs teach the same story consistently
- or do some of them still imply outdated ownership or default entrypoints

This note records the follow-up audit so the remaining example hierarchy does
not quietly drift back toward the pre-refactor mental model.

## Scope

This slice audits documentation under `example/`.

It focuses on:

- README guidance drift
- stable versus compatibility entrypoint wording
- Flutter/chat UI mapping guidance

It does **not** change runtime code or remove intentional compatibility
examples.

## Findings

Three conclusions came out of the audit:

1. Most residual drift lived in README wording, not in the example source files.
2. Several compatibility-oriented provider directories were already correctly
   labeled and did not need churn just for symmetry.
3. The remaining gap was that the example hierarchy did not always repeat the
   now-frozen ownership model clearly enough:
   - `ChatMessageMapper` is shared and core-owned
   - `llm_dart_chat` and `llm_dart_flutter` own runtime/controller concerns
   - provider-specific UI inspection should prefer provider-owned
     `mapComposed(...)` helpers when available

## Decision

The example docs should now follow this policy:

1. keep intentional compatibility examples in place
2. label compatibility paths explicitly instead of silently modernizing them
3. teach mapper ownership from the shared core layer
4. recommend provider-owned composed mappers as the default richer UI path for
   OpenAI and Google
5. update README snippets when the old example text teaches the wrong default
   integration shape

## Files Aligned

This audit updated:

- `example/README.md`
- `example/01_getting_started/README.md`
- `example/02_core_features/README.md`
- `example/04_providers/README.md`
- `example/04_providers/openai/README.md`
- `example/05_use_cases/README.md`

This audit intentionally left compatibility-focused provider directories such
as Ollama and ElevenLabs unchanged because their current README guidance already
matches the post-closure boundary story.

## Acceptance Criteria

This slice is complete when:

- the top-level `example/` guide repeats the core-owned mapper story
- getting-started and core-feature guides no longer imply that runtime
  packages own message mapping
- provider guides recommend `mapComposed(...)` only as a provider-owned UI
  helper, not as shared-core behavior
- Flutter/use-case guidance points to `ChatController` + runtime packages for
  session control, while keeping message projection layered
- intentional compatibility directories stay explicit rather than being
  rewritten only for symmetry

## Bottom Line

This is a small but important documentation cleanup.

It keeps the example hierarchy aligned with the architecture we already chose:
stable shared projection in core, runtime orchestration in chat/flutter
packages, and richer provider-aware UI inspection in provider-owned helpers.
