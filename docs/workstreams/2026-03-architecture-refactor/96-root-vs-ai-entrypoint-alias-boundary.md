# Root Versus `ai.dart` Entrypoint Alias Boundary

## Goal

Freeze the relationship between the default root entrypoint and the explicit
`ai.dart` entrypoint so future documentation, tests, and package cleanup all
teach the same model.

## Problem

The refactor has already established these public entrypoints:

- `package:llm_dart/llm_dart.dart`
- `package:llm_dart/ai.dart`
- `package:llm_dart/chat.dart`
- `package:llm_dart/legacy.dart`

`llm_dart.dart` now re-exports `ai.dart`, which means the runtime surface is
already aligned. The remaining ambiguity is communicational:

- some docs still teach `ai.dart` as if it were the primary modern import
- other docs already describe `llm_dart.dart` as the default modern entrypoint
- tests still validate `ai.dart` mostly as an isolated surface instead of as an
  explicit alias of the root modern surface

If that ambiguity remains, users will continue to wonder whether:

- `llm_dart.dart` is broader than `ai.dart`
- `ai.dart` is the real stable API and the root barrel is temporary
- future breaking changes might diverge the two modern imports

## Decision

Freeze the boundary as follows:

### 1. `llm_dart.dart` Is The Default Modern Entrypoint

The default documented import for general modern usage is:

- `package:llm_dart/llm_dart.dart`

That is the onboarding path README and getting-started material should teach by
default.

### 2. `ai.dart` Is An Explicit Equivalent Alias

`package:llm_dart/ai.dart` remains public, stable, and intentionally supported,
but its role is now:

- an explicit named alias of the same modern stable surface
- a stylistic alternative when teams prefer import names that state intent
- a focused root shell that can coexist with other explicit entrypoints such as
  `chat.dart`

It is not a broader surface and should not drift semantically from
`llm_dart.dart`.

### 3. `legacy.dart` Owns Compatibility Expectations

Builder-era APIs and broad compatibility expectations belong behind:

- `package:llm_dart/legacy.dart`

Neither `llm_dart.dart` nor `ai.dart` should silently inherit compatibility
growth again.

### 4. Focused Entrypoints Still Express Narrow Ownership

The existence of a default root import does not remove the value of:

- `chat.dart` for pure Dart chat runtime usage
- provider entrypoints for provider-native typed options
- `core.dart` and `transport.dart` for explicit lower-level composition

The rule is:

- use the root default for general modern onboarding
- use focused shells when the narrower ownership boundary matters

## Why This Boundary Helps

This gives the package one stable story:

- beginners get the expected package-default import
- advanced users can still choose explicit named shells
- compatibility remains isolated
- future export pruning can happen without reopening the meaning of the two
  modern entrypoints

It also stays close to the spirit of `repo-ref/ai`: entrypoints should express
intent clearly, but the package should not fragment into unnecessary public
surfaces.

## Status

This boundary should now be reflected in:

- README import guidance
- getting-started examples
- root-versus-alias entrypoint tests
- workstream decisions and milestone text
