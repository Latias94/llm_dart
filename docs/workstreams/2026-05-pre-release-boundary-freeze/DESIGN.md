# Pre-Release Boundary Freeze

Status: Complete
Last updated: 2026-05-27

## Why This Lane Exists

The core and remaining boundary refactors are closed. The package graph,
provider/runtime split, typed provider options, capability gates, chat
transport session, and explicit serialization codec posture are now deep enough
for an alpha release.

The remaining pre-release risk is not another broad rewrite. The risk is that
publish-facing evidence and user-visible contracts are not frozen in one place:
provider wire fixtures are uneven across release surfaces, workstream state is
spread across many documents, app entrypoints expose a wide symbol set without
a manifest, chat HTTP protocol compatibility is proven by tests but not frozen
as a policy, and OpenAI Responses projection ownership is hard to navigate.

This lane turns those five risks into narrow, testable seams.

## Target State

When this lane closes:

- release readiness has one ledger and a guard that catches stale workstream
  state before publish;
- provider fixture coverage protects the release-committed provider wire
  surfaces that are most likely to regress during provider-native refactors;
- app facade exports have an explicit release contract manifest and guard;
- HTTP chat transport v1/v2 compatibility rules are frozen as a protocol
  policy with tests;
- OpenAI Responses native projection ownership has a package-private index so
  maintainers can extend it without re-opening a registry debate.

## In Scope

- `docs/release/` release ledger and package publish state.
- Workstream status consistency for active/complete release-facing lanes.
- Provider fixture contract coverage where behavior is already stable.
- Root/app export contract manifest and guard tooling.
- HTTP chat transport protocol policy and compatibility tests.
- OpenAI Responses projection family documentation/index.

## Out Of Scope

- Reopening provider/runtime/chat package ownership.
- Removing public symbols only to make the app facade smaller before alpha.
- Adding a global serialization or provider-native projection registry.
- Publishing packages or changing the release process to auto-publish.
- Flattening provider-native OpenAI Responses tools into shared abstractions.

## Architecture Direction

Use the deletion test:

- If deleting a new Module would spread release-state or contract knowledge
  across many files, keep the Module.
- If deleting it would make the code simpler without losing locality, keep the
  existing owner and document the no-op.

Reference lessons from `repo-ref/ai` remain ownership lessons, not package-count
goals:

- runtime entrypoints stay app-owned;
- provider contracts and wire codecs stay provider-owned;
- provider-native features stay provider-owned;
- release and protocol contracts need explicit, reviewable artifacts.

## Assumptions

| Assumption | Confidence | Evidence | Consequence if wrong |
| --- | --- | --- | --- |
| No broad rewrite is needed before alpha. | High | Final gates passed after core and remaining-boundary refactors. | Split a new architecture lane instead of forcing it into this freeze. |
| Fixture coverage is the highest-value code slice. | High | Existing provider fixture workstreams already proved the pattern. | Keep fixture work to one provider and record the no-op. |
| App facade export shrinkage is too risky immediately before alpha. | Medium | Migration guide depends on root/core convenience. | Freeze a manifest now, schedule removals later. |
| HTTP protocol code is deep enough; policy needs freezing. | High | v1/v2 tests already cover compatibility paths. | Extract a deeper protocol Module if policy duplication appears. |
| OpenAI Responses needs navigation, not another registry. | High | The serialization registry deletion test rejected broad registries. | Revisit only after new projection families repeat dispatcher complexity. |

## Closeout Condition

This lane can close when all five pre-release seams are implemented or
explicitly rejected with evidence, fresh gates pass, and publish-facing docs
tell maintainers which contracts are frozen versus deferred.

Closed on 2026-05-27. The lane implemented all five seams, recorded final
evidence, and left package publishing as an explicit maintainer action.
