# OpenAI Assistants Support Extraction

## Why This Cut Was Worth Doing

`lib/src/compatibility/providers/openai/assistants.dart` was another real mixed
host.

It owned two different kinds of work:

- transport-facing assistant API orchestration
- local assistant utility logic such as query shaping, clone/import request
  building, search filtering, export shaping, and tool parsing

Those local utilities are still compatibility-owned, but they do not belong in
the same file as the raw endpoint flow. The better boundary is:

- the capability shell owns HTTP orchestration
- provider-local support owns deterministic assistant utility logic

This keeps the root compatibility shell easier to reason about without
pretending assistants should move into shared contracts.

## What Changed

Added:

- `lib/src/compatibility/providers/openai/openai_assistant_support.dart`

Kept as the shell:

- `lib/src/compatibility/providers/openai/assistants.dart`

The support file now owns:

- list-query endpoint shaping
- assistant lookup and filtering helpers
- clone/import request construction
- local tool merge/remove helpers
- export shaping and stats helpers
- assistant-tool JSON parsing

The shell now stays focused on:

- calling `GET /assistants`, `POST /assistants`, `DELETE /assistants/...`
- delegating deterministic local transforms to support
- preserving the existing compatibility-facing methods

## Why This Boundary Is Better

This makes `OpenAIAssistants` read more like an API shell instead of a mixed
network-plus-utility module.

It also gives the assistant utility surface a clearer home if we later need to
adjust compatibility-only helpers such as:

- clone metadata policy
- assistant search semantics
- config import/export transforms
- tool JSON parsing rules

Most importantly, this stays aligned with the refactor rules for this phase:

- no new shared abstraction
- no public compatibility import change
- no `repo-ref/ai` symmetry copy
- only a real ownership split inside the provider-local compatibility layer

## Validation

The refactor was validated with targeted checks:

- `dart analyze lib/src/compatibility/providers/openai/assistants.dart lib/src/compatibility/providers/openai/openai_assistant_support.dart test/providers/openai/openai_assistants_test.dart`
- `dart test test/providers/openai/openai_assistants_test.dart`
- `dart run tool/check_workspace_dependency_guards.dart`
- `dart run tool/check_root_package_boundary_guards.dart`
