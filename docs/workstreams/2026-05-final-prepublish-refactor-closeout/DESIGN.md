# Final Prepublish Refactor Closeout

Status: Complete
Last updated: 2026-05-27

## Why This Lane Exists

The release ledger is `release_ready`, but four post-freeze architecture
cleanups remain valuable enough to finish before publishing:

- project context and ADR indexing are missing, so frozen decisions live mostly
  in historical workstreams;
- runtime event/tool-loop work has implementation evidence but needs release
  closeout alignment;
- provider fixture/test support has repeated patterns that should be
  consolidated without creating a public provider utility package;
- the largest scenario tests are hard to navigate and should be split by
  scenario family before they hide release regressions.

This lane is the final prepublish closeout. It must reduce future rewrite risk
without reopening provider/runtime ownership or expanding public surface area.

## Target State

When this lane closes:

- `CONTEXT.md` names the core Modules, Interfaces, seams, and release posture
  in one durable glossary;
- `docs/adr/` indexes the frozen architecture decisions that future agents
  should not re-litigate;
- runtime event/tool-loop workstream state is reconciled with the current
  release posture;
- provider test-only fixture support has a deeper Module for repeated golden
  assertions while provider-native behavior stays provider-owned;
- the highest-risk giant tests are split into scenario-family files without
  changing production behavior;
- release gates still pass and the final publish step remains maintainer
  approved.

## In Scope

- Documentation context and ADR index for already-frozen architecture seams.
- Workstream status reconciliation for runtime event/tool-loop closeout.
- Test-only provider fixture helper extraction.
- Scenario-family test file splits for the largest or most release-critical
  test buckets.
- Release ledger and evidence updates.

## Out Of Scope

- New public provider implementation kit package.
- App facade symbol removal before publish.
- Runtime registry for OpenAI Responses projection families.
- Reintroducing `llm_dart_core`.
- Changing provider/runtime/chat ownership after the release ledger freeze.
- Running `pub publish`; publish remains a manual maintainer action.

## Architecture Direction

Use the deletion test for every new Module:

- `CONTEXT.md` and ADR index stay because deleting them would scatter decision
  knowledge across many workstreams.
- Provider test support may deepen only when deleting the helper would recreate
  the same fixture logic in multiple provider tests.
- Scenario-family test splits are useful only if they improve locality without
  inventing a second testing vocabulary.
- Runtime closeout is documentation and guard alignment, not a new event model.

## Closeout Condition

This lane can close when all four requested cleanups are complete, fresh
targeted gates and release gates pass, workstream and release evidence agree,
and a commit records the final prepublish state.

Closed on 2026-05-27. All four requested cleanups are implemented and the
release ledger is back to `release_ready`; publishing remains a manual
maintainer-approved step.
