# Architecture Foundation Closeout Review

## Review Goal

This review decides whether the post-closure architecture-foundation workstream
should keep cutting provider files or switch to feature-driven refactors.

The answer is: the workstream should now close as an architecture-foundation
phase. More slicing is possible, but the remaining candidates are no longer
high-confidence architecture blockers.

## What Is Now In Good Shape

The refactor has already moved the root compatibility layer toward a clear
internal pattern:

- public compatibility facades stay stable
- provider-local request builders own request shaping
- provider-local response parsers own response normalization
- provider-local stream support owns incremental parser state
- provider-local support files own lifecycle helpers, catalog helpers, bridge
  codecs, and legacy convenience helpers
- package and root-boundary guards prevent the modern workspace from drifting
  back into `package:llm_dart/...` implementation imports

This borrows the useful `repo-ref/ai` layering lesson without copying its
package granularity.

## Remaining Large Files

The remaining large compatibility files fall into three groups.

### Intentionally Frozen

- `lib/src/compatibility/providers/anthropic/request_builder.dart`
  - This was already audited as a long but cohesive Anthropic request codec.
    Splitting it again would be symmetry-driven rather than pressure-driven.

### Cohesive Support State Machines

- `lib/src/compatibility/providers/openai/stream_parsing_support.dart`
- `lib/src/compatibility/providers/anthropic/anthropic_chat_stream_support.dart`

These are stateful stream parsers. They are not short, but their complexity is
real parser state: reasoning/thinking deltas, tool-call aggregation, partial
content buffering, SSE data frames, and completion/error semantics.

They should only be split further if a concrete bug or new provider stream
variant repeatedly touches one isolated sub-area.

### Compatibility Aggregators Or Legacy Helpers

- `lib/src/compatibility/providers/openai/provider_compat.dart`
- `lib/src/compatibility/providers/anthropic_compat_support.dart`
- `lib/src/compatibility/providers/elevenlabs/elevenlabs_audio_bridge_support.dart`
- `lib/src/compatibility/providers/openai/client.dart`
- `lib/src/compatibility/providers/openai/models.dart`

These files still have some size, but their remaining size is not the same as
architecture debt:

- `provider_compat.dart` is large because it implements many legacy capability
  interfaces and delegates to already-thinned modules.
- `anthropic_compat_support.dart` is a provider-family bridge planner with
  role-aware prompt conversion and cache policy handling.
- `elevenlabs_audio_bridge_support.dart` is a bridge codec/normalization
  cluster.
- `openai/client.dart` is already backed by smaller client error/message/SSE
  support helpers.
- `openai/models.dart` has legacy convenience filters and pricing heuristics;
  a split is possible, but it is low-value unless model-catalog behavior is
  being actively changed.

## Closeout Decision

Close this workstream as complete.

The next default should not be "find the next biggest compatibility file." The
next default should be:

- change provider modules only when a real feature or bug requires it
- add focused tests before touching stateful stream parsers
- keep root compatibility surfaces stable until the planned compatibility
  deprecation/removal window
- continue using package/root dependency guards as the hard boundary check

## Future Trigger List

Reopen structural refactoring only if one of these pressures appears:

- a new provider feature needs the same helper pattern in at least two places
- a stream parser bug shows a repeated isolated sub-state that can be extracted
- a public compatibility API is being deprecated and the facade can be removed
  rather than merely thinned
- a package-level feature needs a new modern package boundary
- Flutter integration reveals repeated provider-owned rendering composition
  pain that justifies an app-owned helper above `ChatMessageMapper`

Until then, the architecture foundation should be considered stable enough for
feature work.

## Validation

Closeout classification was based on:

- a clean working tree before the review
- a remaining compatibility-file size scan
- the completed post-closure TODO list
- the existing workspace dependency guard
- the existing root package boundary guard

The review was validated with:

- `dart run tool/check_workspace_dependency_guards.dart`
- `dart run tool/check_root_package_boundary_guards.dart`
- `git diff --check`
