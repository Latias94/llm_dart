# OpenAI Provider Shell Support Thinning

## Why This Cut Was Worth Doing

`lib/src/compatibility/providers/openai/provider_compat.dart` is intentionally a
root compatibility shell, so some size is expected.

But even for a root shell, a few responsibilities had become more local-helper
or policy logic than true shell wiring:

- capability-set policy for whether Responses API is exposed
- audio convenience helpers like `speech`, `speechStream`, `transcribe`, and
  `translate`
- residual provider-owned helper methods already partially housed in
  `openai_provider_support.dart`

That made the provider shell carry more non-shell helper weight than it needed.
The better boundary here is:

- the root provider keeps capability-module delegation
- provider-local support keeps capability policy and compatibility convenience
  helpers

## What Changed

Expanded:

- `lib/src/compatibility/providers/openai/openai_provider_support.dart`

Kept as the shell:

- `lib/src/compatibility/providers/openai/provider_compat.dart`

`OpenAIProviderSupport` now also owns:

- `supportedCapabilities` policy
- `supports(...)` capability checks
- audio convenience wrappers for speech and transcription helpers
- the previously extracted helper methods such as model checking and follow-up
  suggestion generation

The root provider shell now stays focused on:

- wiring capability modules
- delegating the actual shared capability interfaces
- exposing the residual compatibility-facing root provider surface

## Why This Boundary Is Better

This does not try to remove the root shell itself. That would be the wrong move
for this phase.

Instead, it makes the shell a more honest shell:

- wiring stays in the provider
- helper policy stays in provider-local support
- capability delegation remains explicit

This is the same pattern we have been using elsewhere:

- keep public compatibility imports stable
- do not introduce new shared abstractions
- move only real provider-local helper ownership out of mixed hosts

## Validation

The refactor was validated with targeted checks:

- `dart analyze lib/src/compatibility/providers/openai/provider_compat.dart lib/src/compatibility/providers/openai/openai_provider_support.dart test/providers/openai/openai_provider_support_test.dart`
- `dart test test/providers/openai/openai_provider_support_test.dart`
- `dart run tool/check_workspace_dependency_guards.dart`
- `dart run tool/check_root_package_boundary_guards.dart`
