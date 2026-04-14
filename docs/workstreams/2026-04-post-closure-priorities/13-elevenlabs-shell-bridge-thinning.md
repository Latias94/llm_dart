# ElevenLabs Shell Bridge Thinning

## Why This Cut Was Worth Doing

`lib/src/compatibility/providers/elevenlabs/shell_support.dart` had become a
real mixed host.

It was doing two different jobs:

- root-compatibility shell orchestration
- modern-bridge request shaping and response normalization

That made the file harder to reason about than the provider shell actually
needs to be. The important boundary in this area is not "more files for
symmetry". The important boundary is:

- the shell decides bridge versus fallback
- a bridge-local codec translates legacy requests into community-model calls

This mirrors the same refactor principle we have been following elsewhere in
the compatibility layer: keep the public compatibility surface stable, but move
provider-local codec logic closer to its real ownership boundary.

## What Changed

Added:

- `lib/src/compatibility/providers/elevenlabs/elevenlabs_audio_bridge_support.dart`

Kept as the shell:

- `lib/src/compatibility/providers/elevenlabs/shell_support.dart`

The new bridge-support file now owns:

- TTS bridge eligibility checks
- STT bridge eligibility checks
- speech request option translation for the modern community provider
- transcription request option translation for the modern community provider
- bridge response normalization back into legacy `TTSResponse` and `STTResponse`

The shell now stays focused on:

- client and provider wiring
- bridge versus fallback routing
- residual provider-owned capability delegation

## Why This Boundary Is Better

This keeps `ElevenLabsCompatShellSupport` closer to a true shell.

It also makes the bridge path easier to evolve later if we need to:

- widen or narrow bridge eligibility rules
- support additional ElevenLabs provider-specific bridge options
- add bridge-only tests without touching fallback routing

Most importantly, it keeps the refactor honest:

- no new shared cross-provider abstraction
- no public compatibility API change
- no provider-family symmetry split for its own sake

## Validation

The refactor was validated with targeted checks:

- `dart analyze lib/src/compatibility/providers/elevenlabs/shell_support.dart lib/src/compatibility/providers/elevenlabs/elevenlabs_audio_bridge_support.dart lib/src/compatibility/providers/elevenlabs/provider_compat.dart`
- `dart test test/providers/elevenlabs/elevenlabs_provider_bridge_test.dart test/providers/elevenlabs/elevenlabs_audio_compat_test.dart`
- `dart run tool/check_workspace_dependency_guards.dart`
- `dart run tool/check_root_package_boundary_guards.dart`
