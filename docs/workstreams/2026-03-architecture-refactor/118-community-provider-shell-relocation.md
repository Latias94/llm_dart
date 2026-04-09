# 118. Community Provider Shell Relocation

## What Changed

The remaining root compatibility provider classes for Ollama and ElevenLabs are
now implemented under the root compatibility tree:

- `lib/src/compatibility/providers/ollama/provider_compat.dart`
- `lib/src/compatibility/providers/elevenlabs/provider_compat.dart`

The public root provider entry files now act as compatibility re-exports:

- `lib/providers/ollama/provider.dart`
- `lib/providers/elevenlabs/provider.dart`

## Why This Matters

The previous shell-support extraction removed bridge and fallback orchestration
from the public provider files, but those files still looked like the true
implementation home for the provider classes.

That was still structurally misleading:

- the public root provider files sat under provider directories
- the real architectural intent is that they are migration-era compatibility
  shells
- package-owned modern shared-capability logic already lives in
  `llm_dart_community`

Moving the shell implementations under `src/compatibility` makes that ownership
split explicit.

## Architectural Effect

This step does not widen the modern package surface.

It clarifies the three current ownership buckets:

- package-owned modern shared-capability logic stays in `llm_dart_community`
- root compatibility provider shells stay in the root package
- public root provider entry files expose compatibility shells instead of
  hosting their implementations directly

That is closer to the reference repository's structural lesson:

- keep public entrypoints narrow
- keep implementation ownership explicit
- avoid mixing migration compatibility with the package's long-term modern home

## What Did Not Change

This relocation is still a compatibility-structure step only.

It does not:

- close `TODO 157`
- move root compatibility interfaces into `llm_dart_community`
- migrate Ollama model listing or legacy completion into the modern package
- migrate ElevenLabs voice, realtime, or admin helpers into the modern package

## Why `TODO 157` Still Stays Open

The remaining blocker is not just file placement.

The root shells still depend on:

- root compatibility interfaces such as `ChatCapability` and `AudioCapability`
- root compatibility request and response shapes
- compatibility factory and config adaptation paths

So this step should be read as one more narrowing move, not as the final
community-provider decoupling milestone.
