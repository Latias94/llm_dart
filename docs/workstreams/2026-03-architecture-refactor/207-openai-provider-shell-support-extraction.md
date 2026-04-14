# 207 OpenAI Provider Shell Support Extraction

## Why This Slice Exists

After thinning the main OpenAI compatibility capability hosts, the remaining
`lib/src/compatibility/providers/openai/provider_compat.dart` file was already
mostly a healthy delegation shell.

However, it still kept a small cluster of provider-owned helper logic inline:

- model validation through `checkModel()`
- follow-up suggestion generation through `generateSuggestions(...)`
- suggestion text parsing
- extra helper delegation such as `getEmbeddingDimensions()`

That did not justify a large shell split, but it was still enough mixed
ownership to make the provider shell slightly less honest than it could be.

## What Changed

This slice keeps the public `OpenAIProvider` API unchanged while extracting the
remaining provider-owned helper/support logic into:

- `openai_provider_support.dart`
  - model validation helper
  - suggestion generation helper
  - suggestion parsing helper
  - helper-level embedding-dimension delegation

`provider_compat.dart` stays as the main compatibility provider shell, but now
leans more clearly toward:

- capability construction
- capability delegation
- compatibility-facing getters

## Why This Is Better

- keeps the main provider shell closer to pure delegation
- isolates the remaining non-capability helper logic in one obvious place
- preserves the stable public `OpenAIProvider` API
- makes future provider-shell re-audits easier because delegation and helper
  logic are no longer interleaved

## Boundary Decision

This slice is intentionally **small and local**.

The goal is not to split `provider_compat.dart` aggressively just because it is
large. The goal is only to remove the remaining non-delegation helper logic
that still had distinct ownership from the shell itself.

## Why This Matches The Reference Direction

The useful lesson from `repo-ref/ai` is still ownership:

- capability facades and provider shells should mostly delegate
- extra helper logic should not keep accumulating inside the main shell

The Dart root compatibility layer remains intentionally less granular than the
reference repository. This is a targeted cleanup, not a package-graph rewrite.

## Validation

This slice is validated with:

- `dart analyze lib/src/compatibility/providers/openai/provider_compat.dart lib/src/compatibility/providers/openai/openai_provider_support.dart test/providers/openai/openai_provider_support_test.dart test/providers/openai/openai_provider_bridge_test.dart test/providers/openai/openai_advanced_test.dart`
- `dart test test/providers/openai/openai_provider_support_test.dart test/providers/openai/openai_audio_support_test.dart test/providers/openai/openai_config_layering_test.dart test/providers/openai/openai_provider_bridge_test.dart test/legacy_compatibility_test.dart`
- `dart run tool/check_root_package_boundary_guards.dart`
- `dart run tool/check_workspace_dependency_guards.dart`

## Follow-Up

After this slice, the next structural step should be another hotspot audit
rather than an automatic next split.

The most likely remaining candidates are:

- a careful re-audit of `lib/src/compatibility/providers/anthropic/request_builder.dart`
- a broader root-shell closure review to decide which remaining compatibility
  files are still true hotspots and which are now honestly stable enough

The key rule stays unchanged: split mixed ownership, not merely file size.
