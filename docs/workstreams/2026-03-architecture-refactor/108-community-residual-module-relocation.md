# 108. Community Residual Module Relocation

## What Changed

The remaining provider-shaped root modules for Ollama and ElevenLabs are now
relocated behind explicit compatibility-owned modules under:

- `lib/src/compatibility/providers/ollama/`
- `lib/src/compatibility/providers/elevenlabs/`

The public provider entry files now act as thin compatibility exports:

- `lib/providers/ollama/chat.dart`
- `lib/providers/ollama/completion.dart`
- `lib/providers/ollama/models.dart`
- `lib/providers/elevenlabs/audio.dart`
- `lib/providers/elevenlabs/models.dart`

The root provider shells now import those compatibility-owned modules directly
instead of treating the public residual entry files as their internal
implementation location.

## Why This Matters

This is the next ownership cleanup step after the shell-support extraction in
`106-ollama-shell-compat-helper-extraction.md` and
`107-elevenlabs-shell-compat-helper-extraction.md`.

Before this relocation:

- public root provider entry files still held large residual implementations
- root provider shells still depended on those public residual files as their
  internal module boundary
- the package looked more migrated from the outside than it really was inside

After this relocation:

- compatibility-owned implementation now lives under `src/compatibility`
- public root provider entry files are explicitly compatibility exports
- root provider shells are structurally closer to thin orchestration shells

## Ownership Clarification

This relocation does not claim that every remaining residual module should move
into `llm_dart_community`.

Instead it clarifies three different ownership buckets:

- shared-capability modern paths belong in `llm_dart_community`
- compatibility-only residual APIs belong under root compatibility ownership
- public root provider entry files should mostly expose those compatibility
  pieces, not host the implementation directly

That matches the architectural direction borrowed from `repo-ref/ai`: adopt the
ownership boundary, not the exact package granularity.

## What Did Not Change

This step is intentionally structural.

It does not:

- widen the shared modern API surface
- move Ollama `/api/generate` into the shared modern package
- move ElevenLabs voice, realtime, or admin APIs into shared audio models
- remove the root compatibility provider shells
- change the current fallback rules for legacy-only request shapes

## Remaining Work

The root shells are thinner, but migration is still incomplete.

The next meaningful questions remain:

- whether the remaining root builder/factory adaptation should stay as
  compatibility-only shell infrastructure
- whether file-based ElevenLabs transcription should remain legacy-only or gain
  a provider-owned modern helper
- whether additional event or metadata completeness gaps still block a cleaner
  migration boundary for community providers
