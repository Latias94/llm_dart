# Release Readiness Command

## Purpose

Create a Dart-based command that turns the current manual release checklist
into a repeatable release gate.

Preferred entrypoint:

```bash
dart run tool/release_readiness.dart
```

The command is safe to run from the repository root and does not require
shell-specific behavior.

## Required Checks

The first version orchestrates the checks that are already proven:

- `dart run tool/check_workspace_dependency_guards.dart`
- `dart run tool/check_root_package_boundary_guards.dart`
- `dart run tool/check_provider_replay_metadata_guards.dart`
- `dart run tool/check_openai_provider_layout_guard.dart`
- `dart run tool/check_provider_metadata_namespace_guards.dart`
- `dart run tool/check_transport_boundary_guards.dart`
- `dart run tool/check_test_legacy_import_guards.dart`
- `dart run tool/check_example_api_guards.dart`
- `dart analyze lib test example tool`
- `dart test`
- `dart run tool/run_workspace_package_tests.dart`
- `dart run tool/run_consumer_smoke.dart`
- `dart run tool/run_workspace_publish_dry_run.dart`
- `dart run tool/check_pub_version_availability.dart`

The command records elapsed time and command exit codes.

Implemented flags:

- `--skip-publish-dry-run`
- `--skip-pub-version-check`
- `--skip-tests`
- `--skip-consumer-smoke`
- `--proxy=http://127.0.0.1:10809`
- `--report=path/to/report.md`
- `--no-consumer-smoke-checklist`

`--skip-tests` skips both the root `dart test` step and the focused package
test matrix. Use it only for short local iterations.

## Consumer Smoke Checks

The command now runs clean local consumer smoke validation by default:

- create temporary Dart and Flutter consumer projects
- wire local workspace packages through `path:` dependencies and dependency
  overrides
- run Dart package resolution, analysis, and a no-key smoke program
- run Flutter package resolution, analysis, and a pure controller/import test
- remove the temporary projects after the run

Use `--skip-consumer-smoke` only for short local iterations. After publishing,
repeat the same checks against pub.dev versions without local path overrides:

```bash
dart run tool/run_consumer_smoke.dart --published
```

Use `--version=<version>` with `--published` if the post-publish smoke should
target a version other than the root `pubspec.yaml` version.

## Flutter Notes

Flutter validation should use Flutter commands:

- `flutter pub get`
- `flutter analyze`
- `flutter test`

Do not execute Flutter package entrypoints with `dart run`; Flutter imports
depend on `dart:ui`.

For pure controller/import smoke tests, prefer `test(...)` over
`testWidgets(...)` unless the test actually pumps widgets.

If Flutter network resource checks are needed, allow proxy environment
variables to be passed through:

- `HTTP_PROXY`
- `HTTPS_PROXY`
- `NO_PROXY`

## Output Shape

The command prints:

- repository path
- package version being validated
- each command before it runs
- pass/fail status for each step
- elapsed time per step
- dependency-aware publish order
- pub.dev target-version availability
- final release readiness summary
- next action when a step fails

The output should be concise enough to paste into release notes or a PR.

## Non-Goals For The First Version

The first version does not need to:

- publish packages
- create tags
- mutate versions
- push commits
- update changelogs automatically
- accept Android licenses

Those are release execution tasks, not readiness checks.
