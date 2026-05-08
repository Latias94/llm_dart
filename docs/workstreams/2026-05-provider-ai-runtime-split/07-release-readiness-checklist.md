# Release Readiness Checklist

This checklist is the release-facing closeout for the provider and AI runtime
split. It records the validation commands, dry-run expectations, and remaining
manual decisions before publishing the breaking preview.

## Latest Validation Record

Recorded on 2026-05-08:

- `dart run tool/check_workspace_dependency_guards.dart` passed.
- `dart run tool/check_root_package_boundary_guards.dart` passed.
- `dart run tool/check_core_compatibility_shell_guard.dart` passed.
- `dart run tool/check_transport_boundary_guards.dart` passed.
- `dart run tool/check_test_legacy_import_guards.dart` passed.
- `dart analyze lib test example tool` passed.
- `dart test` passed.
- `dart run tool/run_workspace_publish_dry_run.dart` passed for all 11
  publishable workspace packages.

## Publish Dry-Run Expectations

The workspace publish dry-run stages every package in a temporary directory and
rewrites local path overrides for validation. A successful run must report zero
warnings for every package.

Expected local hints:

- Packages that depend on other workspace packages can report
  `Non-dev dependencies are overridden in pubspec_overrides.yaml`.
- These hints are acceptable for local dry-run validation because the script
  validates the unpublished workspace graph before the packages exist on
  pub.dev.
- Any warning is a blocker. The dry-run script intentionally fails on warnings.

Publishable package order:

- `llm_dart_provider`
- `llm_dart_ai`
- `llm_dart_core`
- `llm_dart_transport`
- `llm_dart_chat`
- `llm_dart_openai`
- `llm_dart_google`
- `llm_dart_anthropic`
- `llm_dart_community`
- `llm_dart_flutter`
- `llm_dart`

## Pre-Publish Blockers

Do not publish the breaking preview until all of these are true:

- `CHANGELOG.md` names the breaking imports, removed barrels, and replacement
  paths for the root package.
- Provider package changelogs name their new dependency and entrypoint posture
  where applicable.
- The migration matrix is current for every removed or moved public path.
- Workspace dependency guards match the package graph that will be published.
- Root boundary guards reject new implementation ownership in legacy root
  locations.
- The dry-run command passes with zero warnings.
- There are no untracked generated files except ignored
  `pubspec_overrides.yaml` files.

## Manual Release Checklist

Before publishing:

- Re-run the full validation record from this file.
- Confirm `pubspec.yaml` versions are aligned across the workspace.
- Confirm package descriptions, repository links, topics, and screenshots or
  examples are accurate for the breaking preview.
- Confirm release notes explain the intended architecture rather than only
  listing path changes.
- Confirm examples use focused modern entrypoints unless they intentionally
  demonstrate `legacy.dart`.

During publishing:

- Publish the lower-level packages first, following the publishable package
  order above.
- After each package is published, validate that the next package resolves
  against pub.dev without relying on local overrides when practical.
- Treat any server-side warning or validation change as a blocker until it is
  understood.

After publishing:

- Create a clean consumer project and verify imports for the modern root facade.
- Verify focused imports for `llm_dart_provider`, `llm_dart_ai`, transport,
  chat, Flutter, and the provider packages.
- Verify one legacy compatibility smoke test still compiles with
  `package:llm_dart/legacy.dart`.
- Check generated API docs for the public entrypoints that were moved or
  consolidated.

## Stop Conditions

Stop and fix the release branch instead of continuing publication when:

- A dry-run warning appears.
- A package resolves through a local path override after the dependency has
  already been published and should resolve from pub.dev.
- A public compatibility path is undocumented in the migration matrix.
- A package exposes internal compatibility infrastructure as a first-class
  public API.
- A root package path starts owning new provider-specific implementation code.
