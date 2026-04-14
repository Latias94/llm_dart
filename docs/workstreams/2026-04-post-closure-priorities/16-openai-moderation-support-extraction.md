# OpenAI Moderation Support Extraction

## Why This Cut Was Worth Doing

`lib/src/compatibility/providers/openai/moderation.dart` was another real mixed
host.

It combined two separate responsibilities:

- moderation endpoint orchestration
- local moderation analysis, recommendation, and batch-statistics helpers

Those local helpers are still compatibility-owned behavior, but they do not
need to live in the same file as the raw API shell. The cleaner boundary is:

- the capability shell owns `POST /moderations`
- provider-local support owns deterministic analysis and reporting logic

## What Changed

Added:

- `lib/src/compatibility/providers/openai/openai_moderation_support.dart`

Kept as the shell:

- `lib/src/compatibility/providers/openai/moderation.dart`

The support file now owns:

- moderation request-body shaping
- single-text analysis construction
- batch analysis construction
- safe-content filtering
- batch statistics aggregation
- category and score mapping
- recommendation generation

The capability shell now stays focused on:

- calling the moderation endpoint
- mapping the response through provider-local support helpers
- preserving the existing compatibility-facing utility methods

## Additional Hardening

While moving the local helpers, the batch-statistics path was also hardened for
two compatibility edge cases that previously had weak behavior:

- empty input batches now return `0` totals and `mostCommonViolation = 'none'`
- all-safe batches now also return `mostCommonViolation = 'none'`

This keeps the helper deterministic instead of depending on a non-empty flagged
category set.

## Why This Boundary Is Better

This makes `OpenAIModeration` read like an API shell instead of a combined
transport-plus-reporting utility module.

It also gives moderation-specific analysis behavior a clearer home if we later
need to adjust:

- recommendation policy
- risk-level thresholds
- batch-stat aggregation semantics
- compatibility-only reporting helpers

Most importantly, this stays within the rules of this workstream:

- no shared-core widening
- no public compatibility import-path break
- only a real provider-local ownership split

## Validation

The refactor was validated with targeted checks:

- `dart analyze lib/src/compatibility/providers/openai/moderation.dart lib/src/compatibility/providers/openai/openai_moderation_support.dart test/providers/openai/openai_moderation_test.dart`
- `dart test test/providers/openai/openai_moderation_test.dart`
- `dart run tool/check_workspace_dependency_guards.dart`
- `dart run tool/check_root_package_boundary_guards.dart`
