# 142. Root Runtime Dependency Exit Status

## Goal

Track the remaining direct runtime dependencies of the root `llm_dart` package
after the recent compatibility-shell and workspace-package refactors, and keep
the exit path honest instead of cosmetic.

## Current Status

As of 2026-04-10:

- the root package still directly depends on `dio`
- the root package no longer directly depends on `logging`
- `llm_dart_transport` remains the owner of shared HTTP/SSE/logging primitives

This means the root dependency-exit story is now split:

- `logging` has already exited the root package
- `dio` still remains because real root-hosted compatibility/provider
  implementation weight is still present

## What Changed Since The Earlier Review

The root `logging` dependency became removable only after the following became
true together:

- root registry/bootstrap diagnostics moved off `package:logging` and onto SDK
  logging
- raw Dio cancellation inspection moved into `llm_dart_transport`
- `llm_dart_transport` re-exported the minimal shared logging primitives needed
  by compatibility and test code
- root/provider/example imports were switched from `package:logging` to
  transport-owned exports

This was not a cosmetic dependency deletion.

It was the result of moving ownership to the already-correct lower layer.

## Current Import Reality

Current direct imports under root `lib/`:

- `package:dio/dio.dart`: 30
- `package:logging/logging.dart`: 0

Current direct imports under root `example/`:

- `package:logging/logging.dart`: 0

The root package is therefore no longer a direct logging owner, but it is still
far from being free of transport-heavy implementation.

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

The remaining problem is not dependency direction.

It is root implementation weight.

## Where The Remaining Root Weight Still Lives

The remaining direct root `dio` imports still cluster in the same honest places:

### 1. Root compatibility HTTP infrastructure

Examples:

- `lib/src/compatibility/http/base_http_provider.dart`
- `lib/src/compatibility/http/http_response_handler.dart`
- `lib/src/compatibility/http/http_config_utils.dart`

### 2. Root-hosted compatibility clients

Examples:

- `lib/src/compatibility/providers/openai/client.dart`
- `lib/src/compatibility/providers/google/client.dart`
- `lib/src/compatibility/providers/anthropic/client.dart`

### 3. Remaining root-local community and legacy providers

Examples:

- `lib/providers/ollama/*`
- `lib/providers/elevenlabs/*`
- `lib/providers/phind/*`
- root-local OpenAI-compatible compatibility clients

## Frozen Policy

### Keep

- `llm_dart_transport` as the owner of shared logging primitives
- root/package/example logging imports routed through
  `package:llm_dart_transport/llm_dart_transport.dart` or
  `package:llm_dart/transport.dart`
- root `dio` removal coupled to real implementation movement, not declaration
  editing

### Do not do

- do not re-add `logging` as a direct root dependency for convenience imports
- do not introduce new root-local `package:logging/logging.dart` imports
- do not remove root `dio` before the remaining compatibility/provider clients
  actually stop hosting transport-heavy code

## Recommended Next Exit Path

The honest remaining exit path is now:

1. keep `logging` ownership frozen in `llm_dart_transport`
2. keep slimming root-local compatibility/provider clients that still own `dio`
3. move more real implementation weight into provider-owned packages
4. remove direct root `dio` only after the root package becomes mostly facade
   plus thin compatibility shells

## Related Notes

- `143-root-cancellation-dio-decoupling.md`
- `144-root-registry-logging-decoupling.md`
- `145-root-logging-transport-reexport.md`
