# TODO

## M0 Baseline

- [x] Create workstream tracker.
- [x] Capture current guard/test baseline with direct Dart SDK invocation.
  - workspace dependency guard: passed
  - root boundary guard: passed
  - git diff --check: passed

## M1 Root package dependency topology

- [x] Decide final root package dependency graph: root keeps shared runtime/chat/transport/provider contracts only; concrete providers move to direct provider packages.
- [x] Update root `pubspec.yaml` and root entrypoints.
- [x] Update root boundary guard and tests.
- [x] Migrate examples/docs/tests away from broad root provider factories where needed.

## M2 Provider-utils / transport seam

- [x] Add explicit provider utility seam/package or internal module.
- [x] Move provider-aware stream decode helper out of transport.
- [x] Move transport-error-to-model-error mapping out of transport.
- [x] Update provider packages and tests.

## M3 OpenAI provider organization

- [ ] Create route/capability directories.
- [ ] Move Chat Completions implementation files.
- [ ] Move Responses implementation files.
- [ ] Move assistants/files/images/embedding/audio/tool implementation files.
- [ ] Keep public exports stable or document breakage.

## M4 Typed provider options + provider options bag

- [ ] Add provider options bag primitives to provider contracts.
- [ ] Add helpers for typed options to project into bag form.
- [ ] Add OpenAI-family bag parsing/adoption path.
- [ ] Add tests for typed options and bag coexistence/conflicts.

## M5 Final validation

- [ ] Run focused tests/analyze for changed packages.
- [ ] Run guards.
- [ ] Run `git diff --check`.
- [ ] Commit each coherent slice with conventional commit messages.

