# Community Package Granularity Policy

## Purpose

This note closes the remaining community-package granularity question:

- should Ollama and ElevenLabs already split out of `llm_dart_community` into
  dedicated provider packages
- or should the repository keep the current community package as the right
  granularity for now

## Current State

`llm_dart_community` is no longer an empty placeholder.

It already owns real modern provider surfaces:

- Ollama `chatModel(...)`
- Ollama `embeddingModel(...)`
- ElevenLabs `speechModel(...)`
- ElevenLabs `transcriptionModel(...)`

It also already follows the right dependency direction:

- depends on `llm_dart_core`
- depends on `llm_dart_transport`
- does not depend on the root `llm_dart` package

At the same time, the current package-owned surface is still compact:

- a small Ollama modern slice
- a small ElevenLabs modern slice
- one tiny shared utility/helper layer

That is not yet the shape of a package graph that obviously benefits from more
splitting.

## Why Splitting Now Would Be Premature

Splitting into `llm_dart_ollama` and `llm_dart_elevenlabs` right now would add
cost faster than it adds architectural truth.

### 1. It Would Not Solve The Remaining Root Compatibility Residue

The remaining root-owned weight is still mostly:

- compatibility shells
- builder/factory migration flow
- residual provider-owned APIs that are intentionally not part of the shared
  modern slice

Creating more provider packages would not remove those migration-era root
  responsibilities by itself.

So it would change package count more than it changes ownership truth.

### 2. It Would Increase Release And Maintenance Overhead

Extra packages mean more:

- package versions
- package changelogs
- package pubspec maintenance
- CI/test surface
- example and README synchronization
- dependency and export graph complexity

That overhead is only worth paying once the provider surface is large enough to
justify independent lifecycle management.

### 3. The Current Shared Community Package Still Has Real Cohesion

Ollama and ElevenLabs currently belong together in one practical category:

- community or niche providers
- smaller modern surface area than OpenAI/Anthropic/Google
- still partly surrounded by compatibility-era residual APIs at the root

The current package already expresses that category cleanly enough.

### 4. The Workstream Has Repeatedly Chosen Ownership Over Granularity

The reference repository is useful mainly for ownership discipline, not for
copying its exact package count.

That principle has already guided other decisions in this refactor:

- keep provider-native features provider-owned
- keep compatibility shells separate from modern surfaces
- do not mirror every reference-layer split mechanically

The same rule should apply here.

## Boundary Decision

The repository should keep `llm_dart_community` as the current package boundary
for Ollama and ElevenLabs.

In other words:

- do not split dedicated community-provider packages in this round
- keep growing the modern provider-owned surfaces inside
  `llm_dart_community`
- keep the root provider wrappers as compatibility-first shells where needed

## Reopen Threshold

Dedicated packages should only be reconsidered later if one or more of these
conditions become true:

- one community provider grows substantially beyond the current compact modern
  surface
- a provider needs an independent release cadence or dependency profile
- more community providers join and `llm_dart_community` stops feeling like a
  cohesive provider bucket
- the package starts carrying enough provider-specific helpers, codecs, and
  docs that independent discoverability clearly outweighs the extra package
  overhead

Absent that kind of pressure, more splitting would mostly be package noise.

## TODO Consequence

The workstream should therefore:

- close the open TODO about evaluating dedicated community-provider packages
- keep package-count reconsideration as a future policy question, not current
  migration debt

## Bottom Line

`llm_dart_community` is currently the right granularity.

It already gives the repository the ownership benefit that matters most:

- modern community-provider implementation weight lives outside the root
  compatibility package

Further splitting should wait until it solves a real problem, not just because
the reference repository uses finer package boundaries.
