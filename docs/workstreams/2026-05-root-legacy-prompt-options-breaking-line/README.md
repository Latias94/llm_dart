# Root Legacy, Prompt, and Options Breaking Line

## Why This Workstream Exists

The previous SDK-aligned refactor waves gave `llm_dart` the right package
shape: provider contracts, AI runtime orchestration, transport, chat, Flutter,
focused provider packages, and a root facade are now separate areas of
ownership.

The remaining risk is the migration-era semantic surface:

- root legacy code is still large enough to shape architecture decisions
- app-facing prompts and provider-facing prompts can still be mixed in runtime
  helpers
- prompt input types still preserve request-side `ProviderMetadata` escape
  hatches
- provider replay is valuable but needs to be visibly separate from ordinary
  input customization
- structured text/object result helpers exist, but their long-term public
  direction should be frozen before a stable release line

This workstream is the next intentional breaking line. It should remove the
remaining ambiguity while preserving the Dart-first strengths that make the
library useful.

## Goal

See [GOAL.md](GOAL.md) for the canonical goal text.

## Target Architecture

- `llm_dart`
  - owns modern facade entrypoints and migration documentation only
  - does not own provider implementations, builder-era abstractions, model
    contracts, or compatibility runtime code
- `llm_dart_ai`
  - owns user-facing `ModelMessage` prompt ergonomics, normalization,
    validation, text generation, structured output, tool-loop orchestration,
    result facades, and UI projection
- `llm_dart_provider`
  - owns provider-facing contracts and normalized wire-neutral data structures
  - does not own UI, chat, runtime orchestration, transport, or concrete
    provider behavior
- provider packages
  - own provider wire codecs, typed provider settings/options, replay codecs,
    capability profiles, and native helper clients
  - keep provider-specific product features instead of flattening them into
    weak shared abstractions
- `llm_dart_transport`
  - owns HTTP, SSE, multipart, retry, diagnostics, cancellation, and transport
    error translation
- `llm_dart_chat` and `llm_dart_flutter`
  - adapt AI runtime results and UI projection without owning provider
    contracts or concrete provider implementations

## Non-Goals

This workstream should not:

- copy the Vercel AI SDK package count or TypeScript-specific type utilities
- reopen the completed provider/runtime/transport package split
- remove provider-native features just because they are not provider-neutral
- introduce a public provider-utils package before repeated provider code
  proves a stable contract
- preserve compatibility code that hides the new ownership model

## Documents

- [GOAL.md](GOAL.md)
  - Canonical goal text and completion definition.
- [TODO.md](TODO.md)
  - Executable checklist for implementation.
- [MILESTONES.md](MILESTONES.md)
  - Milestones, acceptance criteria, and current status.
- [01-scope-and-gap-audit.md](01-scope-and-gap-audit.md)
  - Initial gap audit that defines why this line exists.
- [02-breaking-decision-and-first-slices.md](02-breaking-decision-and-first-slices.md)
  - Frozen M1 breaking decision and the first implementation slices.
- [03-root-legacy-source-and-example-exit.md](03-root-legacy-source-and-example-exit.md)
  - Root legacy source deletion, OpenAI lifecycle migration, example rewrite,
    and guard state after the root exit slice.
- [04-metadata-and-replay-options-boundary.md](04-metadata-and-replay-options-boundary.md)
  - Request-side metadata removal, replay option migration, serialization
    rejection of legacy input metadata, and the new replay guard boundary.
- [05-prompt-surface-and-result-facade-freeze.md](05-prompt-surface-and-result-facade-freeze.md)
  - Final prompt-surface, structured-result facade, and provider-options
    freeze target for the remaining breaking-line work.
