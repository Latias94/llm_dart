# 142. Root Runtime Dependency Exit Status

## Goal

Track the root `llm_dart` package dependency-exit status after the staged
transport and compatibility-shell refactors, and keep the exit story honest.

## Current Status

As of 2026-04-10:

- the root package no longer directly depends on `dio`
- the root package no longer directly depends on `logging`
- `llm_dart_transport` owns shared HTTP, SSE, logging, and explicit raw-Dio
  compatibility entrypoints

This means the direct runtime dependency exit is complete even though root
implementation weight still exists.

## What Changed Across The Last Two Slices

The root direct dependency exit completed in two steps:

1. logging moved behind transport-owned exports
2. raw Dio imports moved behind explicit transport-owned sub-entrypoints

Concretely:

- root registry/bootstrap diagnostics moved off `package:logging`
- `llm_dart_transport` now re-exports shared logging primitives from its main
  barrel
- root/provider/test/example logging imports now use transport-owned exports
- `llm_dart_transport` now also exposes explicit raw-Dio sub-entrypoints:
  - `package:llm_dart_transport/dio.dart`
  - `package:llm_dart_transport/dio_io.dart`
- root/provider/test/example raw-Dio imports now use those transport-owned
  entrypoints instead of importing `package:dio` directly

## Current Import Reality

Current direct imports under root `lib/`:

- `package:dio/dio.dart`: 0
- `package:logging/logging.dart`: 0
- `package:llm_dart_transport/dio.dart`: 30

Current direct imports under root `example/`:

- `package:dio/dio.dart`: 0
- `package:logging/logging.dart`: 0
- `package:llm_dart_transport/dio.dart`: 1

Current direct imports under root `test/`:

- `package:llm_dart_transport/dio.dart`: 17
- `package:llm_dart_transport/dio_io.dart`: 1

The root package therefore no longer owns direct transport-implementation
dependencies, but it still hosts compatibility code that depends on
transport-owned implementation entrypoints.

## Dependency Direction Status

The package graph remains directionally healthy:

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
- root `llm_dart`
  - depends downward on workspace packages
  - still hosts compatibility and residual legacy implementation code

The main remaining problem is no longer direct dependency ownership.

It is root implementation weight.

## What Still Remains

The root package still hosts real compatibility/provider code such as:

- compatibility HTTP helpers
- compatibility clients for OpenAI / Google / Anthropic
- residual root-local community and legacy providers
- compatibility-era config adapters and helper wrappers

That weight still matters for maintainability, but it no longer forces direct
root ownership of `dio` or `logging`.

## Frozen Policy

### Keep

- `llm_dart_transport` as the owner of `dio` and `logging`
- raw Dio access behind explicit transport-owned entrypoints instead of the
  root default facade
- root logging access behind transport-owned exports instead of direct package
  imports

### Do not do

- do not re-add `dio` or `logging` as direct root dependencies for convenience
- do not introduce new root-local `package:dio/*` or
  `package:logging/logging.dart` imports
- do not export raw Dio from the root default modern facade just because the
  compatibility layer still uses it internally

## Recommended Next Step

Now that the direct dependency exit is complete, the next honest cleanup target
is narrower:

1. keep shrinking root-hosted compatibility/provider implementation weight
2. keep moving real implementation into provider-owned packages
3. leave raw Dio ownership in transport, even if compatibility code still uses
   it

## Related Notes

- `21-residual-dio-public-surface.md`
- `143-root-cancellation-dio-decoupling.md`
- `144-root-registry-logging-decoupling.md`
- `145-root-logging-transport-reexport.md`
- `146-root-dio-transport-subentry.md`
