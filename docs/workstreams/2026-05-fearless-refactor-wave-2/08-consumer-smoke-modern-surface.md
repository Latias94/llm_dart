# Consumer Smoke Modern Surface

## Objective

Make the release gate itself prove the modern app-facing prompt surface in both
root and split-package consumer paths.

The root consumer smoke already used `ModelMessage`. The split-package smoke
still constructed a provider-contract `UserPromptMessage`, which meant the
consumer smoke gate continued to exercise provider-prompt usage for an
app-facing smoke path.

## Changes

Files changed:

- `tool/run_consumer_smoke.dart`
- `test/tool/run_consumer_smoke_test.dart`

Implementation:

- replace split-package `ai.UserPromptMessage.text(...)` with
  `ai.UserModelMessage.text(...)`
- replace the split-package `provider.PromptRole.user` assertion with
  `ai.ModelMessageRole.user`
- add a regression test that the split-package smoke program contains
  `UserModelMessage` / `ModelMessageRole` and does not contain
  `UserPromptMessage` / `PromptRole`

## Evidence

Commands:

```powershell
dart test test\tool\run_consumer_smoke_test.dart
dart run tool\run_consumer_smoke.dart --direct-package-config
dart run tool\run_consumer_smoke.dart
```

Run time:

- `2026-05-15T19:43+08:00` through `2026-05-15T19:45+08:00`

Results:

- focused tool test passed, 26/26 tests
- direct package-config consumer smoke passed, 7/7 programs
- full local consumer smoke passed, 24/24 steps

## Scope

This is a bounded implementation milestone. It does not change provider
contracts, runtime stream ownership, package layout, or compatibility trunks.

The remaining Wave 2 blocker is still release posture: publish
`0.11.0-alpha.1` and run published consumer smoke, or record an explicit
non-publish decision.
