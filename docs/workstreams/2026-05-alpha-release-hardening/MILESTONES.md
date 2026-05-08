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

- manual validation commands are documented in the previous workstream's
  release readiness checklist
- no unified command exists yet

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

- manual clean Dart and Flutter consumer smoke validation passed on
  2026-05-08
- the validation result is recorded in the previous release readiness checklist

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

- not started
