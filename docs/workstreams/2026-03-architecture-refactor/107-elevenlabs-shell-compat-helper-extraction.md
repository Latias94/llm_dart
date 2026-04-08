# 107. ElevenLabs Shell Compatibility Helper Extraction

## What Changed

The root `ElevenLabsProvider` shell no longer keeps all modern-bridge helper
logic inline in `lib/providers/elevenlabs/provider.dart`.

That compatibility-specific glue now lives in:

- `lib/src/compatibility/providers/elevenlabs_compat_shell_support.dart`

The extracted support now owns:

- package-owned modern ElevenLabs bridge construction
- bridge eligibility checks for shared speech and direct-audio transcription
- shared speech request shaping into modern provider options
- direct-audio transcription request shaping into modern provider options
- response-mapping helpers back into legacy `TTSResponse` and `STTResponse`

## Why This Matters

This is the ElevenLabs counterpart to the Ollama shell-thinning step.

Before this extraction, `lib/providers/elevenlabs/provider.dart` mixed together:

- root compatibility shell orchestration
- modern community-model ownership
- bridge routing predicates
- request-option translation
- response metadata projection helpers

After this extraction, the provider file is closer to the intended role:

- a root compatibility shell
- a fallback owner for broader provider-specific audio APIs
- not the long-term home for modern bridge glue

## What Improved

The root ElevenLabs provider now has less direct dependency on modern bridge
implementation details:

- it no longer directly constructs the modern package-owned provider
- it no longer directly owns speech/transcription bridge helper methods
- it no longer directly owns the format and metadata mapping helpers used only
  by the compatibility bridge

Those details now live behind a dedicated root compatibility support module.

## What Did Not Change

This extraction is intentionally structural only.

It does not:

- widen the shared modern surface
- move realtime, voice-catalog, cloning, or admin APIs into
  `llm_dart_community`
- change the legacy fallback rule for file-based transcription
- remove the root compatibility shell

## Remaining Work

The remaining ElevenLabs decoupling work is still broader than this step:

- the residual root audio shell still exists
- the factory/config adaptation path is still root-owned
- root compatibility interfaces still shape the shell boundary

So this change should be read as ownership cleanup, not final migration
completion.
