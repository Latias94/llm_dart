# 142. Root Runtime Dependency Exit Status

## Goal

Re-evaluate the current dependency usage and dependency direction after the
recent compatibility and package-ownership refactors, with special attention to
why the root `llm_dart` package still directly depends on `dio` and `logging`.

## What Was Reviewed

- `pubspec.yaml`
- `packages/*/pubspec.yaml`
- `lib/` import usage for `package:dio/dio.dart`
- `lib/` import usage for `package:logging/logging.dart`
- `docs/workstreams/2026-03-architecture-refactor/06-dependencies-and-provider-features.md`
- `docs/workstreams/2026-03-architecture-refactor/97-dependency-direction-and-export-graph-audit.md`

## Current Workspace Direction

The package graph is still directionally healthy:

- `llm_dart_core`
  - no runtime third-party dependencies
- `llm_dart_transport`
  - depends on `llm_dart_core`
  - owns `dio`
  - owns `logging`
- `llm_dart_chat`
  - depends on `llm_dart_core`
  - depends on `llm_dart_transport`
- provider packages
  - depend on `llm_dart_core`
  - depend on `llm_dart_transport`
- `llm_dart_flutter`
  - depends on `llm_dart_core`
  - depends on `llm_dart_chat`
- root `llm_dart`
  - depends downward on the workspace packages
  - still hosts compatibility and residual legacy implementation code

Most importantly:

- no provider package depends on the root package
- the old `core -> transport` cycle is still gone
- modern provider packages are not pulling compatibility code back upward

## Current Root Runtime Dependency Reality

The root package still directly depends on:

- `dio`
- `logging`

That is still a migration artifact, not the intended steady-state design.

### Current import counts

Current direct imports under `lib/`:

- `package:dio/dio.dart`: 31
- `package:logging/logging.dart`: 16

Current direct imports under `packages/`:

- `package:dio/dio.dart`: 10
- `package:logging/logging.dart`: 5

This shows the important split clearly:

- the package-owned modern layers are already relatively disciplined
- the root package is still carrying the transitional weight

## Where The Remaining Root Weight Actually Lives

The remaining direct root `dio` / `logging` imports cluster in four places.

### 1. Root compatibility HTTP infrastructure

Examples:

- `lib/src/compatibility/http/base_http_provider.dart`
- `lib/src/compatibility/http/http_response_handler.dart`
- `lib/src/compatibility/http/http_config_utils.dart`

These files are honest compatibility-hosting infrastructure. They still justify
temporary root ownership of transport implementation details.

### 2. Root-hosted OpenAI / Google / Anthropic compatibility clients

Examples:

- `lib/src/compatibility/providers/openai/client.dart`
- `lib/src/compatibility/providers/google/client.dart`
- `lib/src/compatibility/providers/anthropic/client.dart`

These are compatibility-era provider implementations, not stable provider-owned
modern package code.

### 3. Remaining root-local community and legacy providers

Examples:

- `lib/providers/ollama/*`
- `lib/providers/elevenlabs/*`
- `lib/providers/phind/*`
- some OpenAI-compatible root-local client helpers

As long as these still live in the root package, root dependency slimming
cannot be completed honestly.

### 4. Small compatibility helper surfaces

Examples:

- `lib/core/cancellation.dart`
- `lib/src/config/legacy_dio_client_overrides.dart`
- `lib/src/config/legacy_config_extensions.dart`

These are comparatively small, but they still confirm that the root package is
not only a facade yet.

## Dependency Direction Conclusion

The inter-package dependency direction is now mostly stable.

The main remaining issue is not package direction anymore.

It is root implementation weight.

In other words:

- the workspace graph is largely correct
- the root package is still too heavy because compatibility and residual
  provider code still lives there
- direct root `dio` and `logging` removal should happen only after more code
  leaves the root package

## Frozen Policy

### Keep

- `llm_dart_core` free of runtime transport or provider dependencies
- `llm_dart_transport` as the owner of `dio` and `logging` for modern package
  paths
- provider packages depending only on lower shared layers
- Flutter depending on `llm_dart_chat` instead of concrete providers

### Do not do

- do not remove root `dio` or `logging` cosmetically before the remaining
  root-hosted implementation weight moves out
- do not add new runtime third-party dependencies to the root package for newly
  migrated functionality
- do not move package-owned modern provider logic back into the root package
  just because compatibility shells still exist there

## Recommended Exit Path

The remaining root runtime dependency exit path should stay:

1. keep shrinking root-hosted community or compatibility provider code
2. keep pushing modern provider logic into owning packages
3. reduce root-local direct `dio` / `logging` hotspots as a consequence of
   those moves
4. remove root `dio` and `logging` only when the root package becomes mostly
   facade plus compatibility shells without local transport-heavy clients

## OpenAI-Specific Implication

This also reinforces the OpenAI helper policy:

- do not widen deprecated root OpenAI-compatible helper constructors into new
  profile-specific modern bridges
- keep modern profile-aware ownership in `llm_dart_openai` and the `AI` facade
- keep root OpenAI code focused on compatibility and residual APIs

That keeps dependency ownership and architecture direction aligned.
