# Root Modern Entrypoint Slimming

## Goal

After `legacy.dart` became an explicit compatibility shell with its own export
list, the root `package:llm_dart/llm_dart.dart` entrypoint can finally stop
acting as a mixed modern-plus-compatibility barrel.

This note freezes the first real shrinking step.

## Problem

Before this step, `llm_dart.dart` still exported both:

- the stable modern model surface
- compatibility-era builders, legacy models, provider subclasses, and helper
  utilities

That meant the repository had an explicit `legacy.dart` shell on paper, but the
default root import still taught broad compatibility usage in practice.

## Decision

`package:llm_dart/llm_dart.dart` should now be a thin modern default entrypoint.

In this breaking round, it should re-export the same stable surface as:

- `package:llm_dart/ai.dart`

That means the root barrel keeps:

- the stable `AI` facade
- shared core types and helpers that already belong to the modern provider
  entrypoints
- provider-owned typed settings that are part of the stable migrated provider
  shells
- transport types already exposed through the modern provider path

It must no longer export:

- `ai()`
- `createProvider(...)`
- `LLMBuilder`
- builder config helpers
- legacy `ChatMessage` / `ChatCapability` compatibility models
- compatibility provider constructors and broad legacy utility exports

Those compatibility APIs now belong behind:

- `package:llm_dart/legacy.dart`

## Why This Boundary Helps

This makes the default import communicate the intended architecture:

- root import for modern stable model usage
- focused named entrypoints for explicit import style (`ai.dart`, `chat.dart`,
  provider entrypoints)
- `legacy.dart` for compatibility-era code

It also removes the last major reason examples or tests would keep treating the
default root barrel as the place where builder-era APIs still live.

## Non-Goals

This change does not mean:

- `llm_dart.dart` disappears
- `chat.dart` should be merged back into the root barrel
- compatibility APIs are removed from the repository entirely
- unmigrated community-provider compatibility surfaces become stable

## Status

This boundary is now implemented through:

- `lib/llm_dart.dart` shrinking to a thin modern re-export of `ai.dart`
- `lib/legacy.dart` carrying the compatibility surface explicitly
- root entrypoint tests that validate the modern surface only
- compatibility examples and tests importing `legacy.dart` instead of relying
  on the broad root barrel
