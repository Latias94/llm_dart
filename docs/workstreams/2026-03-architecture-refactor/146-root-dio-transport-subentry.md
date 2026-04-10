# 146. Root Dio Transport Sub-entry

## Goal

Remove the direct `dio` runtime dependency from the root `llm_dart` package
without re-promoting raw Dio types into the root default facade.

## Decision

`llm_dart_transport` now exposes explicit raw-Dio sub-entrypoints:

- `package:llm_dart_transport/dio.dart`
- `package:llm_dart_transport/dio_io.dart`

Root compatibility code, tests, and examples that still need raw Dio types must
import those transport-owned entrypoints instead of importing `package:dio`
directly.

## Why A Sub-entry Instead Of The Main Barrel

This keeps two architectural rules true at the same time:

1. transport-specific implementation types remain owned by the transport layer
2. the root default facade does not quietly re-export raw Dio again

That tradeoff matters because:

- `package:llm_dart/llm_dart.dart` and `package:llm_dart/ai.dart` should stay
  focused on the stable model-facing API
- `package:llm_dart/transport.dart` re-exports transport abstractions and
  common helpers, but should not become a convenience tunnel for every raw Dio
  symbol
- compatibility code still needs an honest migration path for `Dio`,
  `DioException`, `FormData`, `MultipartFile`, `ResponseBody`, and
  IO-specific adapters

An explicit sub-entrypoint preserves that migration path without widening the
default root surface again.

## What Changed

### Transport package

- added `packages/llm_dart_transport/lib/dio.dart`
- added `packages/llm_dart_transport/lib/dio_io.dart`

### Root code

Root-hosted compatibility/provider modules now import raw Dio through
transport-owned sub-entrypoints, including:

- compatibility HTTP helpers
- residual root-local provider clients
- root compatibility provider modules that still use multipart or raw
  `DioException` handling

### Tests and examples

Root tests and examples now use the same explicit transport-owned Dio entry:

- generic raw Dio imports use `package:llm_dart_transport/dio.dart`
- IO adapter tests use `package:llm_dart_transport/dio_io.dart`

### Package manifest

- root `pubspec.yaml` no longer lists `dio`

## Public API Implication

The stable root API stays transport-abstraction-first:

- `TransportClient` remains the promoted stable integration boundary
- `DioTransportClient` remains the explicit transport-owned implementation path
- raw Dio types remain available, but only through explicit transport imports

This means raw Dio remains available for compatibility and advanced integration
work without becoming part of the recommended root facade story again.

## Guardrails

- new root code must not import `package:dio/dio.dart` directly
- new IO-specific root code must not import `package:dio/io.dart` directly
- if compatibility code still needs raw Dio, import it from
  `llm_dart_transport`
- do not add a root `dio.dart` re-export just for convenience

## What This Does Not Solve

This change does not mean the root package is now thin enough.

The root still hosts compatibility/provider implementation weight, but that
weight now depends downward on the correct owning layer instead of carrying the
runtime dependency itself.

## Validation

Validated with:

- `dart pub get`
- `dart analyze`
- `dart analyze packages/llm_dart_transport`
- `dart test test/core/cancellation_test.dart test/core/dio_error_handler_test.dart test/utils/http_config_utils_test.dart test/builder/http_config_test.dart test/compat_transport_test.dart`
- `dart test test/utils/dio`
- `dart test test/providers/openai/openai_provider_bridge_test.dart test/providers/openai/openai_config_layering_test.dart`
- `dart test test/providers/ollama/ollama_provider_bridge_test.dart test/providers/elevenlabs/elevenlabs_provider_bridge_test.dart`
