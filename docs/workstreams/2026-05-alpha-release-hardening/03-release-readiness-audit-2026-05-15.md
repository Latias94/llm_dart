# Release Readiness Audit - 2026-05-15

## Objective

Validate the current `refactor/architecture-foundation` branch as a local
`0.11.0-alpha.1` release candidate after the provider codec boundary and
fixture-contract refactors.

The release gate must prove:

- workspace and package dependency boundaries still hold
- root and focused package tests pass
- provider fixture contracts work from package-local test runs
- clean local consumers resolve, analyze, and run without API keys
- publish dry-runs pass for every publishable package
- the target pub.dev versions are still available

## Initial Failure

The first full run failed at `Workspace package tests`.

Failing command:

```powershell
dart tool/run_workspace_package_tests.dart
```

Failure cause:

- `openai_fixture_contract_test.dart` read golden fixtures through a
  repository-root relative path:
  `packages/llm_dart_openai/test/fixtures/...`
- `run_workspace_package_tests.dart` runs focused package tests from the
  package directory.
- From `packages/llm_dart_openai`, the root-relative fixture path does not
  exist.

Preventive fix:

- `packages/llm_dart_openai/test/openai_fixture_contract_test.dart`
- `packages/llm_dart_anthropic/test/anthropic_fixture_contract_test.dart`
- `packages/llm_dart_google/test/google_fixture_contract_test.dart`

Each fixture helper now tries both supported working directories:

- repository root: `packages/<provider>/test/fixtures`
- package root: `test/fixtures`

This keeps the same tests valid for direct root-level focused runs and
package-local release-gate runs.

## Focused Fix Validation

Commands run after the fix:

```powershell
dart test packages\llm_dart_openai\test\openai_fixture_contract_test.dart packages\llm_dart_anthropic\test\anthropic_fixture_contract_test.dart packages\llm_dart_google\test\google_fixture_contract_test.dart
```

Result:

- passed, 10 tests

Package-root fixture runs:

```powershell
cd packages\llm_dart_openai
dart test test\openai_fixture_contract_test.dart

cd packages\llm_dart_anthropic
dart test test\anthropic_fixture_contract_test.dart

cd packages\llm_dart_google
dart test test\google_fixture_contract_test.dart
```

Results:

- OpenAI fixture contracts: passed, 4 tests
- Anthropic fixture contracts: passed, 4 tests
- Google fixture contracts: passed, 2 tests

## Final Release Gate

Command:

```powershell
dart run tool\release_readiness.dart
```

Result:

```text
Started: 2026-05-15T15:40:55.826988
Finished: 2026-05-15T15:44:14.788953
Elapsed: 3m 18s
Result: passed
```

## Step Evidence

| Step | Status | Elapsed |
| --- | --- | ---: |
| Workspace dependency guards | passed | 491ms |
| Root package boundary guards | passed | 240ms |
| Core compatibility shell guard | passed | 199ms |
| Provider replay metadata guard | passed | 183ms |
| Transport boundary guard | passed | 215ms |
| Test legacy-import guard | passed | 190ms |
| Example API guard | passed | 252ms |
| Workspace analysis | passed | 1.583s |
| Workspace tests | passed | 18.481s |
| Workspace package tests | passed | 32.062s |
| Consumer smoke | passed | 53.648s |
| Workspace publish dry-run | passed | 1m 19s |
| Pub version availability | passed | 11.839s |

## Publish Dry-Run Evidence

`dart tool/run_workspace_publish_dry_run.dart` passed for 12 publishable
packages:

- `llm_dart_provider`
- `llm_dart_ai`
- `llm_dart_core`
- `llm_dart_transport`
- `llm_dart_chat`
- `llm_dart_openai`
- `llm_dart_google`
- `llm_dart_anthropic`
- `llm_dart_ollama`
- `llm_dart_elevenlabs`
- `llm_dart_flutter`
- `llm_dart`

The only dry-run hints were expected workspace local path dependency hints and
were suppressed by the dry-run tool.

## Pub Version Availability

`dart tool/check_pub_version_availability.dart` passed.

All focused packages are available as new packages at `0.11.0-alpha.1`.
The root package `llm_dart` is available as a new version at
`0.11.0-alpha.1`; latest published root version at audit time was `0.10.7`.

## Publish Order

The release-readiness report confirmed this dependency-aware publish order:

1. `llm_dart_provider`
2. `llm_dart_ai`
3. `llm_dart_core`
4. `llm_dart_transport`
5. `llm_dart_chat`
6. `llm_dart_openai`
7. `llm_dart_google`
8. `llm_dart_anthropic`
9. `llm_dart_ollama`
10. `llm_dart_elevenlabs`
11. `llm_dart_flutter`
12. `llm_dart`

## Completion Assessment

The branch is locally release-ready for `0.11.0-alpha.1` from the automated
gate's perspective.

Publishing has not started. Before publishing, re-run:

```powershell
dart run tool\release_readiness.dart
```

After publishing, run:

```powershell
dart run tool\run_consumer_smoke.dart --published
```

Record any alpha feedback as targeted follow-up work rather than reopening
broad architecture refactoring by default.
