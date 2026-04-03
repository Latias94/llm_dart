# Example Entrypoint Import Alignment

## Goal

Before shrinking the broad root `package:llm_dart/llm_dart.dart` surface any
further, example code should stop using that barrel as the default import.

This note freezes the import boundary for examples.

## Problem

The repository already has clearer public entrypoints:

- `package:llm_dart/ai.dart`
- `package:llm_dart/chat.dart`
- `package:llm_dart/legacy.dart`
- provider-focused shells such as `openai.dart`, `google.dart`, and
  `anthropic.dart`

If examples continue importing `package:llm_dart/llm_dart.dart` directly, they
keep teaching the broadest import path even after the architecture has already
split into:

- stable modern entrypoints
- pure Dart chat runtime entrypoints
- explicit compatibility entrypoints

That slows future root-barrel slimming because examples keep reintroducing the
idea that everything should come from one broad import.

## Decision

Examples should follow these rules:

### 1. Stable Modern Examples Use Focused Entrypoints

Use focused entrypoints such as:

- `package:llm_dart/ai.dart`
- `package:llm_dart/chat.dart`
- `package:llm_dart/core.dart`
- `package:llm_dart/openai.dart`
- `package:llm_dart/google.dart`
- `package:llm_dart/anthropic.dart`

This applies when an example is centered on:

- `AI.*(...).chatModel(...)`
- shared helper APIs such as `generateTextCall(...)`
- pure Dart chat runtime integration
- provider-owned typed settings in the new package split

### 2. Builder-Era Or Compatibility Examples Use `legacy.dart`

Use `package:llm_dart/legacy.dart` when an example intentionally depends on:

- `ai()`
- `createProvider(...)`
- builder-era `build*()` flows
- legacy `ChatCapability`
- legacy `ChatMessage`
- `MessageBuilder`
- compatibility-only provider helpers such as old root-package provider
  factories

### 3. Do Not Default To `llm_dart.dart` In Examples

The broad root barrel remains public during the migration window, but examples
should no longer treat it as the default teaching surface.

It may still stay in:

- explicit root-entrypoint tests
- migration documentation that compares old and new imports
- intentionally broad compatibility coverage

## Why This Helps

This keeps example guidance aligned with the architecture we already froze:

- focused modern usage teaches focused entrypoints
- compatibility usage teaches `legacy.dart`
- the root barrel can keep slimming without silently breaking example intent

This also matches the useful structural lesson from `repo-ref/ai` without
copying its package count: entrypoints should communicate ownership and API
intent clearly.

## Non-Goals

This change does not mean:

- every example must be rewritten to the stable `AI` facade immediately
- builder-era examples disappear before compatibility cleanup is done
- `package:llm_dart/llm_dart.dart` stops existing in the same patch

## Status

This alignment is now implemented for the remaining example files that still
needed builder-era or compatibility imports:

- they now import `package:llm_dart/legacy.dart`
- modern examples and README snippets continue to prefer focused entrypoints
- the next root-slimming round can focus on tests and export pruning instead of
  fixing example ambiguity first
