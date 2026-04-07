# Example Entrypoint Import Alignment

## Goal

Now that `package:llm_dart/llm_dart.dart` has already shrunk to the modern
stable surface, examples should teach entrypoints according to API intent
instead of drifting between legacy compatibility and explicit aliases.

This note updates the example-import rule after the root-slimming round.

## Problem

The repository now has three distinct import categories:

- `package:llm_dart/llm_dart.dart`
- `package:llm_dart/ai.dart`
- focused capability or provider shells such as `chat.dart`, `core.dart`,
  `openai.dart`, `google.dart`, and `anthropic.dart`
- `package:llm_dart/legacy.dart`

Before the root barrel was slimmed, avoiding `llm_dart.dart` in examples helped
prevent the broad legacy surface from being taught by default.

After that shrink step, continuing to teach only `ai.dart` in quick-start and
high-visibility examples creates a new ambiguity instead:

- users see `llm_dart.dart` as the package-default import path
- examples keep implying that `ai.dart` is a different primary surface
- compatibility and modern guidance stop feeling clearly separated

## Decision

Examples should now follow these rules:

### 1. Default Modern Getting-Started Examples Use `llm_dart.dart`

Use `package:llm_dart/llm_dart.dart` for:

- README quick-start snippets
- first-step onboarding examples
- generic stable `AI.*(...).chatModel(...)` usage
- shared helper flows that do not need a narrower focused entrypoint

This makes the package-default import path match the package-default teaching
path.

### 2. `ai.dart` Stays Valid As An Explicit Equivalent Alias

Use `package:llm_dart/ai.dart` only when an example intentionally wants:

- an explicit named AI import style
- consistency with other focused root shells
- migration guidance that compares root and explicit modern aliases

Examples must not imply that `ai.dart` exposes a broader or different stable
surface than `llm_dart.dart`.

### 3. Focused Entrypoints Still Matter

Use focused entrypoints such as:

- `package:llm_dart/chat.dart`
- `package:llm_dart/core.dart`
- `package:llm_dart/openai.dart`
- `package:llm_dart/google.dart`
- `package:llm_dart/anthropic.dart`

when the example is specifically about pure Dart chat runtime concerns,
provider-owned options, or narrower stable ownership boundaries.

### 4. Compatibility Examples Still Use `legacy.dart`

Use `package:llm_dart/legacy.dart` when an example intentionally depends on:

- `ai()`
- `createProvider(...)`
- `LLMBuilder`
- legacy chat/config/value models
- compatibility-only root utilities or error types

## Why This Helps

This preserves the architectural lesson we want:

- the package-default root import is now safe to teach for modern stable usage
- `ai.dart` remains a supported explicit alias, not a second competing default
- focused entrypoints still communicate narrower ownership clearly
- compatibility guidance stays visibly separate through `legacy.dart`

That gives `llm_dart` a cleaner onboarding story while keeping the deliberate
modularity we adopted from `repo-ref/ai`.

## Non-Goals

This change does not mean:

- every example must import the root barrel
- focused provider or chat entrypoints should disappear
- `ai.dart` should be deprecated
- compatibility examples should be rewritten to hide legacy behavior

## Status

This alignment is now considered the target state for public docs and example
cleanup:

- README and getting-started examples should default to `llm_dart.dart`
- `ai.dart` should be documented as the explicit equivalent alias
- `legacy.dart` should remain the explicit compatibility teaching surface
