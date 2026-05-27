# llm_dart Context

Last updated: 2026-05-27

This document names the project concepts and frozen seams that future
architecture work should preserve unless a new ADR explicitly supersedes them.

## Project Purpose

`llm_dart` is a Dart-native LLM SDK with a unified app-facing interface and
provider-owned support for provider-native features. It takes layering lessons
from mature SDKs such as Vercel AI SDK without copying their TypeScript package
shape.

The library optimizes for:

- one stable app-facing generation interface;
- typed provider options and capability discovery;
- provider-native request, stream, tool, and result behavior staying close to
  the provider package that owns it;
- release-facing contracts that are guarded by local tools and fixture tests.

## Core Modules

### Root Facade

The root package is a thin facade. `lib/llm_dart.dart` exports the app-facing
surface and `lib/core.dart` points to the focused app entrypoint. Root code must
not regain implementation ownership for providers, runtime orchestration, or
legacy compatibility.

### App Runtime

`llm_dart_ai` owns app-facing text generation, structured output, runtime
stream events, tool-loop orchestration, and provider-to-app event projection.
Its Interface is the one app users should learn first.

### Provider Contract

`llm_dart_provider` owns provider-facing model contracts, content/tool/result
data structures, capability descriptors, provider registry interfaces, and
provider option transport types. It must stay free of root, chat, Flutter, and
provider-package implementation dependencies.

### Provider Packages

Provider packages such as `llm_dart_openai`, `llm_dart_anthropic`,
`llm_dart_google`, `llm_dart_ollama`, and `llm_dart_elevenlabs` own concrete
wire codecs, provider-native options, native tool declarations, stream parsing,
result projection, and compatibility policy for their provider family.

### Chat Transport

`llm_dart_chat` owns chat session lifecycle and HTTP chat transport projection.
HTTP chat transport version policy is frozen by
`HttpChatTransportProtocolPolicy`: new payloads default to UI message stream v2,
while legacy payloads missing `streamProtocol` decode as event stream v1.

### Transport

`llm_dart_transport` owns HTTP client and cancellation transport primitives.
Provider packages call transport through provider utilities instead of importing
the root facade.

### Test Support

`llm_dart_test` is non-publishable test support. It may contain fixture runners,
fake models, and contract helpers used by provider tests. It must not become a
public provider implementation kit without a new ADR.

### Release Ledger

`docs/release/release_ledger.json` is the machine-readable release posture. It
records publishable packages, non-publishable support packages, release-facing
workstreams, required gates, and known deferrals. `pub publish` remains a
manual maintainer-approved step.

## Frozen Seams

- App runtime seam: app orchestration belongs in `llm_dart_ai`, not provider
  packages or the root facade.
- Provider wire seam: request/stream/result codecs belong in provider packages.
- Provider option seam: typed provider options stay provider-owned; ordinary
  app request metadata must not become provider configuration.
- HTTP chat protocol seam: v1/v2 compatibility is explicit policy, not implicit
  fallback behavior spread across transport code.
- Fixture seam: provider-local golden tests assert stable wire contracts; shared
  fixture helpers stay test-only until repeated public adapters prove a real
  seam.
- Release seam: release readiness is guarded by local tools and evidence files,
  not by manual reading of historical workstreams.

## Rejected Directions

- Reintroducing `llm_dart_core`.
- Moving provider-native features into a generic runtime registry before
  repeated adapters prove the seam.
- Removing app facade symbols immediately before alpha without a migration
  window.
- Hiding provider request/stream behavior behind a public provider
  implementation kit.
- Automating publish from local guard success.

## Required Local Gates

```powershell
dart --suppress-analytics analyze .
dart --suppress-analytics run tool/check_workspace_dependency_guards.dart
dart --suppress-analytics run tool/check_root_package_boundary_guards.dart
dart --suppress-analytics run tool/check_example_api_guards.dart
dart --suppress-analytics run tool/check_release_ledger.dart
dart --suppress-analytics run tool/check_app_facade_exports.dart
git diff --check
```
