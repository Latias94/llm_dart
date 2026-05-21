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

`packages/llm_dart_test` remains non-publishable through `publish_to: none`.

## Dependency Rationale

The order follows the current workspace dependency graph:

- `llm_dart_provider` owns the stable provider-facing contracts and has no
  workspace dependency.
- `llm_dart_ai` builds runtime helpers on top of `llm_dart_provider`.
- `llm_dart_transport` depends on `llm_dart_provider`.
- `llm_dart_provider_utils` depends on `llm_dart_provider` and
  `llm_dart_transport`, and owns provider-aware transport-call helpers.
- `llm_dart_chat` depends on `llm_dart_provider`, `llm_dart_transport`, and
  `llm_dart_provider_utils`.
- provider packages publish after `llm_dart_provider`, `llm_dart_transport`,
  `llm_dart_provider_utils`, and `llm_dart_ai` where applicable.
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
- `llm_dart_transport` owns HTTP/SSE/Dio transport primitives.
- `llm_dart_provider_utils` owns provider-facing transport-call helpers,
  stream decoding bridges, and transport-to-model error projection.
- `llm_dart_chat` owns pure Dart chat/session runtime behavior.
- `llm_dart_flutter` is a thin Flutter adapter above `llm_dart_chat`.
- provider packages own provider-native codecs, typed options, custom parts,
  capability descriptors, and provider-specific helper APIs.

Public README fixes made in this audit:

- root README example and reference links now use repository-relative paths
  instead of local machine paths.
- the dedicated Ollama and ElevenLabs README files describe direct focused
  provider-package adoption rather than a catch-all provider bucket.

## Validation

Post-boundary-reset fast validation was run on 2026-05-21 with:

```bash
dart --suppress-analytics run tool/release_readiness.dart --skip-tests --skip-consumer-smoke --skip-publish-dry-run --report=build/release_readiness_post_fbr_fast.md
```

Result:

- release readiness fast gate passed
- dependency/root/replay/layout/metadata/transport/test/example guards passed
- `dart analyze lib test example tool` passed
- generated publish order now excludes `llm_dart_core` and includes
  `llm_dart_provider_utils`

The full release gate must still be rerun after this rebaseline before
publishing.

Full release readiness was run on 2026-05-08 with:

```bash
dart run tool/release_readiness.dart --proxy=http://127.0.0.1:10809 --report=build/release_readiness.md
```

Result:

- release readiness passed
- guards passed
- `dart analyze lib test example tool` passed
- `dart test` passed
- workspace publish dry-run passed for 12 packages after the dedicated
  Ollama and ElevenLabs package split
- pub.dev version availability passed: the newly split package names were
  not found on pub.dev, root `llm_dart` had latest `0.10.7`, and
  `0.11.0-alpha.1` was available for every publishable package
- publish dry-run reported `0 warnings`; remaining hints are the expected local
  `pubspec_overrides.yaml` hints while packages are still unpublished
