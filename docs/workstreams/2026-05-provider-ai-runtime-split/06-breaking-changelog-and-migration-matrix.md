# Breaking Changelog And Migration Matrix

## Goal

Turn the already-landed refactor slices into release-facing guidance:

1. a concise breaking changelog draft
2. a migration matrix for current public surfaces
3. a compatibility note for the remaining `llm_dart_core` shell

This document is not trying to invent a new architecture. It records the
breaking line that is already being assembled in code and tells users how to
move.

## Current Branch Status

The following slices are already landed on this branch:

- `llm_dart_core.dart` is now a compatibility barrel over focused entrypoints
- production consumers have moved to focused `llm_dart_core` imports
- the root `lib/core.dart` entrypoint exports focused sub-entrypoints instead
  of the old broad `llm_dart_core` barrel
- `example/06_mcp_integration` now declares local overrides for the full
  workspace package set it needs

## Suggested Breaking Changelog Draft

Use this as the starting point for the next explicit breaking release.

```md
## [next-breaking-release] - TBD

### Changed

- `package:llm_dart_core/llm_dart_core.dart` is now a compatibility barrel
  over focused entrypoints. New code should import
  `package:llm_dart_core/foundation.dart`, `model.dart`, `serialization.dart`,
  or `ui.dart` directly, or use `package:llm_dart/core.dart` for the modern
  facade.
- The root `package:llm_dart/core.dart` entrypoint now re-exports the focused
  contracts instead of the old broad `llm_dart_core` barrel.
- The MCP example package now depends on the full local workspace override set
  it actually uses, so it no longer relies on unpublished sibling packages
  resolving from pub.dev.

### Kept

- `llm_dart_core.dart` remains available as a compatibility shell during the
  breaking window.
- `packages/llm_dart_core/test` keeps broad imports as compatibility-shell
  coverage for now.

### Migration summary

- Replace broad `package:llm_dart_core/llm_dart_core.dart` imports with the
  focused entrypoint that matches the contract you need.
- Prefer `package:llm_dart/core.dart` for modern app code that only needs the
  stable facade.
- Keep test-only broad imports only where the compatibility shell itself is
  under test.
```

## Migration Matrix

| Current surface | New surface | Status | Notes |
| --- | --- | --- | --- |
| `package:llm_dart_core/llm_dart_core.dart` | `foundation.dart`, `model.dart`, `serialization.dart`, `ui.dart`, or `package:llm_dart/core.dart` | Compatibility shell | This is the main public import to shrink in the breaking line. |
| Root compatibility consumers that still used the broad barrel | Focused `llm_dart_core` entrypoints | Landed in production code | New code should not reintroduce the broad barrel as a dependency. |
| `packages/llm_dart_core/test` broad imports | Keep for compatibility coverage | Deliberately retained | These tests exercise the shell itself until the shell disappears. |
| `example/06_mcp_integration` path dependencies | Full local workspace overrides | Landed | The example must resolve all unpublished workspace siblings locally. |

## Compatibility Policy

- Keep the compatibility barrel for the breaking window only.
- Do not add new implementation ownership to the broad barrel.
- Keep test-only broad imports as legacy coverage until the shell is removed.
- Prefer focused entrypoints in docs, examples, and new code.

## Release Note Reminders

The release note should make the following points explicit:

- this is a breaking architecture line, not a routine patch release
- the new default surfaces are focused entrypoints, not the compatibility
  barrel
- provider-owned features still stay provider-owned
- examples that need unpublished workspace siblings should use local path
  overrides

