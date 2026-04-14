# OpenAI Completion Support Extraction

## Why This Cut Was Worth Doing

`lib/src/compatibility/providers/openai/completion.dart` had become another
small but real mixed host.

It combined:

- compatibility endpoint orchestration for completion requests
- request/response shaping
- streaming delta parsing
- use-case presets
- retry helpers
- batch helpers
- token-estimation heuristics

The shell itself only needs the first responsibility. The rest are deterministic
provider-local helpers that belong in a support module.

## What Changed

Added:

- `lib/src/compatibility/providers/openai/openai_completion_support.dart`

Kept as the shell:

- `lib/src/compatibility/providers/openai/completion.dart`

The support file now owns:

- request-body shaping
- response parsing
- streaming delta extraction
- completion use-case presets
- retry and batch helper logic
- token estimation and truncation heuristics

The capability shell now stays focused on:

- calling `chat/completions`
- streaming through the same compatibility endpoint
- delegating deterministic helper behavior to provider-local support

## Why This Boundary Is Better

This keeps `OpenAICompletion` honest as a compatibility API shell rather than a
mixed shell-plus-utility module.

It also gives the compatibility-only completion helpers a clearer future home
if we later need to adjust:

- retry policy
- use-case preset tuning
- stream-delta parsing policy
- token heuristic behavior

As with the other work in this phase, this stays intentionally scoped:

- no new shared abstraction
- no public compatibility import-path break
- only a real provider-local ownership split

## Validation

The refactor was validated with targeted checks:

- `dart analyze lib/src/compatibility/providers/openai/completion.dart lib/src/compatibility/providers/openai/openai_completion_support.dart test/providers/openai/openai_completion_test.dart`
- `dart test test/providers/openai/openai_completion_test.dart`
- `dart run tool/check_workspace_dependency_guards.dart`
- `dart run tool/check_root_package_boundary_guards.dart`
