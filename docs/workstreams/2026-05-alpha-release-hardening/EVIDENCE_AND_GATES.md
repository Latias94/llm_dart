# Alpha Release Hardening — Evidence And Gates

Status: Active
Last updated: 2026-05-21

## Required Post-Reset Gates

Before publishing:

```powershell
dart --suppress-analytics test test/tool/release_readiness_test.dart test/tool/run_workspace_publish_dry_run_test.dart test/tool/run_consumer_smoke_test.dart test/tool/check_transport_boundary_guards_test.dart
dart --suppress-analytics run tool/run_workspace_publish_dry_run.dart --package=llm_dart_provider_utils --package=llm_dart_chat --package=llm_dart
dart --suppress-analytics run tool/release_readiness.dart
git diff --check
```

If pub.dev access fails, retry the full release gate with:

```powershell
dart --suppress-analytics run tool/release_readiness.dart --proxy=http://127.0.0.1:10809
```

Current decision: locally release-ready. Do not treat the workstream as
published until packages are actually published in the documented order and
post-publish consumer smoke passes against pub.dev versions.

## ARH-120 — Fast Release Gate

Command:

```powershell
dart --suppress-analytics run tool/release_readiness.dart --skip-tests --skip-consumer-smoke --skip-publish-dry-run --report=build/release_readiness_post_fbr_fast.md
```

Result: passed.

Evidence:

- `build/release_readiness_post_fbr_fast.md`
- 9/9 steps passed:
  - workspace dependency guards
  - root package boundary guards
  - provider replay metadata guard
  - OpenAI provider layout guard
  - provider metadata namespace guard
  - transport boundary guard
  - test legacy-import guard
  - example API guard
  - workspace analysis
- Generated publish order:
  1. `llm_dart_provider`
  2. `llm_dart_ai`
  3. `llm_dart_transport`
  4. `llm_dart_provider_utils`
  5. `llm_dart_chat`
  6. `llm_dart_openai`
  7. `llm_dart_google`
  8. `llm_dart_anthropic`
  9. `llm_dart_ollama`
  10. `llm_dart_elevenlabs`
  11. `llm_dart_flutter`
  12. `llm_dart`

Assessment:

- The old `llm_dart_core` release path is gone.
- Release-readiness command wiring matches the new guard set.
- This is not enough to publish; tests, consumer smoke, publish dry-run, and
  pub.dev version availability still need a fresh full run.

## ARH-130 — Targeted Tooling And Publish Smoke

Command:

```powershell
dart --suppress-analytics test test/tool/release_readiness_test.dart test/tool/run_workspace_publish_dry_run_test.dart test/tool/run_consumer_smoke_test.dart test/tool/check_transport_boundary_guards_test.dart
```

Result: passed, 58 tests.

Command:

```powershell
dart --suppress-analytics run tool/run_workspace_publish_dry_run.dart --package=llm_dart_provider_utils --package=llm_dart_chat --package=llm_dart
```

Result: passed for 3 package(s).

Dry-run summaries:

- `llm_dart_provider_utils`: 0 warnings, 2 expected workspace override hints.
- `llm_dart_chat`: 0 warnings, 4 expected workspace override hints.
- `llm_dart`: 0 warnings, 5 expected workspace override hints.

Assessment:

- The provider-utils package is publishable from the staged dry-run view.
- The dependent chat and root packages still dry-run cleanly against the
  changed graph.
- Full release readiness remains required before publishing.

## ARH-140 — Full Release Readiness

Command:

```powershell
dart --suppress-analytics run tool/release_readiness.dart --report=build/release_readiness_post_fbr_full.md
```

Result: passed.

Report:

- `build/release_readiness_post_fbr_full.md`

Step evidence:

| Step | Status | Elapsed |
| --- | --- | ---: |
| Workspace dependency guards | passed | 2.811s |
| Root package boundary guards | passed | 700ms |
| Provider replay metadata guard | passed | 493ms |
| OpenAI provider layout guard | passed | 465ms |
| Provider metadata namespace guard | passed | 1.063s |
| Transport boundary guard | passed | 563ms |
| Test legacy-import guard | passed | 516ms |
| Example API guard | passed | 686ms |
| Workspace analysis | passed | 7.270s |
| Workspace tests | passed | 9.720s |
| Workspace package tests | passed | 53.758s |
| Consumer smoke | passed | 1m 52s |
| Workspace publish dry-run | passed | 3m 26s |
| Pub version availability | passed | 4.933s |

Publish dry-run evidence:

- Passed for 12 package(s).
- `llm_dart_provider`, `llm_dart_ai`, `llm_dart_transport`,
  `llm_dart_provider_utils`, `llm_dart_chat`, `llm_dart_openai`,
  `llm_dart_google`, `llm_dart_anthropic`, `llm_dart_ollama`,
  `llm_dart_elevenlabs`, `llm_dart_flutter`, and `llm_dart`.
- All packages reported 0 warnings.
- Remaining hints were expected local workspace override hints where package
  dependencies are not yet published.

Pub version availability:

- Focused packages are available as new packages at `0.11.0-alpha.1`.
- Root `llm_dart` is available as a new version at `0.11.0-alpha.1`; latest
  published root version at the check time was `0.10.7`.

Decision:

- The branch is locally release-ready for `0.11.0-alpha.1` after the fearless
  boundary reset.
- Next action is publish execution in the documented dependency order, then
  `dart --suppress-analytics run tool/run_consumer_smoke.dart --published`.
