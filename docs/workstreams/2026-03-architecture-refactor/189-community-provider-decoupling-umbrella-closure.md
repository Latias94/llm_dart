# 189 Community Provider Decoupling Umbrella Closure

## Goal

Re-evaluate whether this broad TODO item should remain open:

- `Decouple Ollama and ElevenLabs from root-local compatibility imports before
  moving real implementation weight into llm_dart_community`

The question is not whether the root compatibility layer still exists.

The real question is:

- does that umbrella item still represent a concrete architecture blocker
- or has it become an over-broad container for work that is already either
  complete, intentionally residual, or tracked elsewhere

## What Was Reviewed

Earlier blocker notes identified four main categories:

1. root compatibility interfaces still define the shell shape
2. root compatibility bridge helpers still sit on the critical path
3. legacy config shaping and factory routing are still root-owned
4. residual provider-shaped APIs still live in root provider modules

Relevant references:

- `101-community-root-shell-thinning-plan.md`
- `105-community-provider-decoupling-blocker-inventory.md`

Current implementation state was then re-checked against the repository.

## Current Reality

### 1. Real implementation weight already moved into `llm_dart_community`

For the current shared-capability target, this is already true:

- modern Ollama chat lives in `llm_dart_community`
- modern Ollama embeddings live in `llm_dart_community`
- modern ElevenLabs speech lives in `llm_dart_community`
- modern ElevenLabs byte-oriented transcription lives in `llm_dart_community`

That means the original "before moving real implementation weight" condition is
no longer true.

The real implementation weight that belonged in the modern package has already
moved.

### 2. Root bridge logic is already localized as compatibility-only structure

The root provider entry files are now thin:

- `lib/providers/ollama/provider.dart`
- `lib/providers/elevenlabs/provider.dart`

The compatibility bridge orchestration now lives under:

- `lib/src/compatibility/providers/ollama/...`
- `lib/src/compatibility/providers/elevenlabs/...`

So the earlier blocker about root-local glue sitting inline inside provider
implementation files is already substantially resolved.

### 3. Residual root-owned APIs are now intentionally residual

The remaining root-owned Ollama and ElevenLabs APIs are now explicitly frozen
outside the shared-capability migration target:

- Ollama `/api/generate` completion
- Ollama model listing
- ElevenLabs file-path convenience transcription
- ElevenLabs voice/realtime/admin/model-account helpers

These are no longer ambiguous migration leftovers.

They are residual provider-owned or compatibility-only surfaces by design.

### 4. Root compatibility interfaces and builder/factory flow still remain

This part is still true:

- root compatibility interfaces still shape the old provider shells
- builder/factory/config compatibility flow is still root-owned

But this is no longer a blocker to the modern package boundary itself.

It is now simply part of the surviving compatibility shell during the migration
window.

That matters because the original umbrella TODO mixes two different concerns:

- "can the modern package own the real shared-capability implementation?"
- "has the root compatibility shell disappeared yet?"

Only the second one is still partially true, and that is not the same problem.

## Frozen Closure Decision

This umbrella TODO should now close.

## Why It Can Close

### 1. The blocker condition it described is no longer active

The repository is no longer blocked from moving real implementation weight into
`llm_dart_community`.

That move has already happened for the truthful shared-capability surface.

### 2. The remaining root-owned structure is compatibility-era residue, not
migration failure

The remaining root-owned pieces now exist for explicit reasons:

- old compatibility interfaces
- builder/factory migration shell
- residual provider-specific APIs that intentionally stay outside shared modern
  models

Those should not keep masquerading as one still-open decoupling blocker.

### 3. The remaining work is narrower and tracked elsewhere

The remaining meaningful open questions are already narrower than this umbrella:

- whether community providers should later split into dedicated packages
- whether any residual provider-specific helper deserves a future typed modern
  surface
- when broader root compatibility cleanup should happen during or after the
  migration window

Those should remain explicit small items rather than one large stale TODO.

## What This Decision Does Not Mean

Closing the umbrella item does **not** mean:

- the root compatibility layer is gone
- builder/factory migration shells are removed
- all Ollama and ElevenLabs APIs moved into `llm_dart_community`
- no more community-provider cleanup can ever happen

It only means the old umbrella statement is no longer the right way to describe
what remains.

## Conclusion

The broad community-provider decoupling umbrella is now outdated.

The truthful current state is:

- modern shared-capability implementation weight already lives in
  `llm_dart_community`
- root provider shells are already compatibility-first adapters
- residual provider APIs are already intentionally residual
- remaining work belongs to smaller explicit policy or cleanup items, not to
  one large blocker umbrella

So the umbrella TODO should close.
