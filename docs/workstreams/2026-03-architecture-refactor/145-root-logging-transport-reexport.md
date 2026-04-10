# 145. Root Logging Transport Re-export

## Goal

Remove the direct `logging` runtime dependency from the root `llm_dart`
package without lying about ownership and without breaking existing public
entrypoints.

## Decision

`llm_dart_transport` now re-exports the minimal shared logging primitives:

- `Logger`
- `Level`
- `LogRecord`
- `hierarchicalLoggingEnabled`

Root compatibility code, tests, and examples must import those primitives
through transport-owned exports instead of importing `package:logging`
directly.

## Why This Is The Right Layer

The logging dependency already belonged conceptually to the transport layer:

- HTTP configuration and interceptors are transport concerns
- request/response diagnostics are transport concerns
- modern provider packages already depend on `llm_dart_transport`
- the root package already re-exports transport entrypoints through
  `transport.dart`, `ai.dart`, and `llm_dart.dart`

Because of that, a transport-owned re-export keeps dependency direction
consistent while preserving a convenient public surface.

## What Changed

### Transport package

- `packages/llm_dart_transport/lib/llm_dart_transport.dart`
  now re-exports the shared logging primitives

### Root compatibility and provider code

The remaining root-hosted compatibility/provider modules that still need
logging now import it through `llm_dart_transport`, including:

- compatibility HTTP helpers
- root-hosted OpenAI / Google / Anthropic compatibility clients
- residual root-local DeepSeek / Groq / xAI / Ollama / Phind / ElevenLabs
  clients

### Tests and examples

- root logging tests now import logging primitives through
  `package:llm_dart_transport/llm_dart_transport.dart`
- the advanced HTTP configuration example now imports logging through
  `package:llm_dart/transport.dart`
- the MCP example README snippet now teaches the same transport-owned import
  path

### Package manifest

- root `pubspec.yaml` no longer lists `logging`

## Public API Implication

This change keeps the public experience stable:

- consumers can still access logging primitives through
  `package:llm_dart/transport.dart`
- consumers using `package:llm_dart/ai.dart` or
  `package:llm_dart/llm_dart.dart` also keep seeing the transport re-exports

The dependency moved downward, but the user-facing entry surface stayed intact.

## Guardrails

- new root code must not import `package:logging/logging.dart` directly
- if root compatibility code still needs logging, import it via transport
- do not grow a custom logging wrapper API unless the raw package surface
  becomes a proven problem

## What This Does Not Solve

This change does not remove the direct root `dio` dependency.

The root package still hosts real compatibility/provider clients that own
transport-heavy code paths, so `dio` removal still depends on additional
implementation movement.

## Validation

Validated with:

- `dart analyze`
- `dart analyze packages/llm_dart_transport`
- `dart test test/core/registry_test.dart`
- `dart test test/core/cancellation_test.dart`
- `dart test test/utils/dio/dio_logging_test.dart`
- `dart test test/providers/openai/openai_provider_bridge_test.dart test/providers/openai/openai_entrypoint_test.dart test/legacy_compatibility_test.dart`
