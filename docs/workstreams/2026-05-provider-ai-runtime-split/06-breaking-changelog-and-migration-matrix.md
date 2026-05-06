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
- prompt and generated-file shapes now store required `FileData` instead of
  dual `uri`/`bytes` storage
- the root `lib/core.dart` entrypoint exports focused sub-entrypoints instead
  of the old broad `llm_dart_core` barrel
- the root package no longer has a runtime dependency on `llm_dart_core`; it
  keeps `llm_dart_core` only as a dev dependency for compatibility-shell tests
- the shared `llm_dart_test` helper package now depends on
  `llm_dart_provider` rather than `llm_dart_core`
- core no longer carries duplicate JSON codec helper implementations; those
  helpers live only in `llm_dart_provider`
- `packages/llm_dart_core/lib` is now protected by a compatibility-shell guard
  that rejects new concrete implementation ownership outside approved legacy
  aliases
- `llm_dart_transport` now keeps its public cancellation surface transport-
  owned instead of re-exporting provider legacy aliases
- foundational test directories now reject broad `legacy.dart` imports so
  compatibility coverage stays explicit
- `example/06_mcp_integration` now declares local overrides for the full
  workspace package set it needs
- the old `deepseek-openai`, `google-openai`, `xai-openai`, `groq-openai`,
  and `phind-openai` OpenAI-compatible aliases are no longer registered by
  default or exposed as `LLMBuilder` convenience methods; use the dedicated
  provider IDs or explicitly register the legacy alias when migration code
  still needs the generic OpenAI-compatible shell

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
- Prompt and generated-file shapes now store a single required `FileData`
  union. Legacy `uri`/`bytes` JSON is still accepted on decode, but new code
  should construct `FileUrlData`, `FileBytesData`, `FileTextData`, or
  `FileProviderReferenceData` explicitly.
- OpenAI input-side file IDs now resolve through `FileProviderReferenceData`;
  `providerMetadata.openai.fileId` is no longer accepted as an input file
  identity hint.
- The root `package:llm_dart/core.dart` entrypoint now re-exports the focused
  contracts instead of the old broad `llm_dart_core` barrel.
- The root package runtime dependencies no longer include `llm_dart_core`.
  Compatibility coverage may still use `llm_dart_core` from dev/test
  dependencies while the shell exists.
- The MCP example package now depends on the full local workspace override set
  it actually uses, so it no longer relies on unpublished sibling packages
  resolving from pub.dev.
- `llm_dart_provider_utils` is not part of the first public preview; helper
  extraction stays internal until a stable cross-provider helper contract
  exists.
- `llm_dart_core` is guarded as a compatibility shell. New shared contracts
  belong in `llm_dart_provider`, and new runtime helpers belong in
  `llm_dart_ai`.
- OpenAI-family default entrypoints now prefer dedicated provider IDs plus the
  audited OpenRouter bridge. Legacy `*-openai` aliases remain available through
  explicit compatibility registration only.

### Kept

- `llm_dart_core.dart` remains available as a compatibility shell during the
  breaking window.
- `package:llm_dart/legacy.dart` remains in root as the explicit compatibility
  bridge for older builder and broad provider shell APIs.
- `packages/llm_dart_core/test` keeps broad imports as compatibility-shell
  coverage for now.

### Migration summary

- Replace broad `package:llm_dart_core/llm_dart_core.dart` imports with the
  focused entrypoint that matches the contract you need.
- Prefer `package:llm_dart/core.dart` for modern app code that only needs the
  stable facade.
- Replace OpenAI input file IDs previously passed through provider metadata
  with `FileProviderReferenceData(ProviderReference.forProvider('openai', id))`.
- Keep test-only broad imports only where the compatibility shell itself is
  under test.
```

## Migration Matrix

| Current surface | New surface | Status | Notes |
| --- | --- | --- | --- |
| `package:llm_dart_core/llm_dart_core.dart` | `foundation.dart`, `model.dart`, `serialization.dart`, `ui.dart`, or `package:llm_dart/core.dart` | Compatibility shell | This is the main public import to shrink in the breaking line. |
| Root compatibility consumers that still used the broad barrel | Focused `llm_dart_core` entrypoints | Landed in production code | New code should not reintroduce the broad barrel as a dependency. |
| Root runtime dependency on `llm_dart_core` | Direct `llm_dart_provider` and `llm_dart_ai` runtime dependencies | Landed | `llm_dart_core` remains only in dev/test coverage for the compatibility shell. |
| `packages/llm_dart_test` helper package dependency on `llm_dart_core` | `llm_dart_provider` and `llm_dart_transport` | Landed | Shared test fakes should exercise provider contracts directly. |
| Duplicate JSON codec helper implementations in core | Provider-owned helpers only in `llm_dart_provider` | Landed | Core no longer maintains its own parallel JSON helper copies. |
| New implementation declarations in `llm_dart_core/lib` | Owning package plus core re-export | Guarded | `tool/check_core_compatibility_shell_guard.dart` rejects concrete declarations unless they are approved compatibility aliases. |
| Provider legacy aliases on `llm_dart_transport` public barrel | Transport-owned `TransportCancellation` surface | Guarded | `tool/check_transport_boundary_guards.dart` keeps the transport barrel on transport-owned names. |
| Broad `legacy.dart` imports in foundational tests | Focused root/package entrypoints | Guarded | `tool/check_test_legacy_import_guards.dart` keeps core/model/builder/utils tests from depending on the legacy barrel. |
| `packages/llm_dart_core/test` broad imports | Keep for compatibility coverage | Deliberately retained | These tests exercise the shell itself until the shell disappears. |
| `example/06_mcp_integration` path dependencies | Full local workspace overrides | Landed | The example must resolve all unpublished workspace siblings locally. |
| OpenAI input file IDs in `ProviderMetadata` | `FileProviderReferenceData` | Breaking migration | Provider metadata remains for output observation/replay details, not input file identity. |
| `llm_dart_provider_utils` public package | Deferred | Not in first preview | Keep provider helper extraction internal until repeated cross-provider helper needs are stable. |
| `package:llm_dart/legacy.dart` | Keep in root for first preview | Compatibility bridge | Move to `llm_dart_legacy` only in a later release if root dependency shrink requires it. |
| `LLMBuilder.deepseekOpenAI()` and other `*-openai` builder aliases | Dedicated providers such as `deepseek`, `google`, `xai`, `groq`, `phind` | Removed from default builder surface | Use `provider('deepseek-openai')` only after explicit `OpenAICompatibleProviderRegistrar.registerProvider('deepseek-openai')` when migrating old generic-compatible code. |
| Default registry entries for `deepseek-openai`, `google-openai`, `xai-openai`, `groq-openai`, `phind-openai` | Dedicated provider entries plus `openrouter` | Removed from default registry surface | The typed factory remains available for explicit registration; default app discovery should not show duplicate lower-fidelity aliases. |

## Compatibility Policy

- Keep the compatibility barrel for the breaking window only.
- Do not add new implementation ownership to the broad barrel.
- Run `dart run tool/check_core_compatibility_shell_guard.dart` when touching
  `packages/llm_dart_core/lib`.
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
