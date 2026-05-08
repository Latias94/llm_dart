# TODO

## Workstream Setup

- [x] Create the alpha release hardening workstream scaffold
- [x] Freeze release-hardening scope and non-goals

## Release Gate Automation

- [x] Add `tool/release_readiness.dart`
- [x] Run existing guard scripts from the release-readiness command
- [x] Run `dart analyze lib test example tool`
- [x] Run `dart test`
- [x] Run `dart run tool/run_workspace_publish_dry_run.dart`
- [x] Print a concise release report with elapsed time and failed-step context
- [x] Add focused tests for command planning/reporting helpers

## Package Metadata And Publish Order

- [ ] Re-audit all publishable package `pubspec.yaml` descriptions
- [ ] Re-audit package README ownership language
- [ ] Re-audit package changelog entries for the alpha line
- [ ] Verify publish order against workspace dependencies
- [ ] Confirm `llm_dart_test` remains non-publishable

## Consumer Smoke Validation

- [x] Decide whether consumer smoke is manual-only for alpha.1 or automated in
  the first readiness command
- [x] Document clean Dart consumer smoke commands in the command output or docs
- [x] Document clean Flutter consumer smoke commands in the command output or
  docs
- [x] Add optional proxy handling for Flutter network checks if automated

## Publish Execution

- [ ] Run final release-readiness command
- [ ] Publish packages in dependency order
- [ ] Re-run clean consumer smoke against pub.dev versions
- [ ] Record alpha release feedback and decide the next targeted workstream
