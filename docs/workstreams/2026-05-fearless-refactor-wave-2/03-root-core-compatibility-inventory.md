# Root And Core Compatibility Inventory

## Objective

Classify the root package and `llm_dart_core` compatibility surfaces with
removal blockers, review windows, and guard evidence.

This inventory does not schedule removals. The goal explicitly says the second
wave must not remove `legacy.dart`, `LLMBuilder`, or `llm_dart_core`.

## Evidence Commands

Representative searches used for this inventory:

```powershell
rg -n "export 'package:llm_dart_ai|export 'package:llm_dart_provider|Compatibility|compatibility|legacy|LLMBuilder|createProvider|Builder-era|removed" lib packages\llm_dart_core\lib README.md docs\migration\0.11-sdk-aligned.md docs\workstreams\2026-05-alpha-release-hardening -g "*.dart" -g "*.md"
```

```powershell
Get-ChildItem lib -Recurse | Select-Object FullName,Length
```

Reviewed guard sources:

- `tool/check_root_package_boundary_guards.dart`
- `tool/check_core_compatibility_shell_guard.dart`
- `tool/check_test_legacy_import_guards.dart`

## Current Root Shape

The root package is a modern facade plus focused entrypoints:

- `lib/llm_dart.dart` exports only `ai.dart`
- `lib/ai.dart` composes `llm_dart_ai`, focused provider entrypoints, and the
  root provider facade aliases
- focused entrypoints such as `openai.dart`, `anthropic.dart`, `google.dart`,
  `ollama.dart`, `transport.dart`, and `chat.dart` re-export package-owned
  surfaces
- `lib/src/facade/ai.dart` owns short factory aliases such as `openai(...)`,
  `anthropic(...)`, `google(...)`, and OpenAI-family aliases

Guard evidence:

- `tool/check_root_package_boundary_guards.dart` freezes the allowed root
  public entrypoint files.
- The guard requires `lib/llm_dart.dart` to export only `ai.dart`.
- The guard requires `lib/ai.dart` and focused entrypoints to match explicit
  directive lists.
- The guard rejects root public entrypoint implementation declarations.
- The guard rejects example imports from root legacy subpaths and
  `legacy.dart`.

## Current `llm_dart_core` Shape

`llm_dart_core` is a compatibility shell:

- `packages/llm_dart_core/lib/llm_dart_core.dart` is documented as a
  compatibility barrel.
- package README says new applications should normally start with
  `package:llm_dart/llm_dart.dart`.
- `llm_dart_core` re-exports provider contracts from `llm_dart_provider` and
  runtime helpers from `llm_dart_ai`.
- many files under `packages/llm_dart_core/lib/src/...` are single-line
  re-export shells.

Guard evidence:

- `tool/check_core_compatibility_shell_guard.dart` walks
  `packages/llm_dart_core/lib`.
- It permits directives, comments, `library;`, and explicitly allowed
  compatibility aliases.
- It rejects implementation ownership in `llm_dart_core`.

## Compatibility Surface Classification

| Surface | Current Role | Removal Blocker | Earliest Review Window |
| --- | --- | --- | --- |
| root `llm_dart.dart` | default modern facade | none; must remain stable | not a removal candidate |
| root focused entrypoints | convenience re-exports for focused packages | root package remains the easiest onboarding path | not a removal candidate |
| root short provider factories | convenience aliases over focused provider packages | docs and examples rely on concise root onboarding | review only if focused package imports become preferred everywhere |
| `lib/src/facade/ai.dart` | root facade implementation for short aliases | must not grow into model/runtime ownership | review for slimming after alpha feedback |
| `legacy.dart` | no public file in current root tree; docs mention old compatibility as removed or migration-only historical surface | alpha users may still search for it from older versions | review only if a new compatibility package is proposed; do not reintroduce by default |
| `LLMBuilder` | removed from current root public surface; mentioned in migration docs | migration docs must stay clear for old users | no removal work remains; keep docs accurate |
| `createProvider(...)` | removed/frozen compatibility concept in docs | migration docs must point to focused factories | no removal work remains; keep docs accurate |
| `llm_dart_core` package | compatibility shell for historical core imports | published consumers may need broad old import paths during migration | review after alpha feedback and import evidence |

## Current Decision

Keep root and `llm_dart_core` as they are for this wave:

- root stays a modern facade and onboarding convenience
- `llm_dart_core` stays a compatibility shell
- no implementation ownership moves into either surface
- no removal is scheduled before alpha feedback

## Follow-Up Evidence Needed

Before any future `llm_dart_core` removal review:

- collect consumer feedback after `0.11.0-alpha.1`
- count first-party examples and tests that still need
  `package:llm_dart_core/...`
- confirm root/focused packages cover common import replacements
- verify migration docs are sufficient for old `llm_dart_core` users

Before any root facade slimming:

- confirm provider package READMEs and examples make focused imports
  discoverable
- ensure short root aliases are not the only documented way to create provider
  models
- keep boundary guards updated before changing entrypoint directives
