# Milestones

## M1 - Release Gate Automation

Goals:

- introduce a single release-readiness command
- keep the command Dart-based and shell-neutral
- make failures easy to diagnose

Acceptance criteria:

- the command runs existing guard scripts
- the command runs analysis and tests
- the command runs workspace publish dry-run unless explicitly skipped
- command behavior has focused tests where practical
- documentation explains supported flags and manual follow-up steps

Current status:

- `tool/release_readiness.dart` now exists as the single release-readiness
  command
- the command runs dependency/root/core/transport/test import guards,
  workspace analysis, workspace tests, and workspace publish dry-run by default
- `--skip-tests` and `--skip-publish-dry-run` support shorter smoke runs
- `--proxy=<url>` can pass HTTP proxy settings to child validation steps
- `--report=<path>` writes a Markdown release report
- focused tests cover option parsing, step planning, proxy environment
  construction, version reading, and report generation
- a short readiness smoke run passed with guards plus analysis while skipping
  the longest test and publish dry-run steps

## M2 - Package Metadata And Publish Order

Goals:

- freeze publish order
- verify package metadata against the implemented package ownership model
- avoid misleading compatibility-package descriptions

Acceptance criteria:

- every publishable package has reviewed `pubspec.yaml`, README, and changelog
- `llm_dart_core` is described as a compatibility shell
- `llm_dart_provider` is described as the shared provider/UI/serialization
  contract owner for the first alpha
- publish order is documented in both release docs and the readiness command

Current status:

- the publish order is documented in the previous workstream's release
  readiness checklist
- root and core package descriptions have already been corrected for the
  compatibility-shell role
- `02-package-metadata-and-publish-order.md` now records the alpha.1
  dependency-aware publish order, package ownership audit, and
  `llm_dart_test` non-publishable status
- the release-readiness report now prints the same publish order from the
  workspace bootstrap source of truth
- the release-readiness command now checks pub.dev target-version availability
  unless the publish dry-run or version check is explicitly skipped
- root README links have been cleaned to repository-relative paths, and public
  package README language no longer references the internal reference repo

## M3 - Clean Consumer Smoke

Goals:

- validate real consumer import and dependency behavior outside the repository
- cover modern root, focused packages, compatibility core, legacy, and Flutter

Acceptance criteria:

- clean Dart consumer smoke can resolve, analyze, and run without API keys
- clean Flutter consumer smoke can resolve, analyze, and test without API keys
- smoke checks are either automated or documented as explicit manual commands
- known Flutter test harness pitfalls are documented

Current status:

- automated clean Dart and Flutter consumer smoke validation is now part of the
  release-readiness command
- the command creates temporary consumer projects, validates path dependency
  resolution, analyzes them, runs no-key smoke coverage, and removes them
- after publish, repeat clean consumer smoke against pub.dev versions without
  local path overrides

## M4 - Alpha Publish Execution

Goals:

- execute or prepare the publish sequence for `0.11.0-alpha.x`
- validate packages after publication

Acceptance criteria:

- publish dry-run passes immediately before publishing
- packages are published in dependency order
- clean consumers resolve against pub.dev versions
- any alpha feedback is triaged into targeted follow-up work

Current status:

- a full local release-readiness run passed on 2026-05-08 with guards,
  analysis, tests, and workspace publish dry-run for 11 package(s)
- actual publishing has not started
