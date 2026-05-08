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
- `dart run tool/check_core_compatibility_shell_guard.dart`
- `dart run tool/check_transport_boundary_guards.dart`
- `dart run tool/check_test_legacy_import_guards.dart`
- `dart analyze lib test example tool`
- `dart test`
- `dart run tool/run_workspace_publish_dry_run.dart`
- `dart run tool/check_pub_version_availability.dart`

The command records elapsed time and command exit codes.

Implemented flags:

- `--skip-publish-dry-run`
- `--skip-pub-version-check`
- `--skip-tests`
- `--proxy=http://127.0.0.1:10809`
- `--report=path/to/report.md`
- `--no-consumer-smoke-checklist`

## Consumer Smoke Checks

The command currently supports consumer smoke validation as a manual report
section. Future versions can add an automated full mode.

- default mode: print the consumer smoke checklist as a manual post-step
- full mode: create temporary Dart and Flutter consumer projects, run their
  package resolution, analysis, and no-key smoke tests, then remove them

The full mode remains deferred until the basic command has been used in the
alpha publish flow.

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
