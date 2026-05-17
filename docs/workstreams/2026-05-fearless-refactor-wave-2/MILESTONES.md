# Milestones

## M1 - Alpha Handoff Gate

Goals:

- keep the alpha release path executable
- make publication and post-publication validation explicit
- prevent new refactors from invalidating the verified release state

Acceptance criteria:

- final release readiness passes before publishing
- publish order is available from release readiness output
- post-publish clean consumer smoke is documented
- post-publish clean consumer smoke can run with `--published` and no local
  path overrides
- actual publishing remains a maintainer-controlled manual action

Current status:

- local release readiness has passed with guards, analysis, tests, consumer
  smoke, publish dry-run, and version availability preflight
- latest full release readiness rerun passed on 2026-05-15T19:50+08:00 after
  the modern-surface docs cleanup and consumer-smoke modern-surface cleanup:
  - 13/13 steps passed
  - workspace package tests passed for 11 package(s)
  - consumer smoke passed all 24 local path steps
  - workspace publish dry-run passed for 12 publishable package(s)
  - pub.dev version availability still reports `0.11.0-alpha.1` as available
- local consumer smoke was rerun on 2026-05-15T19:45+08:00 with local path
  dependencies and passed all 24 steps across root, focused provider-only,
  split-package, and Flutter consumers
- pub.dev version availability was rerun on 2026-05-15T20:00+08:00; all
  focused packages remain available as new packages at `0.11.0-alpha.1` and
  root `llm_dart` remains available as a new version after `0.10.7`
- workspace publish dry-run now covers 12 publishable packages
- actual publishing has not started

## M2 - Package Test Gate

Goals:

- turn package-local tests into a default release gate
- avoid treating root tests as full coverage for focused packages
- keep Flutter package validation on Flutter tooling

Acceptance criteria:

- a repeatable package-test command exists
- release readiness runs the package-test command by default
- `--skip-tests` skips both root and package tests for short local iterations
- focused tests cover step planning and package-test target selection

Current status:

- `tool/run_workspace_package_tests.dart` records the package-test matrix
- `tool/release_readiness.dart` runs that matrix by default after root tests

## M3 - Second-Wave Scope Freeze

Goals:

- freeze the next refactor order before touching code
- separate release work from compatibility removals
- keep provider utility extraction evidence-based

Acceptance criteria:

- legacy/root/core/provider-utils priorities are written down
- non-goals explicitly protect migration trunks from accidental deletion
- each future removal has a blocker or earliest review window
- provider-utils extraction criteria require repeated provider duplication

Current status:

- `GOAL.md` records the canonical second-wave goal, completion definition,
  non-goals, and decision rules
- `00-priority-map.md` defines the second-wave priority order and non-goals
- `01-architecture-blueprint.md` records the source-versus-reference blueprint
  and confirms the completed provider/runtime event split should be treated as
  a foundation, not reopened by default
- `02-modern-surface-audit.md` records the modern API docs/examples audit and
  identifies provider README plus migration-guide docs gaps
- `03-root-core-compatibility-inventory.md` classifies root and
  `llm_dart_core` compatibility surfaces with blockers and review windows
- `04-provider-helper-duplication-inventory.md` inventories provider helper
  duplication and records that a public `llm_dart_provider_utils` package is
  not justified in this wave
- `05-goal-completion-audit.md` records the remaining blockers before the
  canonical goal can be marked complete
- `06-modern-surface-docs-cleanup.md` records the first bounded docs-only
  milestone execution: provider README and migration-guide default examples now
  lead with `messages:` and `ModelMessage`
- `07-release-posture-decision-gate.md` records the remaining maintainer
  decision required before the canonical goal can be closed
- `08-consumer-smoke-modern-surface.md` records a bounded implementation
  milestone: the split-package consumer smoke program now uses
  `UserModelMessage` and `ModelMessageRole`

## M4 - Alpha Feedback Triage

Goals:

- convert alpha feedback into targeted work
- avoid reopening broad architecture work without evidence

Acceptance criteria:

- post-publish consumer smoke passes against pub.dev versions
- any alpha issue is classified as release blocker, migration gap, docs gap, or
  future refactor candidate
- the next implementation goal names one bounded milestone rather than
  "continue refactoring"

Current status:

- deferred until packages are published or maintainers explicitly choose to
  keep `0.11.0-alpha.1` unpublished
- current local evidence inventories are complete enough to support the next
  maintainer release-posture decision, but alpha feedback and post-publish
  smoke do not exist yet
- the previously proposed docs-only modern-surface cleanup has been executed
  as `06-modern-surface-docs-cleanup.md`
- the consumer smoke modern-surface cleanup has been executed as
  `08-consumer-smoke-modern-surface.md`
- the next milestone after this still depends on alpha feedback or an explicit
  non-publish decision
