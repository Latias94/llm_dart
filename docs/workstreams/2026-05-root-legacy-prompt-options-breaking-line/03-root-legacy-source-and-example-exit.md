# Root Legacy Source And Example Exit

Date: 2026-05-13

## Decision

The root package no longer keeps a compatibility implementation owner. The
breaking line is direct deletion, not a new root `legacy.dart` shell and not a
separate compatibility package.

Current root `lib/` ownership is:

- modern root facade entrypoints
- focused provider entrypoints that re-export provider packages
- `src/facade/ai.dart` short factory namespace only

The root package must not regain:

- `lib/legacy.dart`
- `lib/builder/`
- `lib/models/`
- `lib/providers/`
- `lib/core/` legacy subpaths
- `lib/src/bootstrap/`
- `lib/src/compatibility/`

## Implementation Slices Completed

- Deleted root legacy source ownership for builder, model, provider, bootstrap,
  and compatibility internals.
- Migrated retained OpenAI Assistants lifecycle APIs into
  `llm_dart_openai` as `openai(...).assistants()`.
- Migrated retained raw OpenAI Responses lifecycle APIs into
  `llm_dart_openai` as `openai(...).responsesLifecycle()`.
- Rewrote root examples that still imported legacy root subpaths:
  - Assistants now use the focused OpenAI assistants client.
  - Cancellation now imports cancellation tokens from `transport.dart`.
  - Capability detection now uses concrete `ModelCapabilityProfile` data.
  - Capability factory guidance now uses focused factories.
  - Model listing now uses concrete profiles plus focused provider catalogs.
  - Provider-specific builder guidance now uses typed provider options.
  - Realtime audio is documented as app-owned orchestration until a stable
    shared realtime contract exists.
  - ElevenLabs and Google audio examples now use stable speech/transcription
    models and focused provider options.
  - OpenAI Responses examples now use shared model calls for app generation and
    `responsesLifecycle()` for raw lifecycle operations.
- Removed example-guard allowlists for compatibility files; old example paths
  are now checked like every other default example.
- Updated current README and migration guide so they no longer advertise
  `package:llm_dart/legacy.dart` as an available migration target.

## Guard State

The root boundary guard now enforces:

- `lib/` only contains approved public facade entrypoint files plus `src/`
- `lib/src/` only contains `facade/`
- root public entrypoints stay facade-only
- `llm_dart_chat` is only exported from `lib/chat.dart`
- examples do not import root legacy subpaths

The example API guard now enforces:

- no `package:llm_dart/legacy.dart`
- no root `builder/`, `models/`, `providers/`, or legacy `core/` subpath imports
- no `LLMBuilder()` usage
- no removed root `ai()` helper usage
- no grouped `AI` facade usage in default examples

The strict test legacy import guard currently passes with
`--strict-root-legacy-subpaths`, so the old inventory count of 81 has been
burned down to zero for guarded test scopes.

## Targeted Validation

- `dart run tool/check_root_package_boundary_guards.dart`
- `dart test test/tool/check_root_package_boundary_guards_test.dart`
- `dart run tool/check_example_api_guards.dart`
- `dart test test/tool/check_example_api_guards_test.dart`
- `dart run tool/check_test_legacy_import_guards.dart --strict-root-legacy-subpaths`
- `dart test test/tool/check_test_legacy_import_guards_test.dart`
- `dart analyze` over the migrated example files

## Remaining Work

This slice deliberately does not close the full workstream. The next blockers
are:

- ordinary prompt input and tool output parts still need the request-side
  `ProviderMetadata` exit
- replay must be carried through explicit typed replay options or provider
  replay helpers
- structured output/result facade direction still needs a freeze document and
  tests
- consumer smoke and publish dry-runs still need to be rerun after the metadata
  and structured-result slices land
