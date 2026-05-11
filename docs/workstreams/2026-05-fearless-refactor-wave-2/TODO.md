# TODO

## Workstream Setup

- [x] Create the second fearless refactor wave workstream scaffold
- [x] Freeze second-wave priorities and non-goals
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
- [x] Keep publishing as a manual maintainer-controlled action
- [x] Keep publish order visible in release readiness output
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
- [ ] Inventory repeated provider helper duplication after alpha feedback
- [ ] Decide whether any helper duplication justifies a public
  `llm_dart_provider_utils` package
