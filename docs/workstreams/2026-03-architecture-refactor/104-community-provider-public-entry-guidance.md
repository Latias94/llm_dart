# 104. Community Provider Public Entry Guidance

## Why This Exists

The architecture workstream already froze the ownership split for community
providers:

- shared-capability modern model surfaces belong in `llm_dart_community`
- broader provider-specific or compatibility-era APIs stay in root shells or in
  future provider-owned helpers

However, public-facing guidance was still lagging behind that decision.

The repository README and provider example READMEs still implied that Ollama and
ElevenLabs did not yet have a real modern path, which was no longer true after
the first package-owned community surfaces landed.

## Decision

Public guidance must now follow these rules:

1. Do not describe modern Ollama or ElevenLabs shared-capability surfaces as
   missing.
2. Present `llm_dart_community` as the modern workspace home for:
   - `Ollama(...).chatModel(...)`
   - `Ollama(...).embeddingModel(...)`
   - `ElevenLabs(...).speechModel(...)`
   - `ElevenLabs(...).transcriptionModel(...)`
3. Present root Ollama and ElevenLabs entrypoints as compatibility-first shells
   for broader provider-specific behavior.
4. Keep provider example directories honest:
   - if they use `package:llm_dart/legacy.dart`, say so explicitly
   - explain which provider-specific boundary the example is demonstrating
5. Do not widen the shared modern surface in documentation by implication:
   voice catalogs, realtime, admin endpoints, model listing, and legacy
   completion are still not shared-capability APIs.

## What Changed

The public-entry alignment now covers:

- root `README.md`
- `example/README.md`
- `example/04_providers/ollama/README.md`
- `example/04_providers/elevenlabs/README.md`
- compatibility-oriented provider example source-file headers
- a new `packages/llm_dart_community/README.md`

## Why This Matters

This is not only documentation cleanup.

If the repository keeps teaching the wrong entrypoint:

- contributors keep growing root compatibility shells as if they were the
  primary architecture
- users miss the real package boundary the refactor is trying to establish
- future migration work looks less complete than it actually is

Aligning the public entry story is therefore part of the refactor itself.

## Status

This public-entry guidance is now frozen:

- `llm_dart_community` is the documented modern shared-capability entry path for
  current community providers
- root Ollama and ElevenLabs surfaces are documented as compatibility shells
- provider example directories are documented as compatibility or
  provider-specific residual surfaces rather than missing-modern-surface
  placeholders

The remaining work is implementation cleanup, not entrypoint ambiguity.
