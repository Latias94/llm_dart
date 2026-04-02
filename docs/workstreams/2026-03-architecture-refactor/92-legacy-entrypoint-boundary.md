# Legacy Entrypoint Boundary

## Goal

After adding focused root entrypoints such as `ai.dart` and `chat.dart`, the
repository still needs one explicit place for migration-era broad-surface code.

This note freezes the boundary for that explicit compatibility import.

## Problem

Today, many examples, tests, and migration flows still depend on:

- `ai()`
- `createProvider(...)`
- broad legacy model exports
- compatibility builders and provider subclasses

If all of that remains implicitly attached only to `package:llm_dart/llm_dart.dart`,
the broad root barrel becomes difficult to slim later because compatibility code
has no separate landing zone.

## Decision

The root package should expose:

- `package:llm_dart/legacy.dart`

That entrypoint is the explicit compatibility shell for migration-era code.

During the migration window, it may mirror the broad legacy root surface.

## Intended Usage

Use `legacy.dart` when code still intentionally depends on:

- `ai()`
- `createProvider(...)`
- legacy builders
- legacy compatibility provider classes
- broad root re-exports that have not yet been migrated to focused entrypoints

Use focused entrypoints instead when code is already modernized:

- `ai.dart`
- `chat.dart`
- `openai.dart`
- `google.dart`
- `anthropic.dart`
- `core.dart`
- `transport.dart`

## Why This Helps The Root Refactor

This keeps two different concerns separate:

- modern app-facing focused entrypoints
- explicit compatibility imports

That separation matters because the long-term goal is not to grow the broad root
barrel forever. The long-term goal is to let `llm_dart.dart` keep converging
toward the focused modern surface while `legacy.dart` honestly carries the
compatibility burden.

## Non-Goals

This decision does not mean:

- `legacy.dart` becomes the recommended import for new applications
- new stable model APIs should be added to `legacy.dart` first
- `llm_dart.dart` must shrink immediately in the same patch

## Status

This boundary is now implemented through:

- `lib/legacy.dart`
- README guidance that distinguishes focused entrypoints from compatibility
  imports
- compatibility-oriented tests that can start moving to the explicit legacy
  barrel
