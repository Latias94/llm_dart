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
- actual publishing remains a maintainer-controlled manual action

Current status:

- local release readiness has passed with guards, analysis, tests, consumer
  smoke, publish dry-run, and version availability preflight
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

- `00-priority-map.md` defines the second-wave priority order and non-goals

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
