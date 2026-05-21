# Milestones

## M1 - Release Gate Automation

Goals:

- introduce a single release-readiness command
- keep the command Dart-based and shell-neutral
- make failures easy to diagnose

Acceptance criteria:

- the command runs existing guard scripts
- the command runs analysis and tests
- the command runs focused package-local tests
- the command runs workspace publish dry-run unless explicitly skipped
- command behavior has focused tests where practical
- documentation explains supported flags and manual follow-up steps

Current status:

- `tool/release_readiness.dart` now exists as the single release-readiness
  command
- the command runs dependency/root/core/transport/test import guards,
  workspace analysis, root tests, focused package tests, and workspace publish
  dry-run by default
- `--skip-tests` skips root and focused package tests for shorter smoke runs
  while `--skip-publish-dry-run` skips publish dry-runs
- `--proxy=<url>` can pass HTTP proxy settings to child validation steps
- `--report=<path>` writes a Markdown release report
- focused tests cover option parsing, step planning, proxy environment
  construction, version reading, and report generation
- a short readiness smoke run passed with guards plus analysis while skipping
  the longest test and publish dry-run steps
- `tool/run_workspace_package_tests.dart` now runs the focused Dart package
  test suites and the Flutter package test suite through Flutter tooling

## M2 - Package Metadata And Publish Order

Goals:

- freeze publish order
- verify package metadata against the implemented package ownership model
- avoid misleading compatibility-package descriptions

Acceptance criteria:

- every publishable package has reviewed `pubspec.yaml`, README, and changelog
- the deleted `llm_dart_core` package is absent from the publishable graph and
  documented only as a removed migration source
- `llm_dart_provider_utils` is described as a provider-implementation utility
  package, not as an application-facing runtime
- `llm_dart_provider` is described as the shared provider/UI/serialization
  contract owner for the first alpha
- publish order is documented in both release docs and the readiness command

Current status:

- the publish order is documented in the previous workstream's release
  readiness checklist
- root package descriptions point to focused root and direct provider
  entrypoints; the historical core package has been removed
- `02-package-metadata-and-publish-order.md` now records the alpha.1
  dependency-aware publish order, package ownership audit, and
  `llm_dart_test` non-publishable status
- the release-readiness report now prints the same publish order from the
  workspace bootstrap source of truth
- the release-readiness command now checks pub.dev target-version availability
  unless the publish dry-run or version check is explicitly skipped
- root README links have been cleaned to repository-relative paths, and public
  package README language no longer references the internal reference repo
- after the fearless boundary reset, the publish order was rebaselined to
  remove `llm_dart_core` and include `llm_dart_provider_utils`

## M3 - Clean Consumer Smoke

Goals:

- validate real consumer import and dependency behavior outside the repository
- cover modern root, focused packages, provider utility dependency resolution,
  and Flutter

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
- post-boundary-reset consumer smoke still needs one fresh full readiness run
  before publish execution

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

- a full local release-readiness run passed on 2026-05-11 with guards,
  analysis, root tests, consumer smoke, and workspace publish dry-run for 12
  package(s)
- a full local release-readiness run passed again on 2026-05-15 after the
  provider fixture-contract refactors; the run covered all 13 release steps,
  including workspace package tests, consumer smoke, publish dry-runs for 12
  package(s), and pub.dev version availability
- the 2026-05-15 audit fixed package-root fixture lookup for OpenAI,
  Anthropic, and Google fixture contract tests before the final green run
- actual publishing has not started
- because the package graph changed after the 2026-05-15 full gate, a fresh
  full `dart run tool/release_readiness.dart` run is required before publishing
