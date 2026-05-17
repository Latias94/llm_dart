# TODO

## Workstream Setup

- [x] Create the second fearless refactor wave workstream scaffold
- [x] Record the canonical goal text
- [x] Freeze second-wave priorities and non-goals
- [x] Add architecture blueprint from source and `repo-ref/ai` comparison
- [x] Document milestone acceptance criteria
- [x] Add the workstream to the workstream index

## Release Gate

- [x] Add a repeatable workspace package-test command
- [x] Run focused Dart package tests from the package-test command
- [x] Run the Flutter package test with Flutter tooling
- [x] Add the package-test command to release readiness by default
- [x] Keep `--skip-tests` as the short-iteration escape hatch for root and
  package tests
- [x] Add focused tests for package-test target selection and release step
  planning

## Alpha Handoff

- [x] Run enhanced final release readiness with package tests and pub.dev
  version availability
- [x] Add a published-package consumer smoke mode for post-publish validation
- [x] Keep publishing as a manual maintainer-controlled action
- [x] Keep publish order visible in release readiness output
- [x] Re-check pub.dev version availability before the release posture decision
- [ ] Publish packages in dependency order
- [ ] Re-run clean consumer smoke against pub.dev versions
- [ ] Record alpha feedback and decide the first second-wave implementation
  milestone

## Legacy And Root

- [x] Freeze `legacy.dart` as migration-only compatibility host for this wave
- [x] Freeze `LLMBuilder` as a compatibility trunk for this wave
- [x] Freeze root provider constructors as compatibility hosts for this wave
- [x] Keep root implementation ownership out of second-wave goals
- [ ] Triage alpha feedback for missing modern replacements before scheduling
  any compatibility removals

## Core And Provider Utils

- [x] Freeze `llm_dart_core` as a compatibility shell until later review
- [x] Write the `llm_dart_provider_utils` extraction criteria
- [x] Inventory modern-surface docs and examples that still lead with
  provider-facing or compatibility APIs
- [x] Execute the docs-only modern-surface cleanup for provider README and
  migration-guide default examples
- [x] Classify root and `llm_dart_core` compatibility surfaces with removal
  blockers or review windows
- [x] Inventory repeated provider helper duplication across focused providers
- [x] Decide whether current helper duplication justifies a public
  `llm_dart_provider_utils` package

## Goal Audit

- [x] Add prompt-to-artifact completion audit for the canonical goal
- [ ] Record alpha publish or explicit non-publish decision
- [x] Record equivalent local consumer smoke evidence for the unpublished
  branch
- [x] Add an explicit release posture decision gate
- [x] Modernize split-package consumer smoke to prove `ModelMessage` in the
  split package path
- [ ] Record post-publish consumer smoke evidence after publication, if the
  alpha is published
- [x] Propose and execute the next bounded implementation milestone as
  docs-only modern-surface cleanup
- [ ] Confirm the next implementation milestone after alpha feedback or
  explicit non-publish decision
