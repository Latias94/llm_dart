# Package Metadata And Publish Order

## Scope

This note records the alpha.1 metadata audit for the publishable workspace
packages. It is deliberately narrow: fix misleading public metadata, freeze the
dependency-aware publish order, and keep implementation refactors out of the
release-hardening stream.

## Publishable Packages

The publishable packages for `0.11.0-alpha.1` are:

1. `llm_dart_provider`
2. `llm_dart_ai`
3. `llm_dart_core`
4. `llm_dart_transport`
5. `llm_dart_chat`
6. `llm_dart_openai`
7. `llm_dart_google`
8. `llm_dart_anthropic`
9. `llm_dart_community`
10. `llm_dart_flutter`
11. `llm_dart`

`packages/llm_dart_test` remains non-publishable through `publish_to: none`.

## Dependency Rationale

The order follows the current workspace dependency graph:

- `llm_dart_provider` owns the stable provider-facing contracts and has no
  workspace dependency.
- `llm_dart_ai` builds runtime helpers on top of `llm_dart_provider`.
- `llm_dart_core` is a compatibility shell over `llm_dart_provider` and
  `llm_dart_ai`.
- `llm_dart_transport` depends on `llm_dart_provider`.
- `llm_dart_chat` depends on `llm_dart_provider` and `llm_dart_transport`.
- provider packages publish after `llm_dart_provider`, `llm_dart_transport`,
  and `llm_dart_ai`.
- `llm_dart_flutter` publishes after `llm_dart_chat` and
  `llm_dart_provider`.
- root `llm_dart` publishes last after all direct focused dependencies are
  resolvable from pub.dev.

`tool/bootstrap_workspace_pubspec_overrides.dart` owns the source-of-truth
`publishableWorkspacePackages` list, and `tool/release_readiness.dart` prints
that order in the generated report.

`tool/check_pub_version_availability.dart` also uses the same package list to
verify target versions on pub.dev before publishing.

## Metadata Audit

The package metadata is aligned with the current ownership model:

- root `llm_dart` is the modern facade and compatibility migration host.
- `llm_dart_provider` owns provider contracts, shared prompt/result/UI models,
  and serialization codecs.
- `llm_dart_ai` owns framework-neutral runtime helpers and runners.
- `llm_dart_core` is explicitly compatibility-focused, not the owner of new
  contracts.
- `llm_dart_transport` owns HTTP/SSE/Dio transport primitives.
- `llm_dart_chat` owns pure Dart chat/session runtime behavior.
- `llm_dart_flutter` is a thin Flutter adapter above `llm_dart_chat`.
- provider packages own provider-native codecs, typed options, custom parts,
  capability descriptors, and provider-specific helper APIs.

Public README fixes made in this audit:

- root README example and reference links now use repository-relative paths
  instead of local machine paths.
- `llm_dart_community` README no longer mentions the internal reference repo in
  public package positioning.

## Validation

Full release readiness was run on 2026-05-08 with:

```bash
dart run tool/release_readiness.dart --proxy=http://127.0.0.1:10809 --report=build/release_readiness.md
```

Result:

- release readiness passed
- guards passed
- `dart analyze lib test example tool` passed
- `dart test` passed
- workspace publish dry-run passed for 11 packages
- pub.dev version availability passed: the 10 newly split package names were
  not found on pub.dev, root `llm_dart` had latest `0.10.7`, and
  `0.11.0-alpha.1` was available for every publishable package
- publish dry-run reported `0 warnings`; remaining hints are the expected local
  `pubspec_overrides.yaml` hints while packages are still unpublished
