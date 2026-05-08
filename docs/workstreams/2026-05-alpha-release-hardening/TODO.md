# TODO

## Workstream Setup

- [x] Create the alpha release hardening workstream scaffold
- [x] Freeze release-hardening scope and non-goals

## Release Gate Automation

- [ ] Add `tool/release_readiness.dart`
- [ ] Run existing guard scripts from the release-readiness command
- [ ] Run `dart analyze lib test example tool`
- [ ] Run `dart test`
- [ ] Run `dart run tool/run_workspace_publish_dry_run.dart`
- [ ] Print a concise release report with elapsed time and failed-step context
- [ ] Add focused tests for command planning/reporting helpers

## Package Metadata And Publish Order

- [ ] Re-audit all publishable package `pubspec.yaml` descriptions
- [ ] Re-audit package README ownership language
- [ ] Re-audit package changelog entries for the alpha line
- [ ] Verify publish order against workspace dependencies
- [ ] Confirm `llm_dart_test` remains non-publishable

## Consumer Smoke Validation

- [ ] Decide whether consumer smoke is manual-only for alpha.1 or automated in
  the first readiness command
- [ ] Document clean Dart consumer smoke commands in the command output or docs
- [ ] Document clean Flutter consumer smoke commands in the command output or
  docs
- [ ] Add optional proxy handling for Flutter network checks if automated

## Publish Execution

- [ ] Run final release-readiness command
- [ ] Publish packages in dependency order
- [ ] Re-run clean consumer smoke against pub.dev versions
- [ ] Record alpha release feedback and decide the next targeted workstream
